# Tests for stage 4 and the orchestrator: fit_gbtm(), gbtm_predict(),
# plot_trajectories(), run_gbtm_pipeline().

bspec <- function() {
  data("sim_binary", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_binary, c("y1", "y2", "y3", "y4"),
            c("t1", "t2", "t3", "t4"), id = "id", family = "binomial")
}

test_that("fit_gbtm computes the Hessian by default", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  fit <- fit_gbtm(bspec(), n_groups = 3, degrees = c(1, 1, 1),
                  method = "L", itermax = 80, seed = 1)
  expect_s3_class(fit, "gbtm_fit")
  expect_true(fit$hessian)
})

test_that("gbtm_predict returns fitted trajectories on the outcome scale", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  fit <- fit_gbtm(bspec(), n_groups = 3, degrees = c(1, 2, 1),
                  method = "L", hessian = FALSE, itermax = 80, seed = 1)
  pred <- gbtm_predict(fit, n = 25)
  expect_setequal(names(pred), c("group", "time", "fitted"))
  expect_equal(length(unique(pred$group)), 3)
  expect_equal(nrow(pred), 3 * 25)
  # binomial -> probabilities in [0, 1]
  expect_true(all(pred$fitted >= 0 & pred$fitted <= 1))
  # fitted time span matches the data
  expect_equal(range(pred$time), c(1, 4))
})

test_that("gbtm_predict accepts explicit times", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  fit <- fit_gbtm(bspec(), n_groups = 2, degrees = c(1, 1),
                  method = "L", hessian = FALSE, itermax = 60, seed = 1)
  pred <- gbtm_predict(fit, times = c(1, 2, 3, 4))
  expect_equal(sort(unique(pred$time)), c(1, 2, 3, 4))
})

test_that("gbtm_predict warns when a fit has a degenerate empty group", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  data("sim_continuous", package = "gbtmkit", envir = environment())
  cspec <- gbtm_spec(sim_continuous, c("y1", "y2", "y3", "y4"),
                     c("t1", "t2", "t3", "t4"), id = "id", family = "gaussian")
  # method "L" lands in a degenerate solution (one empty group) on this data
  dfit <- fit_gbtm(cspec, n_groups = 4, degrees = rep(1, 4),
                   method = "L", seed = 1)
  expect_warning(gbtm_predict(dfit), "no assigned members")
})

test_that("plot_trajectories returns a ggplot", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  skip_if_not_installed("ggplot2")
  fit <- fit_gbtm(bspec(), n_groups = 3, degrees = c(1, 1, 1),
                  method = "L", hessian = FALSE, itermax = 60, seed = 1)
  p <- plot_trajectories(fit, observed = TRUE)
  expect_s3_class(p, "ggplot")
})

test_that("run_gbtm_pipeline runs end-to-end and returns a full result", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  # Reduced settings keep this fast: method fixed (skip stage 1), narrow
  # candidate range, degree search fixed at 1 (single shape).
  # criteria-passing is not asserted here (see the fallback test); a single
  # linear shape may fall back to lowest-BIC, so tolerate that warning.
  res <- suppressWarnings(run_gbtm_pipeline(
    bspec(), candidates = 3:4, degree = 1, method = "L",
    min_degree = 1, max_degree = 1, max_passes = 1,
    itermax = 80, seed = 1, verbose = FALSE
  ))
  expect_s3_class(res, "gbtm_result")
  expect_null(res$algorithm_selection)          # method was supplied
  expect_equal(res$n_groups, 4L)                # planted 4 groups
  expect_length(res$chosen_degrees, 4)
  expect_true(res$final_fit$hessian)            # final fit has SEs
  expect_equal(nrow(res$assignment), 1500)
  expect_true(all(res$assignment$group %in% 1:4))
  expect_s3_class(res$diagnostics, "gbtm_diagnostics")
  expect_output(print(res), "<gbtm_result>")
  expect_output(summary(res), "pipeline result")
})

test_that("pipeline falls back to lowest-BIC shape when no shape passes", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  # Impossible OCC threshold -> nothing passes -> fallback + warning + flag.
  expect_warning(
    res <- run_gbtm_pipeline(
      bspec(), candidates = 4, degree = 1, method = "L",
      min_degree = 1, max_degree = 1, occ_min = 1e6,
      itermax = 80, seed = 1, verbose = FALSE
    ),
    "No shape met the GRoLTS criteria"
  )
  expect_false(res$criteria_met)
  expect_length(res$chosen_degrees, 4)
})
