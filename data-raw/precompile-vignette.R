# =============================================================================
# precompile-vignette.R
# -----------------------------------------------------------------------------
# The getting-started vignette runs many real model fits (~20 min), so it is
# precomputed: the executable source lives in vignettes/*.Rmd.orig, and this
# script knits it into the static vignettes/*.Rmd that ships with the package.
# CI, pkgdown, and R CMD check only pandoc-format the static file -- no code
# runs at build time.
#
# Run from the package root after any change to the .orig source (or when the
# package behavior it demonstrates changes):
#
#   Rscript data-raw/precompile-vignette.R
#
# then commit the regenerated .Rmd and the getting-started-*.png figures together with the
# .orig. All engines (trajeR, flexmix, lcmm) and ggplot2 must be installed so
# every chunk actually runs.
# =============================================================================

for (pkg in c("trajeR", "flexmix", "lcmm", "ggplot2", "knitr")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("precompiling the vignette requires '", pkg, "' to be installed.")
  }
}

devtools::load_all(quiet = TRUE)

# Knit from vignettes/ so figure paths come out relative (figure/...).
owd <- setwd("vignettes")
on.exit(setwd(owd), add = TRUE)

knitr::knit("getting-started.Rmd.orig", output = "getting-started.Rmd")

# The static vignette must not execute anything at build time: fail loudly if
# any chunk survived with output-producing options intact.
static <- readLines("getting-started.Rmd")
if (any(grepl("^```\\{r", static))) {
  stop("precompiled vignette still contains executable chunks.")
}
message("OK: vignettes/getting-started.Rmd is fully static (",
        length(static), " lines).")
