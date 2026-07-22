# staging_helpers.R
#
# Shared machinery for the stage_*.R scripts.
#
# "Staging" means: download the tutorial's input data once, do the slow
# preprocessing once, and save the result into the workshop data directory, so
# that nothing touches the network during the workshop itself.
#
# Every stage_*.R script sources this file.

suppressPackageStartupMessages({
  library(argparser)
})

# find_data_dir.R lives two directories up, at slides/find_data_dir.R.
# Each stage_*.R script sources this file with an explicit path, so we can work
# out where we are from that.
# Each stage_*.R script defines .this_dir before sourcing this file.
staging_dir <- if (exists(".this_dir", inherits = TRUE)) {
  get(".this_dir", inherits = TRUE)
} else {
  getwd()
}
source(file.path(dirname(dirname(staging_dir)), "find_data_dir.R"))

#' Standard argument parser for a staging script
#'
#' @param name Tutorial directory name, for example `"3_b_composition_milo"`.
#' @param description One-line description shown in `--help`.
#' @return The parsed argument list.
staging_args <- function(name, description) {
  p <- arg_parser(description)
  p <- add_argument(p, "--force", flag = TRUE,
                    help = "Re-download and overwrite files that already exist")
  p <- add_argument(p, "--outdir", default = "",
                    help = paste("Destination directory. Defaults to the",
                                 name, "subdirectory of the workshop data dir"))
  parse_args(p)
}

#' Resolve and create the output directory for a staging script
#'
#' @param name Tutorial directory name.
#' @param argv Parsed arguments from [staging_args()].
#' @return The output directory path.
staging_outdir <- function(name, argv) {
  outdir <- if (nzchar(argv$outdir)) {
    argv$outdir
  } else {
    # check = FALSE because we are about to create it.
    find_data_dir(name, check = FALSE)
  }
  if (!dir.exists(outdir)) {
    dir.create(outdir, recursive = TRUE)
    message("Created ", outdir)
  }
  outdir
}

#' Should we produce this file?
#'
#' Staging is idempotent. A file that already exists is left alone unless
#' `--force` was passed. This matters because these downloads are large and you
#' will run the scripts more than once.
#'
#' @param path Destination file path.
#' @param force Whether `--force` was passed.
#' @return `TRUE` if the caller should go ahead and build the file.
needs_staging <- function(path, force) {
  if (file.exists(path) && !force) {
    message("SKIP  ", basename(path), " already exists (",
            format(structure(file.size(path), class = "object_size"),
                   units = "auto"), "). Use --force to rebuild.")
    return(FALSE)
  }
  TRUE
}

#' Save an object and report what happened
#'
#' @param object The R object to save.
#' @param path Destination `.rds` path.
#' @return Invisibly, `path`.
staging_save <- function(object, path) {
  message("Saving ", path, " ...")
  saveRDS(object, path)
  message("WROTE ", basename(path), "  ",
          format(structure(file.size(path), class = "object_size"),
                 units = "auto"))
  invisible(path)
}

#' Append a provenance record to the directory's SOURCE.md
#'
#' Without this the staged data is unreproducible the moment anyone asks a
#' question about it. Called by every staging script.
#'
#' @param outdir Directory containing the staged files.
#' @param filename Name of the staged file.
#' @param url Where the raw data came from.
#' @param upstream URL of the tutorial that uses it.
#' @param notes Character vector of preprocessing notes.
#' @return Invisibly, the path to SOURCE.md.
write_source_record <- function(outdir, filename, url, upstream, notes = character()) {
  path <- file.path(outdir, "SOURCE.md")
  con <- file(path, open = "a")
  on.exit(close(con))
  writeLines(c(
    "",
    paste0("## ", filename),
    "",
    paste0("- Staged on: ", format(Sys.Date())),
    paste0("- Staged by: ", Sys.info()[["user"]], " on ", Sys.info()[["nodename"]]),
    paste0("- Source URL: ", url),
    paste0("- Upstream tutorial: ", upstream),
    paste0("- R version: ", R.version.string),
    "- Preprocessing:",
    if (length(notes)) paste0("  - ", notes) else "  - none",
    ""
  ), con)
  message("Recorded provenance in ", path)
  invisible(path)
}

