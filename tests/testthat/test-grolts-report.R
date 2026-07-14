# Tests for grolts_report(). The structural tests run on a hand-built
# gbtm_result (no fitting), so they run everywhere; one real end-to-end test
# runs the actual pipeline locally.

fake_result <- function(covariates = NULL, criteria_met = TRUE,
                        candidates = 2:4) {
  data("sim_binary", package = "gbtmkit", envir = environment())
  d <- sim_binary[1:100, ]
  spec <- gbtm_spec(d, paste0("y", 1:10), paste0("t", 1:10), id = "id",
                    family = "binomial", covariates = covariates)
  K <- 3L
  groups <- data.frame(
    group = 1:K, n_assigned = c(30L, 40L, 30L),
    prop_assigned = c(0.3, 0.4, 0.3), prop_model = c(0.3, 0.4, 0.3),
    mismatch = rep(0, K), appa = c(0.9, 0.85, 0.88), occ = c(10, 9, 11))
  diagnostics <- structure(
    list(groups = groups, entropy = 0.82, n = 100L, n_groups = K,
         bic = 1234.5, aic = 1200.1, loglik = -590.0,
         degrees = c(1L, 2L, 1L)),
    class = "gbtm_diagnostics")
  shapes <- structure(
    list(table = data.frame(deg1 = c(1, 1), deg2 = c(1, 2), deg3 = c(1, 1),
                            bic = c(1250, 1234.5), ok = TRUE),
         best = c(1L, 2L, 1L), n_fits = 2L, budget_hit = FALSE,
         strategy = "stepwise", n_groups = K),
    class = "gbtm_shapes")
  criteria <- structure(
    data.frame(deg1 = 1, deg2 = 2, deg3 = 1, bic = 1234.5),
    thresholds = c(pms_min = 0.05, appa_min = 0.7, occ_min = 5),
    class = c("gbtm_criteria", "data.frame"))
  grp_sel <- structure(
    list(type = "n_groups",
         table = data.frame(n_groups = candidates,
                            bic = seq_along(candidates) + 1000, ok = TRUE),
         best = K, fits = list()),
    class = "gbtm_selection")
  final_fit <- structure(
    list(engine = "trajeR", family = "binomial", method = "L",
         n_groups = K, degrees = c(1L, 2L, 1L), hessian = TRUE,
         itermax = 100L, n_starts = 3L, spec = spec),
    class = "gbtm_fit")
  structure(
    list(spec = spec, engine = "trajeR", method = "L",
         algorithm_selection = NULL, group_selection = grp_sel,
         n_groups = K, shapes = shapes, criteria = criteria,
         chosen_degrees = c(1L, 2L, 1L), criteria_met = criteria_met,
         final_fit = final_fit, assignment = NULL,
         diagnostics = diagnostics, call = quote(run_gbtm_pipeline())),
    class = "gbtm_result")
}

test_that("grolts_report validates its input", {
  expect_error(grolts_report(list()), "gbtm_result")
})

test_that("grolts_report covers all 16 checklist items with statuses", {
  rep <- grolts_report(fake_result())
  expect_s3_class(rep, "gbtm_grolts_report")
  expect_equal(rep$item,
               c("1", "2", "3a", "3b", "3c", "4", "5", "6a", "6b", "7", "8",
                 "9", "10", "11", "12", "13", "14", "15", "16"))
  expect_true(all(rep$status %in% c("auto", "partial", "analyst")))
  expect_true(all(nzchar(rep$detail)))
})

test_that("auto-filled details reflect the result", {
  rep <- grolts_report(fake_result())
  detail <- function(it) rep$detail[rep$item == it]
  expect_match(detail("1"), "10 occasions")
  expect_match(detail("2"), "within-wave variance is 0")
  expect_match(detail("5"), "gbtmkit")
  expect_match(detail("7"), "2 polynomial shapes")
  expect_match(detail("7"), "1, 2, 1")
  expect_match(detail("8"), "No covariates")
  expect_match(detail("9"), "best of 3")
  expect_match(detail("9"), "100")
  expect_match(detail("10"), "2\\.\\.4")
  expect_match(detail("11"), "NOT among the candidates")
  expect_match(detail("12"), "30, 40, 30")
  expect_match(detail("13"), "0.820")
})

test_that("covariates, one-class candidates, and failed criteria change the report", {
  rep <- grolts_report(fake_result(covariates = c("x1", "x2"),
                                   criteria_met = FALSE, candidates = 1:4))
  detail <- function(it) rep$detail[rep$item == it]
  expect_match(detail("8"), "x1, x2")
  expect_false(grepl("NOT among", detail("11")))
  expect_match(detail("10"), "NO shape met the criteria")
})

test_that("the markdown export writes all items", {
  f <- tempfile(fileext = ".md")
  on.exit(unlink(f), add = TRUE)
  grolts_report(fake_result(), file = f)
  md <- readLines(f)
  expect_equal(sum(grepl("^## Item ", md)), 19)
  expect_match(md[1], "GRoLTS")
})

test_that("print groups items by status", {
  rep <- grolts_report(fake_result())
  out <- capture.output(print(rep))
  expect_true(any(grepl("auto-filled from the pipeline result", out)))
  expect_true(any(grepl("analyst must supply", out)))
  expect_true(any(grepl("\\[13\\] Entropy", out)))
})

test_that("grolts_report works on a real pipeline result", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  data("sim_binary", package = "gbtmkit", envir = environment())
  spec <- gbtm_spec(sim_binary[1:300, ], paste0("y", 1:10),
                    paste0("t", 1:10), id = "id", family = "binomial")
  res <- suppressWarnings(run_gbtm_pipeline(
    spec, candidates = 2:3, degree = 1, engine = "trajeR", method = "L",
    min_degree = 1, max_degree = 1, itermax = 80, seed = 1,
    verbose = FALSE))
  rep <- grolts_report(res)
  expect_equal(nrow(rep), 19)
  expect_true(all(nzchar(rep$detail)))
  f <- tempfile(fileext = ".md")
  on.exit(unlink(f), add = TRUE)
  grolts_report(res, file = f)
  expect_true(file.exists(f))
})
