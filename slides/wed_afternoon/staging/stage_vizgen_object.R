#!/usr/bin/env Rscript
#
# Stage the Vizgen MERSCOPE Seurat object for
# seurat5_spatial_vignette_2_local.qmd.
#
# The raw MERSCOPE output for slice 2 replicate 1 is registration-gated, so
# stage_spatial_imaging.R only prints instructions for it. Once those files are
# in place this script does the expensive part once and saves the result, for
# three reasons measured on a 2026-07-25 rehearsal:
#
#   1. LoadVizgen() takes about 38 minutes, nearly all of it parsing the 1242
#      cell_boundaries/*.hdf5 segmentation files single-threaded. That does not
#      fit in a live session.
#   2. It peaks at 15.4 GiB resident, which rules out most attendee laptops.
#   3. It overflows R's pointer protection stack at the polygon-assembly step
#      and dies with "protect(): protection stack overflow" unless R is started
#      with --max-ppsize=500000. That flag can only be set at startup, so a
#      .qmd chunk cannot fix it and an attendee running the tutorial in RStudio
#      has no good way to supply it.
#
# Reading the saved object sidesteps all three. It also means the workshop
# distribution does not need detected_transcripts.csv (3.0 GiB) or
# cell_boundaries/ (6.1 GiB) at all.
#
#   Rscript stage_vizgen_object.R [--force] [--outdir DIR]
#
# The script re-executes itself with --max-ppsize=500000 if it was not started
# with it, so the plain command above is the right one to use.

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

## 0. Re-exec with a bigger protection stack ---------------------------------

# ReadVizgen() assembles roughly 1.2 million segmentation polygons and blows
# through the default protection stack. There is no way to raise it from
# inside a running R, so start a new one with the flag and hand off to it.
if (!any(grepl("^--max-ppsize=", commandArgs(trailingOnly = FALSE)))) {
  message("Restarting with --max-ppsize=500000 (ReadVizgen needs it) ...")
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--max-ppsize=500000",
      shQuote(file.path(.this_dir, "stage_vizgen_object.R")),
      shQuote(commandArgs(trailingOnly = TRUE))))
  quit(save = "no", status = status)
}

source(file.path(.this_dir, "staging_helpers.R"))

NAME     <- "spatial_imaging"
UPSTREAM <- "https://satijalab.org/seurat/articles/seurat5_spatial_vignette_2"
VENDOR   <- "https://info.vizgen.com/mouse-brain-data"

require_packages(c("Seurat", "hdf5r"))

argv   <- staging_args(NAME, "Build the Vizgen MERSCOPE Seurat object")
outdir <- staging_outdir(NAME, argv)

raw_dir <- file.path(outdir, "vizgen_mouse_brain", "s2r1")
out_rds <- file.path(outdir, "vizgen_mouse_brain_s2r1.rds")

## 1. Check the manually staged raw input is present -------------------------

# LoadVizgen() matches these with unanchored patterns, so the long MERSCOPE
# download names work too. The plain names are what MANUAL_DOWNLOADS.md asks
# for and what the .qmd documents, so check for the documented layout.
needed <- c("cell_by_gene.csv", "cell_metadata.csv", "detected_transcripts.csv")

if (!dir.exists(raw_dir)) {
  stop("No raw Vizgen directory at ", raw_dir, "\n",
       "This dataset needs vendor registration. See MANUAL_DOWNLOADS.md, or\n",
       "register at ", VENDOR, " and download slice 2 replicate 1.",
       call. = FALSE)
}

missing <- needed[!file.exists(file.path(raw_dir, needed))]
if (length(missing)) {
  stop("Incomplete Vizgen input in ", raw_dir, "\n",
       "Missing: ", paste(missing, collapse = ", "), "\n",
       "See MANUAL_DOWNLOADS.md for the expected layout.",
       call. = FALSE)
}

boundaries <- list.files(file.path(raw_dir, "cell_boundaries"),
                         pattern = "[.]hdf5$")
if (length(boundaries) == 0L) {
  stop("No cell_boundaries/*.hdf5 under ", raw_dir, "\n",
       "Without them LoadVizgen() cannot build segmentation polygons, and the\n",
       "tutorial's ImageDimPlot() cell borders will not render.",
       call. = FALSE)
}

## 2. Build the object -------------------------------------------------------

if (needs_staging(out_rds, argv$force)) {

  suppressPackageStartupMessages(library(Seurat))

  message("Reading ", raw_dir)
  message("  ", length(boundaries), " segmentation files. This takes roughly ",
          "40 minutes and peaks near 16 GiB.")

  t0 <- Sys.time()

  # Identical to the vignette-load chunk of the .qmd, so the staged object is
  # what the tutorial would have built for itself.
  vizgen.obj <- LoadVizgen(data.dir = raw_dir, fov = "s2r1")

  elapsed <- round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1)

  message("Loaded in ", elapsed, " min: ",
          ncol(vizgen.obj), " cells, ", nrow(vizgen.obj), " features")
  message("Boundaries: ",
          paste(Boundaries(vizgen.obj[["s2r1"]]), collapse = ", "))

  # The tutorial reads all three of these, so fail here rather than on
  # Wednesday if any is absent.
  for (b in c("centroids", "segmentation")) {
    if (!b %in% Boundaries(vizgen.obj[["s2r1"]])) {
      stop("The loaded object has no '", b, "' boundary. The tutorial needs it.",
           call. = FALSE)
    }
  }
  if (is.null(vizgen.obj[["s2r1"]][["molecules"]])) {
    stop("The loaded object has no molecule positions. The tutorial's ",
         "ImageDimPlot(molecules = ...) calls need them.", call. = FALSE)
  }

  staging_save(vizgen.obj, out_rds)

  write_source_record(
    outdir, basename(out_rds), VENDOR, UPSTREAM,
    notes = c(
      "Vizgen MERSCOPE mouse brain receptor showcase, slice 2 replicate 1",
      paste0("Built with LoadVizgen(data.dir = <s2r1>, fov = \"s2r1\") in ",
             elapsed, " min"),
      paste0(ncol(vizgen.obj), " cells x ", nrow(vizgen.obj), " features"),
      "Requires R started with --max-ppsize=500000 to rebuild",
      "256 cells lack polygon information, an upstream data property",
      paste0("Raw input (", raw_dir, ") is not redistributed, it is ",
             "vendor-gated and about 9.5 GiB")))
}

message("\nDone. ", NAME, " Vizgen object at ", out_rds)