#' Path to the project's pixi Python
#'
#' The repo carries a pixi environment at its top level, so staging scripts that
#' need Python use that rather than whatever `python3` happens to be on PATH.
#' Keeping it pinned to pixi means the Python side is reproducible from
#' `pixi.toml` and `pixi.lock`.
#'
#' Set `RETICULATE_PYTHON` to override.
#'
#' @param check When `TRUE`, stop if the interpreter is not there.
#' @return Path to the Python interpreter.
pixi_python <- function(check = TRUE) {

  override <- Sys.getenv("RETICULATE_PYTHON", unset = "")
  if (nzchar(override)) return(override)

  # staging_dir is slides/wed_morning/staging, so the repo root is three up.
  repo_root <- dirname(dirname(dirname(staging_dir)))
  py <- file.path(repo_root, ".pixi", "envs", "default", "bin", "python")

  if (check && !file.exists(py)) {
    stop("No pixi Python at ", py, "\n",
         "Run 'pixi install' at ", repo_root, ", or set RETICULATE_PYTHON.",
         call. = FALSE)
  }
  py
}

#' Run a Python script with the pixi Python
#'
#' We shell out rather than using reticulate. reticulate treats a pixi
#' environment as a conda environment and refuses to start without a conda
#' binary, which pixi does not ship. Handing data between the languages through
#' files sidesteps that, and the conversion stays inspectable and re-runnable on
#' its own.
#'
#' @param script Path to the Python script, usually alongside this file.
#' @param args Character vector of arguments.
#' @return Invisibly `TRUE`, or stops on a non-zero exit status.
run_pixi_python <- function(script, args = character()) {

  py <- pixi_python()
  message("Python: ", py)
  message("Script: ", script)

  status <- system2(py, c(shQuote(script), shQuote(args)))

  if (status != 0) {
    stop("Python script failed with exit status ", status, ".\n",
         "Check that the modules it needs are in the pixi env:\n",
         "  cd ", dirname(dirname(dirname(staging_dir))), " && pixi add <module>",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Check that a module is importable in the pixi Python
#'
#' Fails early with the pixi command to fix it, rather than partway through a
#' download.
#'
#' @param modules Character vector of Python module names.
#' @return Invisibly `TRUE`, or stops.
require_python_modules <- function(modules) {

  py <- pixi_python()
  missing <- character()

  for (m in modules) {
    status <- system2(py, c("-c", shQuote(paste0("import ", m))),
                      stdout = NULL, stderr = NULL)
    if (status != 0) missing <- c(missing, m)
  }

  if (length(missing)) {
    stop("Missing Python modules in the pixi env: ",
         paste(missing, collapse = ", "), "\n",
         "  cd ", dirname(dirname(dirname(staging_dir))),
         " && pixi add ", paste(missing, collapse = " "),
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Check that the packages a staging script needs are actually installed
#'
#' Fails early with one clear list rather than partway through a long download.
#'
#' @param pkgs Character vector of package names.
#' @return Invisibly `TRUE`, or stops.
require_packages <- function(pkgs) {
  # Packages that are neither on CRAN nor Bioconductor, so the generic hint
  # would send you down the wrong path.
  from_github <- c(
    monocle3   = "cole-trapnell-lab/monocle3",
    SeuratData = "satijalab/seurat-data")

  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    lines <- paste0("Missing packages: ", paste(missing, collapse = ", "), "\n",
                    "Install them before staging.\n")

    gh <- intersect(missing, names(from_github))
    other <- setdiff(missing, gh)

    if (length(other)) {
      lines <- paste0(lines, "  BiocManager::install(c(",
                      paste0('"', other, '"', collapse = ", "), "))\n")
    }
    for (g in gh) {
      lines <- paste0(lines, '  remotes::install_github("', from_github[[g]],
                      '")   # ', g, "\n")
    }
    stop(lines, call. = FALSE)
  }
  invisible(TRUE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
