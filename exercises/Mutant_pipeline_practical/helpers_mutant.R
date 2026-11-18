# Helpers for the analysis pipeline of mutant populations
# Free packages only: lme4, nlme, SpATS, ggplot2, patchwork
library(ggplot2)
library(lme4)
library(SpATS)
suppressMessages(library(patchwork))

# ---------------------------------------------------------------- 1. Read the data
# Gives the table the names used by all the functions: trial, g (genotype), block_id, row_number, col_number.
# Change the arguments if your columns have other names.
load_mutant <- function(path, env = "environment", genotype = "genotype", block = "block",
                        row = "row", col = "column") {
  d <- read.csv(path, stringsAsFactors = FALSE)
  d$trial <- factor(d[[env]], levels = unique(d[[env]]))
  d$g <- factor(d[[genotype]])
  d$block_id <- factor(paste(d$trial, d[[block]], sep = "_"))   # block names are unique inside each trial
  d$row_number <- d[[row]]
  d$col_number <- d[[col]]
  d
}

# ---------------------------------------------------------------- 2. Exploratory analysis
plot_missing <- function(d, traits) {
  m <- do.call(rbind, lapply(traits, function(tr)
    data.frame(trait = tr, trial = levels(d$trial),
               miss = as.numeric(tapply(is.na(d[[tr]]), d$trial, mean)) * 100)))
  ggplot(m, aes(trait, trial, fill = miss)) +
    geom_tile(colour = "grey80") +
    geom_text(aes(label = round(miss, 1)), size = 3.4) +
    scale_fill_gradient(low = "white", high = "#D55E00", limits = c(0, 30), oob = scales::squish, name = "% missing") +
    labs(x = NULL, y = NULL) + theme_minimal(base_size = 13) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

# One row per trait: % of missing values, mean, variation. keep = FALSE when the trait has more than
# max_miss % of missing values or almost no variation (coefficient of variation below min_cv %).
check_traits <- function(d, traits, max_miss = 25, min_cv = 1) {
  out <- do.call(rbind, lapply(traits, function(tr) {
    x <- d[[tr]]
    data.frame(trait = tr, missing_pct = round(mean(is.na(x)) * 100, 1), mean = round(mean(x, na.rm = TRUE), 2),
               sd = round(sd(x, na.rm = TRUE), 2), cv_pct = round(sd(x, na.rm = TRUE) / abs(mean(x, na.rm = TRUE)) * 100, 1))
  }))
  out$keep <- out$missing_pct <= max_miss & out$cv_pct >= min_cv
  out
}

# Outlier screening in two steps, in each trial and trait.
# Step 1, gross errors: a value very far from the median of the trial (robust z, using the MAD) is flagged. Wrong units,
#   a decimal point in the wrong place, a typing error.
# Step 2, with a model: genotype (random) and block (random). The residual of a plot is divided by a robust spread (MAD).
#   It is used only when the genotypes have enough plots (on average 1.5 or more), because with one plot per genotype
#   the residual cannot be separated from the genotype.
flag_outliers <- function(d, traits, cutoff_gross = 6, cutoff = 4) {
  d$.id <- seq_len(nrow(d)); out <- NULL
  for (tr in traits) for (t in levels(d$trial)) {
    x <- d[d$trial == t & !is.na(d[[tr]]), ]
    z1 <- (x[[tr]] - median(x[[tr]])) / mad(x[[tr]])
    b1 <- abs(z1) > cutoff_gross
    if (any(b1)) out <- rbind(out, data.frame(.id = x$.id[b1], trait = tr, trial = t, g = as.character(x$g[b1]),
                                              value = x[[tr]][b1], z = round(z1[b1], 1)))
    x <- x[!b1, ]
    if (nrow(x) / nlevels(droplevels(x$g)) >= 1.5) {
      f <- as.formula(paste0(tr, " ~ (1 | g) + (1 | block_id)"))
      m <- try(lmer(f, data = x, control = lmerControl(check.conv.singular = "ignore")), silent = TRUE)
      if (!inherits(m, "try-error")) {
        z <- resid(m) / mad(resid(m)); b2 <- abs(z) > cutoff
        if (any(b2)) out <- rbind(out, data.frame(.id = x$.id[b2], trait = tr, trial = t, g = as.character(x$g[b2]),
                                                  value = x[[tr]][b2], z = round(z[b2], 1)))
      }
    }
  }
  out
}

# Review the flagged values before removing them. A flag is not always an error: a line that is extreme in all its
# plots can be a promising mutant. For each flagged value we look at (1) the limits of what is possible, if you give
# them, and (2) the other plots of the same line (same trait, all trials): are they also extreme in the same direction?
#   limits: a named list, for example list(plant_height_cm = c(5, 200)).
# The column suggestion is only a help. The breeder takes the decision.
review_outliers <- function(d, flags, limits = NULL, check_z = 2) {
  d$.id <- seq_len(nrow(d))
  if (is.null(flags) || !nrow(flags)) return(flags)
  flags$direction <- ifelse(flags$z > 0, "high", "low")
  flags$others_n <- NA_integer_; flags$others_z <- NA_real_
  for (i in seq_len(nrow(flags))) {
    tr <- flags$trait[i]
    zall <- ave(d[[tr]], d$trial, FUN = function(v) (v - median(v, na.rm = TRUE)) / mad(v, na.rm = TRUE))
    o <- d$g == flags$g[i] & d$.id != flags$.id[i] & !is.na(d[[tr]])
    flags$others_n[i] <- sum(o)
    if (any(o)) flags$others_z[i] <- round(mean(zall[o]), 1)
  }
  flags$suggestion <- "isolated value, probably an error. Check the field book and then remove"
  rep <- !is.na(flags$others_z) & sign(flags$others_z) == sign(flags$z) & abs(flags$others_z) >= check_z
  flags$suggestion[rep] <- "the line is extreme in its other plots too. Possible mutant, keep it and check"
  if (!is.null(limits)) for (i in seq_len(nrow(flags))) {
    lim <- limits[[flags$trait[i]]]
    if (!is.null(lim) && (flags$value[i] < lim[1] || flags$value[i] > lim[2]))
      flags$suggestion[i] <- "impossible value. Remove"
  }
  info <- unique(d[, intersect(c("g", "type", "parent", "dose_Gy"), names(d))])
  flags <- merge(flags, info, by = "g", all.x = TRUE, sort = FALSE)
  flags[order(flags$trait, flags$trial), ]
}

# Set the flagged values to NA (the original table is not changed).
# Remove all of them, or only the ones you choose: remove_outliers(d, flags[flags$suggestion != "the line is extreme in its other plots too. Possible mutant, keep it and check", ])
remove_outliers <- function(d, flags) {
  d$.id <- seq_len(nrow(d))
  for (i in seq_len(nrow(flags))) d[[flags$trait[i]]][d$.id == flags$.id[i]] <- NA
  d$.id <- NULL
  d
}

plot_corr <- function(R, title = NULL, size = 3.2) {
  nm <- colnames(R)
  df <- expand.grid(a = nm, b = nm); df$r <- as.vector(R)
  df$a <- factor(df$a, levels = nm); df$b <- factor(df$b, levels = rev(nm))
  ggplot(df, aes(a, b, fill = r)) + geom_tile(colour = "white") +
    geom_text(aes(label = sprintf("%.2f", r)), size = size) +
    scale_fill_gradient2(low = "#D55E00", mid = "white", high = "#0072B2", limits = c(-1, 1), name = "r") +
    labs(x = NULL, y = NULL, title = title) + theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

# ---------------------------------------------------------------- 3. Shared genotypes
plot_connect <- function(d) {
  tr <- levels(d$trial)
  M <- outer(tr, tr, Vectorize(function(a, b) length(intersect(d$g[d$trial == a], d$g[d$trial == b]))))
  df <- expand.grid(a = tr, b = tr); df$n <- as.vector(M)
  df$a <- factor(df$a, levels = tr); df$b <- factor(df$b, levels = rev(tr))
  ggplot(df, aes(a, b, fill = n)) + geom_tile(colour = "white") +
    geom_text(aes(label = n), size = 3.6) +
    scale_fill_gradient(low = "white", high = "#0072B2", name = "Shared\ngenotypes") +
    labs(x = NULL, y = NULL) + theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

# In how many trials is each genotype?
genotype_in_trials <- function(d) {
  n <- tapply(as.character(d$trial), d$g, function(x) length(unique(x)))
  data.frame(g = names(n), n_trials = as.integer(n))
}

# ---------------------------------------------------------------- 4. Single trial
# 4a. lme4. Genotype random: BLUPs and heritability. Genotype fixed: BLUEs and their standard errors.
# Heritability = 1 - (mean prediction error variance of the BLUPs) / (genetic variance)
#
# Four models for the design (all with genotype random). They differ only in the other random terms:
#   block      (1 | block)                                  design only
#   rowcol     (1 | block) + (1 | row) + (1 | col)          row and column as crossed random effects
#   nested     (1 | block) + (1 | block:row) + (1 | block:col)   row and column inside each block
#   rowcol_nb  (1 | row) + (1 | col)                        no block term
# A row or a column is only useful if it explains variance. We look at its variance and at the AIC.
lme4_random_terms <- function(model, nb = 2) {
  blk <- if (nb > 1) "(1 | block_id)" else NULL
  switch(model,
    block     = blk,
    rowcol    = c(blk, "(1 | row_f)", "(1 | col_f)"),
    nested    = c(blk, "(1 | block_id:row_f)", "(1 | block_id:col_f)"),
    rowcol_nb = c("(1 | row_f)", "(1 | col_f)"),
    stop("unknown model: ", model))
}

lme4_models <- c("block", "rowcol", "nested", "rowcol_nb")

prepare_trial <- function(x, trait) {
  x <- x[!is.na(x[[trait]]), ]
  x$g <- droplevels(x$g); x$block_id <- droplevels(x$block_id)
  x$row_f <- factor(x$row_number); x$col_f <- factor(x$col_number)
  x
}

single_lme4 <- function(x, trait, model = "block") {
  x <- prepare_trial(x, trait)
  nb <- nlevels(x$block_id)
  ctl <- lmerControl(check.conv.singular = "ignore")
  rt <- lme4_random_terms(model, nb)
  m <- lmer(as.formula(paste(trait, "~ (1 | g) +", paste(rt, collapse = " + "))), data = x, control = ctl)
  vc <- as.data.frame(VarCorr(m))
  vget <- function(pat) { v <- vc$vcov[grepl(pat, vc$grp)]; if (length(v)) sum(v) else NA_real_ }
  vg <- vc$vcov[vc$grp == "g"]; ve <- vc$vcov[vc$grp == "Residual"]
  pev <- as.numeric(attr(ranef(m, condVar = TRUE)$g, "postVar"))
  h2 <- if (vg > 0) max(0, 1 - mean(pev) / vg) else 0
  blup <- ranef(m)$g[, 1]
  # BLUEs: same random terms, genotype fixed
  ff <- as.formula(paste(trait, "~ g", if (length(rt)) paste("+", paste(rt, collapse = " + ")) else ""))
  mf <- if (length(rt)) lmer(ff, data = x, control = ctl) else lm(ff, data = x)
  b <- fixef(mf); V <- as.matrix(vcov(mf)); gl <- levels(x$g)
  idx <- match(paste0("g", gl[-1]), names(b))
  est <- c(b[1], b[1] + b[idx])
  se2 <- c(V[1, 1], V[1, 1] + diag(V)[idx] + 2 * V[1, idx])
  list(model = model, h2 = h2, vg = vg, ve = ve, aic = AIC(m),
       var_block = vget("^block_id$"), var_row = vget("row_f"), var_col = vget("col_f"),
       blup = data.frame(g = rownames(ranef(m)$g), blup = blup),
       blue = data.frame(g = gl, blue = as.numeric(est), se2 = as.numeric(se2)))
}

# Fit the four models in one trial and one trait. One row per model, ordered as lme4_models.
# Variance components, heritability and AIC. The best model is the one with the lowest AIC.
compare_lme4_models <- function(x, trait, models = lme4_models) {
  out <- lapply(models, function(m) {
    a <- try(single_lme4(x, trait, m), silent = TRUE)
    if (inherits(a, "try-error")) return(NULL)
    data.frame(trait = trait, trial = as.character(x$trial[1]), model = m, AIC = a$aic, h2 = a$h2,
               var_g = a$vg, var_block = a$var_block, var_row = a$var_row, var_col = a$var_col, var_res = a$ve)
  })
  out <- do.call(rbind, out)
  out$delta_AIC <- out$AIC - min(out$AIC)
  out$best <- out$delta_AIC == 0
  out
}

# Plot the comparison of the four lme4 models (the table made by single_trials()$models).
# Left: share of the variance of each model in one trial and trait. Right: AIC of all trials and traits.
plot_lme4_models <- function(M, trait = M$trait[1], trial = M$trial[1]) {
  lv <- c("block", "rowcol", "nested", "rowcol_nb")
  a <- M[M$trait == trait & M$trial == trial, ]
  v <- reshape(a[, c("model", "var_g", "var_block", "var_row", "var_col", "var_res")], direction = "long",
               varying = c("var_g", "var_block", "var_row", "var_col", "var_res"), v.names = "v", timevar = "term",
               times = c("Genotype", "Block", "Row", "Column", "Residual"), idvar = "model")
  v$v[is.na(v$v)] <- 0
  v$term <- factor(v$term, levels = c("Residual", "Column", "Row", "Block", "Genotype"))
  pa <- ggplot(v, aes(factor(model, levels = rev(lv)), v, fill = term)) + geom_col(position = "fill") + coord_flip() +
    scale_fill_manual(values = c(Genotype = "#4F9D5D", Block = "#9AA5B1", Row = "#0072B2", Column = "#56B4E9", Residual = "#D9DDE1"), name = NULL) +
    scale_y_continuous(labels = scales::percent) + labs(x = NULL, y = "Share of the variance", title = paste(trait, trial, sep = ", ")) +
    theme_minimal(base_size = 12) + theme(legend.position = "top")
  pb <- ggplot(M, aes(delta_AIC, factor(model, levels = rev(lv)), colour = trait)) + geom_vline(xintercept = 0, colour = "grey70") +
    geom_point(size = 2.4, alpha = 0.85, position = position_jitter(height = 0.15, width = 0, seed = 1)) +
    scale_x_continuous(trans = "sqrt") +
    labs(x = "AIC minus the lowest AIC of the trial and trait (0 = best)", y = NULL, title = "All traits and trials") +
    theme_minimal(base_size = 12) + theme(legend.position = "bottom", axis.text.y = element_blank())
  pa + pb + plot_layout(widths = c(1.25, 1))
}

# 4b. SpATS. A smooth surface of the field (rows and columns) is removed from the error.
# Block is a random term when the trial has more than one block.
single_spats <- function(x, trait, genotype_random = TRUE) {
  x <- x[!is.na(x[[trait]]) & !is.na(x$row_number) & !is.na(x$col_number), ]
  x$g <- droplevels(x$g); x$block_id <- droplevels(x$block_id)
  nr <- length(unique(x$row_number)); nc <- length(unique(x$col_number))
  rnd <- if (nlevels(x$block_id) > 1) ~ block_id else NULL
  SpATS::SpATS(response = trait, genotype = "g", genotype.as.random = genotype_random,
               spatial = ~ SpATS::PSANOVA(col_number, row_number, nseg = c(2 * floor(min(10, nc - 1) / 2), 2 * floor(min(10, nr - 1) / 2)),
                                          degree = 3, nest.div = 2),
               random = rnd, data = x, control = list(tolerance = 1e-3, monitoring = 0))
}

# All traits in all trials. Returns the heritability of both methods and the BLUEs of both methods.
single_trials <- function(d, traits, spatial = TRUE) {
  h <- NULL; blues <- NULL; models <- NULL
  for (tr in traits) for (t in levels(d$trial)) {
    x <- d[d$trial == t, ]
    cm <- try(compare_lme4_models(x, tr), silent = TRUE)
    best <- if (!inherits(cm, "try-error")) cm$model[cm$best][1] else NA
    a <- if (!is.na(best)) try(single_lme4(x, tr, best), silent = TRUE) else NULL
    s <- if (spatial) try(single_spats(x, tr, TRUE), silent = TRUE) else NULL
    sf <- if (spatial) try(single_spats(x, tr, FALSE), silent = TRUE) else NULL
    hh <- function(m) if (!inherits(cm, "try-error") && m %in% cm$model) cm$h2[cm$model == m] else NA_real_
    row <- data.frame(trait = tr, trial = t,
                      h2_block = hh("block"), h2_rowcol = hh("rowcol"), h2_nested = hh("nested"),
                      best_model = best,
                      h2_lme4 = if (!is.null(a) && !inherits(a, "try-error")) a$h2 else NA_real_,
                      h2_spats = if (spatial && !inherits(s, "try-error")) as.numeric(SpATS::getHeritability(s)) else NA_real_)
    h <- rbind(h, row)
    if (!inherits(cm, "try-error")) models <- rbind(models, cm)
    if (!is.null(a) && !inherits(a, "try-error")) blues <- rbind(blues, cbind(trait = tr, trial = t, method = "lme4", a$blue))
    if (spatial && !inherits(sf, "try-error")) {
      p <- predict(sf, which = "g")
      blues <- rbind(blues, data.frame(trait = tr, trial = t, method = "SpATS", g = as.character(p$g),
                                       blue = p$predicted.values, se2 = p$standard.errors^2))
    }
  }
  list(h2 = h, blues = blues, models = models)
}

# Traffic light for the heritability of a trait in a trial
h2_class <- function(h2) cut(h2, c(-Inf, 0.2, 0.5, Inf), labels = c("low (<0.2)", "medium (0.2 to 0.5)", "good (>0.5)"))

plot_h2 <- function(h, col = "h2_lme4") {
  h$v <- h[[col]]; h$trial <- factor(h$trial, levels = rev(levels(factor(h$trial, levels = unique(h$trial)))))
  ggplot(h, aes(trait, trial, fill = v)) + geom_tile(colour = "grey80") +
    geom_text(aes(label = sprintf("%.2f", v)), size = 3.6) +
    scale_fill_gradient2(low = "#D55E00", mid = "#F4E3A1", high = "#4F9D5D", midpoint = 0.35, limits = c(0, 0.8),
                         oob = scales::squish, name = "Heritability") +
    labs(x = NULL, y = NULL) + theme_minimal(base_size = 13) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

# ---------------------------------------------------------------- 5. Multi-environment analysis
# Start again from the plot data. Do NOT use the BLUPs of the single trials.
# Fixed: trial. Random: block inside trial, genotype, genotype by trial.
met_fit <- function(d, trait) {
  x <- d[!is.na(d[[trait]]), ]; x$g <- droplevels(x$g); x$trial <- droplevels(x$trial)
  f <- as.formula(paste0(trait, " ~ trial + (1 | block_id) + (1 | g) + (1 | g:trial)"))
  lmer(f, data = x, control = lmerControl(check.conv.singular = "ignore"))
}

met_summary <- function(m) {
  vc <- as.data.frame(VarCorr(m)); v <- function(g) vc$vcov[vc$grp == g]
  vg <- v("g"); pev <- as.numeric(attr(ranef(m, condVar = TRUE)$g, "postVar"))
  data.frame(Vg = vg, VgxE = v("g:trial"), Vblock = v("block_id"), Ve = v("Residual"),
             h2 = max(0, 1 - mean(pev) / vg), gxe_over_g = v("g:trial") / vg)
}

# BLUP of each genotype, on the scale of the trait (mean of the trials + BLUP)
met_blups <- function(m) {
  b <- ranef(m)$g; mu <- mean(predict(m, re.form = NA))
  data.frame(g = rownames(b), blup = mu + b[, 1])
}

# BLUE of each genotype over all trials (genotype fixed, genotype by trial random)
met_blues <- function(d, trait) {
  x <- d[!is.na(d[[trait]]), ]; x$g <- droplevels(x$g); x$trial <- droplevels(x$trial)
  f <- as.formula(paste0(trait, " ~ trial + g + (1 | block_id) + (1 | g:trial)"))
  m <- lmer(f, data = x, control = lmerControl(check.conv.singular = "ignore"))
  b <- fixef(m); gl <- levels(x$g)
  idx <- match(paste0("g", gl[-1]), names(b))
  mu <- mean(predict(m, re.form = NA, newdata = transform(x[1, ], g = gl[1])))
  data.frame(g = gl, blue = mu + c(0, b[idx]))
}

# Genotypic correlation between trials: correlation of (genotype + genotype by trial) BLUPs
trial_gcor <- function(m) {
  r <- ranef(m); g <- r$g; ge <- r[["g:trial"]]
  nm <- strsplit(rownames(ge), ":")
  df <- data.frame(g = sapply(nm, `[`, 1), trial = sapply(nm, `[`, 2), v = ge[, 1])
  df$v <- df$v + g[df$g, 1]
  W <- reshape(df, idvar = "g", timevar = "trial", direction = "wide")
  names(W) <- sub("^v\\.", "", names(W))
  cor(W[, -1], use = "pairwise.complete.obs")
}

# BLUPs of all traits, one row per genotype
all_blups <- function(d, traits) {
  out <- NULL
  for (tr in traits) {
    b <- met_blups(met_fit(d, tr)); names(b)[2] <- tr
    out <- if (is.null(out)) b else merge(out, b, by = "g")
  }
  out
}

# ---------------------------------------------------------------- 6. Stability. GGE biplot
# W: matrix of genotype BLUEs, one row per genotype, one column per trial.
# Centred by trial (GGE = genotype + genotype by environment), singular values shared between genotypes and trials.
gge_fit <- function(W) {
  W <- W[complete.cases(W), , drop = FALSE]
  Wc <- sweep(W, 2, colMeans(W))
  s <- svd(Wc); k <- 2
  sg <- sqrt(s$d[1:k])
  G <- s$u[, 1:k] * rep(sg, each = nrow(W)); E <- s$v[, 1:k] * rep(sg, each = ncol(W))
  if (cor(G[, 1], rowMeans(W)) < 0) { G[, 1] <- -G[, 1]; E[, 1] <- -E[, 1] }
  ex <- (s$d^2 / sum(s$d^2))[1:k] * 100
  aec <- colMeans(E); aec <- aec / sqrt(sum(aec^2))                # direction of the average trial
  G <- data.frame(g = rownames(W), PC1 = G[, 1], PC2 = G[, 2], mean = rowMeans(W))
  G$along <- G$PC1 * aec[1] + G$PC2 * aec[2]                       # position along the average-trial axis
  G$stab <- abs(-G$PC1 * aec[2] + G$PC2 * aec[1])                   # distance to that axis. Small = stable
  E <- data.frame(trial = colnames(W), PC1 = E[, 1], PC2 = E[, 2])
  list(G = G, E = E, explained = ex, aec = aec)
}

plot_gge <- function(f, highlight = NULL, n_label = 8) {
  G <- f$G; E <- f$E
  sc <- max(abs(c(G$PC1, G$PC2))) / max(abs(c(E$PC1, E$PC2))) * 0.9
  E$x <- E$PC1 * sc; E$y <- E$PC2 * sc
  G$group <- if (is.null(highlight)) "genotype" else ifelse(G$g %in% highlight, "parent", "mutant")
  lab <- G[order(-sqrt(G$PC1^2 + G$PC2^2)), ][seq_len(n_label), ]
  hull <- G[chull(G$PC1, G$PC2), ]
  ggplot() +
    geom_polygon(data = hull, aes(PC1, PC2), fill = NA, colour = "grey60", linetype = 2) +
    geom_hline(yintercept = 0, colour = "grey85") + geom_vline(xintercept = 0, colour = "grey85") +
    geom_point(data = G, aes(PC1, PC2, colour = group, size = group), alpha = 0.8) +
    geom_segment(data = E, aes(x = 0, y = 0, xend = x, yend = y), arrow = grid::arrow(length = grid::unit(0.2, "cm")),
                 colour = "#0072B2", linewidth = 0.8) +
    geom_text(data = E, aes(x * 1.1, y * 1.1, label = trial), colour = "#0072B2", fontface = "bold", size = 3.8) +
    geom_text(data = lab, aes(PC1, PC2, label = g), size = 3, vjust = -0.8, colour = "grey30") +
    scale_colour_manual(values = c(genotype = "grey50", mutant = "grey55", parent = "#D55E00"), name = NULL) +
    scale_size_manual(values = c(genotype = 2, mutant = 2, parent = 3.5), guide = "none") +
    labs(x = sprintf("PC1 (%.0f%%)", f$explained[1]), y = sprintf("PC2 (%.0f%%)", f$explained[2])) +
    scale_x_continuous(expand = expansion(mult = 0.18)) + coord_equal() + theme_minimal(base_size = 13) + theme(legend.position = "top")
}

# Mean against stability. Best: far to the right and low
plot_mean_stability <- function(f, highlight = NULL, n_label = 8) {
  G <- f$G
  G$group <- if (is.null(highlight)) "genotype" else ifelse(G$g %in% highlight, "parent", "mutant")
  G$score <- scale(G$mean)[, 1] - scale(G$stab)[, 1]
  lab <- G[order(-G$score), ][seq_len(n_label), ]
  ggplot(G, aes(mean, stab, colour = group, size = group)) +
    geom_vline(xintercept = mean(G$mean), colour = "grey70", linetype = 2) +
    geom_point(alpha = 0.8) +
    geom_text(data = lab, aes(label = g), size = 3, vjust = -0.8, colour = "grey30", show.legend = FALSE, check_overlap = TRUE) +
    scale_colour_manual(values = c(genotype = "grey50", mutant = "grey55", parent = "#D55E00"), name = NULL) +
    scale_size_manual(values = c(genotype = 2, mutant = 2, parent = 3.5), guide = "none") +
    labs(x = "Mean over trials (BLUE)", y = "Instability (distance to the average-trial axis)") +
    theme_minimal(base_size = 13) + theme(legend.position = "top")
}

# ---------------------------------------------------------------- 7. Selection index
# weights: named vector. Positive = more is better. Negative = less is better. Use the standardised BLUPs.
selection_table <- function(B, weights, pct = 0.25) {
  Z <- scale(B[, names(weights), drop = FALSE])
  B$index <- as.numeric(Z %*% weights)
  B <- B[order(-B$index), ]
  B$rank <- seq_len(nrow(B))
  B$selected <- B$rank <= ceiling(pct * nrow(B))
  B
}
