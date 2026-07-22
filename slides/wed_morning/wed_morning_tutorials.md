> ## !!! PRE-DOWNLOAD ALL DATA BEFORE THE WORKSHOP !!!
>
> **The upstream versions of these tutorials fetch their datasets over the
> network on first use. Do not find this out in the room.**
>
> Prepare the tutorial machine by running the staging scripts:
>
> ```bash
> cd slides/wed_morning/staging
> Rscript stage_all.R
> ```
>
> See `staging/README.md`. The scripts download each tutorial's input once, do
> the slow or fragile preprocessing once, and write into whatever
> `find_data_dir()` resolves to. They are idempotent, so re-running after a
> partial failure is cheap. On the tutorial machine, point them at the shared
> location first:
>
> ```bash
> echo 'WORKSHOP2026AUG_DATA=/shared/workshop_data' >> ~/.Renviron
> ```
>
> Why each one matters:
>
> - **Milo (3.b)** pulls the mouse gastrulation atlas through
>   `MouseGastrulationData` / `ExperimentHub`. This is the worst one. It is
>   several GB, and `ExperimentHub` caches per user, so 20 students on 20
>   accounts means 20 separate downloads hitting the wifi at once.
> - **Monocle 3 (1.b)** needs Python with `anndata` to convert its input. That
>   comes from the project pixi environment at the repo root, so it is
>   reproducible from `pixi.toml`. Staging does the conversion once, and the
>   student machines need no Python at all.
> - **Slingshot (1.a)** needs GSE72857 from GEO, then a slow `read.delim()`.
> - **Seurat DE (2.b)** has two network dependencies, not one. `SeuratData` for
>   `ifnb`, plus two demuxlet files from GitHub that supply the donor IDs the
>   pseudobulk section needs.
> - **COVID composition (3.a)** substitutes a smaller public dataset (Wilk et al.
>   2020, from CELLxGENE) for the upstream query object, which has no public
>   download. Now stages automatically. See `staging/README.md`.
>
> Only `2_a_pseudobulk_de` is staged so far.
>
> Check each one on the actual workshop hardware. A download that works from
> home can still fail behind an institutional firewall.

## How this directory is organized

Three themes, two tutorials each. For every theme there is a downloaded upstream
`.html` for reference and a `_local.qmd` that we run, which reads pre-staged data
instead of downloading:

| | Downloaded reference | Our runnable version |
|---|---|---|
| 1.a | `wed_morn_tutorials/1_a_slingshot.html` | `1_a_slingshot_local.qmd` |
| 1.b | `wed_morn_tutorials/1_b_monocle3.html` | `1_b_monocle3_local.qmd` |
| 2.a | `wed_morn_tutorials/2_a_pseudobulk_de.html` | `2_a_pseudobulk_de_local.qmd` |
| 2.b | `wed_morn_tutorials/2_b_de_vignette.html` | `2_b_de_vignette_local.qmd` |
| 3.a | `wed_morn_tutorials/3_a_composition_covid.html` | `3_a_composition_covid_local.qmd` |
| 3.b | `wed_morn_tutorials/3_b_composition_milo.html` | `3_b_composition_milo_local.qmd` |

The `.html` files are gitignored. The `.qmd` files are tracked.

Supporting files:

- `slides/find_data_dir.R`, sourced by every `.qmd`, defines `find_data_dir()`
  and `report_data_dir()`.
- `slides/wed_morning/staging/`, the scripts that prepare the tutorial machine.
  `stage_all.R` plus one `stage_<tutorial>.R` each, `staging_helpers.R`, and a
  `README.md`.

**All six `.qmd` files are full transcriptions of their upstream tutorial, with
the downloads replaced by reads from the data directory. None has been run yet.**
Each carries a status callout saying so. Every chunk is `eval: true` and every
document sets `error: true`, so a first test render on the tutorial machine
completes and lists every failure at once instead of stopping at the first.

Read the first rendered HTML as a punch list, not as a result.

One deliberate exception: `1_a_slingshot_local.qmd` keeps its "Seurat route"
chunk at `eval: false`. That section is an alternative to the Scran/Scater
pipeline rather than a step after it, and running both would overwrite the
objects the rest of the document depends on.

### Finding the data

Every `.qmd` starts with:

```r
source(here::here("slides", "find_data_dir.R"))
data_dir <- find_data_dir("3_b_composition_milo")   # the tutorial's subdirectory
```

`slides/find_data_dir.R` resolves the data root in this order:

1. the `WORKSHOP2026AUG_DATA` environment variable, when set
2. `~/github/workshop2026aug_data`
3. `workshop2026aug_data` as a sibling of this repo

