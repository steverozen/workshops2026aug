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
tmp <- paste0(final, ".writing")

if (!dir.exists(in_dir)) {
  stop("CosMx flat files not found: ", in_dir)
}

message("Loading ", in_dir)
nano.obj <- LoadNanostring(data.dir = in_dir, fov = "lung5.rep1")
message("  ", nrow(nano.obj), " features x ", ncol(nano.obj), " cells")
message("  assays: ", paste(names(nano.obj@assays), collapse = ", "))
message("  FOVs: ", paste(Images(nano.obj), collapse = ", "))

# Write to a temporary name and rename, so an interrupted run cannot leave a
# truncated .rds where a good one was.
message("Writing ", tmp)
saveRDS(nano.obj, tmp)
if (!file.rename(tmp, final)) {
  stop("Could not rename ", tmp, " to ", final)
}

message("Staged ", final)
message("  bytes: ", file.size(final))
