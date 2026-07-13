# Tests that parallel execution (future.apply under a future::plan()) gives
# results identical to sequential. multicore (fork) is used so the tests also
# work under devtools::load_all(); it is unavailable on Windows and in some
# GUIs, so guard with supportsMulticore().

with_plan <- function(workers, code) {
  oplan <- future::plan(future::multicore, workers = workers)
  on.exit(future::plan(oplan), add = TRUE)
  force(code)
}

small_bin <- function() {
  data("sim_binary", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_binary[1:300, ], paste0("y", 1:10), paste0("t", 1:10),
            id = "id", family = "binomial")
}

test_that("trajeR multi-start is identical under a parallel plan", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  skip_if_not_installed("future.apply")
  skip_if_not(future::supportsMulticore())
  seq_fit <- gbtm_fit(small_bin(), n_groups = 2, degrees = c(1, 1),
                      method = "L", itermax = 100, seed = 1, n_starts = 3)
  par_fit <- with_plan(3, gbtm_fit(small_bin(), n_groups = 2,
                                   degrees = c(1, 1), method = "L",
                                   itermax = 100, seed = 1, n_starts = 3))
  expect_equal(gbtm_bic(par_fit), gbtm_bic(seq_fit))
  expect_equal(par_fit$start_bics, seq_fit$start_bics)
})

test_that("flexmix multi-start is identical under a parallel plan", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  skip_if_not_installed("future.apply")
  skip_if_not(future::supportsMulticore())
  seq_fit <- gbtm_fit(small_bin(), engine = "flexmix", n_groups = 2,
                      degrees = c(1, 1), seed = 1, n_starts = 3)
  par_fit <- with_plan(3, gbtm_fit(small_bin(), engine = "flexmix",
                                   n_groups = 2, degrees = c(1, 1),
                                   seed = 1, n_starts = 3))
  expect_equal(gbtm_bic(par_fit), gbtm_bic(seq_fit))
  expect_equal(par_fit$start_bics, seq_fit$start_bics)
})

test_that("select_n_groups is identical under a parallel plan", {
  skip_on_cran()
  skip_if_not_installed("flexmix")
  skip_if_not_installed("future.apply")
  skip_if_not(future::supportsMulticore())
  seq_sel <- select_n_groups(small_bin(), engine = "flexmix",
                             candidates = 2:3, degree = 1, seed = 1)
  par_sel <- with_plan(2, select_n_groups(small_bin(), engine = "flexmix",
                                          candidates = 2:3, degree = 1,
                                          seed = 1))
  expect_equal(par_sel$table, seq_sel$table)
  expect_equal(par_sel$best, seq_sel$best)
})

test_that("failed fits are still recorded and warned about under a parallel plan", {
  skip_if_not_installed("future.apply")
  skip_if_not(future::supportsMulticore())
  local_mocked_bindings(gbtm_fit = function(...) stop("boom"))
  ws <- character()
  sel <- with_plan(2, withCallingHandlers(
    select_n_groups(small_bin(), candidates = 2:3, degree = 1),
    warning = function(w) {
      ws <<- c(ws, conditionMessage(w)); invokeRestart("muffleWarning")
    }))
  expect_true(any(grepl("did not yield a finite criterion", ws)))
  expect_true(all(!sel$table$ok))
  expect_true(all(grepl("boom", ws[1:2])))
})
