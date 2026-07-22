#!/usr/bin/env Rscript
#
# Stage the data for visiumhd_analysis_cell_segmentations_local.qmd.
#
# 10x Visium HD, Human Kidney FFPE. Fully public from the 10x CDN. Downloads the
# three Space Ranger tarballs plus two loose files and extracts them into the
# standard layout that Load10X_Spatial() expects.
#
#   Rscript stage_spatial_visium_hd_segmentation.R [--force] [--outdir DIR]

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

NAME     <- "spatial_visium_hd_segmentation"
UPSTREAM <- "https://satijalab.org/seurat/articles/visiumhd_analysis_cell_segmentations"

BASE <- paste0("https://cf.10xgenomics.com/samples/spatial-exp/4.0.1/",
               "Visium_HD_Human_Kidney_FFPE/Visium_HD_Human_Kidney_FFPE_")

# The three tarballs extract into binned_outputs/, segmented_outputs/, spatial/.
# The two loose files sit alongside them. metrics_summary.csv and
# molecule_info.h5 are published but the vignette does not read them, so we skip
# them.
TARBALLS <- c("binned_outputs.tar.gz", "segmented_outputs.tar.gz", "spatial.tar.gz")
LOOSE    <- c("barcode_mappings.parquet", "feature_slice.h5")

argv   <- staging_args(NAME, "Stage the 10x Visium HD Human Kidney FFPE dataset")
outdir <- staging_outdir(NAME, argv)

# A sentinel that tells us the extraction already happened.
sentinel <- file.path(outdir, "binned_outputs")

if (needs_staging(sentinel, argv$force)) {

  for (tb in TARBALLS) {
    url <- paste0(BASE, tb)
    dest <- file.path(outdir, tb)
    message("Downloading ", url)
    download.file(url, dest, mode = "wb", quiet = FALSE)
    message("Extracting ", tb)
    utils::untar(dest, exdir = outdir)
    unlink(dest)
  }

  for (lf in LOOSE) {
    url <- paste0(BASE, lf)
    dest <- file.path(outdir, lf)
    message("Downloading ", url)
    download.file(url, dest, mode = "wb", quiet = FALSE)
  }

  message("Extracted contents of ", outdir, ":")
  print(list.files(outdir))

  write_source_record(
    outdir, "Visium_HD_Human_Kidney_FFPE (extracted)", paste0(BASE, "*"), UPSTREAM,
    notes = c(
      "10x Visium HD Human Kidney FFPE, Space Ranger 4.0.1",
      "downloaded binned_outputs, segmented_outputs, spatial tarballs plus barcode_mappings.parquet and feature_slice.h5",
      "extracted into the standard layout, data_dir is passed straight to Load10X_Spatial",
      "did NOT fetch metrics_summary.csv or molecule_info.h5, the vignette does not read them"))
}

message("\nDone. ", NAME)
message("Note: the .qmd calls AzimuthAPI::CloudAzimuth(), which is a network")
message("call. To keep the workshop offline, run the annotation once and stage")
message("the annotated object. See the callout in the .qmd.")
