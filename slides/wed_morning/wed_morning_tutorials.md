1 [Differential expression testing](wed_morn_tutorials/de_vignette.html)

1.1 This is better pedagogically, might be stale: [Pseudobulk DESeq2 scRNA-seq](wed_morn_tutorials/pseudobulk_DESeq2_scrnaseq.html)

2 Map COVID PBMC datasets to a healthy reference
[covid_sctmapping.html](wed_morn_tutorials/covid_sctmapping.html)

3. Mapping and annotating query datasets:
[integration_mapping.html](wed_morn_tutorials/integration_mapping.html)

4 Trajectory inference with Slingshot (NBIS workshop-scRNAseq, updated 2026-04-15).
Seurat-based, bone marrow data (~6,688 cells, seven hematopoietic lineages),
Slingshot principal curves plus tradeSeq for DE along pseudotime:
[slingshot_nbis_trajectory.html](wed_morn_tutorials/slingshot_nbis_trajectory.html)
Source: https://nbisweden.github.io/workshop-scRNAseq/labs/seurat/seurat_07_trajectory.html

4.1 Method reference, not a lab: [Slingshot Bioconductor vignette](https://bioconductor.org/packages/release/bioc/vignettes/slingshot/inst/doc/vignette.html)

4.2 Slingshot across two conditions, differential progression (KS test) plus
condition-specific DE: [BioC2020 trajectories workshop](https://kstreet13.github.io/bioc2020trajectories/articles/workshopTrajectories.html)

5 Trajectory inference with Monocle 3 (Galaxy Training Network, ~3 h in R).
AnnData to cell_data_set, MNN batch correction, learn_graph / order_cells,
graph-autocorrelation DE. Note that trajectories are inferred within a single
partition, which is the usual student stumbling block:
[monocle3_galaxy_trajectories.html](wed_morn_tutorials/monocle3_galaxy_trajectories.html)
Source: https://training.galaxyproject.org/training-material/topics/single-cell/tutorials/scrna-case_monocle3-rstudio/tutorial.html

5.1 Official reference: [Constructing single-cell trajectories](https://cole-trapnell-lab.github.io/monocle3/docs/trajectories/)

5.2 Background reading, TSCAN / Slingshot / tradeSeq compared, plus how to pick
the root: [OSCA Advanced Ch. 10](https://bioconductor.org/books/release/OSCA.advanced/trajectory-analysis.html)
