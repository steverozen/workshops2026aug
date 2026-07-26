#!/usr/bin/env Rscript
#
# test_tutorials.R
#
# Render every workshop tutorial .qmd and report which ones render cleanly.
#
# This is the pre-workshop smoke test. It answers one question: does each
# tutorial run end to end, on this machine, against the data that
# find_data_dir() resolves to? It is not a correctness check on the analyses.
#
# Each .qmd is rendered in a separate `quarto render` process, so one failure
# cannot take down the run and memory is released between tutorials. Output of
# each render goes to its own log file, and the .html plus its _files/ sidecar
# are moved into the output directory rather than left beside the .qmd.
#
# Usage:
#   Rscript slides/test_tutorials.R                       # render everything
#   Rscript slides/test_tutorials.R --list                # show what would run
#   Rscript slides/test_tutorials.R --only pbmc3k         # one tutorial
#   Rscript slides/test_tutorials.R --skip atac,visiumhd  # all but these
#   Rscript slides/test_tutorials.R --days wed            # Wednesday only
#
# Exit status is 0 only if every tutorial that was attempted rendered.

suppressPackageStartupMessages(library(argparser))

p <- arg_parser(
  paste(
    "Render the workshop tutorial .qmd files and report pass/fail per file.",
    "Run from the repository root."
  )
)
p <- add_argument(
  p,
  "--days",
  help = "Regex matched against the session directory, e.g. 'wed' or 'tues|wed'",
  default = "tues|wed"
)
p <- add_argument(
  p,
  "--only",
  help = "Render only tutorials whose path contains this substring",
  default = ""
)
p <- add_argument(
  p,
  "--skip",
  help = "Comma-separated substrings. Any tutorial whose path matches one is skipped",
  default = ""
)
p <- add_argument(
  p,
  "--outdir",
  help = "Directory for logs, rendered .html, and the summary",
  default = "gitignore/tutorial_tests"
)
p <- add_argument(
  p,
  "--timeout-min",
  help = "Kill a render that exceeds this many minutes and mark it TIMEOUT",
  default = 90
)
p <- add_argument(
  p,
  "--list",
  flag = TRUE,
  help = "List the tutorials that would be rendered, then exit"
)
args <- parse_args(p)

# ---------------------------------------------------------------- discovery --

repo_root <- normalizePath(".", mustWork = TRUE)
if (!dir.exists(file.path(repo_root, "slides"))) {
  stop("Run this from the repository root, the one containing slides/.")
}

qmds <- Sys.glob(file.path("slides", "*", "*_tutorials", "*.qmd"))
qmds <- qmds[grepl(args$days, dirname(dirname(qmds)))]

if (nzchar(args$only)) {
  qmds <- qmds[grepl(args$only, qmds, fixed = TRUE)]
}
if (nzchar(args$skip)) {
  patterns <- trimws(strsplit(args$skip, ",")[[1]])
  patterns <- patterns[nzchar(patterns)]
  for (pat in patterns) {
    qmds <- qmds[!grepl(pat, qmds, fixed = TRUE)]
  }
}
qmds <- sort(qmds)

if (length(qmds) == 0L) {
  stop("No .qmd files matched. Check --days, --only, and --skip.")
}

if (args$list) {
  cat(qmds, sep = "\n")
  cat("\n")
  quit(status = 0L)
}

# ------------------------------------------------------------------- set-up --

