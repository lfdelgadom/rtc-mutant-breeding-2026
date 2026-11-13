# helpers.R: the functions used in the practical.
# You do not need to change anything here. Open it only if you want to see how a step works.

library(dplyr)
library(tidyr)
library(ggplot2)
library(pls)

theme_set(theme_minimal(base_size = 14))

# ---------------------------------------------------------------- 1. Load the data
# Returns a list with: lab (table of laboratory values), X (spectra, one row per sample),
# wl (wavelengths in nm) and line (the bean line of each sample).
load_bean_nir <- function(file = "data/bean_nirs.csv") {
  d <- read.csv(file, check.names = FALSE)
  is_spectrum <- grepl("^w[0-9]+$", names(d))
  X <- as.matrix(d[, is_spectrum])
  wl <- as.numeric(sub("w", "", colnames(X)))
  colnames(X) <- wl
  list(lab = d[, !is_spectrum], X = X, wl = wl, line = d$line)
}

# ---------------------------------------------------------------- 2. Prepare the spectra
# SNV: each spectrum is centred and scaled by itself (removes differences in level and scale).
snv <- function(X) t(apply(X, 1, function(s) (s - mean(s)) / sd(s)))

# First derivative after a light smoothing (removes a sloping baseline, sharpens the peaks).
first_derivative <- function(X, window = 5) {
  smooth <- t(apply(X, 1, function(s) stats::filter(s, rep(1 / window, window), sides = 2)))
  smooth <- smooth[, !apply(smooth, 2, anyNA), drop = FALSE]
  t(apply(smooth, 1, diff))
}

# The two steps together. Each spectrum is treated on its own, so no leakage is possible here.
prepare_spectra <- function(X, window = 5) {
  Z <- first_derivative(snv(X), window)
  wl <- as.numeric(colnames(X))
  keep <- seq(ceiling(window / 2) + 1, length.out = ncol(Z))
  colnames(Z) <- (wl[keep] + wl[keep + 1]) / 2   # wavelength of each derivative value
  Z
}

# ---------------------------------------------------------------- 3. Plot the spectra
plot_spectra <- function(X, colour_by = NULL, n = 40, ylab = "Absorbance", legend_title = NULL) {
  set.seed(1)
  rows <- sample(nrow(X), min(n, nrow(X)))
  wl <- as.numeric(colnames(X))
  long <- data.frame(sample = rep(rows, each = ncol(X)),
                     wavelength = rep(wl, times = length(rows)),
                     value = as.vector(t(X[rows, ])))
  if (!is.null(colour_by)) long$group <- rep(colour_by[rows], each = ncol(X))
  p <- ggplot(long, aes(wavelength, value, group = sample))
  p <- if (is.null(colour_by)) p + geom_line(alpha = 0.5, colour = "#2c7fb8")
       else p + geom_line(aes(colour = group), alpha = 0.6) + labs(colour = legend_title)
  p + labs(x = "Wavelength (nm)", y = ylab)
}

# ---------------------------------------------------------------- 4. Principal component regression (PCR)
# Step 1: PCA on the spectra of the training samples. Step 2: a normal linear regression
# of the trait on the first few principal components (scores).
fit_pcr <- function(X, y, ncomp) {
  centre <- colMeans(X)
  pca <- prcomp(X, center = TRUE, scale. = FALSE)
  scores <- pca$x[, 1:ncomp, drop = FALSE]
  fit <- lm(y ~ ., data = data.frame(y = y, scores))
  list(centre = centre, rotation = pca$rotation[, 1:ncomp, drop = FALSE], fit = fit, ncomp = ncomp)
}

# Predict new samples: they are projected on the components found in the training samples.
predict_pcr <- function(model, Xnew) {
  scores <- scale(Xnew, center = model$centre, scale = FALSE) %*% model$rotation
  colnames(scores) <- paste0("PC", 1:model$ncomp)
  as.numeric(predict(model$fit, newdata = as.data.frame(scores)))
}

# ---------------------------------------------------------------- 5. Quality of a prediction
rmse <- function(obs, pred) sqrt(mean((obs - pred)^2))
r2   <- function(obs, pred) cor(obs, pred)^2
bias <- function(obs, pred) mean(pred - obs)
rpd  <- function(obs, pred) sd(obs) / rmse(obs, pred)

quality <- function(obs, pred) {
  c(RMSE = rmse(obs, pred), R2 = r2(obs, pred), bias = bias(obs, pred), RPD = rpd(obs, pred))
}

# ---------------------------------------------------------------- 6. Cross-validation
# Groups for the folds. "random": every sample goes to a random fold.
# "by_line": all samples of the same line go to the same fold (a new line is never seen in training).
make_folds <- function(line, k = 10, by_line = FALSE, seed = 1) {
  set.seed(seed)
  if (!by_line) return(sample(rep(1:k, length.out = length(line))))
  lines <- unique(line)
  fold_of_line <- sample(rep(1:k, length.out = length(lines)))
  fold_of_line[match(line, lines)]
}

# Predict every sample while it is left out of the training. Works for any number of components.
cv_predict <- function(X, y, folds, ncomp, method = "pcr") {
  pred <- numeric(length(y))
  for (k in unique(folds)) {
    test <- folds == k
    if (method == "pcr") {
      m <- fit_pcr(X[!test, , drop = FALSE], y[!test], ncomp)
      pred[test] <- predict_pcr(m, X[test, , drop = FALSE])
    } else {
      d <- data.frame(y = y[!test]); d$X <- I(X[!test, , drop = FALSE])
      m <- plsr(y ~ X, ncomp = ncomp, data = d)
      pred[test] <- as.numeric(predict(m, ncomp = ncomp, newdata = data.frame(X = I(X[test, , drop = FALSE]))))
    }
  }
  pred
}

# RMSE of cross-validation for 1, 2, 3 ... max_comp components.
cv_curve <- function(X, y, folds, max_comp = 15, method = "pcr") {
  data.frame(components = 1:max_comp,
             RMSE = sapply(1:max_comp, function(k) rmse(y, cv_predict(X, y, folds, k, method))))
}

# ---------------------------------------------------------------- 7. A plot of predicted against observed
plot_pred <- function(obs, pred, title = NULL) {
  ggplot(data.frame(obs, pred), aes(obs, pred)) +
    geom_abline(linetype = 2) +
    geom_point(colour = "#2c7fb8", alpha = 0.7, size = 2) +
    labs(x = "Observed", y = "Predicted", title = title) + coord_equal()
}
