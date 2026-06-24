# Project: ggplot2 vs. tidyplots teaching materials

A side-by-side teaching deliverable for a bioinformatics audience, contrasting
**ggplot2** and **tidyplots** on a synthetic scRNA-seq-style dataset. Two
artifacts: a runnable handout and a slide deck.

## Files
- `ggplot2_vs_tidyplots.qmd` — the handout. Self-contained: simulates the data
  inline (no external files, no network), then renders four figure types both
  ways with "what to notice" callouts and discussion prompts.
- `ggplot2_vs_tidyplots_slides.pptx` — the deck (8 slides, 16:9 wide). Shows
  code + takeaways, not rendered plots.
- `ggplot2_vs_tidyplots_slides.qmd` — a Quarto reveal.js version of the deck that
  EXECUTES the R chunks and embeds the real rendered figures (code + plot side by
  side per figure). Renders to a single self-contained HTML.
- `slides_build.js` — pptxgenjs source that generates the .pptx deck. The deck is
  code-generated, so edit this and rebuild rather than hand-editing the .pptx.

## What the handout covers
- Synthetic dataset: 4 marker genes (CD3D, MS4A1, LYZ, IL2) x 3 cell types
  (T/B/Monocyte) x 2 conditions (Control/Stimulated), 40 cells per group.
  IL2 is wired to be induced by Stimulation in T cells so there's a real effect.
- Plot 1 - points + mean +/- SEM + significance test (the headline contrast).
- Plot 2 - faceted marker-gene violins.
- Plot 3 - mean-expression heatmap.
- Plot 4 - dot plot (size = % expressing, color = per-gene z-scored mean). The
  one scRNA-seq figure neither package draws natively: requires a dplyr
  precompute, and in tidyplots forces a fall-back to add(ggplot2::geom_point()).

## Build / render

### Handout (Quarto + R)
```bash
quarto render ggplot2_vs_tidyplots.qmd            # HTML
quarto render ggplot2_vs_tidyplots.qmd --to pdf   # print handout
```
R packages: tidyverse, tidyplots, ggbeeswarm, ggsignif.
```r
install.packages(c("tidyverse","tidyplots","ggbeeswarm","ggsignif"))
```

### Slides with embedded graphics (Quarto reveal.js + R)
```bash
quarto render ggplot2_vs_tidyplots_slides.qmd     # -> self-contained .html
```
Same R packages as the handout. Each plot slide executes its chunk and embeds the
rendered figure next to the code. This is the deck to use if you want real plots;
the .pptx is the code-only version.

### Deck (Node + pptxgenjs)
```bash
npm install pptxgenjs react-icons react react-dom sharp
node slides_build.js                              # writes the .pptx
# optional: recompress (pptxgenjs writes an uncompressed zip)
```
Palette and layout live at the top of `slides_build.js` (GG = indigo,
TP = teal, CORAL = accent; LAYOUT_WIDE). The `codeSlide()` helper builds the
four code-comparison slides; edit the line arrays there to change snippets.

## Open items / things to verify on first run
- The handout has NOT been rendered yet (R packages weren't available where it
  was drafted). First `quarto render` may surface small API drift.
- Two tidyplots verbs to confirm against the installed version:
  `add_test_asterisks()` and `adjust_legend_position("none")`. Likely alternates
  if either errors: `add_test_pvalue()` and `remove_legend()`.
- Plot 4 tidyplots block assumes the `color=` mapping set in `tidyplot()` is
  inherited by a `geom_point()` added via `add()`. Confirm this renders the dot
  color correctly; if not, set color inside the added geom's `aes()`.

## Possible next steps (not yet done)
- Render real figures from the .qmd and drop them into the deck (slides currently
  show code + takeaways, not rendered plots).
- Add speaker notes to the deck via `addNotes()` in `slides_build.js`.
- A pseudobulk / DE-style example (muscat or a simple aggregated t-test) as a
  fifth comparison, if you want to extend beyond per-cell plots.

## Style notes
- Audience is students/researchers; favor runnable, well-commented R.
- Keep the "ggplot2 needs extra packages" contrast visible - it's a teaching
  point, not a wart to hide.
- Each package has a fixed accent color across handout and deck (ggplot2 indigo,
  tidyplots teal); preserve that mapping if you add material.

## Moving this to the Linux box
All four files are self-contained; just copy the directory over (or pull from
wherever you've synced outputs) and open Claude Code in it. This file is the
context primer - Claude Code reads it on startup. `git init` first so you have
rollback points before letting it install packages and render.
