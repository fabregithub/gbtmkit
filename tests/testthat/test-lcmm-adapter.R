# Tests for the lcmm adapter and its engine-agnostic accessors.
# lcmm is a Suggests dependency, so these skip when it is unavailable.
# The shared conformance check (expect_valid_fit) is in helper-conformance.R.

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

test_that("lcmm gaussian (hlme) fit satisfies the contract and recovers the groups", {
  skip_on_cran()
  skip_if_not_installed("lcmm")
  spec <- continuous_spec()
  fit <- gbtm_fit(spec, engine = "lcmm",
                  n_groups = 4, degrees = rep(3, 4), seed = 1)
  expect_s3_class(fit, "gbtm_fit_lcmm")
  expect_valid_fit(fit, 4)
  # the planted continuous groups are cleanly separated: assignment must match
  # the ground truth up to label permutation
  a <- gbtm_assign(fit)
  tab <- table(spec$data$true_group, a$group)
  expect_equal(sum(apply(tab, 1, max)), spec$n_subjects)
})

test_that("lcmm binomial (thresholds link) fit satisfies the engine contract", {
  skip_on_cran()
  skip_if_not_installed("lcmm")
  fit <- gbtm_fit(binary_spec(), engine = "lcmm",
                  n_groups = 4, degrees = rep(3, 4), seed = 1)
  expect_equal(fit$model, "lcmm-thresholds")
  expect_valid_fit(fit, 4)
})

test_that("group sizes match mean posterior at convergence", {
  skip_on_cran()
  skip_if_not_installed("lcmm")
  fit <- gbtm_fit(continuous_spec(), engine = "lcmm",
                  n_groups = 3, degrees = rep(2, 3), seed = 1)
  expect_equal(unname(gbtm_group_sizes(fit)),
               unname(colMeans(gbtm_posterior(fit))),
               tolerance = 1e-3)
})

test_that("gbtm_predict returns fitted trajectories on the outcome scale", {
  skip_on_cran()
  skip_if_not_installed("lcmm")
  fit <- gbtm_fit(continuous_spec(), engine = "lcmm",
                  n_groups = 3, degrees = rep(2, 3), seed = 1)
  pred <- gbtm_predict(fit, n = 25)
  expect_setequal(names(pred), c("group", "time", "fitted"))
  expect_equal(length(unique(pred$group)), 3)
  expect_equal(nrow(pred), 3 * 25)
  # gaussian -> outcome scale spans the (BMI-like) data range
  expect_true(all(pred$fitted > 5 & pred$fitted < 45))
  # fitted time span matches the data
  expect_equal(range(pred$time), c(1, 10))
})

test_that("non-uniform degrees are rejected with a clear message", {
  skip_if_not_installed("lcmm")
  expect_error(
    gbtm_fit(continuous_spec(), engine = "lcmm",
             n_groups = 4, degrees = c(1, 3, 3, 1)),
    "must be uniform"
  )
})

test_that("a supplied method is rejected (lcmm is Marquardt-only)", {
  skip_if_not_installed("lcmm")
  expect_error(
    gbtm_fit(continuous_spec(), engine = "lcmm",
             n_groups = 2, degrees = c(1, 1), method = "EM"),
    "single optimizer"
  )
})

test_that("engine capability advertising is correct", {
  expect_true("lcmm" %in% gbtm_engines())
  expect_setequal(gbtm_engine_families("lcmm"), c("binomial", "gaussian"))
  expect_true(is.na(gbtm_engine_methods("lcmm")))
  expect_false(gbtm_engine_per_group_degrees("lcmm"))
})

test_that("engine rejects an unsupported family", {
  spec <- continuous_spec()
  spec$family <- "poisson"  # not offered by the lcmm adapter
  expect_error(gbtm_fit(spec, engine = "lcmm", n_groups = 2,
                        degrees = c(1, 1)),
               "does not support family")
})
