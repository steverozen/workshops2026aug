# Seurat / Signac vignettes, runnable .qmd versions

Runnable Quarto versions of four vignettes:

From <https://satijalab.org/seurat/articles/>:

- `pbmc3k_tutorial.qmd`, the [PBMC 3K guided clustering tutorial](https://satijalab.org/seurat/articles/pbmc3k_tutorial).
- `sctransform_vignette.qmd`, the [SCTransform normalization vignette](https://satijalab.org/seurat/articles/sctransform_vignette).
- `multimodal_vignette.qmd`, the [CITE-seq multimodal vignette](https://satijalab.org/seurat/articles/multimodal_vignette) (CBMC 8K antibody-derived tags + RNA, plus a 10x PBMC 10K protein dataset).

From <https://stuartlab.org/signac/articles/>:

- `pbmc_vignette_atac_seq.qmd`, the [Signac PBMC scATAC-seq vignette](https://stuartlab.org/signac/articles/pbmc_vignette.html) (10x PBMC ATAC v2, with label transfer from a reference scRNA-seq object and GO enrichment of nearest genes).

The PBMC 3K and SCTransform vignettes both use the same 10X Genomics PBMC 3K
dataset. The expression matrix is shipped in this folder as
`pbmc3k_filtered_gene_bc_matrices.tar.gz` and expands to
`filtered_gene_bc_matrices/hg19/`, which is the path both `.qmd` files read
from via `here::here()`.

Render any `.qmd` file in RStudio, Positron, or with
`quarto render <file>.qmd`. Quarto sets the working directory to the folder
that contains the `.qmd`, so relative paths resolve correctly when rendered
from this folder.

## Data files

Small files are shipped in this repository and live next to the `.qmd`s:

- `pbmc3k_filtered_gene_bc_matrices.tar.gz` (PBMC 3K, used by `pbmc3k_tutorial.qmd` and `sctransform_vignette.qmd`).
- `GSE100866_CBMC_8K_13AB_10X-ADT_umi.csv.gz`, `GSE100866_CBMC_8K_13AB_10X-RNA_umi.csv.gz` (CBMC CITE-seq, used by `multimodal_vignette.qmd`).
- `pbmc_10k_protein_v3_filtered_feature_bc_matrix.tar.gz` (10x PBMC 10K + protein, used by the second half of `multimodal_vignette.qmd`; the qmd untars it on first run).
- `10k_pbmc_ATACv2_nextgem_Chromium_Controller_singlecell.csv` (per-cell metadata, used by `pbmc_vignette_atac_seq.qmd`).

The large ATAC files needed by `pbmc_vignette_atac_seq.qmd` (~3 GB total) are
**not** in the repo. Put them under `gitignore/` next to the `.qmd`. There is
a download chunk (`eval: false` by default) at the top of the ATAC qmd, or
fetch manually:

```bash
mkdir -p gitignore && cd gitignore
base=https://cf.10xgenomics.com/samples/cell-atac/2.1.0/10k_pbmc_ATACv2_nextgem_Chromium_Controller
for f in filtered_peak_bc_matrix.h5 fragments.tsv.gz fragments.tsv.gz.tbi; do
  curl -O "${base}/10k_pbmc_ATACv2_nextgem_Chromium_Controller_${f}"
done
# Reference scRNA-seq object used for label transfer (~170 MB):
curl -O https://signac-objects.s3.amazonaws.com/pbmc_10k_v3.rds
```

### ATAC checkpoint .rds files (lecture-time speedup)

The ATAC vignette is slow to render end-to-end (`CreateChromatinAssay`,
`NucleosomeSignal`, `TSSEnrichment`, `GeneActivity`, `FindTransferAnchors`,
`TransferData`). It caches the `pbmc` Seurat object after each of three
expensive phases to `.rds` files under `gitignore/`:

- `gitignore/pbmc_atac_ck1_qc.rds` (post-QC metrics)
- `gitignore/pbmc_atac_ck2_dimred.rds` (post-UMAP + GeneActivity)
- `gitignore/pbmc_atac_ck3_labeled.rds` (post-label-transfer)

After the first full render, subsequent runs (and live lecture demos) load
from these caches and skip the slow recomputation. Delete a checkpoint file
to force the corresponding phase to recompute.

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

### Additionally needed for `multimodal_vignette.qmd`

CRAN packages (`Seurat`, `ggplot2`, `patchwork` are already covered above):

```r
install.packages(c("here", "curl"), repos = "https://cran.rstudio.com/")
```

No Bioconductor packages beyond what `Seurat` already pulls in.

### Additionally needed for `pbmc_vignette_atac_seq.qmd`

CRAN:

```r
install.packages(
  c("Signac", "hdf5r"),
  repos = "https://cran.rstudio.com/"
)
```

Bioconductor (used for annotation, blacklist, and GO enrichment):

```r
BiocManager::install(
  c(
    "GenomicRanges", "GenomeInfoDb", "biovizBase", "ensembldb",
    "AnnotationHub",
    "BSgenome.Hsapiens.UCSC.hg38",
    "clusterProfiler", "org.Hs.eg.db", "enrichplot"
  ),
  update = FALSE
)
```

`presto` (also recommended for the PBMC 3K tutorial) accelerates
`FindMarkers`:

```r
remotes::install_github("immunogenomics/presto", upgrade = "never")
```

## Sanity check

After installation, confirm each package loads:

```r
library(Seurat)
library(Signac)
library(dplyr)
library(patchwork)
library(ggplot2)
library(sctransform)
library(presto)
library(GenomicRanges)
library(GenomeInfoDb)
library(biovizBase)
library(AnnotationHub)
library(clusterProfiler)
library(org.Hs.eg.db)
library(enrichplot)
```


