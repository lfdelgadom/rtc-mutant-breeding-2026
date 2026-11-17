SIMULATED DATA. DURUM WHEAT MUTANT TRIALS
=========================================

These data are SIMULATED. They do not come from real trials, but they behave like real data.
Use them if you do not have a data set of your own, or to practise before you use your own data.

THE EXPERIMENT
  105 lines: 3 parent cultivars (not irradiated) and 102 mutant lines (34 from each parent).
  The mutants are advanced lines (M5) from seeds irradiated with gamma rays at three doses: 150, 200 and 250 Gy.
  4 environments (2 locations x 2 years):
     North_2024   normal rainfall
     South_2024   normal rainfall
     North_2025   dry year
     South_2025   dry year
  Design in each environment: 2 blocks, each with 8 rows and 8 columns (128 plots).
  This is a PARTIALLY REPLICATED design, like many real mutant trials with little seed:
     the 3 parents are in both blocks, 30 mutants are in both blocks, 62 mutants are in only one block,
     and 10 mutants are not tested in that environment (a different 10 in each environment).
  512 plots in total. In the file, row and column give the position.

TRAITS (5, plus 2 classes)
  days_to_heading (days), plant_height_cm (cm), spikes_per_m2 (count), thousand_kernel_weight_g (g),
  grain_yield_t_ha (t/ha), lodging_score (1 to 5, an ordered score of each plot),
  and awn_type (a class of the genotype: awned, short awned, awnless).
  See wheat_data_dictionary.csv.

BE CAREFUL. LIKE REAL DATA, THIS FILE IS NOT PERFECT
  There are missing values (plots without emergence, values not recorded) and wrong values (typing
  errors, yield in kg/ha instead of t/ha, a wrong date). Also, one corner of South_2025 had hail.
  That damage is REAL: it is not a mistake in the data. Think about what to do with it.
  Find the problems before you fit any model. Decide what to do with each one, and write why.

HOW TO START
  1. Open first_look.R and run it line by line.
  2. Clean the data: missing values and outliers. Do not delete the hail plots without thinking.
  3. Fit a model for ONE environment (blocks, then rows and columns). Estimate the heritability.
     Remember that many lines are not replicated in the same block.
  4. Fit the model for all environments together. Is there genotype by environment interaction?
     Which lines are stable and which are good only in the dry years?
  5. Compare each mutant with its parent. Do the mutants differ from the parents?
  6. Does the dose change the mean or the variation of the mutants?
  7. The lodging score is ordered, not a continuous number. How will you analyse it?
  8. Build a selection index (high yield, short plant, low lodging) and choose the best lines.

The data are free to use for teaching. Please write "simulated data" when you show results.
Created with the R package FieldSimR (Werner et al.) for the plot errors.
