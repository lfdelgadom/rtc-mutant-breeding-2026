# Run once before the exercises (internet connection needed).
# It installs only the packages that are missing. FielDHub is large:
# start it early and let it run (a few minutes).
pkgs <- c("FielDHub", "dplyr", "ggplot2")
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

# Check: every line should print TRUE
sapply(pkgs, requireNamespace, quietly = TRUE)
