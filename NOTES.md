# Project notes & history — gbtmkit

Working notes on how this package was built. Not part of the shipped package
(excluded via `.Rbuildignore`); intended as a record for maintainers.

## What this package is

`gbtmkit` generalizes a one-off group-based trajectory modeling (GBTM) analysis
script into a reproducible, **engine-agnostic** R package that follows the
GRoLTS reporting checklist. The estimation engine is pluggable (trajeR now;
flexmix/lcmm designed for) behind a small accessor interface, so the diagnostics
and plotting work the same for any backend, and binary and continuous outcomes
run through one specification.

- Repo: https://github.com/fabregithub/gbtmkit (public, MIT)
- Docs site: https://fabregithub.github.io/gbtmkit/ (pkgdown, auto-deployed)
- Author: Shoji F. Nakayama (ORCID 0000-0001-7772-0389)
- Full design rationale: `dev/DESIGN.md`

## Key decisions

- **Name** `gbtmkit` (confirmed free on CRAN/GitHub/Bioconductor).
- **Engine-agnostic** architecture: one S3 adapter contract; trajeR first.
- **Both outcome types first-class**: binary (LOGIT) and continuous (CNORM).
- **Data is entirely synthetic and domain-neutral.** The real cohort data cannot
  be published and no external published dataset is used, to avoid revealing the
  study domain. Two generated datasets (`sim_binary`, `sim_continuous`) with
  known ground-truth groups ship as package data and drive tests, examples, and
  the vignette.
- **License** MIT.
- **Performance/autonomy** treated as a first-class requirement for the shape
  search (the original was slow on ~80k rows).

## Findings established during the build

- **trajeR `hessian`**: only affects standard errors. Point estimates, BIC, and
  posterior diagnostics are identical with `hessian = FALSE` and ~2.6x faster,
  so the search runs Hessian-off and only the final model is refit with it.
- **CNORM local optima**: continuous fits fall into local optima under tight
  group separation (BIC under-selects). The synthetic continuous fixture uses
  wide separation; multi-start initialization noted as a future improvement.
- **Binary is low-information**: 4 binary occasions cap per-subject
  classification (~0.83) even when BIC recovers the right group count; the
  synthetic binary fixture uses wide separation so recovery is reliable.

## Findings from the data redesign (2026-07: 10 occasions, mixed-degree shapes)

The fixtures were rebuilt to be more realistic: ten occasions, two linear groups
(rising G1, falling G4) and two cubic groups (peak G2, trough G3), with the
shapes crossing mid-study. Lessons:

- **Linear-only group-number selection under-selects on curved data**: with
  cubic planted shapes, `select_n_groups(degree = 1)` picks 3 groups; degree 2
  is needed for BIC to find the planted 4. Tests and the vignette select with
  `degree = 2`.
- **Mixed per-group degrees are fragile in single-start fits**: fixing
  `degrees = c(1, 3, 3, 1)` (the truth) pins each degree to an arbitrary
  initialization slot; with method "L" this lands in local optima (empty or
  merged groups) on both fixtures. Uniform `rep(3, 4)` recovers cleanly, so
  examples use it and per-group degrees are left to the shape search.
- **Binary separation must stay wide even with 10 occasions**: crossing
  trajectories put several groups at similar probabilities mid-study; below
  `sep = 3` (log-odds) the 4-group fit collapses. At `sep = 3` the full
  pipeline recovers 4 groups (0.89 assignment recovery, entropy 0.76).
- **trajeR's EMIRLS** fails numerically ("solve(): solution not found") on the
  10-occasion binary fixture; `select_algorithm()` records it and moves on, as
  designed.

## Findings from multi-start initialization (2026-07-13, `n_starts`)

- **trajeR's default initialization is deterministic** (quantile-based):
  re-running with different seeds gives identical fits, so multi-start must
  supply `paraminit`. Its layout (from source, per Method): first ng entries
  are membership *logits vs group 1* for `"L"` but *probabilities* for
  `"EM"`/`"EMIRLS"`; then per-group trajectory coefficients; then per-group
  residual sd (CNORM; with `ssigma=TRUE` only the first is used).
- **Parameter-space noise is useless; k-means partition starts work.** Random
  jitter of the default init either falls back into the same basin or lands in
  garbage. Partitioning subjects with k-means on their outcome vectors and
  fitting per-cluster polynomial regressions reaches the EM-quality optimum
  with the fast "L" optimizer (CNORM rep(1,4): 52906 vs 53012 default), and
  **rescues mixed per-group degrees**: binary c(1,3,3,1) reaches BIC 17110 vs
  18175 default -- better than any uniform-degree fit (18080).
- **lcmm gridsearch NSE**: `gridsearch()` re-parses the `m` call, so the
  fitting function must be bound under a plain name in the calling frame, and
  the `random()` in the `B = random(minit)` it builds is a *syntactic
  sentinel* -- lcmm detects it from the unevaluated call after evaluation
  fails, so no `random` function may exist in that frame.
