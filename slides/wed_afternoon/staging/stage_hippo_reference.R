#!/usr/bin/env Rscript
#
# stage_hippo_reference.R
#
# Stage mouse_hippocampus_reference.rds, the scRNA-seq reference that
# spatial_vignette_local.qmd uses for label transfer and RCTD.
#
# stage_spatial_visium.R already knows this URL, but the file never landed. It
# is split out here because it needs a step that script does not do: the object
# on the Satija lab Dropbox was written by Seurat 3.1.3 and has no `images`
# slot, so current SeuratObject cannot even call ncol() on it. It has to be run
# through UpdateSeuratObject() once, here, rather than by every student on a
# 1.75 GB object during class.
#
# Writes via a temporary file and renames, so an interrupted run leaves the
# previous good copy in place rather than a truncated .rds. Learned the hard
# way on 2026-07-26, when an in-place rewrite was killed partway and left a
# 579 MB stub where a 1.75 GB object had been.
#
# Usage, from the repository root:
#
#   Rscript slides/wed_afternoon/staging/stage_hippo_reference.R
#
# Needs about 10 GB of RAM and roughly 12 minutes on a home connection.

suppressPackageStartupMessages(library(Seurat))

source(here::here("slides", "find_data_dir.R"))
out_dir <- find_data_dir("spatial_visium")

# dl=1 forces a file download rather than the Dropbox HTML preview page.
url <- "https://www.dropbox.com/s/cs6pii5my4p3ke3/mouse_hippocampus_reference.rds?dl=1"
final <- file.path(out_dir, "mouse_hippocampus_reference.rds")
raw <- paste0(final, ".download")
tmp <- paste0(final, ".updating")

message("Downloading ", url)
status <- system2("curl", c("-fL", "--max-time", "3000", "-o", shQuote(raw),
                            shQuote(url)))
if (status != 0L || !file.exists(raw)) {
  unlink(raw)
  stop("Download failed with status ", status)
}
message("  bytes: ", file.size(raw))

# A Dropbox interstitial page is a few KB of HTML, and readRDS on it errors.
obj <- tryCatch(readRDS(raw), error = function(e) {
  unlink(raw)
  stop("Downloaded file is not a readable .rds. Dropbox may have served an ",
       "interstitial page.\n", conditionMessage(e), call. = FALSE)
})
message("  class: ", class(obj)[1],
        ", written by Seurat ", as.character(obj@version))

message("Running UpdateSeuratObject()")
obj <- UpdateSeuratObject(obj)
message("  now Seurat ", as.character(obj@version),
        ", ", nrow(obj), " features x ", ncol(obj), " cells")
message("  assays: ", paste(names(obj@assays), collapse = ", "))

message("Writing ", tmp)
saveRDS(obj, tmp)

# Only replace the good copy once the new one is complete on disk.
if (!file.rename(tmp, final)) {
  stop("Could not rename ", tmp, " to ", final)
}
unlink(raw)

message("Staged ", final)
message("  bytes: ", file.size(final))
