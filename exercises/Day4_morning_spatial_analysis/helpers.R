# Helper functions for the Day 4 morning practical.
# You do not need to edit this file. Each Rmd loads it with source("helpers.R").
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(ggplot2); library(lme4); library(SpATS)
})
theme_set(theme_minimal(base_size = 13))

# The bean trial of Day 3: 792 plots in a field of 66 rows x 12 columns
load_beans <- function(path = "data/Example_Beans.csv") {
  read_csv(path, show_col_types = FALSE) |>
    mutate(rep   = factor(rep),
           line  = factor(line),
           rb    = factor(paste(rep, block, sep = ":")),   # incomplete block, unique within the field
           rowf  = factor(row),                            # row and column as FACTORS (random effects)
           colf  = factor(col),
           yield = YdHa_clean)
}

# SpATS wrapper: one trait, genotype random (BLUPs) or fixed (BLUEs)
fit_spats <- function(data, trait = "yield", genotype_random = TRUE, nseg = c(6, 32)) {
  d <- data |> filter(!is.na(.data[[trait]])) |> droplevels()
  d$y <- d[[trait]]
  SpATS(response = "y", genotype = "line", genotype.as.random = genotype_random,
        spatial = ~ PSANOVA(col, row, nseg = nseg, nest.div = 2),
        fixed = ~ rep, random = ~ rowf + colf + rb, data = d,
        control = list(tolerance = 1e-03, monitoring = 0))
}

# Generalized heritability (Cullis) from an lme4 model with random lines
h2_cullis <- function(model, genotype = "line") {
  X <- getME(model, "X"); Z <- getME(model, "Z"); s2 <- sigma(model)^2
  vc <- as.data.frame(VarCorr(model)); fl <- getME(model, "flist"); Gp <- getME(model, "Gp")
  v <- unlist(lapply(names(fl), function(g) rep(vc$vcov[vc$grp == g], nlevels(fl[[g]]))))
  W <- cbind(X, Z); C <- crossprod(W) / s2; idx <- ncol(X) + seq_along(v)
  C[cbind(idx, idx)] <- C[cbind(idx, idx)] + 1 / v
  Cinv <- solve(as.matrix(C)); k <- match(genotype, names(fl))
  gi <- ncol(X) + (Gp[k] + 1):Gp[k + 1]; P <- Cinv[gi, gi]; n <- nrow(P)
  vdiff <- 2 * (n * sum(diag(P)) - sum(P)) / (n * (n - 1))
  1 - vdiff / (2 * vc$vcov[vc$grp == genotype])
}

# Heritability of a SpATS model (lines random): effective dimension / (number of lines - 1)
h2_spats <- function(model) {
  unname(model$eff.dim[["line"]] / (nlevels(model$data$line) - 1))
}

# Semivariogram of residuals along the rows, within columns
semivariogram <- function(d, max_lag = 25) {
  same <- outer(d$col, d$col, "==")
  lag  <- abs(outer(d$row, d$row, "-"))
  half <- 0.5 * outer(d$res, d$res, "-")^2
  keep <- same & lag > 0 & lag <= max_lag & upper.tri(same)
  tibble(lag = lag[keep], gamma = half[keep]) |>
    group_by(lag) |> summarise(gamma = mean(gamma), .groups = "drop")
}

# One trait, with and without space: heritability and BLUPs
# Returns list(h2_block, h2_spats, blup_block, blup_spats) with a BLUP per line
compare_trait <- function(data, trait) {
  d <- data |> mutate(y = .data[[trait]]) |> filter(!is.na(y)) |> droplevels()
  m_b <- lmer(y ~ rep + (1 | line) + (1 | rb), data = d)
  m_s <- fit_spats(data, trait)
  p <- predict(m_s, which = "line")
  list(h2_block   = h2_cullis(m_b),
       h2_spats   = h2_spats(m_s),
       blup_block = setNames(ranef(m_b)$line[, 1], rownames(ranef(m_b)$line)),
       blup_spats = setNames(p$predicted.values, as.character(p$line)))
}

# How many of the top 10 % lines are the same in two lists of BLUPs?
top_overlap <- function(a, b, prop = 0.10) {
  common <- intersect(names(a), names(b)); k <- round(prop * length(common))
  c(selected = k,
    in_both  = length(intersect(names(sort(a[common], decreasing = TRUE))[1:k],
                                names(sort(b[common], decreasing = TRUE))[1:k])))
}

# SpATS with the SAME settings as the Mr.Bean app (Single-Site, random genotype or not):
# row and column effects inside each replicate, and one spline segment per column and per row
spats_app <- function(data, trait = "yield", genotype_random = TRUE) {
  d <- data |> filter(!is.na(.data[[trait]])) |> droplevels()
  d$y  <- d[[trait]]
  d$rr <- factor(paste(d$rep, d$row, sep = ":"))   # row within replicate
  d$rc <- factor(paste(d$rep, d$col, sep = ":"))   # column within replicate
  SpATS(response = "y", genotype = "line", genotype.as.random = genotype_random,
        spatial = ~ PSANOVA(col, row, nseg = c(length(unique(d$col)), length(unique(d$row))), nest.div = 2),
        fixed = ~ rep, random = ~ rc + rr, data = d,
        control = list(tolerance = 1e-03, monitoring = 0))
}

# BLUPs of the lines from an lme4 model, as a named vector
blup_lmer <- function(m) { r <- ranef(m)$line; setNames(r[, 1], rownames(r)) }
