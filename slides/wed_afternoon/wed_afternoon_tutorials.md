# Wednesday afternoon: spatial transcriptomics

Four Seurat spatial vignettes, presented in the order below. The theme moves from
the most familiar platform to the least, and from one measurement paradigm
(sequencing-based) to the other (imaging-based).

> ## !!! PRE-DOWNLOAD ALL DATA BEFORE THE WORKSHOP !!!
>
> **The upstream vignettes fetch large datasets over the network. Spatial data
> is gigabytes, not megabytes. Do not find this out in the room.**
>
> Prepare the tutorial machine with the staging scripts:
>
> ```bash
> cd slides/wed_afternoon/staging
> Rscript stage_all.R
> ```
>
> See `staging/README.md`. The scripts write into whatever `find_data_dir()`
> resolves to, and are idempotent. On the tutorial machine, point them at the
> shared location first:
>
> ```bash
> echo 'WORKSHOP2026AUG_DATA=/shared/workshop_data' >> ~/.Renviron
> ```
>
> Status: three of the four stage fully and automatically. **The imaging
> tutorial (4) stages only its public parts.** Vizgen and raw CosMx need
> vendor registration and are printed as manual steps. Two vignettes also keep a
> network call inside the render (a cloud Azimuth annotation, and GitHub package
> installs); see `staging/README.md`.

## Suggested order, and why

| Order | Tutorial | Platform | Paradigm |
|---|---|---|---|
| 1 | Visium + Slide-seq | 10x Visium, Slide-seq v2 | sequencing-based |
| 2 | Visium HD | 10x Visium HD | sequencing-based |
| 3 | Visium HD cell segmentation | 10x Visium HD | sequencing-based |
| 4 | Imaging platforms | Xenium, MERSCOPE, CosMx | imaging-based |

The logic: start with **standard Visium** (1), which is spot-based and reads like
scRNA-seq with coordinates attached, so it builds directly on the morning's
material. Then **Visium HD** (2), the same platform at much finer resolution,
which introduces binning and sketch-based clustering. Then the **HD cell
segmentation** deep dive (3), which goes from bins to actual cells, a natural
follow-on that only makes sense once HD is understood. Finish with the
**imaging-based platforms** (4), a different measurement paradigm entirely
(molecules imaged in place, not sequenced), which works as a capstone survey of
where the field is going. Sequencing-based first, increasing resolution, then a
paradigm switch at the end.

If time is short, 1 and 4 alone give the two-paradigm contrast. 3 is the most
advanced and the easiest to drop.

## How this directory is organized

Same convention as `wed_morning`. Each tutorial has a downloaded upstream `.html`
for reference and a `_local.qmd` that we run, which reads pre-staged data through
`find_data_dir()` instead of downloading.

| Downloaded reference | Our runnable version | Data subdir |
|---|---|---|
| `wed_after_tutorials/spatial_vignette.html` | `spatial_vignette_local.qmd` | `spatial_visium` |
| `wed_after_tutorials/visiumhd_analysis_vignette.html` | `visiumhd_analysis_vignette_local.qmd` | `spatial_visium_hd` |
| `wed_after_tutorials/visiumhd_analysis_cell_segmentations.html` | `visiumhd_analysis_cell_segmentations_local.qmd` | `spatial_visium_hd_segmentation` |
| `wed_after_tutorials/seurat5_spatial_vignette_2.html` | `seurat5_spatial_vignette_2_local.qmd` | `spatial_imaging` |

The `.html` files are gitignored (they are 287 MB together). The `.qmd` files are
tracked. Supporting files: `slides/find_data_dir.R` (shared, sourced by every
`.qmd`) and `slides/wed_afternoon/staging/`.

**All four `.qmd` files are transcriptions of their upstream vignette, with the
downloads replaced by reads from the data directory. None has been run yet.**
Every chunk is `eval: true` and every document sets `error: true`, so a first
test render lists every failure at once. Read that first render as a punch list.

One deliberate exception: `spatial_vignette_local.qmd` keeps its interactive
`LinkedDimPlot()` chunk at `eval: false`, because it launches a Shiny app that
would hang a non-interactive render.

---

# 1. Visium and Slide-seq

The Seurat "Analysis, visualization, and integration of spatial datasets"
vignette. Sequencing-based spatial: 10x Visium mouse brain (anterior and
posterior sections) and Slide-seq v2 mouse hippocampus. Covers spatially variable
feature detection, label transfer from an scRNA-seq reference, and RCTD
deconvolution.