On the workshop machines, set the environment variable once in `~/.Renviron` and
every tutorial follows with no edits to any file here. `~/.Renviron` rather than
the shell, because RStudio and Quarto renders do not inherit your shell
environment.

`slides/find_data_dir.R` also defines `report_data_dir()`, which prints the
resolved path and the files in it. Every `.qmd` calls it in its setup chunk, so
each rendered document records which copy of the data produced it.

**The staging scripts do not write to the current working directory.** They
write to `find_data_dir("<tutorial>", check = FALSE)`, which is the same
resolution order as above. With `WORKSHOP2026AUG_DATA` unset that means
`~/github/workshop2026aug_data/<tutorial>/`. Running a script from any directory
gives the same result. Override for one run with `--outdir`.

---

# Before you run the staging scripts

## Per-tutorial status

| Tutorial | Stages automatically | What to expect |
|---|---|---|
| 1.a slingshot | yes | Large GEO download, then a slow `read.delim()`. Falls back from FTP to HTTPS, because GEO's FTP is blocked on some networks. |
| 1.b monocle3 | yes | Needs Python with `anndata`, taken from the project pixi env, and `monocle3` in R. Doing the conversion once here is exactly what spares the students from needing Python. |
| 2.a pseudobulk | yes, done | Already staged. One Dropbox `.rds`, no preprocessing. |
| 2.b de_vignette | yes | Two downloads, not one. See below. |
| 3.a covid | yes | Substitutes Wilk et al. 2020 (CELLxGENE) for the query object that has no public download. Needs `Seurat` in R and Python `anndata`. See below. |
| 3.b milo | yes | The big ExperimentHub download. The one that would otherwise break the room. |

## 3.a substitutes a public dataset for the missing query

The upstream vignette maps a 1,498,064-cell COVID PBMC query onto a healthy
reference. **That query object has no public download**, it lives inside the
Satija lab filesystem, so the vignette cannot be reproduced as written.

Rather than chase it, 3.a now substitutes a smaller public dataset that already
carries the labels the composition analysis needs: Wilk et al. 2020, from
CELLxGENE. 41,305 cells, 13 donors (7 COVID-19, 6 healthy), 26 cell types. The
CELLxGENE schema guarantees `donor_id`, `disease` with the literal levels
`normal` and `COVID-19`, and `cell_type`, so no reference and no mapping are
needed, the annotations come with the data. The headline result reproduces: MAIT
cells down and plasmablasts up in COVID-19.

The `.qmd` was rewritten to match. It uses `cell_type` in place of the
mapping-derived `predicted.celltype.l2`, collapses the two plasmablast subtypes
this dataset distinguishes, and drops the reference-mapping half of the vignette,
which `integration_mapping.html` still covers on its own. The rest of the
teaching arc is unchanged, including the point that the analysis applies **no
statistical test**, and the optional propeller block that adds one.

If you ever want to teach the mapping half, the upstream reference is public on
Zenodo at <https://zenodo.org/record/7779017>.

## 2.b has a second network dependency

Besides `ifnb` through `SeuratData`, the pseudobulk section pulls two demuxlet
files from GitHub, `ye1.ctrl.8.10.sm.best` and `ye2.stim.8.10.sm.best`. They
supply the donor IDs. Without them `AggregateExpression()` and everything after
it fails. The staging script fetches both.

## 2.a has genuinely broken upstream code, not just drift

The lesson is dated May 2020 and three things in it no longer work:

- `scater::calculateQCMetrics()` and `total_features_by_counts` were removed from
  Bioconductor.
- `Matrix.utils` is archived on CRAN, so `aggregate.Matrix()` may not install.
- `levels(metadata$cluster_id)` returns `NULL` under R >= 4.0, because of the
  `stringsAsFactors` change. This one is the dangerous one. It **silently**
  empties a variable rather than erroring.

Each is transcribed as upstream has it, immediately followed by a working modern
equivalent and a callout explaining the situation. The `.qmd` also has a
`package-availability` chunk that tabulates every required package in one pass,
so a single render gives you the whole install list rather than one missing
package at a time.

## Things that will need eyeballing on first run

- **1.b monocle3**: cluster numbering and module numbering are not stable across
  versions. The cluster-to-cell-type mapping and the module plot need checking
  against the marker plots rather than trusting the hardcoded numbers.
- **1.b monocle3**: the upstream biomaRt gene-symbol section was dropped, since
  it makes live Ensembl calls. Say the word if you want it back behind a staged
  lookup table.
- **1.a slingshot**: upstream's `plot_differential_expression()` helper
  overwrites its own argument on the first line, so it always plots the same
  gene whatever you pass it. Fixed in the transcription, with a comment.

## Packages the staging scripts need

