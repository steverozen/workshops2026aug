#!/usr/bin/env Rscript
#
# Stage the data for visiumhd_analysis_vignette_local.qmd.
#
# 10x Visium HD mouse brain (main) and mouse small intestine (second example),
# both public from the 10x CDN, plus a cortex/hippocampus mask CSV and a reduced
# Allen scRNA-seq reference, both on the Satija lab's public Dropbox.
#
#   Rscript stage_spatial_visium_hd.R [--force] [--outdir DIR]

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

NAME     <- "spatial_visium_hd"
UPSTREAM <- "https://satijalab.org/seurat/articles/visiumhd_analysis_vignette"

BRAIN_BASE <- paste0("https://cf.10xgenomics.com/samples/spatial-exp/3.0.0/",
                     "Visium_HD_Mouse_Brain/Visium_HD_Mouse_Brain_")
INTESTINE_BASE <- paste0("https://cf.10xgenomics.com/samples/spatial-exp/3.0.0/",
                         "Visium_HD_Mouse_Small_Intestine/Visium_HD_Mouse_Small_Intestine_")

# binned_outputs holds the 8um and 16um matrices, spatial holds the images.
HD_TARBALLS <- c("binned_outputs.tar.gz", "spatial.tar.gz")

COORDS_URL <- paste0("https://www.dropbox.com/scl/fi/qbs3j1alq33f0qz892ub3/",
                     "cortex-hippocampus_coordinates.csv",
                     "?rlkey=lsxglb15jhjdrircy9lb6n0rd&dl=1")
ALLEN_URL  <- paste0("https://www.dropbox.com/scl/fi/r1mixf4eof2cot891n215/",
                     "allen_scRNAseq_ref.Rds",
                     "?rlkey=ynr6s6wu1efqsjsu3h40vitt7&dl=1")

argv   <- staging_args(NAME, "Stage the 10x Visium HD mouse brain and intestine data")
outdir <- staging_outdir(NAME, argv)

fetch_hd <- function(base, subdir) {
  dir <- file.path(outdir, subdir)
  if (!needs_staging(file.path(dir, "binned_outputs"), argv$force)) return(invisible())
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  for (tb in HD_TARBALLS) {
    url <- paste0(base, tb)
    dest <- file.path(dir, tb)
    message("Downloading ", url)
    message("Visium HD is large, this is the slow part.")
    download.file(url, dest, mode = "wb", quiet = FALSE)
    message("Extracting ", tb)
    utils::untar(dest, exdir = dir)
    unlink(dest)
  }
  message("Extracted into ", dir, ":")
  print(list.files(dir))
}

## 1. Mouse brain, the main dataset ------------------------------------------

fetch_hd(BRAIN_BASE, "visium_hd_mouse_brain")

## 2. Mouse small intestine, the second example ------------------------------

fetch_hd(INTESTINE_BASE, "visium_hd_mouse_small_intestine")

## 3. Mask CSV and Allen reference -------------------------------------------

coords <- file.path(outdir, "cortex-hippocampus_coordinates.csv")
if (needs_staging(coords, argv$force)) {
  message("Downloading ", COORDS_URL)
  download.file(COORDS_URL, coords, mode = "wb", quiet = FALSE)
}

allen <- file.path(outdir, "allen_scRNAseq_ref.Rds")
if (needs_staging(allen, argv$force)) {
  message("Downloading ", ALLEN_URL)
  download.file(ALLEN_URL, allen, mode = "wb", quiet = FALSE)
  obj <- tryCatch(readRDS(allen), error = function(e) {
    unlink(allen)
    stop("allen_scRNAseq_ref.Rds is not a readable .rds. Dropbox may have served",
         " an interstitial page.\n", conditionMessage(e), call. = FALSE)
  })
  message("Allen reference read back OK: ", class(obj)[1])
}

write_source_record(
  outdir, "visium_hd_mouse_brain, visium_hd_mouse_small_intestine, coords, allen ref",
  paste0(BRAIN_BASE, "*"), UPSTREAM,
  notes = c(
    "10x Visium HD mouse brain and mouse small intestine, Space Ranger 3.0.0",
    "binned_outputs (8um + 16um) and spatial tarballs extracted per dataset",
    "cortex-hippocampus_coordinates.csv mask and allen_scRNAseq_ref.Rds from the Satija lab Dropbox",
    "brain is the main example, intestine is the second sketch-clustering example"))

message("\nDone. ", NAME)
message("The .qmd also uses spacexr (RCTD) and SeuratWrappers + Banksy:")
message("  remotes::install_github('dmcable/spacexr')")
message("  remotes::install_github('satijalab/seurat-wrappers')")
