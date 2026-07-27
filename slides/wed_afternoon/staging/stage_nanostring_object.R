#!/usr/bin/env Rscript
#
# stage_nanostring_object.R
#
# Build the CosMx Lung5 Rep1 Seurat object that the Nanostring section of
# seurat5_spatial_vignette_2_local.qmd uses, and stage it beside the flat files.
#
# Same problem, and same reasoning, as stage_vizgen_hippo_fov.R:
#
#   LoadNanostring() builds an sp::SpatialPolygons object from the cell
#   segmentation polygons, which overflows R's pointer protection stack.
#   Measured 2026-07-26 with sp 2.2.3 and SeuratObject 5.4.0:
#
#     Error: protect(): protection stack overflow
#       1. Seurat::LoadNanostring(...)
#       2. SeuratObject::CreateSegmentation(data$segmentations)
#       4. sp::SpatialPolygons(Srl = coords)
#
#   The only fix found is starting R with --max-ppsize=500000, a startup flag
#   that cannot be passed to the rsession that OnDemand RStudio starts for
#   students. So the load happens once here and the object is staged.
#
# The Azimuth annotations and the SCTransform normalization are deliberately
# NOT applied here. They are cheap, they are part of what the tutorial teaches,
# and leaving them in the document keeps the staged object a plain load result.
#
# MUST be run with a raised protection stack:
#
#   Rscript --max-ppsize=500000 slides/wed_afternoon/staging/stage_nanostring_object.R
#
# Writes nanostring_lung5_rep1.rds into the spatial_imaging data directory.
# Reads about 4 GB of flat files and needs several GB of RAM.

suppressPackageStartupMessages(library(Seurat))

source(here::here("slides", "find_data_dir.R"))
data_dir <- find_data_dir("spatial_imaging")

in_dir <- file.path(data_dir, "nanostring_lung5_rep1")
final <- file.path(data_dir, "nanostring_lung5_rep1.rds")
zoom_final <- file.path(data_dir, "nanostring_lung5_rep1_zoom1_fov.rds")

if (!dir.exists(in_dir)) {
  stop("CosMx flat files not found: ", in_dir)
}

#' Save an object through a temporary file
#'
#' An interrupted saveRDS() leaves a truncated .rds where a good one was, which
#' happened to the hippocampus reference on 2026-07-26. Writing to a temporary
#' name and renaming makes the replacement atomic.
#'
#' @param object Object to save.
#' @param path Final path.
#' @return Invisibly, `path`.
save_atomic <- function(object, path) {
  tmp <- paste0(path, ".writing")
  message("Writing ", tmp)
  saveRDS(object, tmp)
  if (!file.rename(tmp, path)) stop("Could not rename ", tmp, " to ", path)
  message("Staged ", path, ", bytes: ", file.size(path))
  invisible(path)
}

message("Loading ", in_dir)
nano.obj <- LoadNanostring(data.dir = in_dir, fov = "lung5.rep1")
message("  ", nrow(nano.obj), " features x ", ncol(nano.obj), " cells")
message("  assays: ", paste(names(nano.obj@assays), collapse = ", "))
message("  FOVs: ", paste(Images(nano.obj), collapse = ", "))

save_atomic(nano.obj, final)

# The zoom1 crop overflows the protection stack for the same reason the load
# does, so it is built here too. Window is the one from the upstream vignette.
message("Cropping the basal-rich zoom1 region")
basal.crop <- Crop(
  nano.obj[["lung5.rep1"]],
  x = c(159500, 164000),
  y = c(8700, 10500)
)
DefaultBoundary(basal.crop) <- "segmentation"
save_atomic(basal.crop, zoom_final)
