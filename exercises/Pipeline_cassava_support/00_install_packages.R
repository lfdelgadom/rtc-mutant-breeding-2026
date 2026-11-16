# Run this file once. Every line must print TRUE.
pkgs <- c("lme4", "nlme", "SpATS", "ggplot2", "patchwork", "knitr", "rmarkdown")
to_install <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)]
if (length(to_install) > 0) install.packages(to_install)
sapply(pkgs, requireNamespace, quietly = TRUE)