outdir <- args$outdir
log_dir <- file.path(outdir, "logs")
html_dir <- file.path(outdir, "html")
for (d in c(outdir, log_dir, html_dir)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

# Report which copy of the data the tutorials will see, so a run against the
# wrong data is obvious from the top of the output rather than from a puzzling
# failure halfway down.
source(file.path("slides", "find_data_dir.R"))
data_dir <- tryCatch(find_data_dir(), error = function(e) NA_character_)
message("Data directory: ", ifelse(is.na(data_dir), "NOT FOUND", data_dir))
message("Quarto:         ", system2("quarto", "--version", stdout = TRUE)[1])
message("R:              ", R.version.string)
message("Tutorials:      ", length(qmds))
message("Output:         ", outdir)
message("")

#' Move a rendered .html and its _files/ sidecar out of the source tree
#'
#' Quarto writes output next to the .qmd. Leaving it there dirties the working
#' tree, so collect it under the output directory instead.
#'
#' @param qmd Path to the source .qmd.
#' @param dest Directory to move the outputs into.
#' @return Invisibly, the new .html path, or NA if nothing was produced.
collect_output <- function(qmd, dest) {
  html <- sub("\\.qmd$", ".html", qmd)
  files_dir <- sub("\\.qmd$", "_files", qmd)
  moved <- NA_character_

  if (file.exists(html)) {
    target <- file.path(dest, basename(html))
    if (file.rename(html, target) || file.copy(html, target, overwrite = TRUE)) {
      moved <- target
    }
    if (file.exists(html)) unlink(html)
  }
  if (dir.exists(files_dir)) {
    target <- file.path(dest, basename(files_dir))
    unlink(target, recursive = TRUE)
    if (!file.rename(files_dir, target)) {
      file.copy(files_dir, dest, recursive = TRUE)
    }
    unlink(files_dir, recursive = TRUE)
  }
  invisible(moved)
}

#' Count and sample the chunk errors baked into a rendered document
#'
#' Most of these tutorials set `error: true`, which tells knitr to print a
#' chunk's error into the document and carry on. `quarto render` then exits 0,
#' so a document full of broken chunks looks identical to a clean one from the
#' outside. This reads the .html back and counts the error blocks, which is the
#' only place that information survives.
#'
#' @param html Path to the rendered .html, or NA.
#' @return A list with `n` (error blocks) and `first` (first message, trimmed).
html_errors <- function(html) {
  if (is.na(html) || !file.exists(html)) return(list(n = 0L, first = ""))
  text <- paste(readLines(html, warn = FALSE), collapse = "\n")
  n <- length(gregexpr("cell-output-error", text, fixed = TRUE)[[1]])
  if (!grepl("cell-output-error", text, fixed = TRUE)) n <- 0L
  first <- ""
  if (n > 0L) {
    # (?s) so . spans newlines; the error text is pretty-printed across lines.
    m <- regmatches(
      text,
      regexpr(
        "(?s)cell-output-error.*?<code[^>]*>(.*?)</code>",
        text,
        perl = TRUE
      )
    )
    if (length(m) == 1L) {
      first <- gsub("<[^>]+>", "", m)
      first <- gsub("&#39;", "'", first, fixed = TRUE)
      first <- gsub("&quot;", '"', first, fixed = TRUE)
      first <- gsub("&amp;", "&", first, fixed = TRUE)
      first <- gsub("&gt;", ">", first, fixed = TRUE)
      first <- gsub("&lt;", "<", first, fixed = TRUE)
      first <- sub('^cell-output-error"?>?', "", first)
      first <- trimws(gsub("[[:space:]]+", " ", first))
      first <- substr(first, 1L, 160L)
    }
  }
  list(n = n, first = first)
}

#' Count chunks that are meant to fail
#'
#' A document can set `error: false` at the top and still mark an individual
#' chunk `#| error: true` when the failure is the thing being taught, as
#' 2_a_pseudobulk_de_local.qmd does for the defunct `calculateQCMetrics()` and
#' the archived `aggregate.Matrix()`. Those errors are expected output, so they
#' are subtracted before deciding whether a document is broken.
#'
#' @param qmd Path to the tutorial source.
#' @return Number of chunks carrying a chunk-level `error: true`.
intentional_errors <- function(qmd) {
  if (!file.exists(qmd)) return(0L)
  lines <- readLines(qmd, warn = FALSE)
  sum(grepl("^#\\|\\s*error:\\s*true\\s*$", lines))
}

#' Pull the informative lines out of a failed render log
#'
#' Quarto prints the R condition after a line starting with "Error", and the
#' rest of the log is chunk-by-chunk progress that says nothing about the
#' failure.
#'
#' @param log_file Path to the captured render log.
#' @param n_lines How many lines of context to keep.
#' @return A single string, possibly empty.
first_error <- function(log_file, n_lines = 6L) {
  if (!file.exists(log_file)) return("")
  lines <- readLines(log_file, warn = FALSE)
  # Quarto colors its output, so the error marker is preceded by an ANSI escape
  # and a bare "^Error" pattern never matches.
  lines <- gsub("\033\\[[0-9;]*m", "", lines)
  hit <- grep("^(Error|ERROR:|Quitting from)", lines)
  if (length(hit) == 0L) {
    lines <- tail(lines, n_lines)
  } else {
    lines <- lines[seq(hit[1], min(hit[1] + n_lines - 1L, length(lines)))]
  }
  lines <- trimws(lines)
  paste(lines[nzchar(lines)], collapse = " | ")
}

# ------------------------------------------------------------------ rendering --

results <- data.frame(
  tutorial = character(),
  status = character(),
  minutes = numeric(),
  log = character(),
  detail = character(),
  stringsAsFactors = FALSE
)

timeout_sec <- as.numeric(args$timeout_min) * 60

for (qmd in qmds) {
  label <- sub("\\.qmd$", "", basename(qmd))
  log_file <- file.path(log_dir, paste0(label, ".log"))
  message(sprintf("[%s] rendering ...", label))

  started <- Sys.time()
  # `timeout` sends TERM at the deadline and KILL 30s later, and exits 124 on
  # timeout. Wrapping quarto this way is simpler than a background process plus
  # polling, and it reaps the child R process too.
  status <- system2(
    "timeout",
    args = c(
      "--kill-after=30s",
      sprintf("%ds", as.integer(timeout_sec)),
      "quarto",
      "render",
      shQuote(qmd),
      "--to",
      "html"
    ),
    stdout = log_file,
    stderr = log_file
  )
  minutes <- as.numeric(difftime(Sys.time(), started, units = "mins"))

  html <- collect_output(qmd, html_dir)

  errs <- html_errors(html)
  expected <- intentional_errors(qmd)
  unexpected <- max(0L, errs$n - expected)

  outcome <- if (status == 124L || status == 137L) {
    "TIMEOUT"
  } else if (status != 0L) {
    "FAIL"
  } else if (unexpected > 0L) {
    # Rendered to completion, but with error: true swallowing broken chunks.
    "ERRORS"
  } else {
    "PASS"
  }
  detail <- if (outcome == "PASS") {
    if (is.na(html)) {
      "rendered, but no .html found"
    } else if (errs$n > 0L) {
      sprintf("%s (%d intentional error chunks)", basename(html), errs$n)
    } else {
      basename(html)
    }
  } else if (outcome == "ERRORS") {
    sprintf(
      "%d unexpected error blocks in the .html (%d intentional); first: %s",
      unexpected, expected, errs$first
    )
  } else if (outcome == "TIMEOUT") {
    sprintf("exceeded %s minutes", args$timeout_min)
  } else {
    first_error(log_file)
  }

  message(sprintf("[%s] %s (%.1f min)", label, outcome, minutes))
  if (outcome != "PASS") message("    ", detail)

  results <- rbind(
    results,
    data.frame(
      tutorial = qmd,
      status = outcome,
      minutes = round(minutes, 1),
      log = log_file,
      detail = detail,
      stringsAsFactors = FALSE
    )
  )
}

# ------------------------------------------------------------------ summary --

summary_file <- file.path(outdir, "summary.tsv")
write.table(
  results,
  summary_file,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)

message("")
message(strrep("=", 78))
for (i in seq_len(nrow(results))) {
  message(sprintf(
    "%-8s %6.1f min  %s",
    results$status[i],
    results$minutes[i],
    basename(results$tutorial[i])
  ))
}
message(strrep("=", 78))
message(sprintf(
  "%d passed, %d with chunk errors, %d failed, %d timed out, %.1f min total",
  sum(results$status == "PASS"),
  sum(results$status == "ERRORS"),
  sum(results$status == "FAIL"),
  sum(results$status == "TIMEOUT"),
  sum(results$minutes)
))
message("Summary: ", summary_file)
message("Logs:    ", log_dir)

quit(status = if (all(results$status == "PASS")) 0L else 1L)
