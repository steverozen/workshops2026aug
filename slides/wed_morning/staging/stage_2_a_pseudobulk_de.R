#!/usr/bin/env Rscript
#
# Stage the data for 2_a_pseudobulk_de_local.qmd.
#
# The easiest one. A single .rds from Dropbox, no preprocessing.
#
#   Rscript stage_2_a_pseudobulk_de.R [--force] [--outdir DIR]

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

NAME     <- "2_a_pseudobulk_de"
URL      <- "https://www.dropbox.com/s/dgdooocb1a03dvk/scRNA-seq_input_data_for_DE.rds?dl=1"
UPSTREAM <- "https://hbctraining.github.io/scRNA-seq/lessons/pseudobulk_DESeq2_scrnaseq.html"

argv   <- staging_args(NAME, "Stage the HBC pseudobulk DE input object")
outdir <- staging_outdir(NAME, argv)

target <- file.path(outdir, "scRNA-seq_input_data_for_DE.rds")

if (needs_staging(target, argv$force)) {

  message("Downloading ", URL)
  # dl=1 makes Dropbox serve the file rather than an HTML preview page.
  download.file(URL, target, mode = "wb", quiet = FALSE)

  # A Dropbox interstitial page is HTML and will happily save as a .rds, so
  # check that we got a real object rather than trusting the exit status.
  obj <- tryCatch(readRDS(target), error = function(e) {
    unlink(target)
    stop("Downloaded file is not a readable .rds. Dropbox probably served an\n",
         "interstitial page. Fetch it in a browser and pass --outdir, or\n",
         "re-run once the link is refreshed.\nOriginal error: ",
         conditionMessage(e), call. = FALSE)
  })
  message("Read back OK: ", class(obj)[1], ", ",
          paste(dim(obj), collapse = " x "))

  write_source_record(
    outdir, basename(target), URL, UPSTREAM,
    notes = c("none, this is the object as distributed",
              paste0("class: ", class(obj)[1]),
              paste0("dimensions: ", paste(dim(obj), collapse = " x "))))
}

message("\nDone. ", NAME)
