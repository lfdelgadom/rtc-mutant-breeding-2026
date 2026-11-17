SIMULATED DATA. CHRYSANTHEMUM MUTANT TRIALS
===========================================

These data are SIMULATED. They do not come from real trials, but they behave like real data.
Use them if you do not have a data set of your own, or to practise before you use your own data.

THE EXPERIMENT
  120 lines: 4 parent cultivars (not irradiated) and 116 mutant lines (29 from each parent).
  The mutants come from cuttings irradiated with gamma rays at three doses: 20, 40 and 60 Gy.
  4 environments:
     GH_autumn      greenhouse, autumn      2 blocks
     GH_spring      greenhouse, spring      2 blocks
     Field_autumn   open field, autumn      3 blocks
     Field_spring   open field, spring      2 blocks
  Design in each environment: randomized complete blocks. Every line is once in each block.
  Each block has 12 rows and 10 columns (120 plots). In the file, row and column give the position.
  1,080 plots in total.

TRAITS (5, plus the colour of the flower)
  days_to_flowering (days), plant_height_cm (cm), flower_diameter_cm (cm),
  flower_number (count), stem_weight_g (g), and flower_colour (a class).
  See chrysanthemum_data_dictionary.csv.

BE CAREFUL. LIKE REAL DATA, THIS FILE IS NOT PERFECT
  There are missing values (dead plants, a flood in one block, values not recorded, plants that did
  not flower) and there are some wrong values (typing errors, a decimal point in the wrong place).
  Find them before you fit any model. Decide what to do with each one, and write why.

HOW TO START
  1. Open first_look.R and run it line by line.
  2. Clean the data: missing values and outliers.
  3. Fit a model for ONE environment (blocks, then rows and columns). Estimate the heritability.
  4. Fit the model for all environments together. Is there genotype by environment interaction?
  5. Compare each mutant with its parent. Do the mutants differ from the parents?
  6. Does the dose change the mean or the variation of the mutants?
  7. Build a selection index and choose the best lines. Which colour classes appear?

The data are free to use for teaching. Please write "simulated data" when you show results.
Created with the R package FieldSimR (Werner et al.) for the plot errors.
