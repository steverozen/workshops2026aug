# Workshops, August 2026

Teaching materials for the August 2026 bioinformatics workshops. Audience is
students and researchers, so favor runnable, well-commented R.

## Layout
- `slides/` — one directory per session. Start with
  `slides/wed_morning/wed_morning_tutorials.md`, which indexes the Wednesday
  morning tutorials and records what data is staged and what is not.
- `r_graphics/` — the ggplot2 vs tidyplots handout and deck. See
  `r_graphics/CLAUDE.md`, which loads when you work in that directory.

## Data organization

The workshop data lives at `~/MEGA/workshop_data`, on the internal drive. That
path is also in `WORKSHOP2026AUG_DATA` (set in `~/.Renviron`, `~/.profile`, and
`~/.bashrc`), which is the first candidate `find_data_dir()` checks.

**The data is not going on GitHub.** It is about 39 GB, and several individual
files exceed the 2 GB per-file git-lfs limit on GitHub Pro, for example the
Vizgen `detected_transcripts.csv` (3.05 GB) and the CosMx
`Lung5_Rep1_tx_file.csv` (3.40 GB). Distribution to the workshop machines is by
other means. Do not propose committing the data, adding it to git-lfs, or
upgrading the GitHub plan to hold it.

**The `staging/` scripts are one-off ephemera, not maintained tools.** The goal
is to get each dataset onto `~/MEGA/workshop_data` once and record where it came
from. Do not spend effort making them idempotent, re-runnable, or correct about
state they no longer own. If a staging script has gone stale because data was
moved or pre-built by hand, that is fine and does not need fixing.

**Provenance is the part that must be right.** Every dataset directory carries a
`SOURCE.md` recording the source URL, the download date, and any by-hand steps
(renames, moves, files linked in from elsewhere). When data is staged or
rearranged by hand, append to `SOURCE.md`. That record, not the script, is what
makes the data reproducible.

## Workshop tutorials must not download during a session
The `*_local.qmd` tutorials read pre-staged data through `find_data_dir()` in
`slides/find_data_dir.R`. Never reintroduce an upstream download call into one
of them. Data is staged ahead of time by the scripts in
`slides/wed_morning/staging/`, which write to whatever `find_data_dir()`
resolves to.
