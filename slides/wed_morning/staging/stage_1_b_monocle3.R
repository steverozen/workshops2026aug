#!/usr/bin/env Rscript
#
# Stage the data for 1_b_monocle3_local.qmd.
#
# Upstream downloads an AnnData .h5ad from Zenodo and converts it to a Monocle 3
# cell_data_set. The conversion needs Python and anndata. We do it once here and
# ship the .rds, so the student machines need no Python at all.
#
# Python comes from the project's pixi environment rather than from PATH, so the
# Python side is reproducible from pixi.toml and pixi.lock, where anndata is
# declared. Override with RETICULATE_PYTHON if you need to.
#
#   Rscript stage_1_b_monocle3.R [--force] [--outdir DIR]

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

NAME     <- "1_b_monocle3"
URL      <- "https://zenodo.org/record/7455590/files/AnnData_filtered.h5ad"
UPSTREAM <- paste0("https://training.galaxyproject.org/training-material/topics/",
                   "single-cell/tutorials/scrna-case_monocle3-rstudio/tutorial.html")

argv   <- staging_args(NAME, "Stage the Galaxy AnnData input for the Monocle 3 tutorial")
outdir <- staging_outdir(NAME, argv)

require_packages(c("monocle3", "Matrix"))
require_python_modules(c("anndata", "scipy", "pandas"))

target <- file.path(outdir, "AnnData_filtered_cds.rds")

if (needs_staging(target, argv$force)) {

  h5ad <- file.path(tempdir(), "AnnData_filtered.h5ad")

  message("Downloading ", URL)
  download.file(URL, h5ad, mode = "wb", quiet = FALSE)

  # Export to .mtx and .csv with the pixi Python, then read those in R. See
  # run_pixi_python() for why this is not reticulate.
  exchange <- file.path(tempdir(), "h5ad_export")
  run_pixi_python(file.path(.this_dir, "h5ad_to_mtx.py"), c(h5ad, exchange))

  message("Reading the exported matrix into R ...")
  # Already transposed to genes-by-cells by the Python script.
  expression_matrix <- Matrix::readMM(file.path(exchange, "matrix.mtx.gz"))
  expression_matrix <- methods::as(expression_matrix, "CsparseMatrix")

  cell_metadata <- read.csv(file.path(exchange, "obs.csv"),
                            row.names = 1, check.names = FALSE)
  gene_metadata <- read.csv(file.path(exchange, "var.csv"),
                            row.names = 1, check.names = FALSE)

  rownames(expression_matrix) <- rownames(gene_metadata)
  colnames(expression_matrix) <- rownames(cell_metadata)

  stopifnot(nrow(expression_matrix) == nrow(gene_metadata),
            ncol(expression_matrix) == nrow(cell_metadata))

  # Monocle requires a column literally named gene_short_name. Upstream renames
  # the second column of var. Guard that, since an unexpected column layout
  # would otherwise produce a broken object that only fails much later.
  if (!"gene_short_name" %in% colnames(gene_metadata)) {
    if (ncol(gene_metadata) >= 2L) {
      message("Renaming gene metadata column '", colnames(gene_metadata)[2],
              "' to gene_short_name, as upstream does.")
      colnames(gene_metadata)[2] <- "gene_short_name"
    } else {
      message("No second gene metadata column. Using the gene ids as ",
              "gene_short_name.")
      gene_metadata$gene_short_name <- rownames(gene_metadata)
    }
  }

  cds <- monocle3::new_cell_data_set(expression_matrix,
                                     cell_metadata = cell_metadata,
                                     gene_metadata = gene_metadata)
  message("Built cell_data_set: ", nrow(cds), " genes x ", ncol(cds), " cells.")

  staging_save(cds, target)

  write_source_record(
    outdir, basename(target), URL, UPSTREAM,
    notes = c(
      paste0("h5ad_to_mtx.py, run with the project pixi Python at ",
             pixi_python(check = FALSE)),
      "exported to matrix.mtx.gz + obs.csv + var.csv, then read back in R",
      "transposed to genes-by-cells in the Python step, because AnnData stores cells as rows",
      "colnames(gene_metadata)[2] renamed to gene_short_name, which Monocle requires",
      "monocle3::new_cell_data_set()",
      paste0("dimensions: ", nrow(cds), " genes x ", ncol(cds), " cells"),
      "no normalization, clustering, or graph learning. The .qmd does all of that"))
}

message("\nDone. ", NAME)
message("If the .qmd is too slow on the workshop machine, the next things worth")
message("precomputing here are preprocess_cds(num_dim = 210) and graph_test().")
