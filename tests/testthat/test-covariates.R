# Tests for class-membership covariates ("risk factors"): time-stable
# subject-level variables that predict group membership via a multinomial
# model. The shipped fixtures' x1/x2 are deliberately inert, so these tests
# build a small dataset where covariates genuinely drive membership and assert
# that adding them improves BIC on every engine.

# Covariate-driven data: x1 pushes subjects toward group 2, the factor x2
# toward group 3 (multinomial logit, group 1 reference); three well-separated
# linear gaussian trajectories.
make_cov_data <- function(n = 800) {
  set.seed(42)
  x1 <- rnorm(n)
  x2 <- rbinom(n, 1, 0.5)
  eta2 <- -0.5 + 1.2 * x1
  eta3 <- -0.5 + 1.5 * x2
  pr  <- cbind(1, exp(eta2), exp(eta3))
  pr  <- pr / rowSums(pr)
  grp <- sapply(seq_len(n), function(i) sample(3, 1, prob = pr[i, ]))
  times <- 1:6
  mu <- rbind(10 + 1.0 * times, 20 + 0.0 * times, 30 - 1.0 * times)
  d <- data.frame(id = seq_len(n), x1 = x1,
                  x2 = factor(ifelse(x2 == 1, "b", "a")))
  d[paste0("y", 1:6)] <- as.data.frame(
    t(sapply(seq_len(n), function(i) rnorm(6, mu[grp[i], ], 1.5))))
  d[paste0("t", 1:6)] <- as.data.frame(matrix(rep(times, each = n), n, 6))
  d
}

cov_spec <- function(covariates = NULL) {
  gbtm_spec(make_cov_data(), paste0("y", 1:6), paste0("t", 1:6),
            id = "id", family = "gaussian", covariates = covariates)
}

test_that("covariate validation fires", {
  d <- make_cov_data(50)
  expect_error(
    gbtm_spec(d, paste0("y", 1:6), paste0("t", 1:6), id = "id",
              family = "gaussian", covariates = "nope"),
    "not found"
  )
  expect_error(
    gbtm_spec(d, paste0("y", 1:6), paste0("t", 1:6), id = "id",
              family = "gaussian", covariates = c("x1", "y1")),
    "overlap"
  )
  d$x1[3] <- NA
  expect_error(
    gbtm_spec(d, paste0("y", 1:6), paste0("t", 1:6), id = "id",
              family = "gaussian", covariates = "x1"),
    "missing values"
  )
})

test_that("spec exposes the covariate design matrix and formula", {
  spec <- cov_spec(c("x1", "x2"))
  X <- gbtmkit:::.spec_X(spec)
  expect_equal(dim(X), c(spec$n_subjects, 2L))   # factor x2 expands to one dummy
  expect_true(is.numeric(X))
  expect_null(gbtmkit:::.spec_X(cov_spec()))
  expect_output(print(spec), "covariates : x1, x2")
})

test_that("trajeR: membership covariates improve BIC on covariate-driven data", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  b0 <- gbtm_bic(gbtm_fit(cov_spec(), n_groups = 3, degrees = rep(1, 3),
                          method = "L", itermax = 200, seed = 1))
  fit <- gbtm_fit(cov_spec(c("x1", "x2")), n_groups = 3, degrees = rep(1, 3),
                  method = "L", itermax = 200, seed = 1)
  expect_valid_fit(fit, 3)
  expect_lt(gbtm_bic(fit), b0 - 50)
})

test_that("trajeR: multi-start works with covariates (method L)", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  single <- gbtm_fit(cov_spec(c("x1", "x2")), n_groups = 3,
                     degrees = rep(1, 3), method = "L", itermax = 200,
                     seed = 1)
  multi <- gbtm_fit(cov_spec(c("x1", "x2")), n_groups = 3,
                    degrees = rep(1, 3), method = "L", itermax = 200,
                    seed = 1, n_starts = 3)
  expect_lte(gbtm_bic(multi), gbtm_bic(single) + 1e-6)
})

test_that("trajeR: multi-start with covariates falls back for EM", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  expect_warning(
    fit <- gbtm_fit(cov_spec("x1"), n_groups = 2, degrees = c(1, 1),
                    method = "EM", itermax = 60, seed = 1, n_starts = 2),
    "only supported for method 'L'"
  )
  expect_equal(fit$n_starts, 1L)
})

test_that("flexmix: concomitant model improves BIC and satisfies the contract", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  b0 <- gbtm_bic(gbtm_fit(cov_spec(), engine = "flexmix", n_groups = 3,
                          degrees = rep(1, 3), seed = 1))
  fit <- gbtm_fit(cov_spec(c("x1", "x2")), engine = "flexmix", n_groups = 3,
                  degrees = rep(1, 3), seed = 1)
  expect_valid_fit(fit, 3)
  expect_lt(gbtm_bic(fit), b0 - 50)
})

test_that("lcmm: classmb improves BIC, contract holds, predict works", {
  skip_on_cran()
  skip_if_not_installed("lcmm")
  b0 <- gbtm_bic(gbtm_fit(cov_spec(), engine = "lcmm", n_groups = 3,
                          degrees = rep(1, 3), seed = 1, itermax = 80))
  fit <- gbtm_fit(cov_spec(c("x1", "x2")), engine = "lcmm", n_groups = 3,
                  degrees = rep(1, 3), seed = 1, itermax = 80)
  expect_valid_fit(fit, 3)
  expect_lt(gbtm_bic(fit), b0 - 50)
  # with covariates, model-implied sizes fall back to mean posterior
  expect_equal(unname(gbtm_group_sizes(fit)),
               unname(colMeans(gbtm_posterior(fit))))
  # predictY needs the covariates in newdata; the adapter supplies them
  pred <- gbtm_predict(fit, n = 5)
  expect_equal(nrow(pred), 3 * 5)
})

test_that("lcmm: gridsearch multi-start works with classmb", {
  skip_on_cran()
  skip_if_not_installed("lcmm")
  fit <- gbtm_fit(cov_spec("x1"), engine = "lcmm", n_groups = 2,
                  degrees = c(1, 1), seed = 1, itermax = 60, n_starts = 2)
  expect_valid_fit(fit, 2)
})