- **trajeR's POIS initialization requires overdispersion** (its qgamma-based
  init NaNs when var(Y) <= mean(Y)) -- relevant for tests that fabricate count
  data.

## Precomputed vignette (2026-07-13)

The getting-started vignette runs ~20 min of real fits, which made every CI /
pkgdown build re-run them (~2 h on a GitHub runner). It is now precomputed:

- **Source of truth**: `vignettes/getting-started.Rmd.orig` (executable,
  `.Rbuildignore`d).
- **Shipped file**: `vignettes/getting-started.Rmd` (static: outputs baked in
  and `vignettes/getting-started-*.png` figures beside it, committed to git;
  builds in seconds). A knitr output/message hook in the `.orig` strips
  trajeR's optimizer chatter; `fig.path` is a file prefix because R CMD check
  flags a `vignettes/figure/` directory as a knitr leftover.
- **Regenerate** with `Rscript data-raw/precompile-vignette.R` after editing
  the `.orig` or when demonstrated behavior changes, and commit the `.orig`,
  the regenerated `.Rmd`, and the figures together.
- Bug-fix verification does NOT require re-knitting: tests and direct runs
  verify code; the vignette is refreshed only when its shown outputs matter.

The pkgdown workflow likewise builds with `examples = FALSE` (the reference
examples are real fits, ~50 min on a runner; pages show the code without
executed output). Since the examples are `\donttest`, nothing runs them
automatically anymore -- **run `devtools::run_examples()` locally before a
release** (and after touching any roxygen example).

## Bugs in the original script that the port fixes

- Duplicated, mutually inconsistent PMS filters -> single robust min-across-group
  summary columns in `apply_grolts_criteria()`.
- `test_algo[1:2]` dropping the third algorithm from the BIC comparison.
- Out-of-bounds `test_algo[i]` in the group loop.
- Silently dropped failed fits (`.errorhandling = "remove"`) -> failures are now
  recorded as `NA` with a warning.
- Mis-applied entropy (Shannon of proportions) -> standard normalized
  classification entropy in [0, 1].

## History (chronological)

Built step by step, confirming each stage, with `R CMD check` kept at 0/0/0
throughout.

| Commit | Date | What |
|--------|------|------|
| d79f091 | 2026-07-07 | Design document + `.gitignore`; folder renamed to `gbtmkit`, git init |
| 0c3b17e | 2026-07-07 | Synthetic data simulator + first fixture (BIC recovers planted groups) |
| 0278f9e | 2026-07-07 | Genericize data: domain-neutral binary + continuous fixtures |
| b88165c | 2026-07-07 | Scrub design doc: synthetic-only, remove domain/published-data refs |
| 583d62f | 2026-07-07 | Package skeleton (DESCRIPTION/MIT/NAMESPACE/testthat), data as package data |
| a3a8f2b | 2026-07-07 | `gbtm_spec()` — validated, name-based model specification |
| b028516 | 2026-07-07 | Engine interface + trajeR adapter (LOGIT + CNORM); accessors |
| 68c6386 | 2026-07-07 | Engine-neutral GRoLTS diagnostics + `gbtm_assign()` |
| 4f1e842 | 2026-07-07 | Stages 1-2: `select_algorithm()`, `select_n_groups()` |
| a8e12db | 2026-07-07 | Stage 3: `evaluate_shapes()` (bounded search) + `apply_grolts_criteria()` |
| fca365f | 2026-07-08 | Stage 4 + `run_gbtm_pipeline()` orchestrator; `gbtm_predict()`, `plot_trajectories()` |
| bba8b51 | 2026-07-08 | Getting-started vignette + README |
| 436b139 | 2026-07-08 | GitHub Actions R-CMD-check workflow + NEWS |
| 29516b3 | 2026-07-08 | Set package author; fix NEWS formatting |
| bfe805f | 2026-07-09 | Speed up CI: `skip_on_cran()` on real-fit tests; `checkout@v5` |
| c1cff38 | 2026-07-09 | Add this NOTES.md project history |
| 70429c1 | 2026-07-10 | Link the Getting started vignette from the README |
| 4344d33 | 2026-07-10 | Add pkgdown site + GitHub Pages deploy workflow |
| 8addca6 | 2026-07-10 | Fix pkgdown build: default `docs/` output, move design doc to `dev/DESIGN.md` |
| f8f297d | 2026-07-10 | Expand vignette: stage-by-stage flow + continuous plot |
| 2759ad5 | 2026-07-10 | Warn on empty groups; EM for the continuous vignette example |
| f7a58a0 | 2026-07-12 | Redesign example data: 10 occasions, mixed linear/cubic shapes |
| 3a1fdf4 | 2026-07-12 | flexmix as a second estimation engine (uniform-degree capability) |
| ba80163 | 2026-07-12 | lcmm as a third estimation engine (hlme / thresholds link) |
| 038d2a2 | 2026-07-13 | Vignette: "Choosing an engine" section for all three backends |
| 1de6584 | 2026-07-13 | Precompute the vignette (static .Rmd from .orig; CI builds in seconds) |
| c518283 | 2026-07-13 | Fix pkgdown: add gbtm_engine_per_group_degrees to the reference index |
| 1e337b5 | 2026-07-13 | pkgdown builds without executing examples (site build ~2 min) |
| 9fa95c4 | 2026-07-13 | Vignette: consistent headings; stages as real sub-headings |
| 4d5a8ed | 2026-07-13 | Vignette: introduce the engine choice up front |
| 4b17254 | 2026-07-13 | **v0.1.0**: README scope section ("does / does not do"), version bump, tag |
| ddde39b | 2026-07-13 | Multi-start initialization (`n_starts`): k-means starts for trajeR, native for flexmix/lcmm |

