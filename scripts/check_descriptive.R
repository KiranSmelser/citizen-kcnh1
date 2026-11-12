# Run from the project root after Rscript R/run_descriptive.R.
# Hashes are pinned to source code after removing only downstream sections.
manifest <- read.csv("docs/source_parity.csv", stringsAsFactors = FALSE)
text_md5 <- function(text) {
  path <- tempfile()
  on.exit(unlink(path))
  writeLines(text, path, useBytes = TRUE)
  unname(tools::md5sum(path))
}
for (i in seq_len(nrow(manifest))) {
  path <- manifest$file[i]
  if (manifest$type[i] == "binary") {
    actual <- unname(tools::md5sum(path))
  } else {
    text <- paste(readLines(path, warn = FALSE), collapse = "\n")
    # Reverse the requested KCNH1 Figure 4 y-axis extension.
    if (path == "R/descriptive/figures.R") {
      text <- gsub("ylim = c(0, 1)", "ylim = c(0, 0.75)", text, fixed = TRUE)
    }
    if (path == "R/descriptive/functions/plotting_functions.R") {
      text <- gsub('size = if (system == "Respiratory") 9 else 12, ', "", text, fixed = TRUE)
      text <- gsub(paste0(
        "    if (system == \"Respiratory\") {\n",
        "      diag_pct$Diagnosis <- stringr::str_wrap(diag_pct$Diagnosis, width = 35)\n",
        "    }\n"), "", text, fixed = TRUE)
    }
    # Reverse only the enumerated KCNH1 schema adaptations.
    if (path == "R/descriptive/functions/cleaning_functions.R") {
      # Reverse the requested fix that retains top-ten drugs outside the display list.
      text <- gsub(paste0(
        "  present_levels <- c(front_to_back_levels[front_to_back_levels %in% normalized_df$medication],\n",
        "                      setdiff(unique(normalized_df$medication), front_to_back_levels))"),
        "  present_levels <- front_to_back_levels[front_to_back_levels %in% normalized_df$medication]",
        text, fixed = TRUE)
      text <- gsub("read_diagnosis_features()",
        'read_excel(PATH_CITIZEN_DATA, sheet = "clinical_diagnosis_features")', text, fixed = TRUE)
      text <- gsub("read_clinical_diagnosis()",
        'readxl::read_excel(\n    PATH_CITIZEN_DATA,\n    sheet = "clinical_diagnosis"\n  )', text, fixed = TRUE)
    }
    actual <- text_md5(text)
  }
  if (!identical(actual, manifest$source_md5[i])) stop("Source parity failed: ", path)
}

suppressPackageStartupMessages({
  source("R/descriptive/functions/cleaning_functions.R")
  source("R/descriptive/functions/classifier_checks.R")
})
classifier_coverage <- check_classifier_coverage()
cohort <- read_citizen_data()$patient_uuid
status <- readr::read_csv(file.path(RESULTS, "analysis_status.csv"), show_col_types = FALSE)
tracker_path <- file.path(DATA_PROCESSED, "patient_tracker.csv")
if (status$status[status$analysis == "patient_tracker"] == "complete") {
  tracker <- readr::read_csv(tracker_path, show_col_types = FALSE)
  stopifnot(all(tracker$patient_uuid %in% cohort),
    identical(names(tracker), c("patient_uuid", "seizure", "medication", "growth", "diagnosis", "hospitalization")))
} else stopifnot(!file.exists(tracker_path))
counts <- clean_appointment_counts_all_patients()
stopifnot(nrow(counts) == 2 * length(unique(read_clinical_diagnosis()$patient_uuid)))
for (domain in c("seizure", "diagnosis", "hospitalization")) {
  if (classifier_coverage$unmapped_terms[classifier_coverage$domain == domain] > 0) {
    err <- tryCatch({ require_classified(domain); NULL }, error = identity)
    stopifnot(inherits(err, "error"))
  }
}

# Exercise the new comparator/unit adapter through the original index-based cleaner.
sz <- clean_seizure_data(TRUE)
stopifnot(nrow(sz) > 0, all(c("value", "unit", "age_days", "index") %in% names(sz)),
          is.numeric(sz$value), !anyNA(sz$index))
hosp <- read_hospitalizations()
stopifnot(names(hosp)[1] == "patient_uuid", names(hosp)[2] == "admission_diagnosis",
          names(hosp)[10] == "admission_age_days_firstDate")
stopifnot(!any(status$status == "failed"))
message("Source parity and KCNH1 import checks passed.")
