#!/usr/bin/env Rscript
#
# stage_atac_checkpoints.R
#
# Move the scATAC-seq checkpoint objects into the workshop data directory and
# repoint their fragment file references at the staged fragments file.
#
# Why the repointing matters:
#
#   Signac stores the path to the fragments file *inside* the saved object. The
#   checkpoints built on 2026-06-21 carry
#
#     /home/steve/github/cite_and_atac_wkshp/gitignore/
#         10k_pbmc_ATACv2_nextgem_Chromium_Controller_fragments.tsv.gz
#
#   which is a different repository on one laptop. Copying the .rds files to the
#   data directory without fixing that would ship checkpoints that resolve on
#   exactly one machine and fail everywhere else, at the first fragment-based
#   call rather than at load time.
#
#   The staged fragments file is byte-identical to the original (2641500673
#   bytes), so UpdatePath() is enough and the checkpoints do not need rebuilding.
#
# Usage, from the repository root:
#
#   Rscript slides/tues_afternoon/staging/stage_atac_checkpoints.R
#
# Reads from gitignore/, writes to the data directory. Needs roughly 10 GB of
# RAM for the largest checkpoint, so do not run it alongside a tutorial render.

suppressPackageStartupMessages({
  library(Signac)
  library(Seurat)
})

source(here::here("slides", "find_data_dir.R"))
data_dir <- find_data_dir()

fragments_file <- file.path(
  data_dir,
  "10k_pbmc_ATACv2_nextgem_Chromium_Controller_fragments.tsv.gz"
)
if (!file.exists(fragments_file)) {
  stop("Staged fragments file not found: ", fragments_file)
}

checkpoints <- c(
  "pbmc_atac_ck1_qc.rds",
  "pbmc_atac_ck2_dimred.rds",
  "pbmc_atac_ck3_labeled.rds",
  "pbmc_atac_ck4_markers.rds"
)

for (ck in checkpoints) {
  src <- here::here("gitignore", ck)
  dest <- file.path(data_dir, ck)

  if (!file.exists(src)) {
    message("skip ", ck, ", not present in gitignore/")
    next
  }

  message("Reading ", src)
  obj <- readRDS(src)

  # ck4 holds two data frames of marker results, with no fragment references.
  if (inherits(obj, "Seurat")) {
    for (assay in Assays(obj)) {
      if (!inherits(obj[[assay]], "ChromatinAssay")) next
      frags <- Fragments(obj[[assay]])
      if (length(frags) == 0L) next
      for (i in seq_along(frags)) {
        old <- GetFragmentData(frags[[i]], "path")
        message("  ", assay, " fragment ", i, " was: ", old)
        # validate = FALSE: the cell-name check re-reads the whole 2.6 GB file.
        # The file is byte-identical to the one the checkpoint was built from,
        # which is the thing that check would confirm.
        frags[[i]] <- UpdatePath(
          frags[[i]],
          new.path = fragments_file,
          verbose = FALSE
        )
      }
      Fragments(obj[[assay]]) <- NULL
      Fragments(obj[[assay]]) <- frags
      message("  ", assay, " fragments now: ", fragments_file)
    }
  }

  message("Writing ", dest)
  saveRDS(obj, dest)
  rm(obj)
  gc(verbose = FALSE)
}

message("")
message("Staged checkpoints in ", data_dir, ":")
for (ck in checkpoints) {
  f <- file.path(data_dir, ck)
  if (file.exists(f)) {
    message(sprintf(
      "  %-28s %s",
      ck,
      format(structure(file.size(f), class = "object_size"), units = "auto")
    ))
  } else {
    message(sprintf("  %-28s MISSING", ck))
  }
}
