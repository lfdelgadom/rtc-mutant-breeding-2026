# Run once. Needs internet.
pkgs <- c("ellmer", "lme4", "agridat", "emmeans")
new  <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(new)) install.packages(new)
