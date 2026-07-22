#!/usr/bin/env Rscript
#
# Stage the data for 3_a_composition_covid_local.qmd.
#
# The upstream vignette maps a 1.5-million-cell COVID PBMC query, which has no
# public download, onto a 162,000-cell reference. We substitute a far smaller
# public COVID PBMC dataset that already carries the annotations the composition
# analysis needs, so no mapping and no reference are required, and the whole
# tutorial stages automatically.
#
# Dataset: Wilk et al. 2020, PBMCs from COVID-19 patients and healthy donors,
# distributed by CELLxGENE. 41,305 cells, 13 donors (7 COVID-19, 6 healthy),
# 26 cell types including IgA/IgG plasmablasts and MAIT cells. The CELLxGENE
# schema guarantees donor_id, disease (levels 'COVID-19' and 'normal'), and
# cell_type, which is exactly what the composition analysis indexes.
#
#   Rscript stage_3_a_composition_covid.R [--force] [--outdir DIR]

# Locate this script, whether run with Rscript or source()d.
.this_dir <- local({
  fa <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(fa) == 1L) {
    dirname(normalizePath(sub("^--file=", "", fa), mustWork = FALSE))
  } else {
    of <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
    if (!is.null(of)) dirname(normalizePath(of, mustWork = FALSE)) else getwd()
  }
})
source(file.path(.this_dir, "staging_helpers.R"))

NAME     <- "3_a_composition_covid"
UPSTREAM <- "https://satijalab.org/seurat/articles/covid_sctmapping"

# Wilk et al. PBMC dataset on CELLxGENE. See the collection for provenance:
# https://cellxgene.cziscience.com/collections/b9fc3d70-5a72-4479-a046-c2cc1ab19efc
DATASET_PAGE <- paste0("https://cellxgene.cziscience.com/collections/",
                       "b9fc3d70-5a72-4479-a046-c2cc1ab19efc")
H5AD_URL <- paste0("https://datasets.cellxgene.cziscience.com/",
                   "b99d7006-3c5f-4c80-bbd9-3bd4b842b782.h5ad")

argv   <- staging_args(NAME, "Stage the Wilk COVID PBMC dataset for the composition tutorial")
outdir <- staging_outdir(NAME, argv)

require_packages(c("Seurat", "Matrix"))
require_python_modules(c("anndata", "scipy", "pandas"))

target <- file.path(outdir, "covid_pbmc_wilk.rds")

if (needs_staging(target, argv$force)) {

  ## 1. Download the h5ad ------------------------------------------------------

  h5ad <- file.path(outdir, "wilk_pbmc.h5ad")
  if (file.exists(h5ad) && !argv$force) {
    message("Reusing existing ", h5ad)
  } else {
    message("Downloading ", H5AD_URL)
    message("About 200 MB from CELLxGENE.")
    download.file(H5AD_URL, h5ad, mode = "wb", quiet = FALSE)
  }

  ## 2. Export raw counts and metadata with the pixi Python --------------------

  # --raw: CELLxGENE stores SCT-normalized values in X and integer counts in
  # raw. Seurat and the pseudobulk DE section both want the counts.
  exchange <- file.path(tempdir(), "wilk_export")
  run_pixi_python(file.path(.this_dir, "h5ad_to_mtx.py"),
                  c("--raw", h5ad, exchange))

  ## 3. Assemble a Seurat object in R -----------------------------------------

  message("Reading the exported matrix into R ...")
  counts <- Matrix::readMM(file.path(exchange, "matrix.mtx.gz"))
  counts <- methods::as(counts, "CsparseMatrix")

  obs <- read.csv(file.path(exchange, "obs.csv"),
                  row.names = 1, check.names = FALSE)
  var <- read.csv(file.path(exchange, "var.csv"),
                  row.names = 1, check.names = FALSE)

  # Gene ids are Ensembl. Use the human-readable symbol as the row name where
  # one exists, which is what students expect to see and what marker lookups
  # use. Fall back to the Ensembl id, and make the result unique.
  gene_names <- if ("feature_name" %in% colnames(var)) {
    ifelse(is.na(var$feature_name) | var$feature_name == "",
           rownames(var), as.character(var$feature_name))
  } else {
    rownames(var)
  }
  rownames(counts) <- make.unique(gene_names)
  colnames(counts) <- rownames(obs)

  stopifnot(nrow(counts) == nrow(var), ncol(counts) == nrow(obs))

  # The composition analysis indexes these by name. Fail here rather than mid
  # workshop if the schema ever changes.
  needed <- c("donor_id", "disease", "cell_type")
  missing <- setdiff(needed, colnames(obs))
  if (length(missing)) {
    stop("Exported metadata is missing required columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  message("Building Seurat object ...")
  object <- Seurat::CreateSeuratObject(counts = counts, meta.data = obs)

  message("Cells: ", ncol(object), "  genes: ", nrow(object))
  message("Disease levels: ", paste(sort(unique(object$disease)), collapse = ", "))
  message("Donors per disease arm:")
  donors_by_arm <- table(object$disease, object$donor_id) > 0
  print(rowSums(donors_by_arm))

  staging_save(object, target)

  # Remove the intermediate h5ad. It is 200 MB and only the .rds is needed at
  # workshop time. Keep it if you passed --outdir for inspection.
  if (!nzchar(argv$outdir)) {
    unlink(h5ad)
    message("Removed the intermediate h5ad. Pass --outdir to keep it.")
  }

  write_source_record(
    outdir, basename(target), H5AD_URL, UPSTREAM,
    notes = c(
      "Wilk et al. 2020 COVID-19 PBMCs, from CELLxGENE",
      paste0("collection: ", DATASET_PAGE),
      "h5ad_to_mtx.py --raw, so raw integer counts, not the SCT-normalized X",
      "gene row names set to feature_name (symbol) where present, else Ensembl id, made unique",
      "assembled into a Seurat object with Seurat::CreateSeuratObject",
      "41,305 cells, 13 donors (7 COVID-19, 6 normal), 26 cell types",
      "substitutes for the upstream 1.5M-cell query, which has no public download",
      "Wilk et al. 2020, Nature Medicine, https://doi.org/10.1038/s41591-020-0944-y"))
}

message("\nDone. ", NAME)