```r
install.packages(c("argparser", "Matrix", "R.utils"))
BiocManager::install(c("MouseGastrulationData", "SingleCellExperiment",
                       "SummarizedExperiment", "Seurat"))
remotes::install_github("satijalab/seurat-data")      # SeuratData
remotes::install_github("cole-trapnell-lab/monocle3") # not on CRAN or Bioconductor
```

Each script checks its own packages first and fails with a single install line
rather than dying partway through a large download.

**`monocle3` is not installed on this machine**, so `stage_1_b_monocle3.R` will
stop before it downloads anything. Install it first if you want 1.b staged in
the same run.

Python is needed by 1.b alone, and comes from the pixi environment at the repo
root. `anndata` has been added to `pixi.toml`. The handoff goes through files
rather than reticulate, since reticulate treats a pixi env as a conda env and
refuses to start without a conda binary. See `staging/README.md`.

---

# 1 Trajectory inference

## 1.a Slingshot

NBIS workshop-scRNAseq, 2020-01-27 archive. Mouse bone marrow progenitors from
GEO GSE72857, subsampled to every fifth cell (27,297 genes × 2,074 cells). Shows
both the Scran/Scater and the Seurat processing route, then `getLineages` /
`getCurves` for principal curves and tradeSeq for DE along pseudotime.

[1_a_slingshot.html](wed_morn_tutorials/1_a_slingshot.html) ·
[1_a_slingshot_local.qmd](wed_morn_tutorials/1_a_slingshot_local.qmd)
Source: https://nbisweden.github.io/workshop-archive/workshop-scRNAseq/2020-01-27/labs/compiled/slingshot/slingshot.html
Page title: "Trajectory inference analysis: Slingshot"
Cites Cannoodt et al. 2016, European Journal of Immunology 46(11):2496-2506,
and Saelens et al. 2019, Nature Biotechnology 37(5):547-554.

