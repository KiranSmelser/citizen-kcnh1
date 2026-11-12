# Run from the project root: Rscript scripts/check_medications.R
suppressPackageStartupMessages(source("R/descriptive/functions/cleaning_functions.R"))

drugs <- c("Diazepam", "Lorazepam", "Midazolam", "Fosphenytoin", "Cenobamate")
stopifnot(identical(normalize_medication_names(tolower(drugs)), drugs),
          identical(normalize_medication_names(c(" cenobamate ", "Unknown drug", NA_character_)),
                    c("Cenobamate", "Unknown drug", NA_character_)),
          all(grepl(MEDS_TO_USE, drugs)),
          all(drugs %in% names(ABBREVIATIONS_MEDS)),
          !anyDuplicated(unname(ABBREVIATIONS_MEDS[drugs])))

categories <- readr::read_csv(PATH_MED_CLASSIFIER, show_col_types = FALSE) %>%
  tidyr::pivot_longer(everything(), names_to = "category", values_to = "medication") %>%
  filter(medication %in% drugs)
stopifnot(nrow(categories) == length(drugs), !anyDuplicated(categories$medication),
          all(categories$category[categories$medication %in% drugs[1:3]] == "GABAergic"),
          categories$category[categories$medication == "Fosphenytoin"] == "Sodium Channel Blockers",
          categories$category[categories$medication == "Cenobamate"] == "Other/Multiple")

# Check the actual export without changing generated data or classifier worklists.
imported <- read_medication_aggregate()
stopifnot(all(drugs %in% imported$medication), !"cenobamate" %in% imported$medication)
durations <- clean_medication_data()
base_names <- sub(" \\d+$", "", durations$medication)
expected <- imported %>% filter(medication %in% drugs,
  medication_age_days_lastDate > medication_age_days_firstDate) %>% pull(medication) %>% unique()
stopifnot(all(expected %in% base_names))
category_durations <- prepare_medication_category_durations(durations)$df_plot_cat
stopifnot(all(expected %in% category_durations$medication_base),
          !anyNA(category_durations$medication))
# Selected top-ten drugs must retain their labels even outside the inherited order.
prep <- prepare_top_medications_over_age(durations)
top_ten <- durations %>% mutate(medication_base = sub(" \\d+$", "", medication)) %>%
  distinct(patient_uuid, medication_base) %>% count(medication_base, name = "participants") %>%
  arrange(desc(participants)) %>% slice_head(n = 10) %>% pull(medication_base)
stopifnot(!anyNA(prep$normalized_df$medication),
          setequal(prep$present_levels, recode(top_ten, !!!ABBREVIATIONS_MEDS)),
          all(c("DZP", "LTG", "PRD") %in% prep$present_levels))
synthetic <- prepare_top_medications_over_age(tibble(patient_uuid = c("a", "b"),
  medication = c("Levetiracetam", "Diazepam"),
  start_med_age = c(0, 0), end_med_age = c(365, 365)))
stopifnot(identical(synthetic$present_levels, c("LEV", "DZP")),
          !anyNA(synthetic$normalized_df$medication))
message("KCNH1 medication selection, capitalization, categories and top-ten display checks passed.")
