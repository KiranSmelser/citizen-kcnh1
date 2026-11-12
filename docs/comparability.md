# Source parity and comparability

The baseline is the local SCN2A code at commit
`aa305cce25932be123df11838bcd16f2cf6aeedc`. The SCN8A comparison was inspected at
`57d00e6a7056871106c9a0ad85ef2c38deca4ce6`. Neither source project's code was
modified. The manifest records the actual source-file contents read during setup.

## Retained source code

`R/descriptive/growth_analysis.R`, `R/descriptive/dev_regressions.R`, and both
`cleaning_utilities.R` files are copied verbatim from SCN2A. The retained portions
of `figures.R` and `plotting_functions.R` follow the source: Figures 14/15 and
their plotting helpers were removed. The requested KCNH1 Figure 4 y-axis extends
to 1 instead of the source limit of 0.75; its parity check reverses this explicit
exception before comparing source hashes.
Figure 3 wraps respiratory diagnosis labels at 35 characters and uses 9-point
text for that table so it fits beside the anatomy image and within the canvas;
diagnosis selection and percentages are unchanged.

The retained cleaning functions are also copied from SCN2A, with these reader
adaptations and the requested top-ten display correction described below:

- `read_excel(PATH_CITIZEN_DATA, sheet = "clinical_diagnosis_features")` becomes
  `read_diagnosis_features()` because the KCNH1 export has no separate feature
  sheet.
- Five direct reads of the old clinical-diagnosis sheet become
  `read_clinical_diagnosis()` so renamed age fields pass through the adapter.
- Longest-seizure-gap/SCB helpers were omitted with Figures 14/15.

No small-cohort substitutions, statistical simplifications, reordered medication
display, additional growth/medication filters, or altered age denominators are
applied. The explicitly requested KCNH1 medication-list exception is documented
below. Other source behavior and warnings are preserved. For example, the
top-ten selection and denominators are retained, and loess can warn on sparse
series. KCNH1's display list now appends selected medications missing from the
source order, so their labels remain valid instead of becoming a combined grey
NA group. Existing display order is retained for the medications already listed.

`R/data_import_functions.R` retains the SCN2A WHO-loading implementation. Its
other readers are replaced by the KCNH1 schema adapter. `R/config.R` uses the
KCNH1 input path and medication configuration needed by the copied code, without
unused downstream configuration.

## Requested KCNH1 medication-list exception

KCNH1 includes Diazepam, Lorazepam, Midazolam and Fosphenytoin in `MEDS_TO_USE`,
with abbreviations DZP, LZP, MDZ and fPHT. Cenobamate was already selected by the
configured canonical name and abbreviated CNB. The KCNH1 import adapter now
normalizes capitalization and surrounding whitespace for recognized medication
names, so the export's lowercase `cenobamate` reaches the existing filters,
abbreviation lookup and category join as `Cenobamate`. Unknown names and missing
values are preserved. All readers of the medication aggregate share this adapter.

The medication-category CSV adds Diazepam, Lorazepam and Midazolam under
GABAergic, and Fosphenytoin under Sodium Channel Blockers. Cenobamate retains its
existing Other/Multiple assignment. The top-ten display correction is the only
additional medication-cleaning change; the SCN8A/SCN2A repositories were not edited. These KCNH1 additions
are an intentional medication-inclusion difference when comparing cohorts.

Selection does not override the original positive-duration filter or the top-ten
cutoff. Selected top-ten drugs all retain display labels. In the current export, all four Midazolam aggregate
records have zero documented duration and therefore do not enter duration plots.
Rescue/acute records and their documentation spans should not be interpreted as
confirmed daily maintenance treatment. These changes do not infer individual
record indications or add the other supportive-treatment candidates.

Mechanism references: [Diazepam prescribing information](https://www.accessdata.fda.gov/drugsatfda_docs/label/2026/013263s095lbl.pdf)
and [Fosphenytoin prescribing information](https://www.accessdata.fda.gov/drugsatfda_docs/label/2020/210864s000lbl.pdf).
Run `Rscript scripts/check_medications.R` for the focused selection, normalization,
abbreviation and category checks on the KCNH1 export.

## KCNH1 schema adaptations

`R/import_schema.R` translates the April 2026 vocabulary to the old reader API:

| New export | Legacy API |
| --- | --- |
| `growth_parameter` | `read_growth()`, old unit/age column names |
| `adverse_effect` | `read_adverse_effects()` |
| `encounter` | `read_hospitalizations()`, legacy column order including admission age in column 10 |
| `sex_assigned_at_birth` | `sex` |
| `milestone`, `milestone_status`, earliest milestone age | `domain_milestone`, `domain_status`, `domain_age_days_firstDate` |
| Earliest/latest documented medication ages | Medication first/last documented ages |
| Earliest documented diagnosis age | Diagnosis first documented age |
| Seizure report age | `seizure_history_age_days` |
| Separate frequency comparator and numeric value | Legacy inequality/value string, with `>=`/`<=` represented as `≥`/`≤` |
| `Per Day (/24h)` | Legacy `Per Day` frequency unit |

Unused legacy admission significant-event fields are blank; no clinical meaning
is inferred for them. The admission reader preserves the positional interface
used by the unchanged hospitalization functions.

The old diagnosis-feature sheet has no direct counterpart. Distinct
participant/diagnosis pairs from the new clinical-diagnosis sheet feed the same
classifier and calculations. This is an input-source difference: identical code
does not make the two export ontologies identical. Review the KCNH1 vocabulary
and exclusions before interpreting comparisons.

Medication durations remain spans of documented records; no missing endpoint is
imputed. The source's treatment of missing frequencies, units, sex, age rounding,
and unmatched frequency indices is retained. In particular, the growth figure
uses days / 30.4375, whereas the separate growth-model script uses days / 30,
exactly as in SCN2A.

## Existing SCN8A/SCN2A differences

A single KCNH1 implementation cannot be identical to both existing projects:

| Component | Difference already present in source projects | KCNH1 baseline |
| --- | --- | --- |
| Seizure figure | SCN2A excludes Spasms after age 5 and uses a different type order | SCN2A |
| Diagnosis classification | SCN8A uses its separate diagnosis-grouping workbook; SCN2A uses health-classifier diagnosis columns | SCN2A |
| Medications | Fixed display order and some CBD normalization differ | SCN2A |
| Adverse-effect heatmap | SCN8A restricts medications to a fixed abbreviation list; SCN2A orders observed medications by participant count | SCN2A |
| Appointment figures | SCN8A censors at last medication end; SCN2A uses all source ages for its clinical-diagnosis cohort and includes zero counts | SCN2A |
| Plot styling | Palettes, legend placement, and some scale settings differ | SCN2A |

The older source projects were not harmonized in this task. Cross-gene analyses
should account for these existing differences rather than assuming all three
implementations were already the same.

## Verification

Run `Rscript scripts/check_descriptive.R` after the pipeline. It checks the
source hashes after reversing only the reader substitutions listed above,
checks unchanged reference assets, and exercises cohort tracking, classifier
gates, seizure comparator/unit conversion, and legacy hospitalization layout.
It does not require the sibling repositories to be present.

The runner is orchestration: it executes unchanged figure sections independently
and holds incomplete classifier-dependent stages. The descriptive participant
tracker is the original SCN2A script with only timeline/cluster sections removed;
it is held until the required classifiers are complete. Source-availability
audits are separate and do not enter the copied analyses. Classifier seeds require the separate review in `classifiers.md`.
