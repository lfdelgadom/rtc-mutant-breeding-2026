# Run once before the practical (internet connection needed).
# pliman needs EBImage, which comes from Bioconductor.
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
if (!requireNamespace("EBImage", quietly = TRUE)) BiocManager::install("EBImage", update = FALSE, ask = FALSE)

pkgs <- c("pliman", "lme4", "dplyr", "tidyr", "readr", "ggplot2")
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) install.packages(missing)

# Check: every line should print TRUE
sapply(c("EBImage", pkgs), requireNamespace, quietly = TRUE)
