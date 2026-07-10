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

## Current state

- v0.1 functionally complete; CI green on all five platforms.
- `R CMD check` 0/0/0 locally (including the pandoc-built vignette).
- Tests: fast logic/mock/validation tests run everywhere (~1s); the 16 real-fit
  integration tests run locally (`devtools`, `NOT_CRAN=true`) and skip on CI/CRAN.

## Possible next steps (not done)

- Tag `v0.1.0`.
- Second engine adapter (`flexmix`) to prove the interface generalizes; the
  adapter conformance test is already set up for it.
- `grolts_report()` mapping outputs to GRoLTS checklist item numbers.
- Multi-start initialization for CNORM.
- pkgdown site.
- Complete author details / consider a CRAN submission.
