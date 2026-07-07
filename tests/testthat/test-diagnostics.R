# Tests for the engine-neutral GRoLTS diagnostics. The core math is tested
# against hand-built toy posteriors where the answers are known exactly.

test_that("perfectly separated posterior gives ideal diagnostics", {
  # 3 subjects certain in group 1, 2 subjects certain in group 2.
  post <- rbind(c(1, 0), c(1, 0), c(1, 0), c(0, 1), c(0, 1))
  d <- gbtmkit:::.diagnostics(post, group_sizes = c(0.6, 0.4))

  expect_equal(d$entropy, 1)                         # perfect separation
  expect_equal(d$groups$appa, c(1, 1))               # certain assignment
  expect_equal(d$groups$prop_assigned, c(0.6, 0.4))  # 3/5, 2/5
  expect_true(all(is.infinite(d$groups$occ)))        # appa = 1 -> Inf odds
  expect_equal(d$groups$mismatch, c(0, 0))           # pi == assigned here
})

test_that("uniform posterior gives zero entropy", {
  post <- matrix(0.25, nrow = 20, ncol = 4)
  d <- gbtmkit:::.diagnostics(post, group_sizes = rep(0.25, 4))
  expect_equal(d$entropy, 0)
})

test_that("moderate posterior matches hand-computed APPA / OCC / entropy", {
  post <- rbind(c(0.9, 0.1), c(0.8, 0.2), c(0.3, 0.7), c(0.1, 0.9))
  # assignment: subjects 1,2 -> group 1 ; subjects 3,4 -> group 2
  pi <- colMeans(post)                 # c(0.525, 0.475)
  d <- gbtmkit:::.diagnostics(post, group_sizes = pi)

  expect_equal(d$groups$prop_assigned, c(0.5, 0.5))
  # APPA = mean posterior of the assigned group
  expect_equal(d$groups$appa, c(mean(c(0.9, 0.8)), mean(c(0.7, 0.9))))  # 0.85, 0.80
  # OCC = (appa/(1-appa)) / (pi/(1-pi))
  expect_equal(d$groups$appa[1], 0.85)
  expect_equal(d$groups$occ[1],
               (0.85 / 0.15) / (0.525 / 0.475), tolerance = 1e-6)
  expect_equal(d$groups$occ[2],
               (0.80 / 0.20) / (0.475 / 0.525), tolerance = 1e-6)
  # entropy hand value
  N <- nrow(post); K <- ncol(post)
  ent_i <- -rowSums(ifelse(post > 0, post * log(post), 0))
  expect_equal(d$entropy, 1 - sum(ent_i) / (N * log(K)))
  expect_true(d$entropy > 0 && d$entropy < 1)
})

test_that("mismatch is model minus assigned proportion", {
  post <- rbind(c(0.9, 0.1), c(0.9, 0.1), c(0.4, 0.6))
  d <- gbtmkit:::.diagnostics(post, group_sizes = c(0.7, 0.3))
  # assigned: 2 in g1, 1 in g2 -> prop_assigned = c(2/3, 1/3)
  expect_equal(d$groups$mismatch, c(0.7, 0.3) - c(2/3, 1/3))
})

test_that("APPA is NA for an empty group and length checks fire", {
  # group 2 never wins the argmax
  post <- rbind(c(0.9, 0.1), c(0.8, 0.2))
  d <- gbtmkit:::.diagnostics(post, group_sizes = c(0.85, 0.15))
  expect_true(is.na(d$groups$appa[2]))
  expect_error(gbtmkit:::.diagnostics(post, group_sizes = c(1)),
               "length must equal")
})

test_that("entropy is undefined for a single group", {
  expect_true(is.na(gbtmkit:::.entropy(matrix(1, 5, 1))))
})

# --- on a real fit -----------------------------------------------------------

test_that("diagnostics on a fitted model are coherent", {
  skip_if_not_installed("trajeR")
  data("sim_binary", package = "gbtmkit", envir = environment())
  spec <- gbtm_spec(sim_binary, c("y1", "y2", "y3", "y4"),
                    c("t1", "t2", "t3", "t4"), id = "id", family = "binomial")
  fit <- gbtm_fit(spec, n_groups = 4, degrees = rep(1, 4), seed = 1, itermax = 100)

  d <- gbtm_diagnostics(fit)
  expect_s3_class(d, "gbtm_diagnostics")
  expect_equal(nrow(d$groups), 4)
  expect_equal(sum(d$groups$prop_assigned), 1, tolerance = 1e-8)
  expect_true(d$entropy >= 0 && d$entropy <= 1)
  expect_true(is.finite(d$bic))
  # well-separated synthetic groups -> decent APPA
  expect_true(mean(d$groups$appa, na.rm = TRUE) > 0.7)

  a <- gbtm_assign(fit)
  expect_equal(nrow(a), 1500)
  expect_true(all(a$group %in% 1:4))
  expect_setequal(names(a), c("id", "group", paste0("p", 1:4)))
})
