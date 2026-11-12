# R/config.R
# Global configuration for file paths and parameters

# Data directories
DATA_RAW <- "./data/raw/"
DATA_PROCESSED <- "./data/processed/"
DATA_CLASSIFIERS <- "./data/classifiers/"

# Data files
PATH_CITIZEN_DATA <- file.path(DATA_RAW, "Citizen_CZI_KCNH1_2026.04.28.xlsx")

# WHO Data
PATH_HEAD_BOYS <- file.path(DATA_RAW, "hcfa-boys-0-5-zscores.xlsx")
PATH_HEAD_GIRLS <- file.path(DATA_RAW, "hcfa-girls-0-5-zscores.xlsx")
PATH_WEIGHT_BOYS <- file.path(DATA_RAW, "wfa_boys_0-to-5-years_zscores.xlsx")
PATH_WEIGHT_GIRLS <- file.path(DATA_RAW, "wfa_girls_0-to-5-years_zscores.xlsx")
PATH_HEIGHT_BOYS_0_TO_2 <- file.path(DATA_RAW, "lhfa_boys_0-to-2-years_zscores.xlsx")
PATH_HEIGHT_BOYS_2_TO_5 <- file.path(DATA_RAW, "lhfa_boys_2-to-5-years_zscores.xlsx")
PATH_HEIGHT_GIRLS_0_TO_2 <- file.path(DATA_RAW, "lhfa_girls_0-to-2-years_zscores.xlsx")
PATH_HEIGHT_GIRLS_2_TO_5 <- file.path(DATA_RAW, "lhfa_girls_2-to-5-years_zscores.xlsx")

# Output directories
FIGS <- "./output/figures/"
RESULTS <- "./output/results/"

# Classifier files
PATH_CLASSIFIER <- file.path(DATA_CLASSIFIERS, "ciitizen_health_classifier.xlsx")
PATH_HOSPITALIZATION_CLASSIFIER <- file.path(DATA_CLASSIFIERS, "Grouping Hospitalizations.xlsx")
PATH_MED_CLASSIFIER <- file.path(DATA_CLASSIFIERS, "med_categories.csv")
PATH_EFFECTS_SEVERITY <- file.path(DATA_CLASSIFIERS, "effects_severity.xlsx")

# Shared seizure-frequency reference tables used by the source descriptive cleaner.
PATH_TC_INDEX <- file.path(DATA_RAW, "tonic-clonic_index.xlsx")
PATH_FOCAL_INDEX <- file.path(DATA_RAW, "focal_index.xlsx")
PATH_MYOCLONIC_INDEX <- file.path(DATA_RAW, "myoclonic_index.xlsx")
PATH_ABSENCE_INDEX <- file.path(DATA_RAW, "absence_index.xlsx")
PATH_TONIC_INDEX <- file.path(DATA_RAW, "tonic_index.xlsx")

# Medication names (KCNH1 also includes the rescue/acute agents below).
MEDS_TO_USE <- paste(
  c("Adrenocorticotropin (ACTH 1-18),I-125 (TYR)", "ACTH", "Clonazepam", "Levetiracetam", 
    "Phenytoin", "Oxcarbazepine", "Carbamazepine", "Phenobarbital", 
    "Lamotrigine", "Briveracetam", "Brivaracetam", "Cannabidiol", "Clobazam", "Epidiolex", 
    "Eslicarbazepine", "Ethosuximide", "Felbamate", "Gabapentin", 
    "Prednisolone", "Lacosamide", "Primidone", "Rufinamide", "Topiramate", 
    "Valproate", "Vigabatrin", "Zonisamide", "Stiripentol", "Tiagabine", 
    "Perampanel", "Pregabalin", "Cannabinol", "Cenobamate", "Fenfluramine",
    "Tetrahydrocannabinol", "Acetazolamide", "Methylprednisolone", "Prednisone",
    "Diazepam", "Lorazepam", "Midazolam", "Fosphenytoin"),
  collapse = "|"
)

# Abbreviations for meds and seizures
ABBREVIATIONS_MEDS <- c(
  "Oxcarbazepine" = "OXC",
  "Lacosamide" = "LCM",
  "Phenytoin" = "PHT", 
  "Valproate" = "VPA", 
  "Lamotrigine" = "LTG", 
  "Carbamazepine" = "CBZ", 
  "Rufinamide" = "RFM",
  "Eslicarbazepine" = "ESL", 
  "Clonazepam" = "CLZ",
  "Clobazam" = "CLB",
  "Diazepam" = "DZP",
  "Lorazepam" = "LZP",
  "Midazolam" = "MDZ",
  "Fosphenytoin" = "fPHT",
  "Phenobarbital" = "PBT", 
  "Vigabatrin" = "VBG", 
  "Felbamate" = "FBM",
  "Primidone" = "PRM", 
  "Stiripentol" = "STP", 
  "Tiagabine" = "TGB", 
  "Zonisamide" = "ZNS",
  "Gabapentin" = "GBP",
  "Ethosuximide" = "ETX", 
  "Levetiracetam" = "LEV", 
  "Briveracetam" = "BRV",
  "Brivaracetam" = "BRV", 
  "ACTH" = "ACTH",
  "Epidiolex/CBD" = "CBD",
  "Topiramate" = "TPM",
  "Prednisolone" = "PRD",
  "Perampanel" = "PER",
  "Pregabalin" = "PGB",
  "Cenobamate" = "CNB",
  "Fenfluramine" = "FFA",
  "Tetrahydrocannabinol" = "THC",
  "Acetazolamide" = "AZM",
  "Methylprednisolone" = "MP",
  "Prednisone" = "PDN",
  "None" = "None"
)
