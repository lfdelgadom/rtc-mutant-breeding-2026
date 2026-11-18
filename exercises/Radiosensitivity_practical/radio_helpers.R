# Helpers for the radiosensitivity analysis. Base R and ggplot2 only (no new packages).
library(ggplot2)

# Mean of each dose, relative to the control (dose 0)
dose_summary <- function(d, y = "height_cm") {
  m <- aggregate(d[[y]], list(dose_Gy = d$dose_Gy), mean, na.rm = TRUE); names(m)[2] <- "mean"
  n <- aggregate(d[[y]], list(dose_Gy = d$dose_Gy), function(z) sum(!is.na(z))); m$n <- n$x
  m$sd <- aggregate(d[[y]], list(dose_Gy = d$dose_Gy), sd, na.rm = TRUE)$x
  m$relative <- m$mean / m$mean[m$dose_Gy == 0]
  m$reduction_pct <- (1 - m$relative) * 100
  m
}

# Dose-response curve with 3 parameters:  y = D / (1 + (dose / GR50)^b)
#   D = value of the control, GR50 = dose that reduces the growth by 50%, b = steepness
# Fitted on the data of each plant (survivors), with nls.
fit_dose_response <- function(d, y = "height_cm") {
  x <- d[!is.na(d[[y]]), ]; x$y <- x[[y]]
  m <- dose_summary(x, y)
  D0 <- m$mean[m$dose_Gy == 0]
  e0 <- approx(m$relative, m$dose_Gy, xout = 0.5, ties = "ordered")$y
  if (is.na(e0)) e0 <- median(x$dose_Gy[x$dose_Gy > 0])
  nls(y ~ D / (1 + (dose_Gy / e)^b), data = x, start = list(D = D0, e = e0, b = 2),
      control = nls.control(maxiter = 200, warnOnly = TRUE))
}

# Dose that gives a reduction of k (0.3 = GR30, 0.5 = GR50), with a 95% interval.
# The interval is made by simulation from the estimated parameters.
dose_for_reduction <- function(fit, k = 0.5, nsim = 2000) {
  cf <- coef(fit); f <- function(p) p[["e"]] * (k / (1 - k))^(1 / p[["b"]])
  sim <- MASS::mvrnorm(nsim, cf, vcov(fit))
  s <- apply(sim, 1, function(r) f(setNames(r, names(cf))))
  c(estimate = f(cf), lower = unname(quantile(s, 0.025, na.rm = TRUE)), upper = unname(quantile(s, 0.975, na.rm = TRUE)))
}

# Survival. Logistic regression: survived (1) or dead (0) against the dose. LD50 = -intercept / slope.
fit_survival <- function(d) glm(survived ~ dose_Gy, family = binomial, data = d)
ld50 <- function(fit, nsim = 2000) {
  cf <- coef(fit); sim <- MASS::mvrnorm(nsim, cf, vcov(fit)); s <- -sim[, 1] / sim[, 2]
  c(estimate = unname(-cf[1] / cf[2]), lower = unname(quantile(s, 0.025)), upper = unname(quantile(s, 0.975)))
}

# Table of candidate doses: growth reduction and survival predicted by the models
dose_table <- function(doses, fit_dr, fit_surv) {
  cf <- coef(fit_dr)
  data.frame(dose_Gy = doses,
             growth_reduction_pct = round((1 - 1 / (1 + (doses / cf[["e"]])^cf[["b"]])) * 100),
             survival_pct = round(predict(fit_surv, data.frame(dose_Gy = doses), type = "response") * 100))
}
