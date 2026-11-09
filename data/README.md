# Shared course datasets

Agree these datasets with all experts before writing the chapters, so examples connect from day to day.

| File | Content | Used in |
|---|---|---|
| `single_trial.csv` | One trial with rep, block, row, col (alpha-lattice) | Days 1–4 |
| `met_trials.csv` | Same genotypes in several environments | Day 5 |
| `mutant_population.csv` | M3–M5 lines with parent and checks, quantitative + qualitative traits | Days 6–9 |
| `radiosensitivity.csv` | Dose–response data (to be defined, Anand will not attend) | Week 2 |
| `Durum_wheat_Algeria.csv` | Durum wheat MET: 24 lines, 22 environments, 4 blocks | Day 5 (G×E) |
| `cassava_nir.csv` | Cassava NIR spectra (1050 wavelengths) and pigment concentration; 2009 to 2012 calibration, 2013 test. From the `rchemo` package (GPL-3), CIAT programme, Davrieux et al. 2016 | Day 5 (machine learning) |

Column names: `location, year, trial, rep, block, row, col, geno, check, generation` + traits (lower case, no spaces, units in the data dictionary).
