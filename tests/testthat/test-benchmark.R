# Tests for benchmark_engines(). Structural checks run on a subsample so the
# real-fit test stays quick.

small_spec <- function() {
  data("sim_binary", package = "gbtmkit", envir = environment())
  gbtm_spec(sim_binary[1:300, ], paste0("y", 1:10), paste0("t", 1:10),
            id = "id", family = "binomial")
}

test_that("benchmark_engines validates its input", {
  expect_error(benchmark_engines("not a spec", n_groups = 2,
                                 degrees = c(1, 1)),
               "must be a gbtm_spec")
})

test_that("benchmark_engines times each engine and reports diagnostics", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  skip_if_not_installed("flexmix")
  skip_if_not_installed("lcmm")
  b <- benchmark_engines(small_spec(), n_groups = 2, degrees = c(1, 1),
                         method = "L", itermax = 80, seed = 1)
  expect_s3_class(b, "gbtm_benchmark")
  expect_setequal(b$engine, gbtm_engines())
  expect_true(all(b$ok))
  expect_true(all(b$seconds > 0))
  expect_true(all(is.finite(b$bic)))
  expect_true(all(b$entropy >= 0 & b$entropy <= 1))
  expect_true(all(b$groups_effective >= 1))
  expect_output(print(b), "comparable only within an engine")
})

test_that("uniform-degree engines are skipped for mixed degrees, not dropped", {
  skip_on_cran()
  skip_if_not_installed("trajeR")
  b <- benchmark_engines(small_spec(), n_groups = 2, degrees = c(1, 2),
                         engines = gbtm_engines(),
                         method = "L", itermax = 80, seed = 1)
  expect_setequal(b$engine, gbtm_engines())
  uni <- b$engine[!vapply(b$engine, gbtm_engine_per_group_degrees, logical(1))]
  expect_true(all(!b$ok[b$engine %in% uni]))
  expect_true(all(b$note[b$engine %in% uni] == "requires uniform degrees"))
  expect_true(b$ok[b$engine == "trajeR"])
})

test_that("an unsupported family is recorded as a skip", {
  spec <- small_spec()
  spec$family <- "beta"   # lcmm/flexmix do not offer beta
  b <- benchmark_engines(spec, n_groups = 2, degrees = c(1, 1),
                         engines = c("flexmix", "lcmm"))
  expect_true(all(!b$ok))
  expect_true(all(grepl("not supported", b$note)))
})
