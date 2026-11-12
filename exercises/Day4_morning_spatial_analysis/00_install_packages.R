# Run once before the practical (internet connection needed).
# It installs only the packages that are missing.
pkgs <- c("SpATS", "lme4", "dplyr", "tidyr", "readr", "ggplot2")
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

# Check: every line should print TRUE
sapply(pkgs, requireNamespace, quietly = TRUE)
