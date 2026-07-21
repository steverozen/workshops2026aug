#!/usr/bin/env Rscript
#
# Stage the data for 1_a_slingshot_local.qmd.
#
# Upstream downloads GSE72857_umitab.txt.gz from the NCBI FTP server, gunzips it,
# reads it with read.delim(), and converts it to a sparse matrix. That read is
# slow and memory hungry, so we do it once here and save the sparse matrix.
#
#   Rscript stage_1_a_slingshot.R [--force] [--outdir DIR]

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

NAME     <- "1_a_slingshot"
URL      <- paste0("ftp://ftp.ncbi.nlm.nih.gov/geo/series/GSE72nnn/GSE72857/",
                   "suppl/GSE72857%5Fumitab%2Etxt%2Egz")
UPSTREAM <- paste0("https://nbisweden.github.io/workshop-archive/",
                   "workshop-scRNAseq/2020-01-27/labs/compiled/slingshot/",
                   "slingshot.html")

argv   <- staging_args(NAME, "Stage GSE72857 UMI counts for the Slingshot tutorial")
outdir <- staging_outdir(NAME, argv)

require_packages("Matrix")

target <- file.path(outdir, "GSE72857_umitab.rds")

if (needs_staging(target, argv$force)) {

  gz  <- file.path(tempdir(), "GSE72857_umitab.txt.gz")
  txt <- sub("\\.gz$", "", gz)

  message("Downloading ", URL)
  message("This is a few hundred MB uncompressed. Be patient.")
  # GEO's FTP is unreliable from some networks. https usually works when ftp
  # does not, so fall back rather than failing outright.
  ok <- tryCatch({
    download.file(URL, gz, mode = "wb", quiet = FALSE)
    TRUE
  }, error = function(e) {
    message("FTP failed (", conditionMessage(e), "), retrying over https.")
    FALSE
  })

  if (!ok) {
    https_url <- sub("^ftp://ftp\\.ncbi\\.nlm\\.nih\\.gov",
                     "https://ftp.ncbi.nlm.nih.gov", URL)
    message("Downloading ", https_url)
    download.file(https_url, gz, mode = "wb", quiet = FALSE)
  }

  message("Decompressing ...")
  R.utils::gunzip(gz, destname = txt, overwrite = TRUE, remove = FALSE)

  message("Reading the count table. This is the slow step, several minutes.")
  data <- read.delim(txt, header = TRUE, row.names = 1)
  message("Read ", nrow(data), " genes x ", ncol(data), " cells.")

  comp_matrix <- Matrix::Matrix(as.matrix(data), sparse = TRUE)
  staging_save(comp_matrix, target)

  write_source_record(
    outdir, basename(target), URL, UPSTREAM,
    notes = c(
      "gunzip, then read.delim(header = TRUE, row.names = 1)",
      "converted to a sparse dgCMatrix with Matrix::Matrix(sparse = TRUE)",
      paste0("dimensions: ", nrow(comp_matrix), " genes x ",
             ncol(comp_matrix), " cells"),
      paste0("NOT subsampled. The .qmd takes every fifth cell itself, ",
             "which keeps that step visible to students")))
}

message("\nDone. ", NAME)
