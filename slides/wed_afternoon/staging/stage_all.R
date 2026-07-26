#!/usr/bin/env Rscript
#
# Run every wed_afternoon staging script in turn.
#
# Each script is idempotent, so re-running this is cheap once things are in
# place. A failure in one tutorial does not stop the others.
#
#   Rscript stage_all.R                          # everything not already staged
#   Rscript stage_all.R --force                  # re-download everything
#   Rscript stage_all.R --only spatial_visium
#   Rscript stage_all.R --list

suppressPackageStartupMessages(library(argparser))

this_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile, mustWork = TRUE)),
  error = function(e) {
    fa <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
    if (length(fa) == 1L) dirname(normalizePath(sub("^--file=", "", fa))) else getwd()
  })

SCRIPTS <- c(
  "spatial_visium",
  "spatial_visium_hd",
  "spatial_visium_hd_segmentation",
  "spatial_imaging")

p <- arg_parser("Stage all wed_afternoon spatial tutorial data")
p <- add_argument(p, "--force", flag = TRUE,
                  help = "Re-download and overwrite files that already exist")
p <- add_argument(p, "--only", default = "",
                  help = "Run just one tutorial, by name")
p <- add_argument(p, "--list", flag = TRUE,
                  help = "List the tutorials and exit")
argv <- parse_args(p)

if (argv$list) {
  cat(paste(SCRIPTS, collapse = "\n"), "\n")
  quit(save = "no")
}

todo <- if (nzchar(argv$only)) {
  if (!argv$only %in% SCRIPTS) {
    stop("Unknown tutorial: ", argv$only, "\nKnown: ",
         paste(SCRIPTS, collapse = ", "), call. = FALSE)
  }
  argv$only
} else {
  SCRIPTS
}

results <- character(0)

for (name in todo) {
  script <- file.path(this_dir, paste0("stage_", name, ".R"))
  cat("\n", strrep("#", 72), "\n# ", name, "\n", strrep("#", 72), "\n", sep = "")

  args <- if (argv$force) "--force" else character(0)
  status <- system2("Rscript", c(shQuote(script), args))

  results[name] <- if (status == 0) "ok" else paste0("FAILED (exit ", status, ")")
}

cat("\n", strrep("=", 72), "\nSummary\n", strrep("=", 72), "\n", sep = "")
for (name in names(results)) {
  cat(sprintf("  %-34s %s\n", name, results[name]))
}

if (any(results != "ok")) {
  cat("\nSome tutorials did not stage cleanly. Scroll up for the reason.\n")
}
cat("\nNote: spatial_imaging stages only its public parts (Xenium, CosMx\n")
cat("annotations). Vizgen and raw CosMx need manual vendor downloads,\n")
cat("printed by that script. The Vizgen download then feeds\n")
cat("stage_vizgen_object.R, which is not part of stage_all.R because it\n")
cat("takes about 45 minutes.\n")

cat("\nNow verify from R:\n")
cat('  source("../../find_data_dir.R"); report_data_dir()\n')
