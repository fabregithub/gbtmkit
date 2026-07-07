# =============================================================================
# simulate-wheeze.R
# -----------------------------------------------------------------------------
# Generates a *synthetic* binary-wheeze dataset that mimics the structure of the
# private cohort data (which cannot be published), with KNOWN ground-truth group
# membership. Used to build regression/unit-test fixtures for gbtmkit: because
# the true number of groups and their trajectory shapes are known, tests can
# assert that the pipeline recovers them.
#
# Structure mirrors the original: an id, two covariates, four binary wheeze
# outcomes over four occasions, four time columns -- plus `true_group` for
# validation (the pipeline never sees this column).
#
# This file ships NO real cohort data.
# =============================================================================

#' Simulate group-based binary trajectory data (wheeze look-alike)
#'
#' @param n        Number of subjects.
#' @param seed     RNG seed for reproducibility.
#' @param props    Mixing proportions of the latent groups (sum to 1).
#' @param times    Numeric occasions (columns T1..Tk).
#' @return A data.frame with columns:
#'   NO, cot, PB, w1..w4 (binary), T1..T4 (time), true_group.
simulate_wheeze <- function(n     = 1500,
                            seed  = 12345,
                            props = c(0.20, 0.20, 0.20, 0.40),
                            times = 1:4) {
  stopifnot(abs(sum(props) - 1) < 1e-8)
  set.seed(seed)

  K  <- length(props)
  nt <- length(times)

  # --- Ground-truth latent trajectories, on the log-odds (logit) scale --------
  # Each group is a distinct polynomial in time, giving a distinct wheeze-
  # probability shape. These are the shapes the pipeline should recover.
  #   G1 persistent : high throughout          (flat, high)
  #   G2 transient  : high early, then falls    (declining)
  #   G3 late-onset : low early, then rises      (rising)
  #   G4 low/never  : low throughout            (flat, low)
  # Separation `sep` is deliberately wide so BIC reliably recovers K groups from
  # only four binary occasions (binary data is low-information per subject;
  # weaker separation makes BIC under-select — verified during fixture design).
  ct  <- times - mean(times)                     # centered time
  sep <- 2.5
  logit_traj <- list(
    G1_persistent =  sep        + 0.00 * ct,      # flat high
    G2_transient  =  sep * 0.9  - sep * 0.9 * ct, # high early -> low late
    G3_lateonset  = -sep * 0.9  + sep * 0.9 * ct, # low early  -> high late
    G4_low        = -sep        + 0.00 * ct       # flat low
  )[seq_len(K)]

  # --- Assign each subject to a latent group ---------------------------------
  grp <- sample.int(K, size = n, replace = TRUE, prob = props)

  # --- Covariates (present but do NOT drive the outcome, keeping truth clean) -
  cot <- round(rnorm(n, 0, 1), 4)                # cotinine-like, standardized
  PB  <- round(rlnorm(n, log(6), 0.5), 2)        # positive, skewed like the original

  # --- Draw binary outcomes from the group-specific probabilities -------------
  W <- matrix(NA_integer_, n, nt)
  for (k in seq_len(K)) {
    idx <- which(grp == k)
    p   <- plogis(logit_traj[[k]])               # length nt probabilities
    for (j in seq_len(nt)) {
      W[idx, j] <- rbinom(length(idx), 1L, p[j])
    }
  }

  out <- data.frame(
    NO         = seq_len(n),
    cot        = cot,
    PB         = PB,
    W,                                           # w columns named below
    matrix(rep(times, each = n), n, nt),         # time columns
    true_group = grp
  )
  colnames(out) <- c("NO", "cot", "PB",
                     paste0("w", seq_len(nt)),
                     paste0("T", seq_len(nt)),
                     "true_group")
  out
}

# --- Build & cache the standard test fixture (small n for fast tests) ---------
if (sys.nframe() == 0L) {                        # only when run as a script
  sim <- simulate_wheeze(n = 1500, seed = 12345)

  cat("Simulated fixture:\n"); cat("  dim:", dim(sim), "\n")
  cat("  true group sizes:\n"); print(table(sim$true_group))
  cat("  empirical wheeze prevalence by group x time:\n")
  agg <- aggregate(sim[, c("w1", "w2", "w3", "w4")],
                   by = list(group = sim$true_group), FUN = mean)
  print(round(agg, 2))

  out_dir <- file.path("tests", "testthat", "fixtures")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(sim, file.path(out_dir, "sim_wheeze.rds"))
  cat("\nSaved:", file.path(out_dir, "sim_wheeze.rds"), "\n")
}
