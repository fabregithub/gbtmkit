# Tests for stage 3: evaluate_shapes() search logic and apply_grolts_criteria().
# The search is exercised with a mocked .shape_fit_diag() giving a known BIC
# surface, so it runs instantly and the optimum is known.

# Fake evaluator: BIC is minimized at degrees == target (default all 2s).
fake_evaluator <- function(target = 2L, pass_criteria = TRUE) {
  function(spec, engine, n_groups, degrees, method, hessian, itermax, seed) {
    tgt <- rep(target, n_groups)
    bic <- 100 + sum((degrees - tgt)^2)
    g <- data.frame(
      group = seq_len(n_groups),
      n_assigned = rep(round(100 / n_groups), n_groups),
      prop_assigned = rep(1 / n_groups, n_groups),
      prop_model = rep(1 / n_groups, n_groups),
      mismatch = rep(0, n_groups),
      appa = rep(if (pass_criteria) 0.9 else 0.5, n_groups),
      occ  = rep(if (pass_criteria) 10 else 1, n_groups)
    )
    d <- structure(list(groups = g, entropy = 0.9, n = 100,
                        n_groups = n_groups, bic = bic, aic = bic - 5,
                        loglik = -bic / 2, degrees = degrees),
                   class = "gbtm_diagnostics")
    list(bic = bic, ok = TRUE, fit = structure(
           list(n_groups = n_groups, degrees = degrees),
           class = c("gbtm_fit_fake", "gbtm_fit")),
         row = gbtmkit:::.diag_to_row(degrees, d, TRUE), degrees = degrees)
  }
}

fake_spec <- function() {
  data("sim_binary", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_binary, paste0("y", 1:10),
            paste0("t", 1:10), id = "id", family = "binomial")
}

test_that(".parse_duration understands seconds and unit strings", {
  expect_equal(gbtmkit:::.parse_duration(120), 120)
  expect_equal(gbtmkit:::.parse_duration("90s"), 90)
  expect_equal(gbtmkit:::.parse_duration("30m"), 1800)
  expect_equal(gbtmkit:::.parse_duration("2h"), 7200)
  expect_error(gbtmkit:::.parse_duration("soon"), "number of seconds")
})

test_that("grid strategy enumerates every shape and finds the optimum", {
  local_mocked_bindings(.shape_fit_diag = fake_evaluator())
  sh <- evaluate_shapes(fake_spec(), n_groups = 2, strategy = "grid",
                        min_degree = 1, max_degree = 3, verbose = FALSE)
  expect_s3_class(sh, "gbtm_shapes")
  expect_equal(sh$n_fits, 9L)                 # 3^2 unique shapes
  expect_equal(sh$best, c(2L, 2L))            # BIC minimized at target
  expect_false(sh$budget_hit)
})

test_that("stepwise strategy converges to the optimum with few fits", {
  local_mocked_bindings(.shape_fit_diag = fake_evaluator())
  sh <- evaluate_shapes(fake_spec(), n_groups = 3, strategy = "stepwise",
                        min_degree = 1, max_degree = 3, verbose = FALSE)
  expect_equal(sh$best, c(2L, 2L, 2L))
  # far fewer than the full grid (4^3 = 64)
  expect_lt(sh$n_fits, 64)
})

test_that("caching prevents refitting the same shape", {
  local_mocked_bindings(.shape_fit_diag = fake_evaluator())
  sh <- evaluate_shapes(fake_spec(), n_groups = 3, strategy = "stepwise",
                        min_degree = 1, max_degree = 3, verbose = FALSE)
  # every table row is a distinct degree combination
  degcols <- paste0("deg", 1:3)
  keys <- apply(sh$table[, degcols], 1, paste, collapse = ",")
  expect_equal(length(keys), length(unique(keys)))
})

test_that("max_fits budget stops the search and flags it", {
  local_mocked_bindings(.shape_fit_diag = fake_evaluator())
  sh <- evaluate_shapes(fake_spec(), n_groups = 3, strategy = "grid",
                        min_degree = 1, max_degree = 3,
                        max_fits = 5, verbose = FALSE)
  expect_equal(sh$n_fits, 5L)
  expect_true(sh$budget_hit)
})

