# Tests for the trajeR adapter and the engine-agnostic accessors.
# trajeR is a Suggests dependency, so these skip when it is unavailable.

binary_spec <- function() {
  data("sim_binary", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_binary,
            outcomes = paste0("y", 1:10),
            time     = paste0("t", 1:10),
            id = "id", family = "binomial")
}

continuous_spec <- function() {
  data("sim_continuous", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_continuous,
            outcomes = paste0("y", 1:10),
            time     = paste0("t", 1:10),
            id = "id", family = "gaussian")
}

# Shared conformance check any engine's fit must satisfy.
expect_valid_fit <- function(fit, n_groups) {
  expect_s3_class(fit, "gbtm_fit")
  expect_equal(gbtm_n_groups(fit), n_groups)
  expect_length(gbtm_degrees(fit), n_groups)

  expect_true(is.finite(gbtm_bic(fit)))
  expect_true(is.finite(gbtm_aic(fit)))
  expect_true(is.finite(gbtm_loglik(fit)))

  post <- gbtm_posterior(fit)
  expect_equal(ncol(post), n_groups)
  expect_equal(nrow(post), fit$spec$n_subjects)
  # rows are probability distributions
  expect_equal(unname(rowSums(post)), rep(1, nrow(post)), tolerance = 1e-6)
  expect_true(all(post >= -1e-8 & post <= 1 + 1e-8))

  sizes <- gbtm_group_sizes(fit)
  expect_length(sizes, n_groups)
  expect_equal(sum(sizes), 1, tolerance = 1e-6)
  expect_true(all(sizes >= 0))
}

test_that("trajeR LOGIT fit satisfies the engine contract", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  fit <- gbtm_fit(binary_spec(), engine = "trajeR",
                  n_groups = 3, degrees = c(1, 1, 1),
                  method = "L", hessian = FALSE, itermax = 80, seed = 1)
  expect_s3_class(fit, "gbtm_fit_trajer")
  expect_equal(fit$model, "LOGIT")
  expect_valid_fit(fit, 3)
})

test_that("trajeR CNORM (continuous) fit satisfies the engine contract", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  fit <- gbtm_fit(continuous_spec(), engine = "trajeR",
                  n_groups = 4, degrees = rep(1, 4),
                  method = "L", hessian = FALSE, itermax = 120, seed = 1)
  expect_equal(fit$model, "CNORM")
  expect_valid_fit(fit, 4)
})

test_that("group sizes match mean posterior at convergence", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  fit <- gbtm_fit(binary_spec(), engine = "trajeR",
                  n_groups = 3, degrees = c(1, 1, 1), seed = 1, itermax = 80)
  expect_equal(unname(gbtm_group_sizes(fit)),
               unname(colMeans(gbtm_posterior(fit))),
               tolerance = 1e-3)
})

test_that("seed makes fits reproducible", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  f1 <- gbtm_fit(binary_spec(), n_groups = 3, degrees = c(1, 1, 1),
                 seed = 42, itermax = 60)
  f2 <- gbtm_fit(binary_spec(), n_groups = 3, degrees = c(1, 1, 1),
                 seed = 42, itermax = 60)
  expect_equal(gbtm_bic(f1), gbtm_bic(f2))
})

test_that("invalid arguments are rejected before fitting", {
  spec <- binary_spec()
  expect_error(gbtm_fit(spec, n_groups = 3, degrees = c(1, 1)), "length n_groups")
  expect_error(gbtm_fit(spec, n_groups = 2, degrees = c(1, -1)), "non-negative")
  expect_error(gbtm_fit(spec, n_groups = 2, degrees = c(1, 1), method = "XYZ"),
               "not supported")
  expect_error(gbtm_fit("not a spec", n_groups = 2, degrees = c(1, 1)),
               "must be a gbtm_spec")
})

test_that("engine capability advertising is correct", {
  expect_true("binomial" %in% gbtm_engine_families("trajeR"))
  expect_true("gaussian" %in% gbtm_engine_families("trajeR"))
  expect_setequal(gbtm_engine_methods("trajeR"), c("L", "EM", "EMIRLS"))
})

test_that("engine rejects an unsupported family", {
  # No engine currently lacks a family among the synthetic ones, so check the
  # guard directly with a spec whose family the engine table would reject.
  spec <- binary_spec()
  spec$family <- "gamma"  # not in gbtm_engine_families()
  expect_error(gbtm_fit(spec, n_groups = 2, degrees = c(1, 1)),
               "does not support family")
})