[spatial_vignette.html](wed_after_tutorials/spatial_vignette.html) ·
[spatial_vignette_local.qmd](wed_after_tutorials/spatial_vignette_local.qmd)
Source: https://satijalab.org/seurat/articles/spatial_vignette
Deconvolution method: Cable et al. 2022, "Robust decomposition of cell type
mixtures in spatial transcriptomics", Nature Biotechnology,
https://doi.org/10.1038/s41587-021-00830-w

Data (all public, staged automatically): `stxBrain` and `ssHippo` from
SeuratData, plus `allen_cortex.rds` and `mouse_hippocampus_reference.rds` from
the Satija lab Dropbox. Needs `spacexr` from GitHub for RCTD.

---

# 2. Visium HD

The Seurat "Analysis of 10x Visium HD data" vignette. The same platform as (1) at
much finer resolution, with data binned at 8 and 16 um. Introduces sketch-based
clustering for the very large bin counts, Banksy tissue domains, and RCTD on HD
bins. Mouse brain is the main example, mouse small intestine the second.

[visiumhd_analysis_vignette.html](wed_after_tutorials/visiumhd_analysis_vignette.html) ·
[visiumhd_analysis_vignette_local.qmd](wed_after_tutorials/visiumhd_analysis_vignette_local.qmd)
Source: https://satijalab.org/seurat/articles/visiumhd_analysis_vignette

Data (public, staged automatically, but large): Visium HD mouse brain and mouse
small intestine from the 10x CDN, plus a cortex/hippocampus mask CSV and a
reduced Allen scRNA-seq reference from Dropbox. Needs `spacexr` and the Banksy
wrapper (`satijalab/seurat-wrappers`) from GitHub.

---

# 3. Visium HD cell segmentation

The Seurat "Visium HD cell segmentation" vignette. A deep dive that goes from
2 um bins to actual segmented single cells, using the segmentation that 10x now
ships with Visium HD. Only worth teaching once (2) has established what HD is.

[visiumhd_analysis_cell_segmentations.html](wed_after_tutorials/visiumhd_analysis_cell_segmentations.html) ·
[visiumhd_analysis_cell_segmentations_local.qmd](wed_after_tutorials/visiumhd_analysis_cell_segmentations_local.qmd)
Source: https://satijalab.org/seurat/articles/visiumhd_analysis_cell_segmentations

Data (fully public, staged automatically): 10x Visium HD Human Kidney FFPE, three
Space Ranger tarballs plus two loose files from the 10x CDN.

**One thing stays network-bound**: the vignette annotates cells with
`AzimuthAPI::CloudAzimuth()`, a cloud service. To run fully offline, annotate
once and stage the annotated object. The `.qmd` flags this in a callout.

---

# 4. Imaging-based platforms

The Seurat "Analysis of image-based spatial data" vignette. A different
measurement paradigm: molecules imaged in place rather than sequenced. Surveys
three platforms, 10x Xenium, Vizgen MERSCOPE, and Nanostring CosMx,
and introduces the `FOV` object model for subcellular coordinates and
segmentations, plus niche and neighborhood analysis.

[seurat5_spatial_vignette_2.html](wed_after_tutorials/seurat5_spatial_vignette_2.html) ·
[seurat5_spatial_vignette_2_local.qmd](wed_after_tutorials/seurat5_spatial_vignette_2_local.qmd)
Source: https://satijalab.org/seurat/articles/seurat5_spatial_vignette_2

**Data is only partly public.** Staged automatically: the Xenium mouse brain
subset (10x), the RCTD reference, and the precomputed CosMx annotations. Manual,
vendor-gated, printed by the staging script: Vizgen MERSCOPE (registration) and
the raw CosMx directory (by request). If you
skip the vendor data, teach the Xenium and CosMx sections, which are complete.
The other sections error at their `Load*` call, which is expected.

---

# Cheat sheet

Seurat command reference, handy to keep open during the session:
https://satijalab.org/seurat/articles/essential_commands

# Open questions from the original notes

- Technology overview slides (Visium vs Visium HD vs Xenium) would help frame the
  four tutorials. Not yet made.
- "Can we translate any of the spatial to scanpy / scverse?" The imaging
  platforms (4) map onto `squidpy` in the Python world, and Visium onto
  `scanpy` + `squidpy`. Worth a slide, not a tutorial rewrite.
