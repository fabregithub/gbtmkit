# Tests for time-varying (trajectory) covariates: gbtm_spec(tcov = ...).
# A binary occasion-level exposure shifts the outcome with group-specific
# effects; adding it must improve BIC on every engine, and fitted trajectories
# are computed at tcov = 0.

make_tcov_data <- function(n = 600, nt = 8) {
  set.seed(11)
  times <- seq_len(nt)
  grp <- sample(1:2, n, TRUE)
  mu  <- rbind(12 + 1.0 * times, 30 - 1.0 * times)
  W   <- matrix(rbinom(n * nt, 1, 0.4), n, nt)
  delta <- c(-3, 3)
  d <- data.frame(id = seq_len(n))
  d[paste0("y", seq_len(nt))] <- as.data.frame(t(sapply(seq_len(n), function(i)
    rnorm(nt, mu[grp[i], ] + delta[grp[i]] * W[i, ], 1.5))))
  d[paste0("t", seq_len(nt))] <- as.data.frame(
    matrix(rep(times, each = n), n, nt))
  d[paste0("w", seq_len(nt))] <- as.data.frame(W)
  d
}

tcov_spec <- function(tcov = list(w = paste0("w", 1:8))) {
  gbtm_spec(make_tcov_data(), paste0("y", 1:8), paste0("t", 1:8),
            id = "id", family = "gaussian", tcov = tcov)
}

test_that("tcov validation fires", {
  d <- make_tcov_data(50)
  base <- function(tcov) gbtm_spec(d, paste0("y", 1:8), paste0("t", 1:8),
                                   id = "id", family = "gaussian", tcov = tcov)
  expect_error(base(paste0("w", 1:8)), "named list")
  expect_error(base(list(paste0("w", 1:8))), "named list")
  expect_error(base(list(y = paste0("w", 1:8))), "reserved")
  expect_error(base(list(w = paste0("w", 1:4))), "one column per occasion")
  expect_error(base(list(w = c(paste0("w", 1:7), "nope"))), "not found")
  d2 <- d; d2$w3[5] <- NA
  expect_error(gbtm_spec(d2, paste0("y", 1:8), paste0("t", 1:8), id = "id",
                         family = "gaussian", tcov = list(w = paste0("w", 1:8))),
               "missing values")
})

test_that("spec prints and exposes tcov", {
  spec <- tcov_spec()
  expect_output(print(spec), "tcov       : w \\(time-varying\\)")
  W <- gbtmkit:::.spec_W(spec)
  expect_named(W, "w")
  expect_equal(dim(W$w), c(600L, 8L))
  expect_equal(dim(gbtmkit:::.spec_TCOV(spec)), c(600L, 8L))
})

test_that("trajeR: tcov improves BIC, recovers effects, predicts at tcov = 0", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  spec0 <- gbtm_spec(make_tcov_data(), paste0("y", 1:8), paste0("t", 1:8),
                     id = "id", family = "gaussian")
  b0 <- gbtm_bic(gbtm_fit(spec0, n_groups = 2, degrees = c(1, 1),
                          engine = "trajeR", method = "L", itermax = 300, seed = 1))
  fit <- gbtm_fit(tcov_spec(), n_groups = 2, degrees = c(1, 1),
                  engine = "trajeR", method = "L", itermax = 300, seed = 1)
  expect_valid_fit(fit, 2)
  expect_lt(gbtm_bic(fit), b0 - 100)
  # group-specific effects (truth -3 and 3, in some group order)
  deltas <- sort(unlist(fit$raw$delta))
  expect_equal(deltas, c(-3, 3), tolerance = 0.15)
  # trajectories at tcov = 0: pure group polynomials, well within data range
  pred <- gbtm_predict(fit, n = 10)
  expect_equal(nrow(pred), 20)
  expect_true(all(pred$fitted > 5 & pred$fitted < 35))
})

test_that("trajeR: multi-start works with tcov", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  single <- gbtm_fit(tcov_spec(), n_groups = 2, degrees = c(1, 1),
                     engine = "trajeR", method = "L", itermax = 300, seed = 1)
  multi <- gbtm_fit(tcov_spec(), n_groups = 2, degrees = c(1, 1),
                    engine = "trajeR", method = "L", itermax = 300, seed = 1, n_starts = 3)
  expect_lte(gbtm_bic(multi), gbtm_bic(single) + 1e-6)
})

test_that("flexmix: tcov improves BIC and satisfies the contract", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  spec0 <- gbtm_spec(make_tcov_data(), paste0("y", 1:8), paste0("t", 1:8),
                     id = "id", family = "gaussian")
  b0 <- gbtm_bic(gbtm_fit(spec0, engine = "flexmix", n_groups = 2,
                          degrees = c(1, 1), seed = 1))
  fit <- gbtm_fit(tcov_spec(), engine = "flexmix", n_groups = 2,
                  degrees = c(1, 1), seed = 1)
  expect_valid_fit(fit, 2)
  expect_lt(gbtm_bic(fit), b0 - 100)
  # predict must use only intercept + polynomial coefficients (tcov = 0)
  pred <- gbtm_predict(fit, n = 10)
  expect_equal(nrow(pred), 20)
  expect_true(all(pred$fitted > 5 & pred$fitted < 35))
})

test_that("lcmm: tcov improves BIC, contract holds, predict works", {
  skip_on_cran()
  skip_if_not_installed("lcmm")
  spec0 <- gbtm_spec(make_tcov_data(), paste0("y", 1:8), paste0("t", 1:8),
                     id = "id", family = "gaussian")
  b0 <- gbtm_bic(gbtm_fit(spec0, engine = "lcmm", n_groups = 2,
                          degrees = c(1, 1), seed = 1, itermax = 80))
  fit <- gbtm_fit(tcov_spec(), engine = "lcmm", n_groups = 2,
                  degrees = c(1, 1), seed = 1, itermax = 80)
  expect_valid_fit(fit, 2)
  expect_lt(gbtm_bic(fit), b0 - 100)
  pred <- gbtm_predict(fit, n = 10)
  expect_equal(nrow(pred), 20)
  expect_true(all(pred$fitted > 5 & pred$fitted < 35))
})

test_that("tcov and membership covariates can coexist", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  d <- make_tcov_data()
  d$x <- rnorm(nrow(d))
  spec <- gbtm_spec(d, paste0("y", 1:8), paste0("t", 1:8), id = "id",
                    family = "gaussian", covariates = "x",
                    tcov = list(w = paste0("w", 1:8)))
  fit <- gbtm_fit(spec, engine = "flexmix", n_groups = 2,
                  degrees = c(1, 1), seed = 1)
  expect_valid_fit(fit, 2)
})