### Build stages (as executed)

1. **Rename + git + gitignore** — folder `gbtm-pipeline` -> `gbtmkit`, git init on
   `main`, private data (`to-be-deleted-before-commit/`, `*.rds`, `*.RData`)
   excluded from history.
2. **Synthetic data** — `data-raw/simulate-data.R` builds `sim_binary` (n=1500)
   and `sim_continuous` (n=1200) with known groups; recovery verified.
3. **Package skeleton** — DESCRIPTION (MIT, engines in Suggests), NAMESPACE, data
   docs, testthat harness; R CMD check clean.
4. **Core** — (4a) `gbtm_spec()`, (4b) engine interface + trajeR adapter,
   (4c) engine-neutral diagnostics.
5. **Pipeline** — (5a) stages 1-2, (5b) stage 3 search + criteria, (5c) final fit
   + assignment + plotting + `run_gbtm_pipeline()` orchestrator.
6. **Release prep** — (6a) vignette + README, (6b) CI workflow + NEWS, then the
   public GitHub repo was created and pushed.
7. **CI** — green on ubuntu (release/devel/oldrel-1), macOS, Windows; then a CI
   speed/cleanup pass.
8. **Docs site** — pkgdown site published to GitHub Pages, auto-rebuilt on every
   push to `main` (deploy workflow -> `gh-pages` branch). The design doc was
   moved from `docs/` to `dev/DESIGN.md` so pkgdown can own the conventional
   `docs/` output. The vignette was later expanded with a stage-by-stage GRoLTS
   walkthrough and a continuous-outcome plot.

## Current state

- **v0.1.0 tagged (2026-07-13)**: three engines (trajeR / flexmix / lcmm), full
  GRoLTS pipeline, precomputed vignette, README scope section; CI green on all
  five platforms.
- `R CMD check` 0/0/0 locally (including the pandoc-built vignette).
- Tests: fast logic/mock/validation tests run everywhere (~1s); the 16 real-fit
  integration tests run locally (`devtools`, `NOT_CRAN=true`) and skip on CI/CRAN.
- Documentation site live at https://fabregithub.github.io/gbtmkit/ with the
  Getting started article (one-call pipeline, stage-by-stage flow, and binary +
  continuous examples) and the full function reference.

## Possible next steps (not done)

- Tag `v0.1.0`.
- ~~Second engine adapter (`flexmix`) to prove the interface generalizes~~ —
  done (2026-07-12). Notes: flexmix maps GBTM to a mixture of GLMs on long
  data grouped by subject (`y ~ poly(t, d, raw = TRUE) | id`); binomial needs a
  two-column `cbind(y, 1 - y)` response; `logLik`/`BIC`/`AIC` are S4 methods,
  so accessors go through `stats4::`; per-component degrees via
  `FLXMRglmfix(nested=)` collapse in practice, so the adapter requires uniform
  degrees and `evaluate_shapes()` sweeps uniform shapes
  (`gbtm_engine_per_group_degrees()`); `flexmix::refit()` (the SE step) can
  produce NaN SEs on boundary parameters — warning, not error. On the binary
  fixture the flexmix pipeline matches trajeR's recovery (0.895) and runs much
  faster.
- Third engine adapter (`lcmm`) — done (2026-07-12). Notes: GBTM = latent
  class growth analysis, `random = ~ -1` with class-specific effects via
  `mixture =`; gaussian → `hlme()`, binary → `lcmm(link = "thresholds")`
  (2-level ordinal ≈ probit trajectory model; conv=1 in ~30 s on the binary
  fixture, recovery 0.896). ng > 1 requires starting values: fit ng = 1 first
  and pass it as `B` (deterministic init). lcmm post-processing (`predictY`)
  re-parses the stored `call`, so the adapter must patch `call$fixed` /
  `call$mixture` with the actual formula objects after fitting. Model-implied
  group sizes = softmax of the first ng-1 parameters (class-membership
  intercepts, last class is reference). `mixture` is shared across classes, so
  uniform degrees only — same capability flag as flexmix.
- `grolts_report()` mapping outputs to GRoLTS checklist item numbers.
- Multi-start initialization for CNORM.
- Consider a CRAN submission.
- Optional: bump `JamesIves/github-pages-deploy-action` to clear its Node 20
  deprecation warning.
