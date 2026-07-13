# =============================================================================
# benchmark-scale.R
# -----------------------------------------------------------------------------
# Maintainer script: benchmark the engines at increasing data scale (the
# dev/DESIGN.md sec. 11 target is ~80k subjects), using the same generators as
# the shipped fixtures. Results are recorded in NOTES.md; re-run after engine
# or adapter changes that could shift the picture.
#
#   Rscript data-raw/benchmark-scale.R [max_n]
#
# max_n defaults to 20000; pass 80000 for the full run (trajeR and the lcmm
# thresholds link get slow -- expect a long wait at that scale).
# =============================================================================

devtools::load_all(quiet = TRUE)
source("data-raw/simulate-data.R")

max_n <- if (length(commandArgs(trailingOnly = TRUE))) {
  as.integer(commandArgs(trailingOnly = TRUE)[1])
} else 20000L
sizes <- c(2000L, 20000L, 80000L)
sizes <- sizes[sizes <= max_n]

run <- function(n, family) {
  sim  <- if (family == "binomial") simulate_binary(n = n) else
    simulate_continuous(n = n)
  spec <- gbtm_spec(sim, paste0("y", 1:10), paste0("t", 1:10),
                    id = "id", family = family)
  b <- benchmark_engines(spec, n_groups = 4, degrees = rep(2, 4),
                         method = "L", itermax = 200, seed = 1)
  b$n <- n
  b$family <- family
  b
}

res <- list()
for (n in sizes) {
  for (fam in c("gaussian", "binomial")) {
    cat(sprintf("\n=== n = %d, family = %s ===\n", n, fam))
    r <- suppressWarnings(run(n, fam))
    print(r)
    res[[length(res) + 1L]] <- r
  }
}

out <- do.call(rbind, res)
cat("\n\n=== summary (seconds) ===\n")
print(stats::reshape(out[, c("n", "family", "engine", "seconds")],
                     idvar = c("n", "family"), timevar = "engine",
                     direction = "wide"), row.names = FALSE)
