#!/usr/bin/env python
"""Export an AnnData .h5ad to files plain R can read.

Run with the project's pixi Python, which is where anndata is declared:

    pixi run python h5ad_to_mtx.py input.h5ad outdir/

Writes into outdir:

    matrix.mtx.gz   the expression matrix, GENES AS ROWS (AnnData stores cells
                    as rows, so this is transposed on the way out, which is the
                    orientation Monocle and Bioconductor want)
    obs.csv         cell metadata, first column is the cell barcode
    var.csv         gene metadata, first column is the gene id

Why this exists rather than reticulate: reticulate treats a pixi environment as
a conda environment and refuses to start without a conda binary, which pixi does
not ship. Handing data between the two languages through files avoids the whole
problem, and it makes the conversion inspectable and re-runnable on its own.
"""

import argparse
import pathlib
import shutil
import subprocess
import sys

import anndata
import scipy.io
import scipy.sparse


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("h5ad", type=pathlib.Path, help="input .h5ad file")
    parser.add_argument("outdir", type=pathlib.Path, help="output directory")
    parser.add_argument(
        "--raw", action="store_true",
        help="Export adata.raw (the raw counts) instead of adata.X. Many "
             "CELLxGENE h5ads store normalized values in X and integer counts "
             "in raw, and Seurat/DESeq2 want the counts.")
    args = parser.parse_args()

    args.outdir.mkdir(parents=True, exist_ok=True)

    print(f"Reading {args.h5ad}", flush=True)
    ann = anndata.read_h5ad(args.h5ad)
    print(f"AnnData: {ann.n_obs} cells x {ann.n_vars} genes", flush=True)

    # Pick the source of the matrix and its gene metadata together, so the two
    # never come from different slots with different gene orders.
    if args.raw:
        if ann.raw is None:
            print("ERROR: --raw given but this AnnData has no .raw slot.",
                  file=sys.stderr, flush=True)
            return 1
        source_X = ann.raw.X
        var = ann.raw.var
        print(f"Using .raw: {source_X.shape[1]} genes", flush=True)
    else:
        source_X = ann.X
        var = ann.var

    # AnnData is cells-by-genes. Transpose to genes-by-cells.
    matrix = source_X.T
    if not scipy.sparse.issparse(matrix):
        matrix = scipy.sparse.csc_matrix(matrix)

    # Write uncompressed with scipy's C-backed mmwrite, which is fast even for
    # tens of millions of nonzeros, then compress with the system gzip. Piping
    # mmwrite straight into Python's gzip is orders of magnitude slower, minutes
    # versus seconds, because the compression runs in the Python layer.
    mtx_plain = args.outdir / "matrix.mtx"
    mtx_path = args.outdir / "matrix.mtx.gz"
    print(f"Writing {mtx_path}  ({matrix.shape[0]} genes x {matrix.shape[1]} cells)",
          flush=True)
    scipy.io.mmwrite(str(mtx_plain), matrix)

    gzip_bin = shutil.which("gzip")
    if gzip_bin:
        # -f overwrites any stale .gz. gzip removes the plain file on success.
        subprocess.run([gzip_bin, "-f", str(mtx_plain)], check=True)
    else:
        # No system gzip. Fall back to Python, slow but correct.
        import gzip as _gzip
        print("  (no system gzip, compressing in Python, this is slow)", flush=True)
        with open(mtx_plain, "rb") as src, _gzip.open(mtx_path, "wb") as dst:
            shutil.copyfileobj(src, dst)
        mtx_plain.unlink()

    obs_path = args.outdir / "obs.csv"
    print(f"Writing {obs_path}  ({ann.obs.shape[1]} columns)", flush=True)
    ann.obs.to_csv(obs_path, index=True, index_label="cell_id")

    var_path = args.outdir / "var.csv"
    print(f"Writing {var_path}  ({var.shape[1]} columns)", flush=True)
    var.to_csv(var_path, index=True, index_label="gene_id")

    print("obs columns:", list(ann.obs.columns), flush=True)
    print("var columns:", list(var.columns), flush=True)
    print("Done.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
