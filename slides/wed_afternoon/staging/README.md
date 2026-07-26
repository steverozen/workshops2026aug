# Staging scripts, wed_afternoon (spatial)

"Staging" means: download each tutorial's input once, ahead of time, into the
workshop data directory, so nothing touches the network during the workshop.
Same design as `slides/wed_morning/staging/`.

## Running them

```bash
cd slides/wed_afternoon/staging

Rscript stage_all.R                       # everything not already staged
Rscript stage_all.R --force               # re-download everything
Rscript stage_all.R --only spatial_visium # just one
Rscript stage_all.R --list                # names
```

Each script also runs standalone with the same flags. They are idempotent: a
file or directory that already exists is skipped unless you pass `--force`. Data
lands in `find_data_dir("<tutorial>")`, which resolves to the USB drive first
(see `slides/find_data_dir.R`). Every script appends provenance to a `SOURCE.md`
in the directory it writes to.

**These are large.** Visium HD and imaging spatial data run to gigabytes. Do not
stage them onto a slow disk or over a slow link the morning of the workshop.

## Status per tutorial

| Tutorial | Auto | Notes |
|---|---|---|
| `spatial_visium` | yes | Visium mouse brain + Slide-seq, both from SeuratData, plus two references from public Dropbox. Fully public. |
| `spatial_visium_hd` | yes | 10x Visium HD mouse brain and small intestine from the 10x CDN, plus a mask CSV and Allen reference from Dropbox. Large. |
| `spatial_visium_hd_segmentation` | yes | 10x Visium HD Human Kidney FFPE, fully public from the 10x CDN. Downloads three tarballs and extracts them. |
| `spatial_imaging` | **partial** | Only some platform data is public. See below. |

## `spatial_imaging` stages only its public parts

The imaging vignette covers four platforms. The data splits into public and
vendor-gated:

**Staged automatically** (public):

- **Xenium** mouse brain subset, a 10x public zip, extracted to
  `xenium_tiny_subset/`.
- **allen_cortex.rds**, the RCTD reference, from the Satija lab Dropbox.
- **CosMx annotations**, `nanostring_data.Rds`, the precomputed Azimuth result
  the CosMx section reads, from the Seurat server.
- **CosMx lung polygons**, from Dropbox.

**Manual, printed by the script** (vendor registration, large):

- **Vizgen MERSCOPE** mouse brain, from `info.vizgen.com/mouse-brain-data`. Only
  needed to rebuild `vizgen_mouse_brain_s2r1.rds` with `stage_vizgen_object.R`,
  since the `.qmd` reads that object rather than calling `LoadVizgen()`.
- **Nanostring CosMx** raw lung directory, by request from Nanostring. Only
  needed to run `LoadNanostring` live, since the annotations are already staged.

If you will not chase the vendor data, teach the Xenium and Vizgen sections,
which are fully staged. The CosMx section in the `.qmd` will error at its
`LoadNanostring` call, which is expected and harmless under `error: true`.

### `stage_vizgen_object.R`

Separate from `stage_all.R`, because it needs the vendor download above and
takes about 45 minutes. It runs `LoadVizgen()` once and saves the result:

```bash
Rscript stage_vizgen_object.R
```

It restarts itself with `--max-ppsize=500000`. `ReadVizgen()` overflows R's
pointer protection stack while assembling roughly 1.2 million segmentation
polygons, and that flag can only be set when R starts, so neither a `.qmd`
chunk nor an `options()` call can work around it. Peak memory is near 16 GiB.
Output is about 405 MB, versus 9.5 GiB of raw input that then does not need to
be distributed.

## Two things that stay network-bound inside the `.qmd`

Staging cannot make these offline, they are cloud API or compile-time calls, and
each `.qmd` flags them in a callout:

- The **Visium HD segmentation** vignette calls `AzimuthAPI::CloudAzimuth()`, a
  cloud annotation service. To run fully offline, annotate once and stage the
  annotated object.
- Several vignettes install **spacexr (RCTD)** and **SeuratWrappers** from
  GitHub, which needs network and compilation. Install those before the
  workshop:

  ```r
  remotes::install_github("dmcable/spacexr")
  remotes::install_github("satijalab/seurat-wrappers")
  ```

## R packages the scripts and tutorials need

```r
install.packages(c("argparser", "Matrix", "arrow", "hdf5r", "sf"))
BiocManager::install("glmGamPoi")                    # speeds up SCTransform
remotes::install_github("satijalab/seurat-data")     # SeuratData
remotes::install_github("dmcable/spacexr")           # RCTD
remotes::install_github("satijalab/seurat-wrappers") # Banksy wrapper
```

`Seurat` (>= 5) itself is assumed already installed. Each script checks its own
R packages and fails early with the right install line rather than dying partway
through a large download.

## Python

Not needed here. Unlike `wed_morning/1_b`, none of these tutorials go through
AnnData, so there is no Python step.
