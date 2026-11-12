# citizen-kcnh1

Citizen KCNH1 processing through the descriptive workflow, using the existing
SCN2A code as the comparison baseline. The supplied April 2026 export contains
16 participants; cohort size is read from the workbook.

SCN8A and SCN2A are not identical to each other. This project follows the newer
SCN2A implementation, with export-schema adaptations, classifier review,
KCNH1 medication-list additions, and removal of downstream analyses. See [comparability](docs/comparability.md)
for the exact exceptions and the existing SCN8A/SCN2A differences.

```text
R/
  config.R
  data_import_functions.R
  import_schema.R
  cleaning_utilities.R
  run_descriptive.R
  descriptive/
    figures.R
    growth_analysis.R
    dev_regressions.R
    patient_tracker.R
    functions/
data/
  raw/
  classifiers/
  processed/
output/
  figures/
  results/
docs/
scripts/
```

The workbook is at `data/raw/Citizen_CZI_KCNH1_2026.04.28.xlsx`. It and generated
outputs are ignored by Git. Shared WHO/index tables, the anatomy image, and
generic classifier seeds are included. No other cohort's participant labels or
processed results were copied.

## Run

Open `citizen-kcnh1.Rproj` or work from this repository's root. Install missing
packages once, using the same R/package versions as the comparison analyses when
reproducing outputs:

```r
install.packages(c("readxl", "readr", "dplyr", "tidyr", "tibble", "stringr",
                   "ggplot2", "purrr", "gridExtra", "ggpubr", "png",
                   "colorspace", "RColorBrewer", "ggh4x", "ggstatsplot",
                   "lme4", "broom.mixed", "emmeans"))
```

```sh
Rscript R/run_descriptive.R
Rscript scripts/check_descriptive.R
```

In RStudio, `source("R/run_descriptive.R")` runs the same entry point. To change
the input workbook, update `PATH_CITIZEN_DATA` in `R/config.R`.

The runner executes the original figure sections through Figure 13, the original
growth mixed-model analysis, and developmental event detection. This preserves
smoothing, statistical boxplots, medication selection/order, denominators,
filters, Fisher tests, multiple-testing adjustments, model specifications,
contrasts, palettes, plot limits, dimensions, and 600-dpi exports from SCN2A.
The batch runner exports developmental events instead of opening the source
script's final interactive `View()` window.

## Classifiers and results

Review [the classifier guide](docs/classifiers.md). Draft mappings have been added
for the initial 12 unmapped seizure terms, 252 diagnosis terms and 13
hospitalization terms. All new entries are yellow in their respective Excel
classifiers and still need human review. This includes provisional exclusions
and inferred admission types. Medication-category coverage is complete for the
selected medications; inherited assignments also remain draft seeds.

All 14 stages now complete with the draft mappings and no unmapped terms remain.
The row/cell rationale is recorded in `docs/classifier_review.csv`. Excel colors
and review-log status do not gate the analysis, so these outputs remain drafts
until the mappings are accepted. If new unmapped terms appear, the runner records
`pending_classifier` for affected stages and runs the remaining stages.
Unexpected errors are recorded as `failed` and return a nonzero exit
status. Previous files owned by the runner are removed before each run to avoid
stale outputs.

- `output/results/analysis_status.csv`: completion, pending stages, and failures.
- `output/results/analysis_warnings.csv`: warnings from the unchanged source
  analyses, including smoothing and plotting warnings; methods are not altered
  in response to the smaller cohort.
- `output/results/growth_zscore_mixed_model_contrasts.csv`: original growth output.
- `output/figures/`: original numbered descriptive figure exports.
- `output/results/classifier_coverage.csv` and `data/processed/unmapped_*.csv`:
  classifier worklists. Edit the classifiers rather than these regenerated files.
- `data/processed/`: adapted input sheets and, once classifiers are complete,
  the original descriptive participant tracker with its five inclusion flags.
- `output/results/sessionInfo.txt`: R and package versions used.

The runner also produces source-availability and medication-filter audits. These
checks reflect the KCNH1 medication-list additions documented in
`docs/comparability.md`; other source inclusion rules are retained. The parity check pins
the retained source code and shared reference assets to the hashes in
`docs/source_parity.csv` and verifies the KCNH1 adapters.

Timeline, cluster, feature-importance, subgroup, and separate odds-ratio analysis
directories are excluded. Figures 14/15 and their longest-seizure-gap helpers are
also excluded because they depend on later analyses. Fisher tests and growth
mixed models remain because they are part of the existing descriptive workflow.
