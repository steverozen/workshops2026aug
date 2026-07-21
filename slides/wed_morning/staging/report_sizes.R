#!/usr/bin/env Rscript
#
# Report the size of the staged data set, per tutorial and in total.
#
# Run this after staging to answer the practical questions: how big is the set,
# what will students have to obtain, and does it fit in a git-lfs quota.
#
#   Rscript report_sizes.R
#   Rscript report_sizes.R --csv sizes.csv

suppressPackageStartupMessages(library(argparser))

.this_dir <- local({
  fa <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(fa) == 1L) {
    dirname(normalizePath(sub("^--file=", "", fa), mustWork = FALSE))
  } else {
    of <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
    if (!is.null(of)) dirname(normalizePath(of, mustWork = FALSE)) else getwd()
  }
})
source(file.path(dirname(dirname(.this_dir)), "find_data_dir.R"))

TUTORIALS <- c("1_a_slingshot", "1_b_monocle3", "2_a_pseudobulk_de",
               "2_b_de_vignette", "3_a_composition_covid",
               "3_b_composition_milo")

p <- arg_parser("Report staged data sizes")
p <- add_argument(p, "--csv", default = "",
                  help = "Also write a per-file CSV to this path")
argv <- parse_args(p)

root <- find_data_dir()
cat("Data root: ", root, "\n\n", sep = "")

fmt <- function(bytes) {
  format(structure(bytes, class = "object_size"), units = "auto", digits = 1)
}

rows <- list()
per_tutorial <- data.frame()

for (tut in TUTORIALS) {
  dir <- file.path(root, tut)
  if (!dir.exists(dir)) {
    per_tutorial <- rbind(per_tutorial,
                          data.frame(tutorial = tut, files = 0L, bytes = 0,
                                     status = "directory missing"))
    next
  }

  # SOURCE.md is provenance, not payload. Count it separately so the number a
  # student actually has to download is not inflated by documentation.
  files <- list.files(dir, full.names = TRUE, recursive = TRUE)
  data_files <- files[basename(files) != "SOURCE.md"]

  info <- file.info(data_files)
  bytes <- sum(info$size, na.rm = TRUE)

  for (f in data_files) {
    rows[[length(rows) + 1L]] <- data.frame(
      tutorial = tut,
      file = basename(f),
      bytes = file.size(f),
      size = fmt(file.size(f)))
  }

  per_tutorial <- rbind(per_tutorial,
    data.frame(tutorial = tut,
               files = length(data_files),
               bytes = bytes,
               status = if (length(data_files) == 0L) "EMPTY, not staged" else "staged"))
}

cat("Per file\n")
cat(strrep("-", 72), "\n")
if (length(rows)) {
  per_file <- do.call(rbind, rows)
  per_file <- per_file[order(-per_file$bytes), ]
  for (i in seq_len(nrow(per_file))) {
    cat(sprintf("  %-24s %-38s %10s\n",
                per_file$tutorial[i], per_file$file[i], per_file$size[i]))
  }
  if (nzchar(argv$csv)) {
    write.csv(per_file, argv$csv, row.names = FALSE)
    cat("\nWrote ", argv$csv, "\n", sep = "")
  }
} else {
  cat("  (nothing staged yet)\n")
}

cat("\nPer tutorial\n")
cat(strrep("-", 72), "\n")
for (i in seq_len(nrow(per_tutorial))) {
  cat(sprintf("  %-24s %2d file(s)  %10s   %s\n",
              per_tutorial$tutorial[i],
              per_tutorial$files[i],
              fmt(per_tutorial$bytes[i]),
              per_tutorial$status[i]))
}

total <- sum(per_tutorial$bytes)
cat("\n", strrep("=", 72), "\n", sep = "")
cat(sprintf("TOTAL staged payload: %s\n", fmt(total)))
cat(strrep("=", 72), "\n\n")

## Practical consequences ----------------------------------------------------

gb <- total / 1024^3
n_students <- 20

cat("What this means\n")
cat(strrep("-", 72), "\n")
cat(sprintf("  Per student, one copy:            %s\n", fmt(total)))
cat(sprintf("  %d students, all downloading:     %s\n",
            n_students, fmt(total * n_students)))
cat("\n")
cat("  GitHub free git-lfs allowance is 1 GB storage and 1 GB/month bandwidth.\n")
if (gb > 1) {
  cat(sprintf("  This set is %.1f GB, so free git-lfs is not an option for storage.\n", gb))
} else {
  cat(sprintf("  This set is %.2f GB, so storage fits the free tier.\n", gb))
}
cat(sprintf("  %d students pulling it is %.1f GB of bandwidth, against a 1 GB/month cap.\n",
            n_students, gb * n_students))
cat("\n")
cat("  Realistic distribution options:\n")
cat("    1. USB copies handed out. No quota, no network, works when wifi does not.\n")
cat("    2. Institutional share (Duke Box or OneDrive). Free, but check the\n")
cat("       per-file size cap.\n")
cat("    3. Zenodo. Free, permanent, citable, 50 GB per record. Good if the data\n")
cat("       is redistributable, which needs checking per dataset.\n")
cat("    4. Paid GitHub lfs data packs. Simplest to wire up, costs money, and the\n")
cat("       bandwidth cap bites harder than the storage cap.\n")
cat("\n")
cat("  Check redistribution terms before option 3. These are other people's\n")
cat("  datasets, and some are derived objects rather than the original files.\n")

## Provenance completeness ---------------------------------------------------

cat("\nProvenance check\n")
cat(strrep("-", 72), "\n")
for (tut in TUTORIALS) {
  src <- file.path(root, tut, "SOURCE.md")
  if (!file.exists(src)) {
    cat(sprintf("  %-24s NO SOURCE.md\n", tut))
  } else {
    txt <- readLines(src, warn = FALSE)
    staged <- grepl("^- Staged on:", txt)
    cat(sprintf("  %-24s %d provenance record(s)%s\n", tut, sum(staged),
                if (sum(staged) == 0L) "  <- still just the stub" else ""))
  }
}
