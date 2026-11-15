# helpers.R: short functions for the practical. You do not need to change this file.
library(lme4)
library(randomForest)
library(ggplot2)

# Read the data and turn the design columns into factors
load_wheat <- function(path) {
  d <- read.csv(path)
  d <- d[!is.na(d$yield), ]
  for (v in c("Year", "Location", "Environment", "region", "Block", "Genotype", "GenoGroup")) {
    d[[v]] <- factor(trimws(d[[v]]))
  }
  d
}

# Variance components of a mixed model, in percent
variance_table <- function(model) {
  v <- as.data.frame(VarCorr(model))[, c("grp", "vcov")]
  names(v) <- c("source", "variance")
  v$percent <- round(100 * v$variance / sum(v$variance), 1)
  v$variance <- round(v$variance, 3)
  v[order(-v$variance), ]
}

# Folds: random rows, or whole groups (for example whole environments)
make_folds <- function(n, group = NULL, k = 5, seed = 1) {
  set.seed(seed)
  if (is.null(group)) return(sample(rep(1:k, length.out = n)))
  g  <- unique(as.character(group))
  fg <- sample(rep(1:k, length.out = length(g)))
  names(fg) <- g
  unname(fg[as.character(group)])
}

# Random forest with cross-validation. Also returns the "always the mean" baseline.
cv_rf <- function(formula, data, folds, ntree = 150, seed = 1) {
  set.seed(seed)
  y <- all.vars(formula)[1]
  pred <- numeric(nrow(data)); baseline <- numeric(nrow(data))
  for (k in sort(unique(folds))) {
    train <- folds != k
    fit   <- randomForest(formula, data[train, ], ntree = ntree)
    test  <- data[!train, ]
    for (v in names(fit$forest$xlevels)) test[[v]] <- factor(test[[v]], levels = fit$forest$xlevels[[v]])
    pred[!train]     <- predict(fit, test)
    baseline[!train] <- mean(data[[y]][train])
  }
  list(pred = pred, baseline = baseline)
}

# Quality of the predictions: error of the model and error of "always the mean"
quality <- function(obs, pred, baseline) {
  c(RMSE = sqrt(mean((obs - pred)^2)),
    RMSE_always_mean = sqrt(mean((obs - baseline)^2)))
}

# Median correlation between observed and predicted, calculated inside each group
within_r <- function(group, obs, pred) {
  r <- sapply(split(data.frame(obs, pred), group), function(d) cor(d$obs, d$pred))
  median(r, na.rm = TRUE)
}

# One random forest on all the data, with variable importance
fit_rf <- function(formula, data, ntree = 150, seed = 1) {
  set.seed(seed)
  randomForest(formula, data, ntree = ntree, importance = TRUE)
}

plot_pred <- function(obs, pred, title = "") {
  ggplot(data.frame(obs, pred), aes(obs, pred)) +
    geom_abline(linetype = 2, colour = "red") +
    geom_point(colour = "#2c7fb8", alpha = 0.5) +
    labs(title = title, x = "Observed yield (t/ha)", y = "Predicted yield (t/ha)")
}

plot_importance <- function(rf) {
  imp <- data.frame(variable = rownames(importance(rf)), importance(rf)[, "%IncMSE"])
  names(imp)[2] <- "IncMSE"
  ggplot(imp, aes(IncMSE, reorder(variable, IncMSE))) + geom_col(fill = "#2c7fb8") +
    labs(x = "% increase of the error when the variable is shuffled", y = NULL)
}
