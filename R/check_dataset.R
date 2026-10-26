# Quick check of a participant dataset before the course
check_dataset <- function(file) {
  d <- if (grepl("\\.xlsx?$", file)) readxl::read_excel(file) else readr::read_csv(file, show_col_types = FALSE)
  d <- janitor::clean_names(d)
  required <- c("location", "year", "rep", "geno")
  missing  <- setdiff(required, names(d))
  cat("Rows:", nrow(d), " Columns:", ncol(d), "\n")
  if (length(missing)) cat("Missing required columns:", paste(missing, collapse = ", "), "\n")
  if (all(c("row", "col") %in% names(d))) {
    dup <- sum(duplicated(d[c("location", "year", "row", "col")]))
    cat("Duplicated plot positions:", dup, "\n")
  } else cat("No row/col coordinates: spatial analysis will not be possible\n")
  cat("Missing values per column:\n"); print(colSums(is.na(d)))
  invisible(d)
}
