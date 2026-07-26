# Datasets that must be downloaded by hand

The 10x Genomics files (Visium HD mouse brain, Visium HD human kidney, Xenium
mouse brain) are NOT in this list. They download automatically once `stage_all.R`
is re-run with the raised `download.file` timeout in `staging_helpers.R`.

Only the two imaging platforms below need manual, registered downloads. They
are not public in the exact subset the tutorial uses, and each is large. They
belong under the `spatial_imaging` data directory (the `outdir` that
`stage_spatial_imaging.R` reports), in the subdirectory named for each.

If you will not obtain these, present only the Xenium and CosMx sections, which
are fully staged. The CosMx section of the `.qmd` will error at its
`LoadNanostring` call, which is expected. The Vizgen section is different, see
below, it reads a pre-built object and needs the raw download only if you are
rebuilding that object.

## 1. Vizgen MERSCOPE mouse brain

**Only needed to rebuild `vizgen_mouse_brain_s2r1.rds`.** The tutorial itself
reads that saved object, so if you already have it, you can skip this download
entirely and the Vizgen section runs fine.

- Destination: `<spatial_imaging>/vizgen_mouse_brain/s2r1/`
- Register and download: https://info.vizgen.com/mouse-brain-data
- Take slice 2, replicate 1. `LoadVizgen` expects the MERSCOPE output files
  (`cell_by_gene.csv`, `cell_metadata.csv`, `detected_transcripts.csv`, and a
  `cell_boundaries/` directory of `HDF5` files).
- About 9.5 GiB in total, and **not** part of the workshop distribution.
- Then build the object:

  ```bash
  Rscript stage_vizgen_object.R
  ```

  That takes about 45 minutes and peaks near 16 GiB of memory. It restarts
  itself with `--max-ppsize=500000`, which `LoadVizgen` needs in order not to
  overflow R's pointer protection stack, so run it exactly as written above.
  Output is `<spatial_imaging>/vizgen_mouse_brain_s2r1.rds`, about 405 MB.

## 2. Nanostring CosMx lung (raw)

- Destination: `<spatial_imaging>/nanostring_lung5_rep1/`
- Download: https://nanostring.com/products/cosmx-spatial-molecular-imager/ffpe-dataset/
- Take Lung5 Rep1. The precomputed annotations are already staged, so this raw
  directory is only needed to run `LoadNanostring` live.
