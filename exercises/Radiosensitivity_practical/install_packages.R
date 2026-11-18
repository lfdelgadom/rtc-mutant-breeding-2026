# Run once. Needs internet.
pkgs <- c("ggplot2", "lme4", "SpATS", "patchwork", "rmarkdown", "scales", "MASS")
need <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(need)) install.packages(need)
cat("Ready.\n")
