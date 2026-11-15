# Run once before the practical (internet connection needed).
# It installs only the packages that are missing.
pkgs <- c("lme4", "randomForest", "ggplot2", "knitr", "rmarkdown")
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

# Check: every line should print TRUE
sapply(pkgs, requireNamespace, quietly = TRUE)
