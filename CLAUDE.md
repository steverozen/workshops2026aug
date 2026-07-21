# Workshops, August 2026

Teaching materials for the August 2026 bioinformatics workshops. Audience is
students and researchers, so favor runnable, well-commented R.

## Layout
- `slides/` — one directory per session. Start with
  `slides/wed_morning/wed_morning_tutorials.md`, which indexes the Wednesday
  morning tutorials and records what data is staged and what is not.
- `r_graphics/` — the ggplot2 vs tidyplots handout and deck. See
  `r_graphics/CLAUDE.md`, which loads when you work in that directory.

## Workshop tutorials must not download during a session
The `*_local.qmd` tutorials read pre-staged data through `find_data_dir()` in
`slides/find_data_dir.R`. Never reintroduce an upstream download call into one
of them. Data is staged ahead of time by the scripts in
`slides/wed_morning/staging/`, which write to whatever `find_data_dir()`
resolves to.
