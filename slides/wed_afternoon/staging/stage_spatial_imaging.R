#!/usr/bin/env Rscript
#
# Stage the data for seurat5_spatial_vignette_2_local.qmd.
#
# Imaging-based spatial platforms. Only some of the data is public:
#
#   Xenium (10x)        public zip, staged automatically
#   CosMx annotations   public on the Seurat server, staged automatically
#   CosMx lung polygons public Dropbox, staged automatically
#
# The RCTD reference (allen_cortex.rds) is a large shared asset staged once at
# the data-dir root, not by this script.
#
# The raw per-platform directories are NOT public in the exact subset the
# vignette uses. Those need vendor registration and are large:
#
#   Vizgen MERSCOPE     info.vizgen.com/mouse-brain-data (registration)
#   Nanostring CosMx    nanostring.com FFPE dataset (raw dir, by request)
#   Akoya CODEX         HuBMAP portal, via Globus
#
# This script stages the public pieces and prints instructions for the rest,
# the same pattern as the COVID composition tutorial.
#
#   Rscript stage_spatial_imaging.R [--force] [--outdir DIR]

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

NAME     <- "spatial_imaging"
UPSTREAM <- "https://satijalab.org/seurat/articles/seurat5_spatial_vignette_2"

XENIUM_URL <- paste0("https://cf.10xgenomics.com/samples/xenium/1.0.2/",
                     "Xenium_V1_FF_Mouse_Brain_Coronal_Subset_CTX_HP/",
                     "Xenium_V1_FF_Mouse_Brain_Coronal_Subset_CTX_HP_outs.zip")
COSMX_ANNOT_URL <- "https://seurat.nygenome.org/vignette_data/spatial_vignette_2/nanostring_data.Rds"
COSMX_POLY_URL  <- paste0("https://www.dropbox.com/scl/fi/aw2qa96jzhbzu670a5lod/",
                          "Lung5_Rep1-polygons.csv",
                          "?rlkey=a86qh3tx7f12bsb5gvf11eykr&dl=1")

argv   <- staging_args(NAME, "Stage the public parts of the imaging spatial tutorial")
outdir <- staging_outdir(NAME, argv)

## 1. Xenium mouse brain subset (public) -------------------------------------

xenium_dir <- file.path(outdir, "xenium_tiny_subset")
if (needs_staging(xenium_dir, argv$force)) {
  zip <- file.path(tempdir(), "xenium.zip")
  message("Downloading ", XENIUM_URL)
  download.file(XENIUM_URL, zip, mode = "wb", quiet = FALSE)
  dir.create(xenium_dir, showWarnings = FALSE, recursive = TRUE)
  utils::unzip(zip, exdir = xenium_dir)
  unlink(zip)
  message("Xenium extracted into ", xenium_dir, ":")
  print(list.files(xenium_dir))
}

## 2. CosMx precomputed annotations and lung polygons (public) ---------------

cosmx_annot <- file.path(outdir, "nanostring_data.Rds")
if (needs_staging(cosmx_annot, argv$force)) {
  message("Downloading ", COSMX_ANNOT_URL)
  download.file(COSMX_ANNOT_URL, cosmx_annot, mode = "wb", quiet = FALSE)
}

cosmx_poly <- file.path(outdir, "Lung5_Rep1-polygons.csv")
if (needs_staging(cosmx_poly, argv$force)) {
  message("Downloading ", COSMX_POLY_URL)
  download.file(COSMX_POLY_URL, cosmx_poly, mode = "wb", quiet = FALSE)
}

write_source_record(
  outdir, "xenium_tiny_subset, nanostring_data.Rds, Lung5_Rep1-polygons.csv",
  XENIUM_URL, UPSTREAM,
  notes = c(
    "Xenium V1 mouse brain coronal subset, 10x public zip, extracted",
    "nanostring_data.Rds precomputed CosMx Azimuth annotations, seurat.nygenome.org",
    "Lung5_Rep1-polygons.csv CosMx cell boundaries, Dropbox",
    "allen_cortex.rds RCTD reference is staged separately at the data-dir root, shared with the Visium tutorial",
    "raw Vizgen / CosMx / Akoya directories are NOT staged, see the manual steps"))

## 3. The three vendor datasets that are not public --------------------------

manual <- c(
  vizgen_mouse_brain = file.path(outdir, "vizgen_mouse_brain"),
  nanostring_lung5_rep1 = file.path(outdir, "nanostring_lung5_rep1"),
  akoya_lymph_node = file.path(outdir, "akoya_lymph_node"))

pending <- manual[!dir.exists(manual)]

if (length(pending)) {
  message("")
  message(strrep("=", 72))
  message("MANUAL STEPS: three platform datasets are not publicly downloadable")
  message(strrep("=", 72))
  message("Each needs vendor registration and is large. Stage them by hand:")
  message("")
  message("Vizgen MERSCOPE mouse brain -> ", manual[["vizgen_mouse_brain"]], "/s2r1/")
  message("  Register at https://info.vizgen.com/mouse-brain-data and download")
  message("  slice 2 replicate 1. LoadVizgen expects the MERSCOPE output files")
  message("  (cell_by_gene.csv, cell_metadata.csv, detected_transcripts.csv, ...).")
  message("")
  message("Nanostring CosMx lung (raw) -> ", manual[["nanostring_lung5_rep1"]], "/")
  message("  From https://nanostring.com/products/cosmx-spatial-molecular-imager/ffpe-dataset/")
  message("  Lung5 Rep1. The precomputed annotations are already staged, so this")
  message("  raw directory is only needed to run LoadNanostring live.")
  message("")
  message("Akoya CODEX lymph node -> ", manual[["akoya_lymph_node"]], "/")
  message("  LN7910_20_008_11022020_reg001_compensated.csv, from the HuBMAP portal")
  message("  via Globus.")
  message("")
  message("If you will not obtain these, present only the Xenium and CosMx")
  message("sections, which are fully staged. The .qmd sections for the missing")
  message("platforms will error at their Load* call, which is expected.")
  message(strrep("=", 72))
}

message("\nDone. ", NAME, " (public parts staged; manual steps above if any)")
