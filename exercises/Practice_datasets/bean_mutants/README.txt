SIMULATED DATA. COMMON BEAN MUTANT TRIALS
=========================================

These data are SIMULATED. They do not come from real trials, but they behave like real data.
Use them if you do not have a data set of your own, or to practise before you use your own data.

THE EXPERIMENT
  84 lines: 3 parent cultivars (not irradiated) and 81 mutant lines (27 from each parent).
  The mutants are advanced lines (M6) from seeds irradiated with gamma rays at three doses: 100, 200 and 300 Gy.
  3 environments:
     Site1_irrigated   site 1, with irrigation
     Site1_drought     site 1, terminal drought (no water at pod filling)
     Site2_rainfed     site 2, rainfed
  Design in each environment: randomized complete blocks, 3 blocks. Every line is once in each block.
  Each block has 7 rows and 12 columns (84 plots). In the file, row and column give the position.
  756 plots in total.

TRAITS (5, plus the seed coat colour)
  days_to_flowering (days), days_to_maturity (days), pods_per_plant (count),
  hundred_seed_weight_g (g), seed_yield_kg_ha (kg/ha), and seed_coat_colour (a class).
  See bean_data_dictionary.csv.

BE CAREFUL. LIKE REAL DATA, THIS FILE IS NOT PERFECT
  There are missing values (plots without emergence, values not recorded) and wrong values (typing
  errors, yield in t/ha instead of kg/ha, a wrong date).
  Two things are NOT mistakes, and you must think before you remove them:
     a few plots in Site1_drought gave no pods at all (the zero is real, not a missing value),
     and animals (goats) damaged a corner of one block in Site2_rainfed.
  Find the problems before you fit any model. Decide what to do with each one, and write why.

HOW TO START
  1. Open first_look.R and run it line by line.
  2. Clean the data: missing values, outliers, and think about the zeros.
  3. Fit a model for ONE environment (blocks, then rows and columns). Estimate the heritability.
  4. Fit the model for all environments together. Is there genotype by environment interaction?
     Which lines keep their yield under drought?
  5. Compare each mutant with its parent. Do the mutants differ from the parents?
  6. Does the dose change the mean or the variation of the mutants?
  7. Build a selection index (yield, early maturity, seed weight) and choose the best lines.
     Which seed coat colours appear? Is the colour important for the market?

The data are free to use for teaching. Please write "simulated data" when you show results.
Created with the R package FieldSimR (Werner et al.) for the plot errors.
