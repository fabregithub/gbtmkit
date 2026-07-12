# =============================================================================
# simulate-data.R
# -----------------------------------------------------------------------------
# Generates *synthetic* group-based trajectory datasets with KNOWN ground-truth
# group membership, for gbtmkit's regression/unit-test fixtures. Because the true
# number of groups and their shapes are known, tests can assert that the pipeline
# recovers them.
#
# The data is entirely synthetic and domain-neutral: generic id, two covariates
# (x1, x2), outcomes over ten occasions (y1..y10), time columns (t1..t10), and a
# `true_group` label the pipeline never sees. No real data of any kind is used.
#
#   simulate_binary()      -> binary outcomes     (for LOGIT / family="binomial")
#   simulate_continuous()  -> continuous outcomes (for CNORM / family="gaussian")
# =============================================================================

# Four canonical trajectory shapes shared by both generators, on the linear
# predictor scale (log-odds for binary, mean for continuous). Time is rescaled
# to s in [-1, 1] so the same coefficients work for any `times` grid:
#   G1 linear rising  : degree 1, low early  -> high late
#   G2 cubic peak     : degree 3, rises to a mid-study peak, then declines
#   G3 cubic trough   : degree 3, declines to a mid-study trough, then recovers
#   G4 linear falling : degree 1, high early -> low late
.traj_shapes <- function(times, sep) {
  s <- (times - mean(times)) / (diff(range(times)) / 2)   # rescaled to [-1, 1]
  list(
    G1_linear_rising  = sep * (-0.6 + 1.0 * s),
    G2_cubic_peak     = sep * ( 0.5 + 0.3 * s - 0.9 * s^2 - 0.6 * s^3),
    G3_cubic_trough   = sep * (-0.5 - 0.3 * s + 0.9 * s^2 + 0.6 * s^3),
    G4_linear_falling = sep * ( 0.6 - 1.0 * s)
  )
}

.sim_common <- function(n, seed, props, times) {
  stopifnot(abs(sum(props) - 1) < 1e-8)
  set.seed(seed)
  K   <- length(props)
  grp <- sample.int(K, size = n, replace = TRUE, prob = props)
  # Covariates: present but do NOT drive the outcome (keeps ground truth clean).
  x1  <- round(rnorm(n, 0, 1), 4)
  x2  <- round(rlnorm(n, log(6), 0.5), 2)
  list(K = K, grp = grp, x1 = x1, x2 = x2, nt = length(times))
}

.assemble <- function(base, Y, times) {
  n  <- length(base$grp); nt <- base$nt
  out <- data.frame(
    id  = seq_len(n),
    x1  = base$x1,
    x2  = base$x2,
    Y,
    matrix(rep(times, each = n), n, nt),
    true_group = base$grp
  )
  colnames(out) <- c("id", "x1", "x2",
                     paste0("y", seq_len(nt)),
                     paste0("t", seq_len(nt)),
                     "true_group")
  out
}

#' Simulate binary group-based trajectory data
#'
#' @param n,seed,props,times See details in the file header.
#' @param sep Group separation on the log-odds scale. Binary data is
#'   low-information and the shapes cross mid-study, so separation must stay
#'   generous: below ~3 the single-start fit lands in local optima (empty or
#'   merged groups) and BIC under-selects the number of groups.
simulate_binary <- function(n     = 1500,
                            seed  = 12345,
                            props = c(0.20, 0.20, 0.20, 0.40),
                            times = 1:10,
                            sep   = 3) {
  base   <- .sim_common(n, seed, props, times)
  shapes <- .traj_shapes(times, sep)[seq_len(base$K)]
  Y <- matrix(NA_integer_, n, base$nt)
  for (k in seq_len(base$K)) {
    idx <- which(base$grp == k)
    p   <- plogis(shapes[[k]])
    for (j in seq_len(base$nt)) Y[idx, j] <- rbinom(length(idx), 1L, p[j])
  }
  .assemble(base, Y, times)
}

#' Simulate continuous group-based trajectory data
#'
#' @param n,seed,props,times See details in the file header.
#' @param sep   Group separation on the outcome scale. Kept generous relative to
#'   `noise`: with tighter separation the single-start CNORM fit can land in a
#'   local optimum (BIC then under-selects the number of groups) -- a known GBTM
#'   pitfall that motivates multi-start initialization in the pipeline itself.
#' @param noise Within-group residual standard deviation.
#' @param center Mean added to all groups (shifts the outcome to a positive,
#'   BMI-like range; the shapes themselves are unaffected).
simulate_continuous <- function(n      = 1200,
                                seed   = 12345,
                                props  = c(0.25, 0.25, 0.25, 0.25),
                                times  = 1:10,
                                sep    = 6,
                                noise  = 1.5,
                                center = 24) {
  base   <- .sim_common(n, seed, props, times)
  shapes <- .traj_shapes(times, sep)[seq_len(base$K)]
  Y <- matrix(NA_real_, n, base$nt)
  for (k in seq_len(base$K)) {
    idx <- which(base$grp == k)
    mu  <- center + shapes[[k]]
    for (j in seq_len(base$nt)) {
      Y[idx, j] <- round(rnorm(length(idx), mu[j], noise), 2)
    }
  }
  .assemble(base, Y, times)
}

# --- Build the shipped package datasets --------------------------------------
# Run from the package root:  Rscript data-raw/simulate-data.R
# Writes data/sim_binary.rda and data/sim_continuous.rda (documented in R/data.R).
if (sys.nframe() == 0L) {                        # only when run as a script
  report <- function(sim, label, ycols) {
    cat(sprintf("\n== %s ==\n  dim: %s\n", label, paste(dim(sim), collapse = " x ")))
    cat("  true group sizes:\n"); print(table(sim$true_group))
    agg <- aggregate(sim[, ycols], by = list(group = sim$true_group), FUN = mean)
    cat("  outcome mean by group x time:\n"); print(round(agg, 2))
  }

  sim_binary     <- simulate_binary()
  sim_continuous <- simulate_continuous()
  report(sim_binary,     "binary",     paste0("y", 1:10))
  report(sim_continuous, "continuous", paste0("y", 1:10))

  usethis::use_data(sim_binary, sim_continuous, overwrite = TRUE)
}
