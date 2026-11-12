# Run from the repository root: Rscript R/run_descriptive.R
packages <- c("readxl", "readr", "dplyr", "tidyr", "tibble", "stringr", "ggplot2",
              "purrr", "gridExtra", "ggpubr", "png", "colorspace", "RColorBrewer",
              "ggh4x", "ggstatsplot", "lme4", "broom.mixed", "emmeans")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required R packages: ", paste(missing, collapse = ", "))
if (!file.exists("R/config.R")) stop("Run from the citizen-kcnh1 repository root")
suppressPackageStartupMessages({
  source("R/config.R")
  source("R/descriptive/functions/cleaning_functions.R")
  source("R/descriptive/functions/plotting_functions.R")
  source("R/descriptive/functions/classifier_checks.R")
})
for (path in c(DATA_PROCESSED, FIGS, RESULTS)) dir.create(path, recursive = TRUE, showWarnings = FALSE)

# Each run replaces its own generated files; never touch raw inputs or classifiers.
figure_names <- c("fig_2b", "fig_2c", "fig_2d", "fig_3", "fig_4", "fig_5", "fig_5a",
                  "fig_6", "fig_11", "fig_12", "fig_13")
unlink(file.path(FIGS, paste0(figure_names, ".jpeg")))
unlink(file.path(DATA_PROCESSED, "patient_tracker.csv"))
result_names <- c("analysis_status", "developmental_regressions", "growth_zscores",
  "growth_summary", "medication_category_durations", "seizures_by_age", "hospitalization_counts",
  "diagnoses_by_system", "diagnosis_percentages", "medication_durations", "medications_by_age",
  "adverse_effect_counts", "record_intervals", "record_counts", "classifier_coverage",
  "data_inventory", "medication_filter_audit", "demographics_summary",
  "growth_zscore_mixed_model_contrasts", "analysis_warnings")
unlink(c(file.path(RESULTS, paste0(result_names, ".csv")), file.path(RESULTS, "sessionInfo.txt")))

operational <- read_citizen_data()
demo <- read_demographics()
cohort_ids <- operational$patient_uuid
if (anyDuplicated(cohort_ids) || anyDuplicated(demo$patient_uuid) ||
    !setequal(cohort_ids, demo$patient_uuid)) stop("Operational/demographics cohort mismatch or duplicate IDs")
message("KCNH1 participants: ", length(cohort_ids))
imported <- list(seizure = read_seizure_history(), medication = read_medication_aggregate(),
                 diagnosis = read_clinical_diagnosis(), development = read_development_data(),
                 growth = read_growth(), hospitalization = read_hospitalizations(),
                 adverse_effect = read_adverse_effects())
for (domain in names(imported)) {
  df <- imported[[domain]]
  if (any(!df$patient_uuid %in% cohort_ids)) stop(domain, ": IDs outside operational cohort")
  readr::write_csv(df, file.path(DATA_PROCESSED, paste0(domain, ".csv")))
}
inventory <- dplyr::bind_rows(lapply(names(imported), function(domain) {
  tibble(domain = domain, records = nrow(imported[[domain]]),
         participants = dplyr::n_distinct(imported[[domain]]$patient_uuid),
         cohort_n = length(cohort_ids))
}))
readr::write_csv(inventory, file.path(RESULTS, "data_inventory.csv"))
med_audit <- imported$medication %>% count(medication, name = "records") %>%
  mutate(selected_by_medication_filter = grepl(MEDS_TO_USE, medication))
readr::write_csv(med_audit, file.path(RESULTS, "medication_filter_audit.csv"))
readr::write_csv(dplyr::count(demo, sex, name = "participants"), file.path(RESULTS, "demographics_summary.csv"))
classifier_coverage <- check_classifier_coverage()
message("Inherited term mappings are draft seeds; review docs/classifiers.md before interpretation.")

analysis_status <- tibble(analysis = character(), status = character(), detail = character())
analysis_warnings <- tibble(analysis = character(), warning = character())
run_analysis <- function(name, expr, classifier = NULL) {
  pending <- !is.null(classifier) &&
    any(classifier_coverage$unmapped_terms[classifier_coverage$domain %in% classifier] > 0)
  if (pending) {
    status <- "pending_classifier"
    detail <- paste0("Complete ", paste(classifier, collapse = ", "),
                     " classifier reviews; see data/processed/unmapped_*.csv")
  } else {
    detail <- tryCatch(withCallingHandlers({ eval.parent(substitute(expr)); "" },
      warning = function(w) {
        analysis_warnings <<- bind_rows(analysis_warnings,
          tibble(analysis = name, warning = conditionMessage(w)))
        invokeRestart("muffleWarning")
      }), error = function(e) conditionMessage(e))
    status <- if (detail == "") "complete" else "failed"
  }
  analysis_status <<- bind_rows(analysis_status, tibble(analysis = name, status = status, detail = detail))
  message(name, ": ", status, if (detail != "") paste0(" — ", detail))
}

run_analysis("patient_tracker", source("R/descriptive/patient_tracker.R"),
             classifier = c("seizure", "diagnosis", "hospitalization"))
run_analysis("developmental_regressions", {
  # Keep the source file identical; skip its final interactive View() in batch mode.
  dev_code <- parse("R/descriptive/dev_regressions.R")
  stopifnot(identical(dev_code[[length(dev_code)]], quote(View(dev_regressions))))
  eval(dev_code[-length(dev_code)])
  readr::write_csv(dev_regressions, file.path(RESULTS, "developmental_regressions.csv"))
})
run_analysis("growth_models", source("R/descriptive/growth_analysis.R"))

# Execute unchanged SCN2A figure sections independently, so unfinished KCNH1
# classifiers hold only their own outputs. Expressions within sections are intact.
figure_code <- readLines("R/descriptive/figures.R", warn = FALSE)
starts <- grep("^# Figure (2B|2C|2D|3|4|5|5a|6|11|12|13)$", figure_code)
ends <- c(starts[-1] - 1L, length(figure_code))
figure_ids <- sub("# Figure ", "", figure_code[starts], fixed = TRUE)
classifier_for <- c(`2B` = "seizure", `2C` = "hospitalization", `2D` = "hospitalization",
                     `3` = "diagnosis", `5a` = "medication_category")
for (i in seq_along(starts)) {
  domain <- unname(classifier_for[figure_ids[i]])
  if (is.na(domain)) domain <- NULL
  run_analysis(paste0("fig_", tolower(figure_ids[i])),
    eval(parse(text = figure_code[starts[i]:ends[i]])), classifier = domain)
}
readr::write_csv(analysis_status, file.path(RESULTS, "analysis_status.csv"))
readr::write_csv(analysis_warnings, file.path(RESULTS, "analysis_warnings.csv"))
if (nrow(analysis_warnings)) message(nrow(analysis_warnings), " warnings recorded in output/results/analysis_warnings.csv")
writeLines(capture.output(sessionInfo()), file.path(RESULTS, "sessionInfo.txt"))
if (any(analysis_status$status == "failed")) stop("Descriptive stages failed; see output/results/analysis_status.csv")
if (any(analysis_status$status == "pending_classifier")) {
  message("Available descriptive stages finished. Classified stages await the term reviews listed in analysis_status.csv.")
} else message("All descriptive stages finished.")
