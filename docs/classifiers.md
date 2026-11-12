# KCNH1 classifier review

The classifier files are **draft term mappings inherited from SCN2A**, not newly
validated KCNH1 classifications. Review the inherited assignments as well as the
new terms. No SCN2A/SCN8A participant IDs, subgroup assignments, functional variant
labels, overlap lists, or patient-to-PDF mappings were copied.

## Draft KCNH1 additions

All 277 previously unmapped terms now have a proposed assignment in the existing
first worksheet of their respective classifier workbooks. Every new health term
cell and every new hospitalization row is filled **yellow (`#FFFF00`)**. Original
entries were preserved. Yellow means **needs your review**, including entries
placed in an exclusion column; it does not mean approved or clinically validated.

- Health workbook: 12 seizure terms and 252 diagnosis terms added.
- Hospitalization workbook: 13 rows added, including proposed admission types.
- Nine nonspecific seizure labels were provisionally placed in `seizure_exclude`
  rather than inferring their semiology. This excludes them from the type figure,
  not from the cohort or from an epilepsy diagnosis.
- Forty-eight diagnosis terms were provisionally placed in `diagnosis_exclude`,
  chiefly endocrine/metabolic, skin, genitourinary, normal-development or
  nonspecific findings outside the existing eight-system grouping.
- All 13 new admission-type assignments need context review: diagnosis wording
  alone does not establish Emergency, Incidental or Planned status. Feeding
  problem follows the inherited hospitalization Behavioral convention; review
  that assignment in particular if GI is preferred.

`docs/classifier_review.csv` lists each added term, target cell, proposed category,
reason, review attention, and `Needs review` status. Edit category assignments in
the Excel classifiers; the CSV is a record of this draft pass, not an input to
the pipeline. Remove a yellow fill after accepting an assignment, or move/correct
the term and keep it yellow until reviewed. The R code reads values, not colors
or this review log.

The unchanged analysis pipeline now has complete term coverage and runs all 14
stages with these **draft** mappings. Successful execution is a technical check,
not completion of the human review. No analysis code was changed during mapping.

