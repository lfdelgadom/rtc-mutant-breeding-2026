# Run once. Needs internet.
pkgs <- c("readr", "readxl", "dplyr", "ggplot2", "rmarkdown")
need <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(need)) install.packages(need)
cat("Ready.\n")
