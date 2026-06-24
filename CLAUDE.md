# Project: ggplot2 vs. tidyplots teaching handout

A side-by-side teaching deliverable for a bioinformatics audience, contrasting
**ggplot2** and **tidyplots** on a synthetic scRNA-seq-style dataset.

## Files
- `ggplot2_vs_tidyplots.qmd` — the handout. Self-contained: simulates the data
  inline (no external files, no network), then renders three figure types both
  ways with "what to notice" callouts.

## What the handout covers
- Synthetic dataset: 4 marker genes (CD3D, MS4A1, LYZ, IL2) × 3 cell types
  (T/B/Monocyte) × 2 conditions (Control/Stimulated), 40 cells per group.
  IL2 is wired to be induced by Stimulation in T cells so there's a real effect.
- Plot 1 — points + mean ± SEM + significance test (the headline contrast).
- Plot 2 — faceted marker-gene violins.
- Plot 3 (bonus) — mean-expression heatmap.

## How to render
```bash
quarto render ggplot2_vs_tidyplots.qmd            # HTML
quarto render ggplot2_vs_tidyplots.qmd --to pdf   # print handout
```
Requires R packages: tidyverse, tidyplots, ggbeeswarm, ggsignif.

## Open items / things to verify
- Two tidyplots verbs to confirm against the *installed* version:
  `add_test_asterisks()` and `adjust_legend_position("none")`. Both are current
  in tidyplots 0.4.x; likely alternates are `add_test_pvalue()` and
  `remove_legend()` if either errors.
- The handout has not been rendered yet (packages weren't available where it was
  drafted) — first run may surface small API drift to fix.

## Possible next steps (not yet done)
- Convert the three comparisons into PowerPoint slides (one figure-pair + code +
  takeaway per slide).
- Add a dot-plot / Seurat `DotPlot`-style example (mean expression + % expressing)
  — the one common scRNA-seq figure neither package makes trivially.

## Style notes
- Audience is students/researchers; favor runnable, well-commented R.
- Keep the ggplot2-needs-extra-packages contrast visible — it's a teaching point,
  not a wart to hide.
