# Helpers for the cassava data analysis pipeline (free packages only: lme4, SpATS, ggplot2)
library(ggplot2)
library(SpATS)
suppressMessages(library(patchwork))

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
    scale_y_reverse(breaks = function(l) unique(round(pretty(l, 4)))) +
    scale_x_continuous(breaks = function(l) unique(round(pretty(l, 4)))) +
    coord_equal() + labs(x = "Column", y = "Row", title = trial) +
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

# Several field layouts in one figure (needs the patchwork package)
plot_layout_grid <- function(d, trials, ncol = 3) {
  patchwork::wrap_plots(lapply(trials, function(t) plot_trial_layout(d, t) + coord_cartesian() + theme(legend.position = "bottom")),
                        ncol = ncol, guides = "collect") &
    theme(legend.position = "bottom")
}

# The flow of the data, from the field to the selection. "active" highlights some steps.
plot_flow <- function(active = NULL) {
  steps <- data.frame(
    n = 1:7,
    title = c("Data collection", "Data storage", "Download", "Exploratory\nanalysis",
              "Single trial\nanalysis", "Multi-environment\nanalysis", "Selection"),
    detail = c("Field book app,\nsensors, robots", "Database in the cloud\n(Cassava Base, BMS)",
               "One table,\none row per plot", "Design, missing data,\nshared clones",
               "Spatial model,\nheritability", "G x E, BLUPs,\nheritability", "Index and\nadvancement table"),
    block = c("Data", "Data", "Data", "Pre-processing", "Modelling", "Modelling", "Results"),
    x = c(1, 2, 3, 4, 1, 2, 3), y = c(2, 2, 2, 2, 0.4, 0.4, 0.4), stringsAsFactors = FALSE)
  steps$y[5:7] <- 0.4
  steps$x[5:7] <- c(1.6, 2.6, 3.6)
  cols <- c(Data = "#3E6FA8", `Pre-processing` = "#E0A030", Modelling = "#4F7A3A", Results = "#7A5C4F")
  steps$fill <- cols[steps$block]
  if (!is.null(active)) steps$fill[!(steps$n %in% active)] <- "#C9CDD2"
  steps$txt <- ifelse(is.null(active) | steps$n %in% active, "white", "grey35")
  w <- 0.42; h <- 0.5
  arr <- data.frame(x = c(1, 2, 3, 1.6, 2.6) + w + 0.01, xend = c(2, 3, 4, 2.6, 3.6) - w - 0.01,
                    y = c(2, 2, 2, 0.4, 0.4), yend = c(2, 2, 2, 0.4, 0.4))
  ggplot() +
    geom_segment(data = arr, aes(x = x, xend = xend, y = y, yend = yend),
                 arrow = grid::arrow(length = grid::unit(0.18, "cm"), type = "closed"), colour = "grey30", linewidth = 0.7) +
    geom_segment(aes(x = 4, xend = 4, y = 2 - h - 0.02, yend = 1.2), colour = "grey30", linewidth = 0.7) +
    geom_segment(aes(x = 4, xend = 1.6, y = 1.2, yend = 1.2), colour = "grey30", linewidth = 0.7) +
    geom_segment(aes(x = 1.6, xend = 1.6, y = 1.2, yend = 0.4 + h + 0.02), colour = "grey30", linewidth = 0.7,
                 arrow = grid::arrow(length = grid::unit(0.18, "cm"), type = "closed")) +
    geom_rect(data = steps, aes(xmin = x - w, xmax = x + w, ymin = y - h, ymax = y + h, fill = I(fill)), colour = "white") +
    geom_text(data = steps, aes(x, y + 0.13, label = title, colour = I(txt)), size = 3.7, fontface = "bold", lineheight = 0.9) +
    geom_text(data = steps, aes(x, y - 0.22, label = detail, colour = I(txt)), size = 3, lineheight = 0.9) +
    geom_text(data = steps, aes(x - w + 0.04, y + h - 0.08, label = n, colour = I(txt)), size = 3.2, fontface = "bold") +
    xlim(0.45, 4.55) + ylim(-0.25, 2.65) + theme_void()
}

# Stage 1 of a two-stage analysis: a spatial model in each trial gives one adjusted mean (BLUE) per clone
# and its standard error. The weight of each mean is 1 / se^2.
stage1_blues <- function(d, trait) {
  out <- lapply(levels(d$trial), function(tr) {
    x <- d[d$trial == tr & !is.na(d[[trait]]), ]; x$g <- droplevels(x$g)
    m <- SpATS::SpATS(response = trait, genotype = "g", genotype.as.random = FALSE,
                      spatial = ~ SpATS::PSANOVA(col_number, row_number, nseg = c(8, 8), degree = 3, nest.div = 2),
                      data = x, control = list(tolerance = 1e-3, monitoring = 0))
    p <- predict(m, which = "g")
    data.frame(trial = tr, g = as.character(p$g), blue = p$predicted.values, se2 = p$standard.errors^2)
  })
  B <- do.call(rbind, out); B$trial <- factor(B$trial); B$g <- factor(B$g); B
}

# Stage 2: clone and clone by trial are random, and the known variance of each mean is used as weight.
# nlme can fix the residual standard deviation to 1 (lme4 cannot).
stage2_met <- function(B) {
  nlme::lme(blue ~ trial, random = ~ 1 | g/trial, weights = nlme::varFixed(~ se2), data = B,
            control = nlme::lmeControl(sigma = 1))
}
