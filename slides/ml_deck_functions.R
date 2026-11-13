# ml_deck_functions.R: model functions used only in the Day 5 lecture slides.
# They need helpers.R (loaded first) and the packages below.
suppressMessages({ library(glmnet); library(ranger); library(gbm); library(pls); library(e1071) })

# Average neighbouring wavelengths (step = 5) so the models run fast in class.
thin <- function(M, step = 5) {
  g <- ceiling(seq_len(ncol(M)) / step)
  out <- sapply(split(seq_len(ncol(M)), g), function(i) rowMeans(M[, i, drop = FALSE]))
  colnames(out) <- paste0("v", seq_len(ncol(out))); out
}
fit_predict <- function(model, A, y, B, lineA) {
  inner <- make_folds(lineA, k = 5, by_line = TRUE, seed = 7)
  switch(model,
    PCR = { cv <- cv_curve(A, y, inner, 12, "pcr"); predict_pcr(fit_pcr(A, y, which.min(cv$RMSE)), B) },
    PLS = { cv <- cv_curve(A, y, inner, 12, "pls"); k <- which.min(cv$RMSE)
            d <- data.frame(y = y); d$X <- I(A); as.numeric(predict(plsr(y ~ X, ncomp = k, data = d), ncomp = k, newdata = data.frame(X = I(B)))) },
    Ridge = { set.seed(1); as.numeric(predict(cv.glmnet(A, y, alpha = 0,   foldid = inner), B, s = "lambda.min")) },
    Lasso = { set.seed(1); as.numeric(predict(cv.glmnet(A, y, alpha = 1,   foldid = inner), B, s = "lambda.min")) },
    ENet  = { set.seed(1); as.numeric(predict(cv.glmnet(A, y, alpha = 0.5, foldid = inner), B, s = "lambda.min")) },
    RF  = { set.seed(1); predict(ranger(x = A, y = y, num.trees = 500), B)$predictions },
    GBM = { set.seed(1); d <- as.data.frame(A); d$y <- y
            g <- gbm(y ~ ., data = d, distribution = "gaussian", n.trees = 300, shrinkage = 0.05, interaction.depth = 2, bag.fraction = 0.7, verbose = FALSE)
            predict(g, as.data.frame(B), n.trees = 300) },
    SVM = { as.numeric(predict(svm(x = A, y = y, kernel = "radial", cost = 4, scale = TRUE), B)) })
}
cv_model <- function(model, M, y, folds, line) {
  p <- numeric(length(y))
  for (k in unique(folds)) { t <- folds == k; p[t] <- fit_predict(model, M[!t, , drop = FALSE], y[!t], M[t, , drop = FALSE], line[!t]) }
  p
}
