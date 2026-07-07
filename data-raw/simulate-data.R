# =============================================================================
# simulate-data.R
# -----------------------------------------------------------------------------
# Generates *synthetic* group-based trajectory datasets with KNOWN ground-truth
# group membership, for gbtmkit's regression/unit-test fixtures. Because the true
# number of groups and their shapes are known, tests can assert that the pipeline
# recovers them.
#
# The data is entirely synthetic and domain-neutral: generic id, two covariates
# (x1, x2), outcomes over four occasions (y1..y4), time columns (t1..t4), and a
# `true_group` label the pipeline never sees. No real data of any kind is used.
#
#   simulate_binary()      -> binary outcomes     (for LOGIT / family="binomial")
#   simulate_continuous()  -> continuous outcomes (for CNORM / family="gaussian")
# =============================================================================

# Four canonical trajectory shapes shared by both generators, on the linear
# predictor scale (log-odds for binary, mean for continuous):
#   G1 stable-high : flat, high
#   G2 falling     : high early -> low late
#   G3 rising      : low early  -> high late
#   G4 stable-low  : flat, low
.traj_shapes <- function(times, sep) {
  ct <- times - mean(times)                      # centered time
  list(
    G1_stable_high =  sep        + 0.00 * ct,
    G2_falling     =  sep * 0.9  - sep * 0.9 * ct,
    G3_rising      = -sep * 0.9  + sep * 0.9 * ct,
    G4_stable_low  = -sep        + 0.00 * ct
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
#' @param sep Group separation on the log-odds scale. Wide by default because
#'   binary data over few occasions is low-information; too little separation
#'   makes BIC under-select the number of groups.
simulate_binary <- function(n     = 1500,
                            seed  = 12345,
                            props = c(0.20, 0.20, 0.20, 0.40),
                            times = 1:4,
                            sep   = 2.5) {
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
                                times  = 1:4,
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

# --- Build & cache the standard test fixtures --------------------------------
if (sys.nframe() == 0L) {                        # only when run as a script
  out_dir <- file.path("tests", "testthat", "fixtures")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  report <- function(sim, label, ycols) {
    cat(sprintf("\n== %s ==\n  dim: %s\n", label, paste(dim(sim), collapse = " x ")))
    cat("  true group sizes:\n"); print(table(sim$true_group))
    agg <- aggregate(sim[, ycols], by = list(group = sim$true_group), FUN = mean)
    cat("  outcome mean by group x time:\n"); print(round(agg, 2))
  }

  simB <- simulate_binary()
  saveRDS(simB, file.path(out_dir, "sim_binary.rds"))
  report(simB, "binary", c("y1", "y2", "y3", "y4"))

  simC <- simulate_continuous()
  saveRDS(simC, file.path(out_dir, "sim_continuous.rds"))
  report(simC, "continuous", c("y1", "y2", "y3", "y4"))

  cat("\nSaved fixtures to", out_dir, "\n")
}
