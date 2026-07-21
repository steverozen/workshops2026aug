#!/usr/bin/env Rscript
#
# Stage the data for 3_b_composition_milo_local.qmd.
#
# This is the one that would otherwise break the workshop. EmbryoAtlasData()
# pulls from ExperimentHub, which caches per user, so N students means N
# multi-GB downloads at once. Run this once, ship the .rds, and the workshop
# never touches ExperimentHub.
#
#   Rscript stage_3_b_composition_milo.R [--force] [--outdir DIR]

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

NAME     <- "3_b_composition_milo"
URL      <- "MouseGastrulationData::EmbryoAtlasData() via Bioconductor ExperimentHub"
UPSTREAM <- paste0("https://bioconductor.org/packages/release/bioc/vignettes/",
                   "miloR/inst/doc/milo_gastrulation.html")

# Four samples at E7.5 and four at E7.0, matching the vignette.
SELECT_SAMPLES <- c(2, 3, 6, 4, 10, 14)

argv   <- staging_args(NAME, "Stage the mouse gastrulation atlas subset for the Milo tutorial")
outdir <- staging_outdir(NAME, argv)

require_packages(c("MouseGastrulationData", "SingleCellExperiment", "SummarizedExperiment"))

target <- file.path(outdir, "embryo_atlas_subset.rds")

if (needs_staging(target, argv$force)) {

  message("Fetching samples ", paste(SELECT_SAMPLES, collapse = ", "),
          " from the mouse gastrulation atlas.")
  message("This downloads through ExperimentHub and is the slow, large step.")
  message("ExperimentHub cache: ", tools::R_user_dir("ExperimentHub", "cache"))

  embryo_data <- MouseGastrulationData::EmbryoAtlasData(samples = SELECT_SAMPLES)
  message("Fetched: ", nrow(embryo_data), " genes x ", ncol(embryo_data), " cells.")

  # Drop cells whose batch-corrected PCA is all NA. The vignette does this
  # inline, but it belongs here, it is data cleaning rather than teaching.
  keep <- apply(SingleCellExperiment::reducedDim(embryo_data, "pca.corrected"),
                1, function(x) !all(is.na(x)))
  embryo_data <- embryo_data[, keep]
  message("After dropping all-NA pca.corrected cells: ", ncol(embryo_data), " cells.")

  # These columns are indexed by name in the .qmd. Fail here rather than
  # halfway through a workshop.
  needed <- c("sample", "stage", "sequencing.batch", "celltype")
  missing <- setdiff(needed, colnames(SummarizedExperiment::colData(embryo_data)))
  if (length(missing)) {
    stop("Staged object is missing required colData columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }
  message("colData check passed: ", paste(needed, collapse = ", "))
  print(table(embryo_data$sample, embryo_data$stage))

  staging_save(embryo_data, target)

  write_source_record(
    outdir, basename(target), URL, UPSTREAM,
    notes = c(
      paste0("EmbryoAtlasData(samples = c(", paste(SELECT_SAMPLES, collapse = ", "), "))"),
      "dropped cells whose pca.corrected reduction is entirely NA",
      paste0("dimensions after filtering: ", nrow(embryo_data), " genes x ",
             ncol(embryo_data), " cells"),
      "no UMAP. The .qmd runs runUMAP itself",
      "no Milo object, graph, or neighbourhoods. All of that is the lesson",
      paste0("MouseGastrulationData version: ",
             as.character(utils::packageVersion("MouseGastrulationData"))),
      "Pijuan-Sala et al. 2019, Nature, https://doi.org/10.1038/s41586-019-0933-9"))
}

message("\nDone. ", NAME)
message("If calcNhoodDistance is too slow live, the next thing to precompute")
message("here is the Milo object with buildGraph, makeNhoods, countCells and")
message("calcNhoodDistance already applied.")
