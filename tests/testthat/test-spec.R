# Tests for gbtm_spec(): construction and validation.

make_binary <- function() {
  data("sim_binary", package = "gbtmkit", envir = environment())
  sim_binary
}

test_that("valid binary spec is constructed with the right structure", {
  spec <- gbtm_spec(
    make_binary(),
    outcomes = paste0("y", 1:10),
    time     = paste0("t", 1:10),
    id       = "id",
    family   = "binomial"
  )
  expect_s3_class(spec, "gbtm_spec")
  expect_equal(spec$family, "binomial")
  expect_equal(spec$n_occasions, 10L)
  expect_equal(spec$n_subjects, 1500L)
  expect_equal(dim(.spec_Y(spec)), c(1500L, 10L))
  expect_equal(dim(.spec_A(spec)), c(1500L, 10L))
  expect_equal(.spec_ids(spec), make_binary()$id)
})

test_that("continuous spec accepts censoring bounds and ssigma", {
  data("sim_continuous", package = "gbtmkit", envir = environment())
  spec <- gbtm_spec(
    sim_continuous,
    outcomes = paste0("y", 1:10),
    time     = paste0("t", 1:10),
    id       = "id",
    family   = "gaussian",
    ymin     = 0, ymax = 60, ssigma = TRUE
  )
  expect_equal(spec$family, "gaussian")
  expect_true(spec$ssigma)
  expect_equal(spec$ymin, 0)
})

test_that("id defaults to row numbers when NULL", {
  spec <- gbtm_spec(make_binary(), c("y1", "y2"), c("t1", "t2"))
  expect_null(spec$id)
  expect_equal(.spec_ids(spec), seq_len(1500L))
})

test_that("missing columns are reported clearly", {
  expect_error(
    gbtm_spec(make_binary(), c("y1", "nope"), c("t1", "t2")),
    "not found in data: nope"
  )
  expect_error(
    gbtm_spec(make_binary(), c("y1", "y2"), c("t1", "missingtime")),
    "not found in data: missingtime"
  )
})

test_that("outcomes and time must match in length and be >= 2", {
  expect_error(
    gbtm_spec(make_binary(), c("y1", "y2", "y3"), c("t1", "t2")),
    "same length"
  )
  expect_error(
    gbtm_spec(make_binary(), "y1", "t1"),
    "At least two occasions"
  )
})

test_that("duplicate ids are rejected", {
  d <- make_binary()
  d$id <- 1L  # all identical
  expect_error(
    gbtm_spec(d, c("y1", "y2"), c("t1", "t2"), id = "id"),
    "duplicate values"
  )
})

test_that("binomial family enforces 0/1 outcomes", {
  d <- make_binary()
  d$y1 <- d$y1 + 0.5  # non-binary
  expect_error(
    gbtm_spec(d, c("y1", "y2"), c("t1", "t2"), family = "binomial"),
    "coded 0/1"
  )
})

test_that("unknown family is rejected", {
  expect_error(
    gbtm_spec(make_binary(), c("y1", "y2"), c("t1", "t2"), family = "weibull")
  )
})

test_that("matrix input requires column names", {
  m <- matrix(c(0, 1, 0, 1), 2, 2)
  expect_error(gbtm_spec(m, c("y1", "y2"), c("t1", "t2")), "column names")
})

test_that("print method returns the spec invisibly", {
  spec <- gbtm_spec(make_binary(), c("y1", "y2"), c("t1", "t2"),
                    id = "id", family = "binomial")
  expect_output(print(spec), "<gbtm_spec>")
  expect_invisible(print(spec))
})
