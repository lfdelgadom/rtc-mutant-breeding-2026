# Helpers for the cassava data analysis pipeline (free packages only: lme4, SpATS, ggplot2)
library(ggplot2)
library(SpATS)

TRAITS <- c("yield_ha", "DM_gravity", "plant_type",
            "germination_perc", "height_1st_branch", "branch_number")
TRAIT_LABELS <- c(yield_ha = "Yield (t/ha)", DM_gravity = "Dry matter (%)",
                  plant_type = "Plant type (1 to 5)",
                  germination_perc = "Germination (%)",
                  height_1st_branch = "Height 1st branch (m)",
                  branch_number = "Branch number")

load_cassava <- function(path = "data/cassava_DVGXE_tidy.csv") {
  d <- read.csv(path, check.names = FALSE)
  d$trial <- paste0(d$location_short, substr(d$year, 3, 4))
  d$trial <- factor(d$trial, levels = unique(d$trial[order(d$year, d$location_short)]))
  d$g <- factor(d$accession_name)
  d$rep <- factor(d$rep_number)
  d
}

plot_missing <- function(d, traits = TRAITS) {
  m <- do.call(rbind, lapply(traits, function(tr)
    data.frame(trait = tr, trial = levels(d$trial),
               miss = as.numeric(tapply(is.na(d[[tr]]), d$trial, mean)) * 100)))
  ggplot(m, aes(trait, trial, fill = miss)) +
    geom_tile(colour = "grey80") +
    geom_text(aes(label = round(miss, 1)), size = 3.2) +
    scale_fill_gradient(low = "white", high = "#D55E00", limits = c(0, 20), oob = scales::squish, name = "% missing") +
    labs(x = NULL, y = NULL) + theme_minimal(base_size = 13) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

plot_trial_layout <- function(d, trial) {
  x <- d[d$trial == trial, ]
  ggplot(x, aes(col_number, row_number, fill = check_test)) +
    geom_tile(colour = "white") +
    scale_fill_manual(values = c(check = "#D55E00", test = "#56B4E9"), name = NULL) +
    scale_y_reverse() + coord_equal() + labs(x = "Column", y = "Row", title = trial) +
    theme_minimal(base_size = 12)
}

plot_connect <- function(d) {
  tr <- levels(d$trial)
  M <- outer(tr, tr, Vectorize(function(a, b)
    length(intersect(d$g[d$trial == a], d$g[d$trial == b]))))
  df <- expand.grid(a = tr, b = tr); df$n <- as.vector(M)
  df$a <- factor(df$a, levels = tr); df$b <- factor(df$b, levels = rev(tr))
  ggplot(df, aes(a, b, fill = n)) + geom_tile(colour = "white") +
    geom_text(aes(label = n), size = 3.2) +
    scale_fill_gradient(low = "white", high = "#0072B2", name = "Shared\nclones") +
    labs(x = NULL, y = NULL) + theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

plot_trait_trial <- function(d, trait = "yield_ha") {
  ggplot(d, aes(trial, .data[[trait]], fill = trial)) +
    geom_boxplot(outlier.size = 1, show.legend = FALSE) +
    scale_fill_grey(start = 0.95, end = 0.6) +
    labs(x = NULL, y = TRAIT_LABELS[[trait]]) + theme_minimal(base_size = 13) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

# single trial, spatial model (SpATS): genotype random, 2D smooth surface
fit_spats <- function(d, trial, trait) {
  x <- d[d$trial == trial & !is.na(d[[trait]]), ]
  x <- x[!is.na(x$row_number) & !is.na(x$col_number), ]
  x$g <- droplevels(x$g)
  SpATS::SpATS(response = trait, genotype = "g", genotype.as.random = TRUE,
               spatial = ~ SpATS::PSANOVA(col_number, row_number,
                                          nseg = c(8, 8), degree = 3, nest.div = 2),
               data = x, control = list(tolerance = 1e-3, monitoring = 0))
}

single_h2 <- function(d, traits = TRAITS) {
  out <- expand.grid(trial = levels(d$trial), trait = traits, stringsAsFactors = FALSE)
  out$h2 <- NA_real_
  for (i in seq_len(nrow(out))) {
    m <- try(fit_spats(d, out$trial[i], out$trait[i]), silent = TRUE)
    if (!inherits(m, "try-error")) out$h2[i] <- as.numeric(SpATS::getHeritability(m))
  }
  out
}

# multi-environment model with lme4: genotype and genotype by trial random
met_model <- function(d, trait) {
  x <- d[!is.na(d[[trait]]), ]
  f <- as.formula(paste0(trait, " ~ trial + (1 | g) + (1 | g:trial)"))
  lme4::lmer(f, data = x, control = lme4::lmerControl(check.conv.singular = "ignore"))
}

met_h2 <- function(m, d, trait) {
  vc <- as.data.frame(lme4::VarCorr(m))
  vg <- vc$vcov[vc$grp == "g"]; vge <- vc$vcov[vc$grp == "g:trial"]; ve <- vc$vcov[vc$grp == "Residual"]
  x <- d[!is.na(d[[trait]]), ]
  ne <- length(unique(x$trial)); nr <- nrow(x) / (ne * length(unique(x$g)))
  c(Vg = vg, VgxE = vge, Ve = ve, h2 = vg / (vg + vge / ne + ve / (ne * nr)))
}

met_blups <- function(m) {
  b <- lme4::ranef(m)$g
  data.frame(g = rownames(b), blup = b[, 1])
}

# genotypic correlation between trials: correlation of the genotype BLUPs per trial
# (genotype + genotype by trial effects), computed with all clones present in both trials
trial_gcor <- function(m) {
  r <- lme4::ranef(m)
  g <- r$g; ge <- r[["g:trial"]]
  nm <- strsplit(rownames(ge), ":")
  df <- data.frame(g = sapply(nm, `[`, 1), trial = sapply(nm, `[`, 2), v = ge[, 1])
  df$v <- df$v + g[df$g, 1]
  W <- reshape(df, idvar = "g", timevar = "trial", direction = "wide")
  names(W) <- sub("^v\\.", "", names(W))
  cor(W[, -1], use = "pairwise.complete.obs")
}

plot_corr <- function(R, title = NULL) {
  nm <- colnames(R)
  df <- expand.grid(a = nm, b = nm); df$r <- as.vector(R)
  df$a <- factor(df$a, levels = nm); df$b <- factor(df$b, levels = rev(nm))
  ggplot(df, aes(a, b, fill = r)) + geom_tile(colour = "white") +
    geom_text(aes(label = sprintf("%.2f", r)), size = 3) +
    scale_fill_gradient2(low = "#D55E00", mid = "white", high = "#0072B2", limits = c(-1, 1), name = "r") +
    labs(x = NULL, y = NULL, title = title) + theme_minimal(base_size = 12) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

# overall BLUPs for all traits, one row per clone
all_blups <- function(d, traits = TRAITS) {
  out <- NULL
  for (tr in traits) {
    m <- met_model(d, tr); b <- met_blups(m); names(b)[2] <- tr
    out <- if (is.null(out)) b else merge(out, b, by = "g")
  }
  out
}

# selection index: weighted sum of standardised BLUPs (scores as in the original report)
selection_table <- function(B, weights = c(yield_ha = 10, DM_gravity = 10, plant_type = -5), pct = 0.20) {
  Z <- scale(B[, names(weights)])
  B$index <- as.numeric(Z %*% weights)
  B <- B[order(-B$index), ]
  B$rank <- seq_len(nrow(B))
  B$selected <- B$rank <= ceiling(pct * nrow(B))
  B
}
