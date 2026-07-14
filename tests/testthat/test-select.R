# Tests for stages 1-2: select_algorithm() and select_n_groups().

bspec <- function() {
  data("sim_binary", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_binary, paste0("y", 1:10),
            paste0("t", 1:10), id = "id", family = "binomial")
}

test_that("select_algorithm compares methods and picks a finite-BIC winner", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  sel <- select_algorithm(bspec(), engine = "trajeR", n_groups = 3,
                          degrees = c(1, 1, 1), itermax = 80, seed = 1)
  expect_s3_class(sel, "gbtm_selection")
  expect_equal(sel$type, "algorithm")
  expect_setequal(sel$table$method, c("L", "EM", "EMIRLS"))
  expect_true(sel$best %in% c("L", "EM", "EMIRLS"))
  # best row really is the minimum BIC among the ones that worked
  ok <- sel$table[sel$table$ok, ]
  expect_equal(sel$best, ok$method[which.min(ok$bic)])
  expect_s3_class(sel$best_fit, "gbtm_fit")
})

test_that("select_n_groups sweeps candidates and recovers the planted 4", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  # degree 2: with curved (cubic) planted shapes, linear-only selection
  # under-selects -- quadratic is enough for BIC to find the planted 4.
  sel <- select_n_groups(bspec(), candidates = 2:5, degree = 2,
                         engine = "trajeR", method = "L", itermax = 300, seed = 1)
  expect_equal(sel$type, "n_groups")
  expect_equal(sort(sel$table$n_groups), 2:5)
  # sim_binary has 4 planted groups -> BIC should choose 4
  expect_equal(sel$best, 4L)
  expect_equal(gbtm_n_groups(sel$best_fit), 4L)
})

test_that("select_n_groups accepts a per-candidate degrees list", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  sel <- select_n_groups(bspec(), candidates = c(2, 3),
                         degrees = list(c(1, 1), c(1, 1, 1)),
                         engine = "trajeR", method = "L", itermax = 60, seed = 1)
  expect_equal(sel$table$degrees, c("1,1", "1,1,1"))
})

test_that("by = 'aic' selects on AIC", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  sel <- select_n_groups(bspec(), candidates = 2:4, degree = 1,
                         engine = "trajeR", method = "L", by = "aic", itermax = 80, seed = 1)
  ok <- sel$table[sel$table$ok, ]
  expect_equal(sel$best, ok$n_groups[which.min(ok$aic)])
})

test_that("failed fits are recorded (not dropped) with a warning", {
  # Stub gbtm_fit so every fit errors; selection must still return a table with
  # ok = FALSE rows and NA criteria, and warn -- verifying we don't silently
  # drop failures the way the original script did.
  local_mocked_bindings(
    gbtm_fit = function(...) stop("boom")
  )
  ws <- character()
  sel <- withCallingHandlers(
    select_n_groups(bspec(), candidates = 2:3, degree = 1),
    warning = function(w) {
      ws <<- c(ws, conditionMessage(w)); invokeRestart("muffleWarning")
    }
  )
  expect_true(any(grepl("did not yield a finite criterion", ws)))
  expect_true(any(grepl("selection is undefined", ws)))
  expect_true(all(!sel$table$ok))
  expect_true(all(is.na(sel$table$bic)))
  expect_true(is.na(sel$best))
})

test_that("input validation fires", {
  expect_error(select_n_groups(bspec(), candidates = c(2, -1)),
               "positive integers")
  expect_error(
    select_n_groups(bspec(), candidates = 2:3, degrees = list(c(1, 1))),
    "one entry per candidate"
  )
})
