# Project notes & history — gbtmkit

Working notes on how this package was built. Not part of the shipped
package (excluded via `.Rbuildignore`); intended as a record for
maintainers.

## What this package is

`gbtmkit` generalises a one-off group-based trajectory modelling (GBTM)
analysis script into a reproducible, **engine-agnostic** R package that
follows the GRoLTS reporting checklist. The estimation engine is
pluggable (trajeR now; flexmix/lcmm designed for) behind a small
accessor interface, so the diagnostics and plotting work the same for
any backend, and binary and continuous outcomes run through one
specification.

- Repo: <https://github.com/fabregithub/gbtmkit> (public, MIT)
- Docs site: <https://fabregithub.github.io/gbtmkit/> (pkgdown,
  auto-deployed)
- Author: Shoji F. Nakayama (ORCID 0000-0001-7772-0389)
- Full design rationale: `dev/DESIGN.md`

## Key decisions

- **Native engine is the default (decided 2026-07-14, v0.3.0).** Same
  models, ~30-60x faster, validated against the established engines;
  trajeR/flexmix/ lcmm remain selectable as citable instruments.
  Breaking edge: default-engine calls that passed trajeR-specific
  arguments (method=) now need engine = “trajeR”.

- **Demo-data covariates stay inert (decided 2026-07-13).** Regenerating
  the fixtures so x1 drives membership would cascade into every baked
  number (tests, vignette, benchmarks); the vignette’s small simulated
  covariate example states its truth inline and is the clearer demo.
  `x1`/`x2` being inert is documented as deliberate.

- **Name** `gbtmkit` (confirmed free on CRAN/GitHub/Bioconductor).

- **Engine-agnostic** architecture: one S3 adapter contract; trajeR
  first.

- **Both outcome types first-class**: binary (LOGIT) and continuous
  (CNORM).

- **Data is entirely synthetic and domain-neutral.** The real cohort
  data cannot be published and no external published dataset is used, to
  avoid revealing the study domain. Two generated datasets
  (`sim_binary`, `sim_continuous`) with known ground-truth groups ship
  as package data and drive tests, examples, and the vignette.

- **License** MIT.

- **Performance/autonomy** treated as a first-class requirement for the
  shape search (the original was slow on ~80k rows).

## Findings established during the build

- **trajeR `hessian`**: only affects standard errors. Point estimates,
  BIC, and posterior diagnostics are identical with `hessian = FALSE`
  and ~2.6x faster, so the search runs Hessian-off and only the final
  model is refit with it.
- **CNORM local optima**: continuous fits fall into local optima under
  tight group separation (BIC under-selects). The synthetic continuous
  fixture uses wide separation; multi-start initialisation noted as a
  future improvement.
- **Binary is low-information**: 4 binary occasions cap per-subject
  classification (~0.83) even when BIC recovers the right group count;
  the synthetic binary fixture uses wide separation so recovery is
  reliable.

## Findings from the data redesign (2026-07: 10 occasions, mixed-degree shapes)

The fixtures were rebuilt to be more realistic: ten occasions, two
linear groups (rising G1, falling G4) and two cubic groups (peak G2,
trough G3), with the shapes crossing mid-study. Lessons:

- **Linear-only group-number selection under-selects on curved data**:
  with cubic planted shapes, `select_n_groups(degree = 1)` picks 3
  groups; degree 2 is needed for BIC to find the planted 4. Tests and
  the vignette select with `degree = 2`.
- **Mixed per-group degrees are fragile in single-start fits**: fixing
  `degrees = c(1, 3, 3, 1)` (the truth) pins each degree to an arbitrary
  initialisation slot; with method “L” this lands in local optima (empty
  or merged groups) on both fixtures. Uniform `rep(3, 4)` recovers
  cleanly, so examples use it and per-group degrees are left to the
  shape search.
- **Binary separation must stay wide even with 10 occasions**: crossing
  trajectories put several groups at similar probabilities mid-study;
  below `sep = 3` (log-odds) the 4-group fit collapses. At `sep = 3` the
  full pipeline recovers 4 groups (0.89 assignment recovery, entropy
  0.76).
