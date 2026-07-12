# Shared engine-adapter conformance check: every engine's fit must satisfy this
# contract for the pipeline's accessors to work.
expect_valid_fit <- function(fit, n_groups) {
  expect_s3_class(fit, "gbtm_fit")
  expect_equal(gbtm_n_groups(fit), n_groups)
  expect_length(gbtm_degrees(fit), n_groups)

  expect_true(is.finite(gbtm_bic(fit)))
  expect_true(is.finite(gbtm_aic(fit)))
  expect_true(is.finite(gbtm_loglik(fit)))

  post <- gbtm_posterior(fit)
  expect_equal(ncol(post), n_groups)
  expect_equal(nrow(post), fit$spec$n_subjects)
  # rows are probability distributions
  expect_equal(unname(rowSums(post)), rep(1, nrow(post)), tolerance = 1e-6)
  expect_true(all(post >= -1e-8 & post <= 1 + 1e-8))

  sizes <- gbtm_group_sizes(fit)
  expect_length(sizes, n_groups)
  expect_equal(sum(sizes), 1, tolerance = 1e-6)
  expect_true(all(sizes >= 0))
}