1.a.i Method reference, not a lab: [Slingshot: Trajectory Inference for Single-Cell Data](https://bioconductor.org/packages/release/bioc/vignettes/slingshot/inst/doc/vignette.html)

1.a.ii Slingshot across two conditions, differential progression (KS test) plus
condition-specific DE: [Trajectory inference across conditions: differential expression and differential progression](https://kstreet13.github.io/bioc2020trajectories/articles/workshopTrajectories.html)

## 1.b Monocle 3

Galaxy Training Network, roughly 3 h in R. AnnData to `cell_data_set`, MNN batch
correction, `learn_graph` / `order_cells`, graph-autocorrelation DE. Note that
trajectories are inferred within a single partition, which is the usual student
stumbling block.

[1_b_monocle3.html](wed_morn_tutorials/1_b_monocle3.html) ·
[1_b_monocle3_local.qmd](wed_morn_tutorials/1_b_monocle3_local.qmd)
Source: https://training.galaxyproject.org/training-material/topics/single-cell/tutorials/scrna-case_monocle3-rstudio/tutorial.html
Julia Jakiela, 2025, "Inferring single cell trajectories with Monocle3 (R)", Galaxy Training Network.

1.b.i Official reference: [Constructing single-cell trajectories](https://cole-trapnell-lab.github.io/monocle3/docs/trajectories/) [unverified: page `<title>` is only the generic "Monocle 3", so the section name could not be confirmed by metadata fetch]

1.b.ii Background reading, TSCAN / Slingshot / tradeSeq compared, plus how to
pick the root: [Chapter 10 Trajectory Analysis | Advanced Single-Cell Analysis with Bioconductor](https://bioconductor.org/books/release/OSCA.advanced/trajectory-analysis.html)

---

# 2 Differential expression

## 2.a Pseudobulk with DESeq2

Better pedagogically than 2.b, but confirmed stale: the page banner reads
"Introduction to Single-cell RNA-seq - ARCHIVED" and the lesson is dated 2020.
This is the one whose data is already staged.

[2_a_pseudobulk_de.html](wed_morn_tutorials/2_a_pseudobulk_de.html) ·
[2_a_pseudobulk_de_local.qmd](wed_morn_tutorials/2_a_pseudobulk_de_local.qmd)
Source: https://hbctraining.github.io/scRNA-seq/lessons/pseudobulk_DESeq2_scrnaseq.html

## 2.b Seurat differential expression testing

[2_b_de_vignette.html](wed_morn_tutorials/2_b_de_vignette.html) ·
[2_b_de_vignette_local.qmd](wed_morn_tutorials/2_b_de_vignette_local.qmd)
Source: https://satijalab.org/seurat/articles/de_vignette

Teach 2.a and 2.b together. Seurat's default `FindMarkers()` treats each cell as
a replicate, which inflates significance because cells within a donor are not
independent. Putting both p-value distributions on one slide makes the point
faster than any amount of explanation.

---

# 3 Cell type composition

The only theme that tests changes in **composition**, meaning which cell types
are present and in what proportion, as opposed to changes in expression.

## 3.a COVID PBMCs, healthy versus infected

Compares cell type proportions between healthy and COVID-19 donors, reporting a
reduction in MAIT cells and an increase in plasmablasts.

**It does this with a contingency table and boxplots, with no statistical test.**
That is the setup for 3.b. Make the gap explicit rather than letting students
infer that eyeballing proportions is the method.

The downloaded `.html` is the original vignette, which maps a query onto a
reference to get its annotations. The `.qmd` we run substitutes Wilk et al. 2020
from CELLxGENE (see the 3.a staging note above), which already carries
`cell_type`, so it drops the mapping half and goes straight to composition. Same
result, no unobtainable query object.

[3_a_composition_covid.html](wed_morn_tutorials/3_a_composition_covid.html) ·
[3_a_composition_covid_local.qmd](wed_morn_tutorials/3_a_composition_covid_local.qmd)
Source: https://satijalab.org/seurat/articles/covid_sctmapping
Substitute dataset: Wilk et al. 2020, "A single-cell atlas of the peripheral
immune response in patients with severe COVID-19", Nature Medicine,
https://doi.org/10.1038/s41591-020-0944-y

## 3.b Milo

Bioconductor `miloR` vignette, compiled 12 May 2026. Mouse gastrulation atlas
from Pijuan-Sala et al. 2019, subset to 8 samples, 4 at stage E7.0 and 4 at E7.5
(29,452 genes × 7,558 cells), so the contrast is developmental time.

Milo works on KNN-graph neighbourhoods rather than on cluster labels, so it
detects shifts within a continuum that a cluster-level test would dilute. That
pairs naturally with theme 1. It puts `sequencing.batch` into the design matrix
as a technical covariate, so the design-matrix idea carries straight over from
2.a. Workflow: Milo object, KNN graph, define neighbourhoods, count cells per
neighbourhood, design, neighbourhood connectivity, test with an edgeR
negative-binomial GLM, spatial FDR, then markers of DA populations.

[3_b_composition_milo.html](wed_morn_tutorials/3_b_composition_milo.html) ·
[3_b_composition_milo_local.qmd](wed_morn_tutorials/3_b_composition_milo_local.qmd)
Source: https://bioconductor.org/packages/release/bioc/vignettes/miloR/inst/doc/milo_gastrulation.html
Page title: "Differential abundance testing with Milo - Mouse gastrulation example"
Method: Dann et al. 2022, "Differential abundance testing on single-cell data
using k-nearest neighbor graphs", Nature Biotechnology,
https://doi.org/10.1038/s41587-021-01033-z
Dataset: Pijuan-Sala et al. 2019, "A single-cell molecular map of mouse
gastrulation and early organogenesis", Nature,
https://doi.org/10.1038/s41586-019-0933-9
**See the pre-download warning at the top of this file. This is the tutorial
most likely to break the room.**

3.b.i Shorter toy version on simulated data, and shows conversion into a Milo
object from AnnData and from Seurat: [Differential abundance testing with Milo](https://bioconductor.org/packages/release/bioc/vignettes/miloR/inst/doc/milo_demo.html)

3.b.ii Mixed-effect models, for repeated samples per donor. Probably beyond
scope for a morning: [Mixed effect models for Milo DA testing](https://bioconductor.org/packages/release/bioc/vignettes/miloR/inst/doc/milo_glmm.html)

3.b.iii Alternatives worth naming in passing, both test cluster-level
proportions rather than graph neighbourhoods. `propeller` is the easier one to
teach, one function call on a Seurat or SingleCellExperiment object, limma
underneath, but the repo has not been touched since December 2022. `scCODA` is
Python, and its teaching value is the compositionality point, that an apparent
decrease in one cell type can be an artifact of a real increase in another.
Phipson et al. 2022, "propeller: testing for differences in cell type
proportions in single cell data", Bioinformatics,
https://doi.org/10.1093/bioinformatics/btac582
Büttner et al. 2021, "scCODA is a Bayesian model for compositional single-cell
data analysis", Nature Communications,
https://doi.org/10.1038/s41467-021-27150-6

---

# Not renumbered

`wed_morn_tutorials/integration_mapping.html` was not in the renaming scheme, so
it kept its name and has no `.qmd`. It covers mapping and annotating query
datasets, which 3.a already does as a prerequisite to its composition analysis.
Fold it into 3.a, promote it to its own numbered slot, or drop it.
Source: https://satijalab.org/seurat/articles/integration_mapping
