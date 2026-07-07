# Sanity checks on the shipped synthetic datasets. These also serve as a
# smoke test that the package builds and lazy-loads its data correctly.

test_that("sim_binary has the expected structure", {
  data("sim_binary", package = "gbtmkit")
  expect_s3_class(sim_binary, "data.frame")
  expect_identical(
    names(sim_binary),
    c("id", "x1", "x2", "y1", "y2", "y3", "y4", "t1", "t2", "t3", "t4", "true_group")
  )
  expect_equal(nrow(sim_binary), 1500L)
  # binary outcomes
  ys <- unlist(sim_binary[, c("y1", "y2", "y3", "y4")])
  expect_true(all(ys %in% c(0L, 1L)))
  # four planted groups
  expect_setequal(sim_binary$true_group, 1:4)
})

test_that("sim_continuous has the expected structure", {
  data("sim_continuous", package = "gbtmkit")
  expect_s3_class(sim_continuous, "data.frame")
  expect_equal(nrow(sim_continuous), 1200L)
  # continuous outcomes (not all integer 0/1)
  expect_type(sim_continuous$y1, "double")
  expect_setequal(sim_continuous$true_group, 1:4)
})
