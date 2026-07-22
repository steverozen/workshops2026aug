#!/usr/bin/env Rscript
#
# Stage the data for spatial_vignette_local.qmd.
#
# Sequencing-based spatial: 10x Visium mouse brain (stxBrain) and Slide-seq
# mouse hippocampus (ssHippo), both from SeuratData, plus two scRNA-seq
# references the deconvolution and label-transfer sections need.
#
#   Rscript stage_spatial_visium.R [--force] [--outdir DIR]

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

NAME     <- "spatial_visium"
UPSTREAM <- "https://satijalab.org/seurat/articles/spatial_vignette"

# The two scRNA-seq references are on the Satija lab's public Dropbox. dl=1
# forces a file download rather than the HTML preview page.
ALLEN_URL <- "https://www.dropbox.com/s/cuowvm4vrf65pvq/allen_cortex.rds?dl=1"
HIPPO_URL <- "https://www.dropbox.com/s/cs6pii5my4p3ke3/mouse_hippocampus_reference.rds?dl=1"

argv   <- staging_args(NAME, "Stage Visium + Slide-seq data and references")
outdir <- staging_outdir(NAME, argv)

require_packages(c("Seurat", "SeuratData"))

## 1. stxBrain, the Visium mouse brain sections -------------------------------

anterior  <- file.path(outdir, "stxBrain_anterior1.rds")
posterior <- file.path(outdir, "stxBrain_posterior1.rds")

if (needs_staging(anterior, argv$force) || needs_staging(posterior, argv$force)) {
  message("Installing the stxBrain SeuratData package. This downloads.")
  SeuratData::InstallData("stxBrain")

  staging_save(SeuratData::LoadData("stxBrain", type = "anterior1"), anterior)
  staging_save(SeuratData::LoadData("stxBrain", type = "posterior1"), posterior)

  write_source_record(
    outdir, "stxBrain_anterior1.rds / stxBrain_posterior1.rds",
    "SeuratData::InstallData('stxBrain')", UPSTREAM,
    notes = c("anterior1 and posterior1 Visium mouse brain sections",
              paste0("SeuratData version: ",
                     as.character(utils::packageVersion("SeuratData")))))
}

## 2. ssHippo, the Slide-seq v2 hippocampus -----------------------------------

sshippo <- file.path(outdir, "ssHippo.rds")

if (needs_staging(sshippo, argv$force)) {
  message("Installing the ssHippo SeuratData package. This downloads.")
  SeuratData::InstallData("ssHippo")
  staging_save(SeuratData::LoadData("ssHippo"), sshippo)

  write_source_record(
    outdir, "ssHippo.rds", "SeuratData::InstallData('ssHippo')", UPSTREAM,
    notes = "Slide-seq v2 mouse hippocampus")
}

## 3. The two scRNA-seq references --------------------------------------------

for (ref in list(list(path = file.path(outdir, "allen_cortex.rds"), url = ALLEN_URL),
                 list(path = file.path(outdir, "mouse_hippocampus_reference.rds"),
                      url = HIPPO_URL))) {
  if (needs_staging(ref$path, argv$force)) {
    message("Downloading ", ref$url)
    download.file(ref$url, ref$path, mode = "wb", quiet = FALSE)

    obj <- tryCatch(readRDS(ref$path), error = function(e) {
      unlink(ref$path)
      stop("Downloaded ", basename(ref$path), " is not a readable .rds. ",
           "Dropbox may have served an interstitial page.\n", conditionMessage(e),
           call. = FALSE)
    })
    message("Read back OK: ", class(obj)[1])

    write_source_record(
      outdir, basename(ref$path), ref$url, UPSTREAM,
      notes = c("scRNA-seq reference for label transfer / RCTD",
                paste0("class: ", class(obj)[1])))
  }
}

message("\nDone. ", NAME)
message("The vignette also needs spacexr (RCTD) from GitHub:")
message("  remotes::install_github('dmcable/spacexr')")
