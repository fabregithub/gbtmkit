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

- v0.1 functionally complete; CI green on all five platforms.
- `R CMD check` 0/0/0 locally (including the pandoc-built vignette).
- Tests: fast logic/mock/validation tests run everywhere (~1s); the 16 real-fit
  integration tests run locally (`devtools`, `NOT_CRAN=true`) and skip on CI/CRAN.
- Documentation site live at https://fabregithub.github.io/gbtmkit/ with the
  Getting started article (one-call pipeline, stage-by-stage flow, and binary +
  continuous examples) and the full function reference.

## Possible next steps (not done)

- Tag `v0.1.0`.
- Second engine adapter (`flexmix`) to prove the interface generalizes; the
  adapter conformance test is already set up for it.
- `grolts_report()` mapping outputs to GRoLTS checklist item numbers.
- Multi-start initialization for CNORM.
- Consider a CRAN submission.
- Optional: bump `JamesIves/github-pages-deploy-action` to clear its Node 20
  deprecation warning.
