# Staging scripts

"Staging" means: download each tutorial's input once, do the slow or fragile
preprocessing once, and save the result into the workshop data directory. Then
nothing touches the network during the workshop.

These scripts are the way the tutorial machine gets prepared. They do not need
the `workshop2026aug_data` git repo, and they do not need GitHub. They write
straight to whatever `find_data_dir()` resolves to.

## Running them

```bash
cd slides/wed_morning/staging

Rscript stage_all.R                              # everything not already staged
Rscript stage_all.R --force                      # re-download everything
Rscript stage_all.R --only 3_b_composition_milo  # just one
Rscript stage_all.R --list                       # names
```

Each script also runs on its own and takes the same flags:

```bash
Rscript stage_3_b_composition_milo.R --force
Rscript stage_1_a_slingshot.R --outdir /shared/workshop_data/1_a_slingshot
```

They are **idempotent**. A file that already exists is skipped unless you pass
`--force`. Re-running the whole set after a partial failure is cheap.

## Where the data lands

By default, the tutorial's subdirectory of whatever `find_data_dir()` resolves
to, which is:

1. `$WORKSHOP2026AUG_DATA`, when set
2. `~/github/workshop2026aug_data`
3. `workshop2026aug_data` beside the code repo

On the tutorial machine, set the environment variable once and everything
follows:

```bash
export WORKSHOP2026AUG_DATA=/shared/workshop_data
echo 'WORKSHOP2026AUG_DATA=/shared/workshop_data' >> ~/.Renviron
```

The `.Renviron` line is the one that matters, because RStudio and Quarto renders
do not inherit your shell environment.

## Verifying afterwards

```r
source("slides/find_data_dir.R")
report_data_dir()                        # the root
report_data_dir("3_b_composition_milo")  # one tutorial
```

Every script appends a provenance record to a `SOURCE.md` in the directory it
writes to, recording the URL, the date, the machine, the R version, and the
preprocessing applied. Read those when a number looks wrong six months from now.

## Status per tutorial

| Tutorial | Automatic | Notes |
|---|---|---|
| `1_a_slingshot` | yes | Large GEO download, then a slow `read.delim()`. Falls back from FTP to HTTPS. |
| `1_b_monocle3` | yes | Needs Python with `anndata`, which comes from the project pixi environment. Doing the conversion here is precisely what spares the students from needing Python at all. Needs `monocle3` in R. |
| `2_a_pseudobulk_de` | yes | Already staged. One Dropbox `.rds`, no preprocessing. |
| `2_b_de_vignette` | yes | Two downloads, not one. `SeuratData` for `ifnb`, plus two demuxlet files from GitHub that supply the donor IDs the pseudobulk section needs. |
| `3_a_composition_covid` | **no** | See below. |
| `3_b_composition_milo` | yes | The big ExperimentHub download. This is the one that would otherwise break the room. |

## `3_a_composition_covid` cannot be fully staged

The upstream vignette reads two objects from paths inside the Satija lab
filesystem:

```r
reference <- readRDS("/brahms/hartmana/vignette_data/pbmc_multimodal_2023.rds")
object    <- readRDS("/brahms/mollag/seurat_v5/vignette_data/merged_covid_object.rds")
```

The **reference** is public, on Zenodo at <https://zenodo.org/record/7779017>.
The script does not guess the direct file URL, because it has changed between
releases. Copy the link from the record page and either drop the file in place
yourself, or set `PBMC_REFERENCE_URL` and re-run.

The **query object**, 1,498,064 cells from 277 donors, has no public URL at all.
It is built by the Seurat BPCells interaction vignette out of three cellxgene
collections. Running the script prints the three collection URLs and the
options, which are, in increasing order of sanity: ask the Satija lab for a
copy, rebuild it yourself, or substitute a smaller COVID PBMC dataset and adapt
the `.qmd`.

The third is probably the right answer for a workshop. The composition analysis
only needs `donor_id`, `disease` with the literal levels `normal` and
`COVID-19`, and a predicted cell type column. A far smaller object teaches the
same point, and the point of that section is that the vignette applies no
statistical test.

## The Python side, for 1_b only

`1_b_monocle3` is the one script that needs Python, to read the AnnData `.h5ad`.
It uses the **project pixi environment** at the repo root, not whatever
`python3` is on PATH, so the Python side is reproducible from `pixi.toml` and
`pixi.lock`. `anndata` is declared there.

```bash
cd /home/steve/github/workshops2026aug
pixi install          # if the env is not built yet
```

Override the interpreter with `RETICULATE_PYTHON` if you ever need a different
one.

**This deliberately does not use reticulate.** reticulate treats a pixi
environment as a conda environment and refuses to start without a conda binary,
which pixi does not ship. Instead, `h5ad_to_mtx.py` exports the AnnData to
`matrix.mtx.gz`, `obs.csv`, and `var.csv`, and the R script reads those back.
The matrix is transposed to genes-by-cells on the Python side, which is the
orientation Monocle and Bioconductor want.

That script runs on its own too, which is useful for debugging:

```bash
pixi run python slides/wed_morning/staging/h5ad_to_mtx.py input.h5ad outdir/
```

Nothing else in the workshop needs Python, and the students never do.

## Packages the scripts themselves need

Each script checks and fails early with a single install line. Between them:

```r
install.packages(c("argparser", "Matrix", "R.utils"))
BiocManager::install(c("MouseGastrulationData", "SingleCellExperiment",
                       "SummarizedExperiment", "Seurat"))
remotes::install_github("satijalab/seurat-data")     # SeuratData
remotes::install_github("cole-trapnell-lab/monocle3") # not on CRAN or Bioconductor
```

On this machine `monocle3` is currently **missing**, and `stage_1_b_monocle3.R`
will stop on that before it downloads anything.
