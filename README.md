# Seurat vignettes, runnable .qmd versions

Runnable Quarto versions of two Seurat vignettes from
<https://satijalab.org/seurat/articles/>:

- `pbmc3k_tutorial.qmd`, the [PBMC 3K guided clustering tutorial](https://satijalab.org/seurat/articles/pbmc3k_tutorial).
- `sctransform_vignette.qmd`, the [SCTransform normalization vignette](https://satijalab.org/seurat/articles/sctransform_vignette).

Both use the same 10X Genomics PBMC 3K dataset. The expression matrix is
shipped in this folder as `pbmc3k_filtered_gene_bc_matrices.tar.gz` and
expands to `filtered_gene_bc_matrices/hg19/`, which is the path both `.qmd`
files read from via `here::here()`.

Render either `.qmd` file in RStudio, Positron, or with
`quarto render <file>.qmd`. Quarto sets the working directory to the folder
that contains the `.qmd`, so the relative path
`filtered_gene_bc_matrices/hg19/` resolves correctly when rendered from this
folder.

## R packages

### Needed for `pbmc3k_tutorial.qmd`

```r
install.packages(
  c("dplyr", "Seurat", "patchwork", "ggplot2"),
  repos = "https://cran.rstudio.com/"
)
# presto greatly speeds up FindAllMarkers / FindMarkers
install.packages("remotes")
remotes::install_github("immunogenomics/presto", upgrade = "never")
```

Important: you need Seurat v5. Check with `packageVersion("Seurat")`.

### Additionally needed for `sctransform_vignette.qmd`

```r
install.packages("sctransform", repos = "https://cran.rstudio.com/")
install.packages("BiocManager")
BiocManager::install("glmGamPoi", update = FALSE)
```

`glmGamPoi` is not strictly required, but `SCTransform()` is much faster when
it is available.

## Sanity check

After installation, confirm each package loads:

```r
library(Seurat)
library(dplyr)
library(patchwork)
library(ggplot2)
library(sctransform)
library(presto)
```


