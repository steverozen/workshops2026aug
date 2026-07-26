#!/usr/bin/env Rscript
#
# stage_vizgen_hippo_fov.R
#
# Build the cropped "hippo" field of view used by the Vizgen section of
# seurat5_spatial_vignette_2_local.qmd, and stage it beside the Vizgen object.
#
# Why this exists, rather than the tutorial calling Crop() itself:
#
#   SeuratObject::Crop() on the 83,546-cell s2r1 FOV overflows R's pointer
#   protection stack. Measured 2026-07-26 with sp 2.2.3 and SeuratObject 5.4.0:
#
#     Error: protect(): protection stack overflow
#       1. SeuratObject::Crop(...) -> ... -> sp::SpatialPolygons(...)
#
#   The overflow does not depend on how much the crop keeps. Windows holding
#   2997, 1729, and 832 cells all fail, as do simplify-then-crop,
#   subset-then-crop, and cropping with centroids as the default boundary. The
#   only thing that works is starting R with --max-ppsize=500000, which is a
#   startup flag. Students reach R through OnDemand RStudio, which starts
#   rsession for them with no way to pass it. So the crop is done once here and
#   the result is staged.
#
# MUST be run with a raised protection stack:
#
#   Rscript --max-ppsize=500000 slides/wed_afternoon/staging/stage_vizgen_hippo_fov.R
#
# Writes vizgen_mouse_brain_s2r1_hippo_fov.rds into the spatial_imaging data
# directory. Takes a few minutes and needs several GB of RAM.

suppressPackageStartupMessages(library(Seurat))

source(here::here("slides", "find_data_dir.R"))
data_dir <- find_data_dir("spatial_imaging")

in_file <- file.path(data_dir, "vizgen_mouse_brain_s2r1.rds")
out_file <- file.path(data_dir, "vizgen_mouse_brain_s2r1_hippo_fov.rds")

# The window is the one in the upstream Seurat vignette, kept unchanged so the
# staged FOV matches the figures students see.
crop_x <- c(1750, 3000)
crop_y <- c(3750, 5250)

message("Reading ", in_file)
vizgen.obj <- readRDS(in_file)
message("  cells: ", ncol(vizgen.obj))

message("Cropping to x ", paste(crop_x, collapse = "-"),
        ", y ", paste(crop_y, collapse = "-"))
cropped.coords <- Crop(
  vizgen.obj[["s2r1"]],
  x = crop_x,
  y = crop_y,
  coords = "plot"
)

# Simplify() is done here too, so nothing in the tutorial has to touch the
# polygon machinery that overflowed in the first place.
message("Simplifying segmentations, tol = 3")
cropped.coords[["simplified.segmentations"]] <- Simplify(
  coords = cropped.coords[["segmentation"]],
  tol = 3
)

message("Writing ", out_file)
saveRDS(cropped.coords, out_file)

message("Done. Boundaries: ", paste(Boundaries(cropped.coords), collapse = ", "))
message("Size: ", format(
  structure(file.size(out_file), class = "object_size"),
  units = "auto"
))
