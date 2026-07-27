# find_data_dir.R
#
# Single point of truth for where the workshop data lives.
#
# Every tutorial .qmd under slides/ sources this file and calls find_data_dir()
# instead of writing a path. That way, moving the data (laptop today, shared
# workshop filesystem in August, cloud bucket if it comes to that) is a one-line
# change here rather than an edit to every tutorial.
#
# The data itself lives in a separate git repo, workshop2026aug_data, which uses
# git-lfs. See its README for the layout.

#' Locate the workshop data directory
#'
#' Resolves the root of the workshop data checkout, then optionally descends
#' into a per-tutorial subdirectory. Resolution order:
#'
#' 1. The `WORKSHOP2026AUG_DATA` environment variable, when set. This is the
#'    hook for the workshop machines. Set it once in `~/.Renviron` and every
#'    tutorial follows, with no edits to any file in this repo.
#' 2. `~/MEGA/workshop_data`, the master copy on the internal drive.
#' 3. `~/github/workshop2026aug_data`, a local checkout, if one exists.
#' 4. `workshop2026aug_data` as a sibling of this code repo, which is what a
#'    student gets if they clone both repos side by side.
#'
#' The first candidate that exists on disk wins.
#'
#' @param subdir Optional tutorial subdirectory, for example
#'   `"3_b_composition_milo"`. When supplied, the returned path points into it.
#' @param check When `TRUE`, stop with an informative error if the resolved
#'   path does not exist. Set to `FALSE` when you want the path in order to
#'   create it.
#'
#' @return A normalized absolute path, as a length-one character vector.
#'
#' @examples
#' \dontrun{
#' find_data_dir()
#' find_data_dir("3_b_composition_milo")
#' readRDS(file.path(find_data_dir("2_a_pseudobulk_de"),
#'                   "scRNA-seq_input_data_for_DE.rds"))
#' }
find_data_dir <- function(subdir = NULL, check = TRUE) {
  candidates <- c(
    Sys.getenv("WORKSHOP2026AUG_DATA", unset = NA_character_),
    # Master copy, on the internal drive.
    path.expand("~/MEGA/workshop_data"),
    path.expand("~/github/workshop2026aug_data"),
    # Sibling of the code repo. this_dir is slides/, so up two levels.
    file.path(
      dirname(dirname(find_data_dir_this_dir())),
      "workshop2026aug_data"
    )
  )
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]

  root <- NULL
  for (cand in candidates) {
    if (dir.exists(cand)) {
      root <- cand
      break
    }
  }

  if (is.null(root)) {
    stop(
      "Could not find the workshop data directory.\n",
      "Looked in:\n  ",
      paste(candidates, collapse = "\n  "),
      "\n",
      "Clone the workshop2026aug_data repo, or set the WORKSHOP2026AUG_DATA\n",
      "environment variable to point at wherever the data actually is.",
      call. = FALSE
    )
  }

  out <- if (is.null(subdir)) root else file.path(root, subdir)

  if (check && !dir.exists(out)) {
    stop(
      "Data directory does not exist: ",
      out,
      "\n",
      "The data root resolved to ",
      root,
      ", so the root is fine and it is\n",
      "the '",
      subdir,
      "' subdirectory that is missing. Either the data has\n",
      "not been downloaded yet, or the checkout is incomplete.",
      call. = FALSE
    )
  }

  normalizePath(out, winslash = "/", mustWork = FALSE)
}

#' Directory containing this file
#'
#' Works whether the file was `source()`d, run through `Rscript`, or knit by
#' Quarto. Falls back to `here::here("slides")` and then to the working
#' directory when the calling context gives us nothing to go on.
#'
#' @return A path, as a length-one character vector.
#' @keywords internal
find_data_dir_this_dir <- function() {
  # source() sets ofile in the calling frames.
  for (i in seq_len(sys.nframe())) {
    ofile <- tryCatch(get("ofile", envir = sys.frame(i)), error = function(e) {
      NULL
    })
    if (is.character(ofile) && length(ofile) == 1L && nzchar(ofile)) {
      return(dirname(normalizePath(ofile, mustWork = FALSE)))
    }
  }

  # Rscript --file=
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) == 1L) {
    return(dirname(normalizePath(
      sub("^--file=", "", file_arg),
      mustWork = FALSE
    )))
  }

  if (requireNamespace("here", quietly = TRUE)) {
    slides <- here::here("slides")
    if (dir.exists(slides)) return(slides)
  }

  getwd()
}

#' Report where the data is, and what is in it
#'
#' Call this in the setup chunk of a tutorial so that the rendered document
#' records which copy of the data produced it. When a student's numbers differ
#' from yours, this is the first thing you will want to see.
#'
#' @param subdir Optional tutorial subdirectory, as in [find_data_dir()].
#' @return Invisibly, the resolved path.
report_data_dir <- function(subdir = NULL) {
  path <- find_data_dir(subdir)
  message("Workshop data directory: ", path)
  files <- list.files(path, recursive = FALSE, full.names = TRUE)
  if (length(files) == 0L) {
    message("  (empty)")
  } else {
    info <- file.info(files)
    for (i in seq_along(files)) {
      message(sprintf(
        "  %-50s %s",
        basename(files[i]),
        if (isTRUE(info$isdir[i])) {
          "<dir>"
        } else {
          format(structure(info$size[i], class = "object_size"), units = "auto")
        }
      ))
    }
  }
  invisible(path)
}

in_data_dir <- function(basename) {
  return(file.path(find_data_dir(), basename))
}
