# Run once before the exercises (internet connection needed).
# It installs only the packages that are missing. If you did the morning
# script, only the new ones (agricolae, car, lmerTest) are installed now.
pkgs <- c("FielDHub", "agridat", "lme4", "lmerTest", "emmeans", "agricolae",
          "car", "MASS", "dplyr", "ggplot2", "readr")
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

# Check: every line should print TRUE
sapply(pkgs, requireNamespace, quietly = TRUE)