Assignments are draft inferences based primarily on the inherited dictionary's
semantic conventions. General seizure context/duration labels were not forced
into a motor type, consistent with the distinction between seizure classes and
descriptors in the [ILAE position paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC12169392/).
The [HPO hierarchy](https://www.informatics.jax.org/vocab/hp_ontology/) distinguishes
integument, metabolism/homeostasis and genitourinary findings from the retained
systems; these references do not certify individual proposed mappings.

## Initial coverage before mapping

The first run on `Citizen_CZI_KCNH1_2026.04.28.xlsx` found:

| Classifier | Work needed | Figures held until coverage is complete |
| --- | --- | --- |
| `ciitizen_health_classifier.xlsx`, `seizure_*` columns | 21 observed terms; 12 terms (244 records) were unmapped | 2B |
| Same workbook, `diagnosis_*` columns | 463 observed terms; 252 terms (526 records) were unmapped | 3 |
| `Grouping Hospitalizations.xlsx` | 39 observed admission diagnoses; 13 terms (26 records) were unmapped | 2C, 2D |
| `med_categories.csv` | Review inherited medication mechanisms; all observed selected medication labels are covered | 5A can run with the draft map |

Run `Rscript R/run_descriptive.R` from the project root to regenerate the current
coverage report at `output/results/classifier_coverage.csv` and these worklists:

- `data/processed/unmapped_seizure.csv`
- `data/processed/unmapped_diagnosis.csv`
- `data/processed/unmapped_hospitalization.csv`
- `data/processed/unmapped_medication_category.csv`

Each worklist contains the exact observed term and record/participant counts.
These files are regenerated, so **edit the classifier files, not the worklists**.
Matching follows the original source code: diagnosis keys ignore case and repeated
whitespace; seizure, admission and medication terms use the source spelling.
The coverage checker never assigns new categories automatically. This draft pass
added proposed assignments for your review. Coverage completion indicates that
every term has a mapping or explicit exclusion; it does not establish clinical
validity.

## Health classifier

Keep the first worksheet and the existing wide format: column headers are
categories, and the cells below each header contain terms. Add each term to
exactly one column within its domain. Blank padding is allowed; duplicate terms
across categories are rejected.

Seizure columns: `seizure_focal`, `seizure_spasms`, `seizure_tonic-clonic`,
`seizure_clonic`, `seizure_tonic`, `seizure_myoclonic`, `seizure_absence`, and
`seizure_exclude`. Use the last column for reviewed terms that do not belong in
the plotted seizure-type categories. General terms such as “Seizure”, provoked
events, and status epilepticus require an explicit review decision; their new
yellow exclusion entries remain provisional. The inherited assignments also
warrant review; they were preserved during this draft pass.

Diagnosis columns: `diagnosis_behavioral`, `diagnosis_muscoloskeletal` (the
inherited spelling; `diagnosis_musculoskeletal` is also supported),
`diagnosis_gastro`, `diagnosis_immune`, `diagnosis_neuro`, `diagnosis_sensory`,
`diagnosis_respiratory`, `diagnosis_cardio`, and `diagnosis_exclude`. Use the last
column for reviewed terms outside the eight-system descriptive figure. The new
export has no `clinical_diagnosis_features` sheet, so the pipeline uses distinct
participant/diagnosis pairs from `clinical_diagnosis`.

Only seizure and diagnosis columns were retained from the original health
classifier. EEG and other downstream mappings are outside this setup.

## Hospitalizations

Keep `Hospitalization Events`, `Admission Type`, and `Subgroup` on the first
worksheet. `Type` is retained for compatibility but is unused here. Add one row
per diagnosis term. `Admission Type` must be `Emergency`, `Incidental`, `Planned`,
or `Exclude`. Emergency and incidental rows require a nonblank subgroup.

As in the source analyses, the figures retain Emergency/Incidental rows. Figure
2D displays the Seizure, Status epilepticus, Pulmonary, Infection, and GI series.
The KCNH1 encounter sheet only labels the diagnosis class as “Hospital admission”;
it does not supply these clinical groupings. The classifier therefore requires
review rather than inferring admission urgency from that field.

## Medications

`med_categories.csv` retains the source wide format: medication names under
mechanism columns. The existing steroid exclusion for the category-duration
figure is retained. ACTH and CBD names are normalized as in SCN2A.

`R/config.R` contains the inherited medication-selection expression and
abbreviations plus the requested KCNH1 additions: Diazepam (DZP), Lorazepam (LZP),
Midazolam (MDZ) and Fosphenytoin (fPHT). The first three are GABAergic; Fosphenytoin
is a Sodium Channel Blocker. Cenobamate retains CNB and Other/Multiple, with the
import adapter fixing capitalization before selection and category joins.
See [comparability](comparability.md) for this intentional KCNH1-only exception.
Review `output/results/medication_filter_audit.csv` after rerunning to check which
of the export's medication names it selects. This is separate from category
coverage: complete mechanism coverage cannot detect a relevant drug omitted by
the selection expression. Top medications are selected by participant count.
The source display order is retained, with other selected top-ten medications
appended so every selected medication has a valid label and colour. This fixes
the combined grey NA group produced by the original fixed display list.

## Other mappings and downstream classifiers

- `subgroups*.csv`: any future KCNH1 participant or variant groups must be built
  afresh; sodium-channel GoF/LoF labels were not carried over.
- `initial_seizure_types_classifier.xlsx`: review/rebuild before adding an
  initial-seizure/onset classification analysis; unused in these descriptives.
- `effects_severity.xlsx` is included as the seed required by the original
  descriptive Fisher helper. Its severity-filter join is commented out in the
  source, so the current heatmap is not severity-filtered and does not use the
  assignments. Review/rebuild the map before enabling a severity filter. All 90
  exported adverse-effect severity cells are missing.
- `denver_skills_map.csv`: review vocabulary coverage before milestone scoring.
  The current Able-to-Unable event listing uses no developmental score map.
- The five shared seizure-frequency index workbooks are included unchanged,
  because the source seizure cleaner loads them. The KCNH1 import adapter joins
  the separate comparator/value fields and translates the daily unit to the
  legacy vocabulary. Their indices are not used by the type-by-age plot.

Downstream patient classifiers and analysis directories are not included. Shared
reference tables and the severity seed needed by the original descriptive code
are included.
