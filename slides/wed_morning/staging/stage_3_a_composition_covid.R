#!/usr/bin/env Rscript
#
# Stage the data for 3_a_composition_covid_local.qmd.
#
# READ THIS BEFORE RUNNING. This tutorial cannot be fully staged automatically.
#
# The vignette reads two objects from paths inside the Satija lab filesystem:
#
#   reference <- readRDS("/brahms/hartmana/vignette_data/pbmc_multimodal_2023.rds")
#   object    <- readRDS("/brahms/mollag/seurat_v5/vignette_data/merged_covid_object.rds")
#
# The reference has a public home on Zenodo, so this script can fetch it.
#
# The 1.5-million-cell merged COVID query object does NOT. There is no public
# URL. It is built by the Seurat BPCells interaction vignette out of three
# cellxgene collections. Getting it means either rebuilding it, which is a
# substantial job in its own right, or asking the Satija lab for a copy.
#
#   Rscript stage_3_a_composition_covid.R [--force] [--outdir DIR]

# Locate this script, whether run with Rscript or source()d.
.this_dir <- local({
  fa <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(fa) == 1L) {
    dirname(normalizePath(sub("^--file=", "", fa), mustWork = FALSE))
  } else {
    of <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
    if (!is.null(of)) dirname(normalizePath(of, mustWork = FALSE)) else getwd()
  }
})
source(file.path(.this_dir, "staging_helpers.R"))

NAME     <- "3_a_composition_covid"
UPSTREAM <- "https://satijalab.org/seurat/articles/covid_sctmapping"

REFERENCE_URL <- "https://zenodo.org/record/7779017"
BPCELLS_VIGNETTE <- "https://satijalab.org/seurat/articles/seurat5_bpcells_interaction_vignette"

argv   <- staging_args(NAME, "Stage the PBMC reference for the COVID composition tutorial")
outdir <- staging_outdir(NAME, argv)

## 1. The PBMC CITE-seq reference --------------------------------------------

ref_target <- file.path(outdir, "pbmc_multimodal_2023.rds")

if (needs_staging(ref_target, argv$force)) {
  message("The PBMC reference is distributed from Zenodo:")
  message("  ", REFERENCE_URL)
  message("")
  message("Zenodo record pages list their files under a /files/ path whose exact")
  message("name has changed between releases, so this script does not guess it.")
  message("Open the record, copy the .rds download link, and either:")
  message("  1. download it into ", outdir, " as pbmc_multimodal_2023.rds, or")
  message("  2. set REFERENCE_DIRECT_URL below and re-run.")
  message("")
  message("The object must retain the spca reduction, the wnn.umap reduction")
  message("model, and the celltype.l1 and celltype.l2 metadata columns.")

  REFERENCE_DIRECT_URL <- Sys.getenv("PBMC_REFERENCE_URL", unset = "")
  if (nzchar(REFERENCE_DIRECT_URL)) {
    message("Downloading ", REFERENCE_DIRECT_URL)
    download.file(REFERENCE_DIRECT_URL, ref_target, mode = "wb", quiet = FALSE)
    write_source_record(
      outdir, basename(ref_target), REFERENCE_DIRECT_URL, UPSTREAM,
      notes = c("none, the reference as distributed",
                paste0("Zenodo record: ", REFERENCE_URL),
                "Hao, Hao et al. 2021, Cell, https://doi.org/10.1016/j.cell.2021.04.048"))
  } else {
    message("PBMC_REFERENCE_URL is not set, so nothing was downloaded.")
  }
}

## 2. The merged COVID query object ------------------------------------------

query_target <- file.path(outdir, "merged_covid_object.rds")

if (!file.exists(query_target)) {
  message("")
  message(strrep("=", 72))
  message("MANUAL STEP REQUIRED: merged_covid_object.rds")
  message(strrep("=", 72))
  message("There is no public download for this file. Upstream reads it from")
  message("  /brahms/mollag/seurat_v5/vignette_data/merged_covid_object.rds")
  message("which is internal to the Satija lab.")
  message("")
  message("Options, roughly in order of effort:")
  message("  1. Ask the Satija lab for a copy.")
  message("  2. Rebuild it by following the BPCells interaction vignette:")
  message("     ", BPCELLS_VIGNETTE)
  message("     It merges three COVID PBMC collections from cellxgene:")
  message("       Ahern:   https://cellxgene.cziscience.com/collections/8f126edf-5405-4731-8374-b5ce11f53e82")
  message("       Jin:     https://cellxgene.cziscience.com/collections/b9fc3d70-5a72-4479-a046-c2cc1ab19efc")
  message("       Yoshida: https://cellxgene.cziscience.com/collections/03f821b4-87be-4ff4-b65a-b5fc00061da7")
  message("     That is 1,498,064 cells from 277 donors. Not a quick job.")
  message("  3. Substitute a smaller COVID PBMC dataset and adapt the .qmd.")
  message("     The composition analysis only needs donor_id, disease, and a")
  message("     predicted cell type column, so a smaller object works fine for")
  message("     teaching the point.")
  message("")
  message("Whichever you choose, the object must carry these metadata columns,")
  message("because the composition analysis indexes them by name:")
  message("  donor_id, disease (with literal levels 'normal' and 'COVID-19'),")
  message("  cell_type, publication")
  message(strrep("=", 72))
}

## 3. Optional: the post-mapping object --------------------------------------

message("")
message("Optional: stage merged_covid_object_mapped.rds to skip the slow")
message("FindTransferAnchors + MapQuery step during the workshop. Run the")
message("mapping section of the .qmd once, then saveRDS the result. It must")
message("carry the ref.umap reduction and the predicted.celltype.l1 and")
message("predicted.celltype.l2 columns.")

message("\nDone. ", NAME, " (with manual steps outstanding, see above)")