- **trajeR’s EMIRLS** fails numerically (“solve(): solution not found”)
  on the 10-occasion binary fixture;
  [`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md)
  records it and moves on, as designed.

## Findings from multi-start initialisation (2026-07-13, `n_starts`)

- **trajeR’s default initialisation is deterministic** (quantile-based):
  re-running with different seeds gives identical fits, so multi-start
  must supply `paraminit`. Its layout (from source, per Method): first
  ng entries are membership *logits vs group 1* for `"L"` but
  *probabilities* for `"EM"`/`"EMIRLS"`; then per-group trajectory
  coefficients; then per-group residual sd (CNORM; with `ssigma=TRUE`
  only the first is used).
- **Parameter-space noise is useless; k-means partition starts work.**
  Random jitter of the default init either falls back into the same
  basin or lands in garbage. Partitioning subjects with k-means on their
  outcome vectors and fitting per-cluster polynomial regressions reaches
  the EM-quality optimum with the fast “L” optimiser (CNORM rep(1,4):
  52906 vs 53012 default), and **rescues mixed per-group degrees**:
  binary c(1,3,3,1) reaches BIC 17110 vs 18175 default – better than any
  uniform-degree fit (18080).
- **lcmm gridsearch NSE**: `gridsearch()` re-parses the `m` call, so the
  fitting function must be bound under a plain name in the calling
  frame, and the `random()` in the `B = random(minit)` it builds is a
  *syntactic sentinel* – lcmm detects it from the unevaluated call after
  evaluation fails, so no `random` function may exist in that frame.
- **trajeR’s POIS initialisation requires overdispersion** (its
  qgamma-based init NaNs when var(Y) \<= mean(Y)) – relevant for tests
  that fabricate count data.

## Findings from covariate support (2026-07-13, `gbtm_spec(covariates=)`)

Class-membership covariates (time-varying covariates followed the same
day; see the next section): trajeR `Risk` (numeric design matrix from
`model.matrix`, no intercept column), flexmix concomitant
`FLXPmultinom(formula)`, lcmm `classmb = formula` (ng \> 1 fits only;
the 1-class init has no membership model). Verified on all three engines
with a covariate-driven synthetic dataset (BIC improves by ~200).
Gotchas:

- **trajeR theta layout with Risk**: group-major blocks of (intercept,
  covariate effects); the k-means multi-start builds those blocks with
  zero effects, Method “L” only – the user-paraminit path for EM with nx
  \> 1 is not well-defined in trajeR, so multi-start falls back with a
  warning there.
- **lcmm parameter layout with classmb** is parameter-major (int c1, int
  c2, x1 c1, x1 c2, …), so the softmax-of-first-(K-1) shortcut for
  model-implied group sizes is wrong with covariates;
  [`gbtm_group_sizes()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_accessors.md)
  falls back to mean posterior (which is also the honest marginal answer
  when proportions are subject-specific).
- **lcmm predictY demands every model covariate in newdata** even though
  classmb covariates do not enter the trajectories; the adapter supplies
  representative values (numeric mean / first level).

## Findings from trajectory covariates (2026-07-13, `gbtm_spec(tcov=)`)

Time-varying covariates with group-specific effects on all three
engines: trajeR `TCOV` (covariate-major wide blocks, n x
(occasions\*nw); delta estimates recovered the planted -3/+3 exactly),
flexmix and lcmm via extra formula terms (in both `fixed` and `mixture`
for lcmm so effects are class-specific). Gotchas:

- **trajeR GroupProb needs TCOV (and X) passed again** – without TCOV
  the posterior accessor crashes (`gkCNORM_cpp ... type=NULL`); X turns
  out to be a numerical no-op (GroupProb recovers priors from the stored
  fit; verified max \|diff\| ~ 1e-12) but is passed for safety.
