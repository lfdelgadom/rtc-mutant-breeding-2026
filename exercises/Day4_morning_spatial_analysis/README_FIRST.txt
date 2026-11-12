RER5030 training course - Day 4, morning: spatial analysis and trial precision

1. Unzip this folder on your computer (do not work inside the ZIP file).
2. Open Day4_morning.Rproj in RStudio (double click).
3. Run 00_install_packages.R once. All lines should show TRUE.

Practical of this session (10:30 - 12:30). The same bean trial (yield only) is analysed twice:
  Spatial_models_comparison.Rmd   in R: ANOVA with rows and columns, a ladder of mixed models (lme4), SpATS,
                                  heritability, BLUEs and BLUPs, choice of model (about 80 min)
  Mr.Bean tutorial (web page)     the same SpATS analysis in the Mr.Bean app, without code (about 35 min):
                                  https://lfdelgadom.github.io/rtc-mutant-breeding-2026/slides/tutorial-mrbean-spatial.html

How to work: run each grey box with the green triangle, from top to bottom.
Replace the ___ in the lines marked # TODO. The # HINT line above tells you where to look.
Every part says what result you should get, so you can check yourself.
Write your findings in the boxes. Knit only at the end, if time allows.
Work with your neighbour: one types, the other reads the output and asks "why?". Swap every part.

Files:
  helpers.R               functions used in all exercises (do not edit; open it to see how the model is fitted)
  data/Example_Beans.csv  the bean trial of Day 3: 380 lines, 2 replicates, 792 plots, 66 rows x 12 columns

Keep everything in this folder. It is your own copy: updating the course project with Git never touches it.
Posit Cloud users: upload this ZIP to your project (Files > Upload), then open the .Rmd files.
