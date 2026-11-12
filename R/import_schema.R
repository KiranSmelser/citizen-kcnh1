# Adapt the April 2026 Citizen export to the SCN2A/SCN8A descriptive API.
library(readxl)
library(dplyr)

read_citizen_sheet <- function(sheet, required) {
  df <- readxl::read_excel(PATH_CITIZEN_DATA, sheet = sheet)
  missing <- setdiff(c("patient_uuid", required), names(df))
  if (length(missing)) stop(sheet, ": missing columns: ", paste(missing, collapse = ", "))
  if (any(is.na(df$patient_uuid) | df$patient_uuid == "")) {
    stop(sheet, ": missing participant IDs")
  }
  df
}

read_citizen_data <- function() {
  read_citizen_sheet("operational", "most_recent_clinical_activity_age_days")
}

read_classifier <- function() readxl::read_excel(PATH_CLASSIFIER)

read_demographics <- function() {
  read_citizen_sheet("demographics", "sex_assigned_at_birth") %>%
    rename(sex = sex_assigned_at_birth)
}

normalize_medication_names <- function(x) {
  canonical <- c(names(ABBREVIATIONS_MEDS), "Epidiolex", "Cannabidiol", "Cannabinol")
  index <- match(tolower(trimws(x)), tolower(canonical))
  ifelse(is.na(index), x, canonical[index])
}

read_medication_aggregate <- function() {
  read_citizen_sheet("medication_aggregate", c("medication",
    "medication_earliestDate_age_days", "medication_latestDate_age_days")) %>%
    mutate(medication = normalize_medication_names(medication)) %>%
    rename(medication_age_days_firstDate = medication_earliestDate_age_days,
           medication_age_days_lastDate = medication_latestDate_age_days)
}

read_seizure_history <- function() {
  read_citizen_sheet("seizure_history", c("seizure_history_type",
    "seizure_history_value", "seizure_history_value_unit",
    "seizure_history_value_comparator", "seizure_history_reportDate_age_days")) %>%
    rename(seizure_history_age_days = seizure_history_reportDate_age_days,
           seizure_history_unit = seizure_history_value_unit) %>%
    mutate(
      # Legacy frequency inequalities were stored in the value string.
      seizure_history_value = if_else(is.na(seizure_history_value), NA_character_,
        paste0(recode(coalesce(seizure_history_value_comparator, ""),
                      `>=` = "≥", `<=` = "≤"), seizure_history_value)),
      seizure_history_unit = recode(seizure_history_unit, `Per Day (/24h)` = "Per Day")
    )
}

read_clinical_diagnosis <- function() {
  read_citizen_sheet("clinical_diagnosis", c("clinical_diagnosis",
    "clinical_diagnosis_earliestDate_age_days")) %>%
    rename(clinical_diagnosis_age_days_firstDate = clinical_diagnosis_earliestDate_age_days)
}

read_diagnosis_features <- function() {
  # The new export combines diagnosis information in clinical_diagnosis.
  read_clinical_diagnosis() %>% rename(diagnosis = clinical_diagnosis)
}

read_development_data <- function() {
  read_citizen_sheet("development", c("milestone", "milestone_status",
    "milestone_earliestDate_age_days")) %>%
    rename(domain_milestone = milestone, domain_status = milestone_status,
           domain_age_days_firstDate = milestone_earliestDate_age_days)
}

read_adverse_effects <- function() {
  read_citizen_sheet("adverse_effect", c("adverse_effect", "adverse_effect_severity"))
}

read_hospitalizations <- function() {
  read_citizen_sheet("encounter", c("admission_diagnosis", "admission_date_age_days")) %>%
    transmute(patient_uuid, admission_diagnosis, admission_diagnosis_code,
      admission_diagnosis_code_system,
      admission_significant_event = NA_character_,
      admission_significant_event_code = NA_character_,
      admission_significant_event_code_system = NA_character_,
      admission_firstDate = admission_date, admission_lastDate = discharge_date,
      admission_age_days_firstDate = admission_date_age_days,
      admission_age_days_lastDate = discharge_date_age_days)
}

read_growth <- function() {
  read_citizen_sheet("growth_parameter", c("growth_parameter", "growth_parameter_value",
    "growth_parameter_value_unit", "growth_parameter_reportDate_age_days")) %>%
    rename(growth_parameter_unit = growth_parameter_value_unit,
           growth_parameter_age_days = growth_parameter_reportDate_age_days)
}
