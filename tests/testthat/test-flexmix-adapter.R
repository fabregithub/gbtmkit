# Tests for the flexmix adapter and its engine-agnostic accessors.
# flexmix is a Suggests dependency, so these skip when it is unavailable.
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

test_that("flexmix binomial fit satisfies the engine contract", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  fit <- gbtm_fit(binary_spec(), engine = "flexmix",
                  n_groups = 4, degrees = rep(3, 4), seed = 1)
  expect_s3_class(fit, "gbtm_fit_flexmix")
  expect_valid_fit(fit, 4)
})

test_that("flexmix gaussian fit satisfies the contract and recovers the groups", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  spec <- continuous_spec()
  fit <- gbtm_fit(spec, engine = "flexmix",
                  n_groups = 4, degrees = rep(3, 4), seed = 1)
  expect_valid_fit(fit, 4)
  # the planted continuous groups are cleanly separated: assignment must match
  # the ground truth up to label permutation
  a <- gbtm_assign(fit)
  tab <- table(spec$data$true_group, a$group)
  expect_equal(sum(apply(tab, 1, max)), spec$n_subjects)
})

test_that("group sizes match mean posterior at convergence", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  fit <- gbtm_fit(binary_spec(), engine = "flexmix",
                  n_groups = 3, degrees = rep(2, 3), seed = 1)
  expect_equal(unname(gbtm_group_sizes(fit)),
               unname(colMeans(gbtm_posterior(fit))),
               tolerance = 1e-3)
})

test_that("gbtm_predict returns fitted trajectories on the outcome scale", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  fit <- gbtm_fit(binary_spec(), engine = "flexmix",
                  n_groups = 3, degrees = rep(2, 3), seed = 1)
  pred <- gbtm_predict(fit, n = 25)
  expect_setequal(names(pred), c("group", "time", "fitted"))
  expect_equal(length(unique(pred$group)), 3)
  expect_equal(nrow(pred), 3 * 25)
  # binomial -> probabilities in [0, 1]
  expect_true(all(pred$fitted >= 0 & pred$fitted <= 1))
  # fitted time span matches the data
  expect_equal(range(pred$time), c(1, 10))
})

test_that("seed makes fits reproducible", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  f1 <- gbtm_fit(binary_spec(), engine = "flexmix",
                 n_groups = 3, degrees = rep(1, 3), seed = 42)
  f2 <- gbtm_fit(binary_spec(), engine = "flexmix",
                 n_groups = 3, degrees = rep(1, 3), seed = 42)
  expect_equal(gbtm_bic(f1), gbtm_bic(f2))
})

test_that("non-uniform degrees are rejected with a clear message", {
  skip_if_not_installed("flexmix")
  expect_error(
    gbtm_fit(binary_spec(), engine = "flexmix",
             n_groups = 4, degrees = c(1, 3, 3, 1)),
    "must be uniform"
  )
})

test_that("a supplied method is rejected (flexmix is EM-only)", {
  skip_if_not_installed("flexmix")
  expect_error(
    gbtm_fit(binary_spec(), engine = "flexmix",
             n_groups = 2, degrees = c(1, 1), method = "L"),
    "single optimiser"
  )
})

test_that("engine capability advertising is correct", {
  expect_true("flexmix" %in% gbtm_engines())
  expect_setequal(gbtm_engine_families("flexmix"),
                  c("binomial", "gaussian", "poisson"))
  expect_true(is.na(gbtm_engine_methods("flexmix")))
  expect_false(gbtm_engine_per_group_degrees("flexmix"))
  expect_true(gbtm_engine_per_group_degrees("trajeR"))
})

test_that("engine rejects an unsupported family", {
  spec <- binary_spec()
  spec$family <- "beta"  # trajeR-only family
  expect_error(gbtm_fit(spec, engine = "flexmix", n_groups = 2,
                        degrees = c(1, 1)),
               "does not support family")
})

test_that("evaluate_shapes sweeps uniform shapes for flexmix", {
  # Mocked evaluator (see test-evaluate-shapes.R): counts fits without fitting.
  seen <- list()
  local_mocked_bindings(
    .shape_fit_diag = function(spec, engine, n_groups, degrees, method,
                               hessian, itermax, seed) {
      seen[[length(seen) + 1L]] <<- degrees
      list(bic = 100 + degrees[1], ok = TRUE,
           fit = structure(list(n_groups = n_groups, degrees = degrees),
                           class = "gbtm_fit"),
           row = data.frame(matrix(degrees, nrow = 1,
                                   dimnames = list(NULL, paste0("deg", seq_len(n_groups)))),
                            n_groups = n_groups, bic = 100 + degrees[1],
                            aic = NA, loglik = NA, entropy = NA,
                            min_pms = 1, min_appa = 1, min_occ = 10,
                            max_abs_mismatch = 0, ok = TRUE,
                            check.names = FALSE),
           degrees = degrees)
    }
  )
  data("sim_binary", package = "gbtmkit", envir = environment())
  spec <- gbtm_spec(sim_binary, paste0("y", 1:10), paste0("t", 1:10),
                    id = "id", family = "binomial")
  sh <- evaluate_shapes(spec, n_groups = 4, engine = "flexmix",
                        min_degree = 1, max_degree = 3, verbose = FALSE)
  # one fit per uniform degree, nothing else
  expect_equal(sh$n_fits, 3L)
  expect_true(all(vapply(seen, function(d) length(unique(d)) == 1L, logical(1))))
  expect_equal(sh$best, rep(1L, 4))    # lowest mocked BIC at degree 1
})
