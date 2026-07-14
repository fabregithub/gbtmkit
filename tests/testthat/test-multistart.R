# Tests for multi-start initialisation (n_starts). The flagship regression is
# the known trajeR CNORM local optimum: linear shapes with method "L" on
# sim_continuous collapse to 3 effective groups from the default start; the
# k-means starts recover the 4-group optimum (the same one EM finds).

cont_spec <- function() {
  data("sim_continuous", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_continuous, paste0("y", 1:10), paste0("t", 1:10),
            id = "id", family = "gaussian")
}

bin_spec <- function() {
  data("sim_binary", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_binary, paste0("y", 1:10), paste0("t", 1:10),
            id = "id", family = "binomial")
}

test_that("n_starts is validated", {
  expect_error(gbtm_fit(cont_spec(), n_groups = 2, degrees = c(1, 1),
                        n_starts = 0),
               "positive integer")
  expect_error(gbtm_fit(cont_spec(), n_groups = 2, degrees = c(1, 1),
                        n_starts = c(2, 3)),
               "positive integer")
})

test_that("trajeR multi-start escapes the known CNORM local optimum", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  spec <- cont_spec()
  single <- gbtm_fit(spec, n_groups = 4, degrees = rep(1, 4), engine = "trajeR", method = "L",
                     itermax = 300, seed = 1)
  multi  <- gbtm_fit(spec, n_groups = 4, degrees = rep(1, 4), engine = "trajeR", method = "L",
                     itermax = 300, seed = 1, n_starts = 5)
  # default start collapses to 3 effective groups; multi-start finds all 4
  expect_lt(length(unique(gbtm_assign(single)$group)), 4)
  expect_equal(length(unique(gbtm_assign(multi)$group)), 4)
  expect_lt(gbtm_bic(multi), gbtm_bic(single) - 50)
  # bookkeeping on the fit object
  expect_equal(multi$n_starts, 5L)
  expect_length(multi$start_bics, 5)
  expect_equal(gbtm_bic(multi), min(multi$start_bics, na.rm = TRUE))
})

test_that("trajeR multi-start never does worse than the default start", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  spec <- bin_spec()
  single <- gbtm_fit(spec, n_groups = 3, degrees = rep(2, 3), engine = "trajeR", method = "L",
                     itermax = 200, seed = 1)
  multi  <- gbtm_fit(spec, n_groups = 3, degrees = rep(2, 3), engine = "trajeR", method = "L",
                     itermax = 200, seed = 1, n_starts = 3)
  expect_lte(gbtm_bic(multi), gbtm_bic(single) + 1e-6)
})

test_that("trajeR multi-start warns and falls back for unsupported families", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  # plausible count data: scaled continuous outcomes, rounded. The x3 scaling
  # makes the counts overdispersed (var > mean), which trajeR's POIS
  # initialisation requires (its qgamma-based init NaNs otherwise).
  data("sim_continuous", package = "gbtmkit", envir = environment())
  d <- sim_continuous
  d[paste0("y", 1:10)] <- lapply(d[paste0("y", 1:10)],
                                 function(x) as.integer(round(3 * x)))
  spec <- gbtm_spec(d, paste0("y", 1:10), paste0("t", 1:10),
                    id = "id", family = "poisson")
  expect_warning(
    fit <- gbtm_fit(spec, n_groups = 2, degrees = c(1, 1), engine = "trajeR", method = "L",
                    itermax = 60, seed = 1, n_starts = 2),
    "multi-start is not implemented"
  )
  expect_equal(fit$n_starts, 1L)
})

test_that("flexmix multi-start keeps the best of the seeded runs", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  spec <- bin_spec()
  single <- gbtm_fit(spec, engine = "flexmix", n_groups = 3,
                     degrees = rep(2, 3), seed = 1)
  multi  <- gbtm_fit(spec, engine = "flexmix", n_groups = 3,
                     degrees = rep(2, 3), seed = 1, n_starts = 3)
  # start 1 reuses `seed`, so the best-of can only match or improve it
  expect_lte(gbtm_bic(multi), gbtm_bic(single) + 1e-6)
  expect_length(multi$start_bics, 3)
})

test_that("lcmm multi-start runs through gridsearch and satisfies the contract", {
  skip_on_cran()
  skip_if_not_installed("lcmm")
  fit <- gbtm_fit(cont_spec(), engine = "lcmm", n_groups = 3,
                  degrees = rep(2, 3), seed = 1, n_starts = 2, itermax = 60)
  expect_valid_fit(fit, 3)
  expect_equal(fit$n_starts, 2L)
})

test_that("print shows the number of starts", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  fit <- gbtm_fit(bin_spec(), n_groups = 2, degrees = c(1, 1), engine = "trajeR", method = "L",
                  itermax = 60, seed = 1, n_starts = 2)
  expect_output(print(fit), "starts  : 2")
})
