# Exact term coverage is checked before a classified figure can run.
term_key <- function(x) stringr::str_to_lower(stringr::str_squish(as.character(x)))

health_lookup <- function(prefix) {
  classifier <- read_classifier()
  cols <- names(classifier)[startsWith(names(classifier), prefix)]
  if (!length(cols)) stop("Classifier has no ", prefix, " columns")
  classifier %>%
    select(all_of(cols)) %>%
    tidyr::pivot_longer(everything(), names_to = "category", values_to = "term") %>%
    filter(!is.na(term), term != "") %>%
    mutate(key = if (prefix == "diagnosis_") term_key(term) else as.character(term)) %>%
    distinct(key, category)
}

check_classifier_coverage <- function() {
  sz <- read_seizure_history()
  dx <- read_clinical_diagnosis()
  hosp <- read_hospitalizations()
  hc <- readxl::read_excel(PATH_HOSPITALIZATION_CLASSIFIER)
  required <- c("Hospitalization Events", "Admission Type", "Subgroup")
  if (!all(required %in% names(hc))) stop("Invalid hospitalization classifier columns")
  if (any(!hc$`Admission Type` %in% c("Emergency", "Incidental", "Planned", "Exclude"))) {
    stop("Hospitalization Admission Type must be Emergency, Incidental, Planned or Exclude")
  }
  if (any(is.na(hc$Subgroup) & hc$`Admission Type` %in% c("Emergency", "Incidental"))) {
    stop("Emergency/Incidental hospitalization terms require a Subgroup")
  }
  hc <- hc %>% mutate(key = as.character(`Hospitalization Events`))
  if (anyDuplicated(hc$key)) stop("Duplicate hospitalization classifier terms")
  lookups <- list(seizure = health_lookup("seizure_"), diagnosis = health_lookup("diagnosis_"))
  allowed <- list(
    seizure = paste0("seizure_", c("focal", "spasms", "tonic-clonic", "clonic", "tonic",
                                  "myoclonic", "absence", "exclude")),
    diagnosis = paste0("diagnosis_", c("behavioral", "muscoloskeletal", "musculoskeletal",
      "gastro", "immune", "neuro", "sensory", "respiratory", "cardio", "exclude")))
  for (domain in names(lookups)) {
    lookup <- lookups[[domain]]
    if (any(!lookup$category %in% allowed[[domain]])) stop("Unknown ", domain, " classifier category")
    if (anyDuplicated(lookup$key)) stop("Multiple classifications for a ", domain, " term")
  }
  sources <- list(seizure = sz %>% transmute(patient_uuid, term = seizure_history_type),
                  diagnosis = dx %>% transmute(patient_uuid, term = clinical_diagnosis),
                  hospitalization = hosp %>% transmute(patient_uuid, term = admission_diagnosis))
  known <- list(seizure = lookups$seizure$key, diagnosis = lookups$diagnosis$key,
                hospitalization = hc$key)
  med_map <- readr::read_csv(PATH_MED_CLASSIFIER, show_col_types = FALSE)
  med_terms <- unlist(med_map, use.names = FALSE)
  if (any(med_terms %in% c("Cannabidiol", "Cannabinol", "Epidiolex"), na.rm = TRUE)) {
    med_terms <- c(med_terms, "Epidiolex/CBD")
  }
  sources$medication_category <- clean_medication_data() %>%
    transmute(patient_uuid, term = sub(" \\d+$", "", medication))
  known$medication_category <- as.character(med_terms)
  summary <- lapply(names(sources), function(domain) {
    terms <- sources[[domain]] %>%
      filter(!is.na(term), term != "") %>%
      mutate(key = if (domain == "diagnosis") term_key(term) else as.character(term)) %>%
      group_by(key, term) %>%
      summarise(records = n(), participants = n_distinct(patient_uuid), .groups = "drop")
    pending <- terms %>% filter(!key %in% known[[domain]]) %>% select(-key)
    readr::write_csv(pending, file.path(DATA_PROCESSED, paste0("unmapped_", domain, ".csv")))
    tibble(domain = domain, observed_terms = nrow(terms), unmapped_terms = nrow(pending),
           unmapped_records = sum(pending$records))
  }) %>% bind_rows()
  readr::write_csv(summary, file.path(RESULTS, "classifier_coverage.csv"))
  summary
}

require_classified <- function(domain) {
  n <- classifier_coverage$unmapped_terms[classifier_coverage$domain == domain]
  if (length(n) != 1 || n > 0) stop("Unmapped ", domain, " terms; see data/processed/unmapped_", domain, ".csv")
}

