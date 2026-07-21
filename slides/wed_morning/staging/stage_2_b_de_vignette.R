#!/usr/bin/env Rscript
#
# Stage the data for 2_b_de_vignette_local.qmd.
#
# Two network dependencies, not one. The vignette loads ifnb through SeuratData,
# and the pseudobulk section separately pulls demuxlet donor assignments from
# GitHub. Without the second one there are no donor IDs, so AggregateExpression()
# and everything after it fails.
#
#   Rscript stage_2_b_de_vignette.R [--force] [--outdir DIR]

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

NAME     <- "2_b_de_vignette"
UPSTREAM <- "https://satijalab.org/seurat/articles/de_vignette"

DEMUX_BASE <- paste0("https://raw.githubusercontent.com/yelabucsf/",
                     "demuxlet_paper_code/master/fig3/")
DEMUX_FILES <- c("ye1.ctrl.8.10.sm.best", "ye2.stim.8.10.sm.best")

argv   <- staging_args(NAME, "Stage the ifnb dataset and demuxlet donor assignments")
outdir <- staging_outdir(NAME, argv)

require_packages(c("Seurat", "SeuratData"))

## 1. The ifnb Seurat object -------------------------------------------------

target <- file.path(outdir, "ifnb.rds")

if (needs_staging(target, argv$force)) {

  message("Installing the ifnb SeuratData package. This downloads.")
  SeuratData::InstallData("ifnb")

  ifnb <- SeuratData::LoadData("ifnb")
  message("Loaded ifnb: ", nrow(ifnb), " features x ", ncol(ifnb), " cells.")

  # Saved un-normalized on purpose. The .qmd calls NormalizeData() itself,
  # exactly as the vignette does, and students should see that step.
  staging_save(ifnb, target)

  write_source_record(
    outdir, basename(target),
    "SeuratData::InstallData('ifnb') then SeuratData::LoadData('ifnb')",
    UPSTREAM,
    notes = c("none, saved un-normalized as loaded",
              "the .qmd calls NormalizeData() itself, matching the vignette",
              paste0("dimensions: ", nrow(ifnb), " x ", ncol(ifnb)),
              paste0("SeuratData version: ",
                     as.character(utils::packageVersion("SeuratData")))))
}

## 2. The demuxlet donor assignments -----------------------------------------

for (f in DEMUX_FILES) {
  dtarget <- file.path(outdir, f)
  if (needs_staging(dtarget, argv$force)) {
    url <- paste0(DEMUX_BASE, f)
    message("Downloading ", url)
    download.file(url, dtarget, mode = "wb", quiet = FALSE)

    tab <- tryCatch(read.table(dtarget, head = TRUE, stringsAsFactors = FALSE),
                    error = function(e) NULL)
    if (is.null(tab)) {
      unlink(dtarget)
      stop("Downloaded ", f, " is not a readable table. Check the URL, the\n",
           "demuxlet_paper_code repo layout may have changed.", call. = FALSE)
    }
    message("Read back OK: ", nrow(tab), " rows, ", ncol(tab), " columns.")

    write_source_record(
      outdir, f, url, UPSTREAM,
      notes = c("none, raw demuxlet output as distributed",
                "supplies the donor IDs that the pseudobulk section needs",
                paste0("dimensions: ", nrow(tab), " x ", ncol(tab))))
  }
}

message("\nDone. ", NAME)
message("Optional extras for the alternative tests: BiocManager::install(c('DESeq2', 'MAST', 'limma'))")
message("and presto for the fast default wilcox path.")