test_that("checkpoint persists results and a rerun resumes", {
  ckpt <- tempfile(fileext = ".rds")
  on.exit(unlink(ckpt), add = TRUE)
  local_mocked_bindings(.shape_fit_diag = fake_evaluator())

  sh1 <- evaluate_shapes(fake_spec(), n_groups = 2, strategy = "grid",
                         min_degree = 1, max_degree = 3,
                         checkpoint = ckpt, verbose = FALSE)
  expect_true(file.exists(ckpt))
  expect_equal(nrow(readRDS(ckpt)), 9L)

  # Rerun: all 9 shapes are already on disk, so no new fits happen.
  sh2 <- evaluate_shapes(fake_spec(), n_groups = 2, strategy = "grid",
                         min_degree = 1, max_degree = 3,
                         checkpoint = ckpt, verbose = FALSE)
  expect_equal(sh2$n_fits, 0L)
  expect_equal(sh2$best, c(2L, 2L))
})

test_that("auto-downshifts a large grid to stepwise under max_fits", {
  local_mocked_bindings(.shape_fit_diag = fake_evaluator())
  expect_message(
    sh <- evaluate_shapes(fake_spec(), n_groups = 4, strategy = "grid",
                          min_degree = 0, max_degree = 3, max_fits = 10,
                          verbose = TRUE),
    "switching to stepwise"
  )
  expect_equal(sh$strategy, "stepwise")
})

# --- apply_grolts_criteria ---------------------------------------------------

make_shape_table <- function() {
  # three shapes: two pass, one fails APPA; different BICs for ordering
  data.frame(
    deg1 = c(1, 2, 3), deg2 = c(1, 2, 3),
    n_groups = 2,
    bic = c(120, 110, 130), aic = c(115, 105, 125),
    loglik = c(-60, -55, -65), entropy = c(0.8, 0.9, 0.7),
    min_pms = c(0.10, 0.20, 0.20),
    min_appa = c(0.75, 0.85, 0.60),   # third fails appa_min
    min_occ = c(6, 8, 7),
    max_abs_mismatch = c(0.02, 0.01, 0.03),
    ok = TRUE
  )
}

test_that("criteria keep only qualifying shapes, ranked by BIC", {
  res <- apply_grolts_criteria(make_shape_table())
  expect_s3_class(res, "gbtm_criteria")
  expect_equal(nrow(res), 2)                 # third fails APPA
  expect_equal(res$bic, c(110, 120))         # ordered ascending
  rec <- grolts_recommended(res)
  expect_equal(rec$bic, 110)
})

test_that("criteria thresholds are configurable", {
  res <- apply_grolts_criteria(make_shape_table(), appa_min = 0.5)
  expect_equal(nrow(res), 3)                  # now the third qualifies too
})

test_that("no qualifying shape yields empty result and NULL recommendation", {
  tab <- make_shape_table(); tab$min_occ <- 1  # all fail OCC
  res <- apply_grolts_criteria(tab)
  expect_equal(nrow(res), 0)
  expect_null(grolts_recommended(res))
})

test_that("criteria errors on a missing required column", {
  tab <- make_shape_table(); tab$min_appa <- NULL
  expect_error(apply_grolts_criteria(tab), "missing column")
})

# --- one real end-to-end -----------------------------------------------------

test_that("evaluate_shapes runs end-to-end on real data", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  sh <- evaluate_shapes(fake_spec(), n_groups = 4, method = "L",
                        strategy = "stepwise", min_degree = 1, max_degree = 2,
                        max_passes = 1, itermax = 80, seed = 1, verbose = FALSE)
  expect_true(sh$n_fits >= 4)
  expect_length(sh$best, 4)
  expect_true(all(c("min_pms", "min_appa", "min_occ") %in% names(sh$table)))
  crit <- apply_grolts_criteria(sh)
  expect_s3_class(crit, "gbtm_criteria")
})
