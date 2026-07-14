# Tests for the native "gbtmkit" engine: analytic-gradient correctness
# (against numDeriv), the engine contract, cross-engine agreement with trajeR,
# ground-truth recovery, covariates, and robustness features.

bin_spec <- function(n = NULL) {
  data("sim_binary", package = "gbtmkit", envir = environment())
  d <- if (is.null(n)) sim_binary else sim_binary[seq_len(n), ]
  gbtm_spec(d, paste0("y", 1:10), paste0("t", 1:10), id = "id",
            family = "binomial")
}

cont_spec <- function() {
  data("sim_continuous", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_continuous, paste0("y", 1:10), paste0("t", 1:10),
            id = "id", family = "gaussian")
}

# -- analytic gradients vs numDeriv -------------------------------------------

test_that("analytic gradients match numDeriv across families and features", {
  skip_if_not_installed("numDeriv")
  set.seed(3)
  d <- data.frame(id = 1:80, x1 = rnorm(80),
                  x2 = factor(sample(c("a", "b"), 80, TRUE)))
  d[paste0("y", 1:6)] <- as.data.frame(matrix(rnorm(480, 20, 4), 80, 6))
  d[paste0("t", 1:6)] <- as.data.frame(matrix(rep(1:6, each = 80), 80, 6))
  d[paste0("w", 1:6)] <- as.data.frame(matrix(rbinom(480, 1, .5), 80, 6))
  d$y2[c(3, 17)] <- NA                              # NA outcomes too

  check <- function(spec, degrees, par) {
    ctx <- gbtmkit:::.ngb_ctx(spec, degrees)
    ga <- gbtmkit:::.ngb_grad(par, ctx)
    gn <- numDeriv::grad(gbtmkit:::.ngb_loglik, par, ctx = ctx)
    max(abs(ga - gn) / (abs(gn) + 1e-6))
  }

  # gaussian + membership covariates + tcov, mixed degrees
  spec <- gbtm_spec(d, paste0("y", 1:6), paste0("t", 1:6), id = "id",
                    family = "gaussian", covariates = c("x1", "x2"),
                    tcov = list(w = paste0("w", 1:6)))
  # theta: (K-1)*(1+px) = 1*(1+2) = 3; beta: (1+1+1) + (2+1+1) = 7; sigma: 2
  set.seed(1); par <- c(rnorm(3, 0, .3), rnorm(3 + 4, 10, 2), log(c(3, 4)))
  expect_lt(check(spec, c(1L, 2L), par), 1e-4)

  # gaussian shared sigma
  spec_s <- gbtm_spec(d, paste0("y", 1:6), paste0("t", 1:6), id = "id",
                      family = "gaussian", ssigma = TRUE)
  set.seed(2); par <- c(rnorm(1, 0, .3), rnorm(2 + 2, 20, 3), log(4))
  expect_lt(check(spec_s, c(1L, 1L), par), 1e-4)

  # binomial
  db <- d; db[paste0("y", 1:6)] <- lapply(d[paste0("w", 1:6)], identity)
  spec_b <- gbtm_spec(db, paste0("y", 1:6), paste0("t", 1:6), id = "id",
                      family = "binomial", covariates = "x1")
  # theta: 1*(1+1) = 2; beta: (1+1) + (2+1) = 5
  set.seed(4); par <- c(rnorm(2, 0, .3), rnorm(2 + 3, 0, .5))
  expect_lt(check(spec_b, c(1L, 2L), par), 1e-4)

  # poisson
  dp <- d; dp[paste0("y", 1:6)] <- lapply(d[paste0("y", 1:6)],
                                          function(x) as.integer(pmax(round(x), 0)))
  spec_p <- gbtm_spec(dp, paste0("y", 1:6), paste0("t", 1:6), id = "id",
                      family = "poisson")
  set.seed(5); par <- c(rnorm(1, 0, .3), rnorm(2 + 2, 1, .2))
  expect_lt(check(spec_p, c(1L, 1L), par), 1e-4)

  # censored normal (both tails present in the data)
  dc <- d
  dc[paste0("y", 1:6)] <- lapply(d[paste0("y", 1:6)],
                                 function(x) pmin(pmax(x, 16), 24))
  spec_c <- gbtm_spec(dc, paste0("y", 1:6), paste0("t", 1:6), id = "id",
                      family = "gaussian", ymin = 16, ymax = 24)
  set.seed(6); par <- c(rnorm(1, 0, .3), rnorm(2 + 2, 20, 2), log(c(3, 4)))
  expect_lt(check(spec_c, c(1L, 1L), par), 1e-4)
})

