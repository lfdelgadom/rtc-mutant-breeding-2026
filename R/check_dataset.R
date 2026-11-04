# =====================================================================
# Quick check of a participant dataset before the course
#
#   source("R/check_dataset.R")
#   check_dataset("data/my_trial.csv")      # or .xlsx
#
# It reports problems; it does not change your file.
# =====================================================================

check_dataset <- function(file, sheet = 1) {

  # 1. Read the file (Excel, comma CSV or semicolon CSV) ----------------
  if (grepl("\\.xlsx?$", file, ignore.case = TRUE)) {
    d <- readxl::read_excel(file, sheet = sheet)
  } else {
    first_line <- readLines(file, n = 1, warn = FALSE)
    if (lengths(regmatches(first_line, gregexpr(";", first_line))) >
        lengths(regmatches(first_line, gregexpr(",", first_line)))) {
      cat("Semicolon file detected: reading with read_csv2()\n")
      d <- readr::read_csv2(file, show_col_types = FALSE)
    } else {
      d <- readr::read_csv(file, show_col_types = FALSE)
    }
  }
  d <- as.data.frame(d)

  # 2. Clean column names: lower case, no spaces or symbols --------------
  old <- names(d)
  names(d) <- tolower(gsub("[^A-Za-z0-9]+", "_", trimws(old)))
  names(d) <- gsub("^_|_$", "", names(d))
  cat("\nRows:", nrow(d), "| Columns:", ncol(d), "\n")
  if (any(old != names(d))) {
    cat("Column names cleaned, for example:",
        paste0("'", head(old[old != names(d)], 3), "' -> '",
               head(names(d)[old != names(d)], 3), "'", collapse = "; "), "\n")
  }

  problems <- 0

  # 3. Required columns ---------------------------------------------------
  required <- c("location", "year", "rep", "geno")
  missing_cols <- setdiff(required, names(d))
  if (length(missing_cols)) {
    problems <- problems + 1
    cat("\n[!] Missing required columns:", paste(missing_cols, collapse = ", "), "\n")
  }

  # Title or note above the header?
  long <- old[nchar(old) > 40]
  if (length(long)) {
    problems <- problems + 1
    cat("[!] Very long column name: is there a title or note above the header?\n",
        "   Delete it, or read the file with read_excel(file, skip = 1)\n")
  }

  # 4. Columns that look empty (for example, left over from merged cells) --
  empty <- names(d)[colSums(!is.na(d)) == 0 | grepl("^x?\\d+$|^$", names(d))]
  if (length(empty)) {
    problems <- problems + 1
    cat("[!] Empty or unnamed columns (merged cells or double header?):",
        paste(empty, collapse = ", "), "\n")
  }

  # 5. Text inside columns that should be numbers --------------------------
  for (v in names(d)) {
    x <- d[[v]]
    if (is.character(x)) {
      as_num <- suppressWarnings(as.numeric(gsub(",", ".", x)))
      share  <- mean(!is.na(as_num[!is.na(x)]))
      if (share > 0.8 && share < 1) {
        bad <- unique(x[!is.na(x) & is.na(as_num)])
        problems <- problems + 1
        cat("[!] Column '", v, "' is almost all numbers but has text: ",
            paste(head(bad, 5), collapse = " | "), "\n", sep = "")
      }
    }
  }

  # 6. Suspicious missing-value codes ---------------------------------------
  codes <- c(".", "-", "--", "NA", "na", "n/a", "N/A", "missing", "?")
  found <- sapply(d, function(x) sum(as.character(x) %in% codes))
  if (any(found > 0)) {
    problems <- problems + 1
    cat("[!] Missing values typed as codes (leave the cell empty instead):\n")
    print(found[found > 0])
  }

  # 7. Plot positions and replicates ----------------------------------------
  if (all(c("row", "col") %in% names(d))) {
    keys <- intersect(c("location", "year", "row", "col"), names(d))
    dup <- sum(duplicated(d[keys]))
    if (dup > 0) { problems <- problems + 1; cat("[!] Duplicated plot positions:", dup, "\n") }
  } else {
    cat("[i] No row/col coordinates: spatial analysis will not be possible\n")
  }
  if (all(c("geno", "rep") %in% names(d))) {
    cat("[i] Genotypes:", length(unique(d$geno)),
        "| Replicates:", paste(sort(unique(d$rep)), collapse = ", "), "\n")
  }

  # 8. Missing values per column ---------------------------------------------
  cat("\nMissing values per column:\n")
  print(colSums(is.na(d)))

  cat(if (problems == 0) "\nNo problems found. Your file looks tidy.\n"
      else paste0("\n", problems, " problem(s) found. See the [!] lines above.\n"))
  invisible(d)
}