- **Engine predict paths must exclude tcov terms**: flexmix’s
  coefficient matrix gains rows for the covariates (select only
  Intercept + poly rows); lcmm’s predictY needs the tcov columns in
  newdata (set to 0). Convention (documented in ?gbtm_spec): fitted
  trajectories are at tcov = 0, so users should code tcov with a
  meaningful zero.
- **trajeR paraminit with TCOV**: delta block (ng x nw, zeros as start)
  sits at the very end; the k-means multi-start appends it.

## Findings from the native engine (2026-07-14, `engine = "gbtmkit"`)

Clean-room vectorised ML implementation (BFGS + analytic gradients),
written from the model equations – no code from GPL trajeR. Key facts:

- **Correctness anchors**: the likelihood evaluated at trajeR’s fitted
  parameters reproduces trajeR’s log-likelihood exactly (same
  convention); analytic gradients match numDeriv to ~1e-8 across
  families x covariates x tcov x ssigma x NA masks (tested); 99.8%
  assignment agreement with trajeR on the binary fixture; perfect
  recovery on the continuous fixture.
- **Speed**: the binary 4-group quadratic fit that takes trajeR ~44 s
  runs in ~1.1 s single-start (~3.4 s with 3 starts) at a slightly
  *better* optimum. The root cause of trajeR’s slowness (profiled):
  ~99.7% of time inside its C++ likelihood at ~130 ms/eval vs \<1 ms
  vectorised.
- **Parameterisation** (optim vector): group-major theta blocks
  (intercept + membership-covariate effects, group 1 reference),
  per-group beta = polynomial coefficients then tcov coefficients,
  gaussian log-sigma (1 value if ssigma else K). tcov enters as extra
  design columns, so it shares the beta code path; trajectories at tcov
  = 0 use only the poly part.
- **NA outcomes are masked, not dropped** (unlike the long-format
  engines) – subjects need \>= 1 observed occasion.
- **Censored normal (added 2026-07-14)**: Tobit cells (y \<= ymin left-,
  y \>= ymax right-censored) with Mills-ratio gradients computed on the
  log scale; gradient matches numDeriv to ~1e-7 on censored data,
  recovers latent parameters through ~13% censoring, and the
  log-likelihood matches trajeR’s CNORM with explicit bounds exactly.
  Note trajeR *defaults* ymin/ymax to min/max of Y (treating the
  extremes as censored); the native engine censors only when the spec
  sets bounds explicitly.
- **EM optimiser** (post-0.3.0): `method = "EM"` runs
  expectation-maximisation as an alternative to BFGS. E-step reuses the
  posterior computation; M-step is a per-class weighted GLM (`lm.wfit`
  for gaussian, `glm.fit(weights=)` for binomial/poisson, subject
  weights broadcast to the subject’s occasions) plus a membership update
  (closed-form `log(pi_k/pi_1)` without covariates, a small
  weighted-multinomial `optim` with them, reusing the `W - pi` score).
  Verified: monotone likelihood ascent, and EM converges to the *same*
  MLE as BFGS on binary/gaussian/covariate fixtures (diff \< 1e-3). This
  makes gbtmkit a two-optimiser engine, so
  `gbtm_engine_methods("gbtmkit")` returns `c("BFGS","EM")` and the
  pipeline’s stage-1 selection now runs for the native default
  (user-chosen: auto-select BFGS vs EM). Censored-normal is BFGS-only
  (the Tobit M-step is not a weighted GLM). Both optimisers reuse the
  same `par` layout, so accessors/`optimHess`/multi-start are unchanged.
- **Multi-start starts** (v0.3.0): start 1 is the deterministic
  quantile- intercept “default” init; starts \>= 2 are k-means
  partitions + per-cluster polynomial/GLM regressions (full coefficient
  starts, not just intercepts). The regression starts are what escape
  merged-group local optima on curved data: continuous `rep(3,4)`
  single-start collapses to 3 groups (BIC 54200), but n_starts \>= 2
  finds the good optimum (BIC 47205, exactly matching trajeR) and
  perfect recovery.