# -- engine contract ----------------------------------------------------------

test_that("native binomial fit satisfies the engine contract", {
  skip_on_cran()
  fit <- gbtm_fit(bin_spec(), engine = "gbtmkit", n_groups = 4,
                  degrees = rep(2, 4), itermax = 300, seed = 1)
  expect_s3_class(fit, "gbtm_fit_gbtmkit")
  expect_valid_fit(fit, 4)
})

test_that("native gaussian fit recovers the planted groups perfectly", {
  skip_on_cran()
  fit <- gbtm_fit(cont_spec(), engine = "gbtmkit", n_groups = 4,
                  degrees = rep(3, 4), itermax = 400, seed = 1, n_starts = 3)
  expect_valid_fit(fit, 4)
  tab <- table(cont_spec()$data$true_group, gbtm_assign(fit)$group)
  expect_equal(sum(apply(tab, 1, max)), 1200L)
})

test_that("native poisson fit works", {
  skip_on_cran()
  data("sim_continuous", package = "gbtmkit", envir = environment())
  d <- sim_continuous
  d[paste0("y", 1:10)] <- lapply(d[paste0("y", 1:10)],
                                 function(x) as.integer(round(x)))
  spec <- gbtm_spec(d, paste0("y", 1:10), paste0("t", 1:10), id = "id",
                    family = "poisson")
  fit <- gbtm_fit(spec, engine = "gbtmkit", n_groups = 2, degrees = c(1, 1),
                  itermax = 200, seed = 1)
  expect_valid_fit(fit, 2)
})

# -- cross-engine agreement ---------------------------------------------------

test_that("native optimum matches or beats trajeR's on the same model", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  spec <- bin_spec()
  fn <- gbtm_fit(spec, engine = "gbtmkit", n_groups = 4, degrees = rep(2, 4),
                 itermax = 400, seed = 1, n_starts = 3)
  ft <- gbtm_fit(spec, engine = "trajeR", n_groups = 4, degrees = rep(2, 4),
                 method = "L", itermax = 400, seed = 1)
  # same likelihood convention; the native optimiser must not be worse
  expect_gte(gbtm_loglik(fn), gbtm_loglik(ft) - 0.5)
  # near-identical classification (allow label permutation)
  an <- gbtm_assign(fn)$group
  at <- gbtm_assign(ft)$group
  tab <- table(factor(an, 1:4), factor(at, 1:4))
  perms <- as.matrix(expand.grid(1:4, 1:4, 1:4, 1:4))
  perms <- perms[apply(perms, 1, function(r) length(unique(r)) == 4), ]
  agree <- max(apply(perms, 1, function(p) sum(tab[cbind(1:4, p)]))) / length(an)
  expect_gt(agree, 0.95)
})

test_that("native tcov estimates agree with trajeR's", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  set.seed(11)
  n <- 600; nt <- 8; times <- 1:nt
  grp <- sample(1:2, n, TRUE)
  mu  <- rbind(12 + 1.0 * times, 30 - 1.0 * times)
  W   <- matrix(rbinom(n * nt, 1, 0.4), n, nt)
  delta <- c(-3, 3)
  d <- data.frame(id = seq_len(n))
  d[paste0("y", 1:nt)] <- as.data.frame(t(sapply(seq_len(n), function(i)
    rnorm(nt, mu[grp[i], ] + delta[grp[i]] * W[i, ], 1.5))))
  d[paste0("t", 1:nt)] <- as.data.frame(matrix(rep(times, each = n), n, nt))
  d[paste0("w", 1:nt)] <- as.data.frame(W)
  spec <- gbtm_spec(d, paste0("y", 1:nt), paste0("t", 1:nt), id = "id",
                    family = "gaussian", tcov = list(w = paste0("w", 1:nt)))
  fit <- gbtm_fit(spec, engine = "gbtmkit", n_groups = 2, degrees = c(1, 1),
                  itermax = 300, seed = 1)
  # each group's tcov coefficient is the last element of its beta block
  deltas <- sort(vapply(fit$params$beta, function(b) b[length(b)], numeric(1)))
  expect_equal(deltas, c(-3, 3), tolerance = 0.15)
})

# -- robustness features -------------------------------------------------------

