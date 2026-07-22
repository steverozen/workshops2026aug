# Datasets that must be downloaded by hand

The 10x Genomics files (Visium HD mouse brain, Visium HD human kidney, Xenium
mouse brain) are NOT in this list. They download automatically once `stage_all.R`
is re-run with the raised `download.file` timeout in `staging_helpers.R`.

Only the two imaging platforms below need manual, registered downloads. They
are not public in the exact subset the tutorial uses, and each is large. They
belong under the `spatial_imaging` data directory (the `outdir` that
`stage_spatial_imaging.R` reports), in the subdirectory named for each.

If you will not obtain these, present only the Xenium and CosMx sections, which
are fully staged. The `.qmd` sections for the missing platforms will error at
their `Load*` call, which is expected.

## 1. Vizgen MERSCOPE mouse brain

- Destination: `<spatial_imaging>/vizgen_mouse_brain/s2r1/`
- Register and download: https://info.vizgen.com/mouse-brain-data
- Take slice 2, replicate 1. `LoadVizgen` expects the MERSCOPE output files
  (`cell_by_gene.csv`, `cell_metadata.csv`, `detected_transcripts.csv`, ...).

## 2. Nanostring CosMx lung (raw)

- Destination: `<spatial_imaging>/nanostring_lung5_rep1/`
- Download: https://nanostring.com/products/cosmx-spatial-molecular-imager/ffpe-dataset/
- Take Lung5 Rep1. The precomputed annotations are already staged, so this raw
  directory is only needed to run `LoadNanostring` live.