- **RNG-kind reproducibility trap (found + fixed 2026-07-14)**:
  multi-start runs through `.fit_map` -\>
  `future.apply(future.seed = TRUE)`, which switches the RNG to
  L’Ecuyer-CMRG. A bare `set.seed(v)` inside the worker then seeds
  *that* stream, so `kmeans` produced different partitions under a
  future plan vs a plain call – the same seed gave different fits in
  `devtools::test()` vs interactively. Fix: seed with an explicit
  `kind = "Mersenne-Twister"` (see `seed_start()` in `.fit_gbtmkit`).
  Lesson for any future engine doing RNG in a `.fit_map` worker: pin the
  kind.
- **Not yet**: beta family.
- The native engine is the default from v0.3.0; trajeR/flexmix/lcmm
  remain selectable as established, citable instruments (a reviewer may
  ask for one).

## Findings from parallelisation (2026-07-13, `.fit_map` via future.apply)

Independent fits (multi-start starts; selection-stage
candidates/methods) run through `.fit_map`, which uses
`future.apply::future_lapply(future.seed=TRUE)` when installed; the user
controls workers via
[`future::plan()`](https://future.futureverse.org/reference/plan.html).
Notes:

- **Speedup is bounded by the slowest fit**: measured 2.6x for 5-way
  multi-start and 2.0x for a 4-candidate sweep (the 4-group fit
  dominates).
- **Seeded determinism holds under any plan** (each task set.seed()s
  itself; verified bit-identical BICs sequential vs multicore).
- **trajeR speed dead ends, measured**: BLAS threading is irrelevant
  (44.0 s vs 43.6 s at 1 vs 8 OpenBLAS threads – per-subject matrices
  too small), and `itermax` has no “loose search” headroom (the
  optimiser self-terminates at ~50-60 iterations; itermax 60/100/400
  identical, 30 truncates to a worse BIC).
- **Tests use `plan(multicore)`** (fork): multisession workers cannot
  loadNamespace a devtools::load_all package; fork inherits it. Guarded
  by
  [`future::supportsMulticore()`](https://parallelly.futureverse.org/reference/supportsMulticore.html)
  (unavailable on Windows/RStudio).
- **Warm starts in the shape search: tried and REJECTED (negative
  result, 2026-07-13).** Initialising each trajeR candidate from the
  incumbent’s parameters (coefficient blocks padded/truncated) looks
  great per move – 1.8-3.3x faster and often better BIC when the
  incumbent is good (it pins group identities to the degree slots). But
  in the actual stepwise search it is poison: the search starts from the
  *linear* incumbent, warm candidates inherit that poor basin,
  near-converged starting points kill exploration, and the search
  stalled at rep(1,4) (BIC 17637 vs cold 17117) despite being 14.7x
  faster. Do not re-implement as a default; if ever revisited, it must
  be best-of(cold, warm) per candidate, which forfeits the speedup.
- Remaining (unimplemented) speed ideas: subsample-based search; hybrid
  workflow (select K with flexmix, fit with trajeR).

## Findings from the engine benchmark (2026-07-13, `benchmark_engines()`)

`data-raw/benchmark-scale.R` at n = 2000 / 20000 (10 occasions, 4
groups, quadratic, method “L”, itermax 200, single start; wall-clock
seconds on the dev Mac):

| n     | family   | trajeR | flexmix |  lcmm |
|-------|----------|-------:|--------:|------:|
| 2000  | gaussian |   62.4 |     0.3 |   9.3 |
| 2000  | binomial |   36.1 |     3.0 |   8.3 |
| 20000 | gaussian |  730.5 |    15.0 | 168.7 |
| 20000 | binomial |  517.5 |    36.0 | 118.0 |

- **flexmix is 15-180x faster than trajeR**, lcmm sits in between – the
  DESIGN.md expectation (“C/Fortran engines much faster at large N”)
  holds, and scaling looks roughly linear in n, so 80k extrapolates to
  hours for trajeR vs a minute or two for flexmix.
- **Quality caveat at scale**: at n = 20000 binomial, trajeR’s
  deterministic single-start fit collapsed to 3 effective groups (empty
  group, min APPA -Inf) while flexmix/lcmm found all 4 – `n_starts`
  matters most for trajeR.
- Practical guidance (now in the docs): fit a subsample with
  [`benchmark_engines()`](https://fabregithub.github.io/gbtmkit/reference/benchmark_engines.md),
  pick the fastest engine whose classification diagnostics are adequate.

## Precomputed vignette (2026-07-13)

The getting-started vignette runs ~20 min of real fits, which made every
CI / pkgdown build re-run them (~2 h on a GitHub runner). It is now
precomputed:

- **Source of truth**: `vignettes/getting-started.Rmd.orig` (executable,
  `.Rbuildignore`d).
- **Shipped file**: `vignettes/getting-started.Rmd` (static: outputs
  baked in and `vignettes/getting-started-*.png` figures beside it,
  committed to git; builds in seconds). A knitr output/message hook in
  the `.orig` strips trajeR’s optimiser chatter; `fig.path` is a file
  prefix because R CMD check flags a `vignettes/figure/` directory as a
  knitr leftover.
- **Regenerate** with `Rscript data-raw/precompile-vignette.R` after
  editing the `.orig` or when demonstrated behaviour changes, and commit
  the `.orig`, the regenerated `.Rmd`, and the figures together.
- Bug-fix verification does NOT require re-knitting: tests and direct
  runs verify code; the vignette is refreshed only when its shown
  outputs matter.

The pkgdown workflow likewise builds with `examples = FALSE` (the
reference examples are real fits, ~50 min on a runner; pages show the
code without executed output). Since the examples are `\donttest`,
nothing runs them automatically anymore – **run
`devtools::run_examples()` locally before a release** (and after
touching any roxygen example).

## Bugs in the original script that the port fixes

- Duplicated, mutually inconsistent PMS filters -\> single robust
  min-across-group summary columns in
  [`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md).
- `test_algo[1:2]` dropping the third algorithm from the BIC comparison.
- Out-of-bounds `test_algo[i]` in the group loop.
- Silently dropped failed fits (`.errorhandling = "remove"`) -\>
  failures are now recorded as `NA` with a warning.
- Mis-applied entropy (Shannon of proportions) -\> standard normalised
  classification entropy in \[0, 1\].

## History (chronological)

Built step by step, confirming each stage, with `R CMD check` kept at
0/0/0 throughout.

| Commit | Date | What |
|----|----|----|
| d79f091 | 2026-07-07 | Design document + `.gitignore`; folder renamed to `gbtmkit`, git init |
| 0c3b17e | 2026-07-07 | Synthetic data simulator + first fixture (BIC recovers planted groups) |
| 0278f9e | 2026-07-07 | Genericise data: domain-neutral binary + continuous fixtures |
| b88165c | 2026-07-07 | Scrub design doc: synthetic-only, remove domain/published-data refs |
| 583d62f | 2026-07-07 | Package skeleton (DESCRIPTION/MIT/NAMESPACE/testthat), data as package data |
| a3a8f2b | 2026-07-07 | [`gbtm_spec()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md) — validated, name-based model specification |
| b028516 | 2026-07-07 | Engine interface + trajeR adapter (LOGIT + CNORM); accessors |
| 68c6386 | 2026-07-07 | Engine-neutral GRoLTS diagnostics + [`gbtm_assign()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_assign.md) |
| 4f1e842 | 2026-07-07 | Stages 1-2: [`select_algorithm()`](https://fabregithub.github.io/gbtmkit/reference/select_algorithm.md), [`select_n_groups()`](https://fabregithub.github.io/gbtmkit/reference/select_n_groups.md) |
| a8e12db | 2026-07-07 | Stage 3: [`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md) (bounded search) + [`apply_grolts_criteria()`](https://fabregithub.github.io/gbtmkit/reference/apply_grolts_criteria.md) |
| fca365f | 2026-07-08 | Stage 4 + [`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md) orchestrator; [`gbtm_predict()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_predict.md), [`plot_trajectories()`](https://fabregithub.github.io/gbtmkit/reference/plot_trajectories.md) |
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
| 038d2a2 | 2026-07-13 | Vignette: “Choosing an engine” section for all three backends |
| 1de6584 | 2026-07-13 | Precompute the vignette (static .Rmd from .orig; CI builds in seconds) |
| c518283 | 2026-07-13 | Fix pkgdown: add gbtm_engine_per_group_degrees to the reference index |
| 1e337b5 | 2026-07-13 | pkgdown builds without executing examples (site build ~2 min) |
| 9fa95c4 | 2026-07-13 | Vignette: consistent headings; stages as real sub-headings |
| 4d5a8ed | 2026-07-13 | Vignette: introduce the engine choice up front |
| 4b17254 | 2026-07-13 | **v0.1.0**: README scope section (“does / does not do”), version bump, tag |
| ddde39b | 2026-07-13 | Multi-start initialisation (`n_starts`): k-means starts for trajeR, native for flexmix/lcmm |
| 1882db3 | 2026-07-13 | Class-membership covariates (`gbtm_spec(covariates=)`) on all three engines |
| ca77f40 | 2026-07-13 | [`benchmark_engines()`](https://fabregithub.github.io/gbtmkit/reference/benchmark_engines.md) harness + scale results (flexmix 15-180x faster) |
| 7a950b8 | 2026-07-13 | [`grolts_report()`](https://fabregithub.github.io/gbtmkit/reference/grolts_report.md): pipeline result -\> GRoLTS checklist reporting aid |
| 78b3806 | 2026-07-13 | Vignette: grolts_report, n_starts, covariates, benchmark_engines |
| a55f985 | 2026-07-13 | Time-varying trajectory covariates (`gbtm_spec(tcov=)`) on all engines |
| 19717b1 | 2026-07-13 | Parallel multi-start and selection sweeps via future.apply (~2-2.6x) |
| 03c7c92 | 2026-07-13 | **v0.2.0**: vignette parallel note, warm-start negative result, demo-data decision |
| 4e97507 | 2026-07-14 | Native engine (`engine = "gbtmkit"`): vectorised ML, ~30-60x faster than trajeR |
| 3f11fba | 2026-07-14 | Native engine: censored-normal (Tobit) support |
| 72add36 | 2026-07-14 | **v0.3.0**: native engine as default; British English; RNG-reproducible multi-start |
| 9ddb73a | 2026-07-14 | British English: catch remaining -ize words |
| 65d9851 | 2026-07-15 | Native engine: EM optimiser alongside BFGS (`method = "EM"`) |
| 9d765cb | 2026-07-15 | Record the EM-optimiser and British-follow-up commits in NOTES.md history |
| b325016 | 2026-07-16 | **v0.4.0**: release cut (native EM optimiser); Description reflects four engines |

### Build stages (as executed)

1.  **Rename + git + gitignore** — folder `gbtm-pipeline` -\> `gbtmkit`,
    git init on `main`, private data (`to-be-deleted-before-commit/`,
    `*.rds`, `*.RData`) excluded from history.
2.  **Synthetic data** — `data-raw/simulate-data.R` builds `sim_binary`
    (n=1500) and `sim_continuous` (n=1200) with known groups; recovery
    verified.
3.  **Package skeleton** — DESCRIPTION (MIT, engines in Suggests),
    NAMESPACE, data docs, testthat harness; R CMD check clean.
4.  **Core** — (4a)
    [`gbtm_spec()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_spec.md),
    (4b) engine interface + trajeR adapter, (4c) engine-neutral
    diagnostics.
5.  **Pipeline** — (5a) stages 1-2, (5b) stage 3 search + criteria, (5c)
    final fit
    - assignment + plotting +
      [`run_gbtm_pipeline()`](https://fabregithub.github.io/gbtmkit/reference/run_gbtm_pipeline.md)
      orchestrator.
6.  **Release prep** — (6a) vignette + README, (6b) CI workflow + NEWS,
    then the public GitHub repo was created and pushed.
7.  **CI** — green on ubuntu (release/devel/oldrel-1), macOS, Windows;
    then a CI speed/cleanup pass.
8.  **Docs site** — pkgdown site published to GitHub Pages, auto-rebuilt
    on every push to `main` (deploy workflow -\> `gh-pages` branch). The
    design doc was moved from `docs/` to `dev/DESIGN.md` so pkgdown can
    own the conventional `docs/` output. The vignette was later expanded
    with a stage-by-stage GRoLTS walkthrough and a continuous-outcome
    plot.

## Current state

- **v0.2.0 tagged (2026-07-13)**: multi-start (`n_starts`), membership +
  time-varying covariates,
  [`grolts_report()`](https://fabregithub.github.io/gbtmkit/reference/grolts_report.md),
  [`benchmark_engines()`](https://fabregithub.github.io/gbtmkit/reference/benchmark_engines.md),
  parallel independent fits; 482 tests, check 0/0/0.
- **v0.1.0 tagged (2026-07-13)**: three engines (trajeR / flexmix /
  lcmm), full GRoLTS pipeline, precomputed vignette, README scope
  section; CI green on all five platforms.
- `R CMD check` 0/0/0 locally (including the pandoc-built vignette).
- Tests: fast logic/mock/validation tests run everywhere (~1s); the 16
  real-fit integration tests run locally (`devtools`, `NOT_CRAN=true`)
  and skip on CI/CRAN.
- Documentation site live at <https://fabregithub.github.io/gbtmkit/>
  with the Getting started article (one-call pipeline, stage-by-stage
  flow, and binary + continuous examples) and the full function
  reference.

## Engine adapter notes (flexmix / lcmm, 2026-07-12)

- **flexmix**: mixture of GLMs on long data grouped by subject
  (`y ~ poly(t, d, raw = TRUE) | id`); binomial needs a two-column
  `cbind(y, 1 - y)` response; `logLik`/`BIC`/`AIC` are S4 methods, so
  accessors go through `stats4::`; per-component degrees via
  `FLXMRglmfix(nested=)` collapse in practice, so the adapter requires
  uniform degrees and
  [`evaluate_shapes()`](https://fabregithub.github.io/gbtmkit/reference/evaluate_shapes.md)
  sweeps uniform shapes
  ([`gbtm_engine_per_group_degrees()`](https://fabregithub.github.io/gbtmkit/reference/gbtm_engine_per_group_degrees.md));
  `flexmix::refit()` (the SE step) can produce NaN SEs on boundary
  parameters — warning, not error. On the binary fixture the flexmix
  pipeline matches trajeR’s recovery (0.895), much faster.
- **lcmm**: LCGA via `random = ~ -1` with class-specific effects in
  `mixture =`; gaussian → `hlme()`, binary → `lcmm(link = "thresholds")`
  (2-level ordinal ≈ probit trajectory model; recovery 0.896 on the
  binary fixture). ng \> 1 requires starting values: fit ng = 1 first
  and pass it as `B`. Post-processing (`predictY`) re-parses the stored
  `call`, so the adapter patches
  `call$fixed`/`call$mixture`/`call$classmb` with the actual formula
  objects. Model-implied group sizes = softmax of the first ng-1
  parameters (covariate-free fits only). `mixture` is shared across
  classes, so uniform degrees only — same capability flag as flexmix.

## Possible next steps (not done)

- Consider a CRAN submission.
- Optional: bump `JamesIves/github-pages-deploy-action` to clear its
  Node 20 deprecation warning.

Done along the way: v0.1.0 tag, flexmix + lcmm adapters, multi-start
initialisation, class-membership covariates,
[`benchmark_engines()`](https://fabregithub.github.io/gbtmkit/reference/benchmark_engines.md),
[`grolts_report()`](https://fabregithub.github.io/gbtmkit/reference/grolts_report.md),
precomputed vignette (see History).