test_that("NA outcomes are handled (masked, not dropped)", {
  skip_on_cran()
  data("sim_continuous", package = "gbtmkit", envir = environment())
  d <- sim_continuous
  set.seed(9)
  for (col in sample(paste0("y", 1:10), 6)) {
    idx <- sample(nrow(d), 60)
    d[idx, col] <- NA
  }
  spec <- gbtm_spec(d, paste0("y", 1:10), paste0("t", 1:10), id = "id",
                    family = "gaussian")
  fit <- gbtm_fit(spec, engine = "gbtmkit", n_groups = 4, degrees = rep(2, 4),
                  itermax = 300, seed = 1, n_starts = 2)
  expect_valid_fit(fit, 4)
  tab <- table(d$true_group, gbtm_assign(fit)$group)
  expect_gt(sum(apply(tab, 1, max)) / nrow(d), 0.95)
})

test_that("hessian = TRUE yields a usable vcov", {
  skip_on_cran()
  fit <- gbtm_fit(bin_spec(300), engine = "gbtmkit", n_groups = 2,
                  degrees = c(1, 1), itermax = 200, seed = 1, hessian = TRUE)
  expect_false(is.null(fit$vcov))
  expect_true(all(diag(fit$vcov) > 0))
})

test_that("validation and capability advertising", {
  expect_true("gbtmkit" %in% gbtm_engines())
  expect_setequal(gbtm_engine_families("gbtmkit"),
                  c("binomial", "gaussian", "poisson"))
  expect_true(is.na(gbtm_engine_methods("gbtmkit")))
  expect_true(gbtm_engine_per_group_degrees("gbtmkit"))

  expect_error(gbtm_fit(bin_spec(50), engine = "gbtmkit", n_groups = 2,
                        degrees = c(1, 1), method = "L"),
               "single optimiser")
})

test_that("censored normal recovers latent parameters and matches trajeR", {
  skip_on_cran()
  # 2 groups, latent normal clipped at [12, 28] (~13% of cells censored)
  set.seed(21)
  n <- 800; nt <- 8; times <- 1:nt
  grp <- sample(1:2, n, TRUE)
  mu <- rbind(10 + 1.5 * times, 30 - 1.5 * times)
  Y  <- pmin(pmax(t(sapply(seq_len(n), function(i)
    rnorm(nt, mu[grp[i], ], 2))), 12), 28)
  d <- data.frame(id = seq_len(n))
  d[paste0("y", 1:nt)] <- as.data.frame(Y)
  d[paste0("t", 1:nt)] <- as.data.frame(matrix(rep(times, each = n), n, nt))
  spec <- gbtm_spec(d, paste0("y", 1:nt), paste0("t", 1:nt), id = "id",
                    family = "gaussian", ymin = 12, ymax = 28)
  fit <- gbtm_fit(spec, engine = "gbtmkit", n_groups = 2, degrees = c(1, 1),
                  itermax = 400, seed = 1)
  expect_valid_fit(fit, 2)
  # Tobit correction recovers the LATENT trajectory parameters
  b <- fit$params$beta[order(vapply(fit$params$beta, `[`, numeric(1), 1))]
  expect_equal(unlist(b), c(10, 1.5, 30, -1.5), tolerance = 0.05,
               ignore_attr = TRUE)
  expect_equal(unname(exp(fit$params$log_sigma)), c(2, 2), tolerance = 0.05)

  # same likelihood convention as trajeR CNORM with explicit bounds
  skip_if_not_installed("trajeR")
  ft <- gbtm_fit(spec, engine = "trajeR", n_groups = 2, degrees = c(1, 1),
                 method = "L", itermax = 400, seed = 1)
  expect_equal(gbtm_loglik(fit), gbtm_loglik(ft), tolerance = 1e-4)
})

test_that("multi-start bookkeeping and print", {
  skip_on_cran()
  fit <- gbtm_fit(bin_spec(300), engine = "gbtmkit", n_groups = 2,
                  degrees = c(1, 1), itermax = 200, seed = 1, n_starts = 3)
  expect_equal(fit$n_starts, 3L)
  expect_length(fit$start_bics, 3)
  expect_equal(gbtm_bic(fit), min(fit$start_bics, na.rm = TRUE))
  expect_output(print(fit), "engine=gbtmkit")
})

# -- end-to-end pipeline -------------------------------------------------------

test_that("the full pipeline runs on the native engine and recovers 4 groups", {
  skip_on_cran()
  res <- suppressWarnings(run_gbtm_pipeline(
    bin_spec(), engine = "gbtmkit", candidates = 2:5, degree = 2,
    max_degree = 3, itermax = 300, seed = 1, verbose = FALSE))
  expect_equal(res$n_groups, 4L)
  expect_s3_class(res$diagnostics, "gbtm_diagnostics")
  expect_true(all(gbtm_assign(res$final_fit)$group %in% 1:4))
})
