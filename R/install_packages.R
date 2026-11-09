# =====================================================================
# RTC RER5030: installation of the course packages
# Run once, inside the course RStudio project:
#   source("R/install_packages.R")
# The script installs only the packages that are missing, then checks
# that every package loads, and prints OK or FAILED for each one.
# =====================================================================

# Packages used in the course
pkgs <- c(
  # data handling and plots
  "tidyverse",      # readr, dplyr, tidyr, ggplot2, readxl and more
  "ggrepel",        # non-overlapping labels in plots
  "cowplot",        # combining plots
  # experimental design
  "FielDHub",       # randomization and field layouts
  "agricolae",      # classical designs and mean comparison tests
  "agridat",        # example datasets from agricultural experiments
  # models
  "lme4",           # mixed models (BLUEs and BLUPs)
  "emmeans",        # adjusted means and comparisons (Tukey, Dunnett)
  "sommer",         # mixed models for genetic analysis
  "SpATS",          # spatial analysis of field trials
  "agriutilities",  # utilities for single and multi-environment trials
  # G x E and multivariate analysis
  "statgenGxE",     # genotype by environment analysis
  "metan",          # stability, AMMI, GGE biplot, selection indices
  "FactoMineR",     # principal component analysis
  "factoextra",     # plots for PCA and clustering
  # machine learning
  "glmnet",         # ridge, lasso and elastic net
  "pls",            # partial least squares regression
  "ranger",         # random forest
  "gbm",            # gradient boosting
  "e1071",          # support vector machines
  # image analysis
  "pliman"          # plant image analysis (also needs EBImage, see below)
)

# Use a CRAN mirror and binary packages (no compilation needed)
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (.Platform$OS.type == "windows" || Sys.info()[["sysname"]] == "Darwin") {
  options(install.packages.compile.from.source = "never")
}

# R version check
if (getRversion() < "4.3.0") {
  message("Your R version is ", getRversion(),
          ". Please install R 4.3 or newer before continuing.")
}

# Install only the missing packages
missing <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(missing) > 0) {
  message("Installing ", length(missing), " packages: ",
          paste(missing, collapse = ", "))
  install.packages(missing)
} else {
  message("All course packages are already installed.")
}

# EBImage (needed by pliman) comes from Bioconductor, not CRAN
if (!requireNamespace("EBImage", quietly = TRUE)) {
  message("Installing EBImage from Bioconductor")
  if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
  BiocManager::install("EBImage", update = FALSE, ask = FALSE)
}

# Check that every package loads
chk <- c(pkgs, "EBImage")
ok <- vapply(chk, requireNamespace, logical(1), quietly = TRUE)
cat("\n", sprintf("%-15s %s\n", chk, ifelse(ok, "OK", "FAILED")), sep = "")

if (all(ok)) {
  cat("\nEverything is ready for the course.\n")
} else {
  cat("\nSome packages FAILED: ", paste(chk[!ok], collapse = ", "),
      "\nRun the script again. If the problem continues, copy the error",
      "message and send it to the instructor.\n")
}
