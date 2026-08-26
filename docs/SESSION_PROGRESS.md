# IRIS3 Development Session Progress

**Last Updated:** 2026-01-15
**Status:** In Progress - Zeisel Dataset Test

---

## Project Overview

Converting IRIS3 from PHP web application to Python CLI with Docker containerization.

### Completed Features

1. **Python CLI Pipeline** (`iris3/`)
   - Pydantic config validation
   - Multi-step pipeline orchestration
   - Parallel MEME/TOMTOM execution
   - Progress reporting with Rich

2. **R Modules** (`r_modules/`)
   - `preprocessing.R` - Seurat-based preprocessing
   - `gene_module.R` - Bicluster to cell type assignment
   - `regulon_scoring.R` - AUCell/WMW scoring
   - `finalize.R` - Consolidated output generation

3. **Seurat Object Input Support** (NEW)
   - Accepts `.rds` and `.qsave` Seurat objects
   - Extracts cell labels from metadata column (configurable via `label_column`)
   - Reuses existing normalization/PCA/UMAP if available

4. **Bug Fixes Completed**
   - TF names all "Unknown" → Fixed MEME output format (-oc instead of -text)
   - Duplicate TF names across cell types → Fixed TOMTOM directory naming collision
   - Added cell type context to TOMTOM output dirs: `tomtom/CT_1_bic_bic1/`

---

## Current Issue: Zeisel Dataset Test

### Problem
Pipeline fails at `gene_module` step with error:
```
Error in assignments[[best_ct]] :
  attempt to select less than one element in integerOneIndex
```

### Root Cause
In `r_modules/gene_module.R`, `which.min(enrich$pvalue)` returns `integer(0)` when all p-values are NA or empty, causing index error.

### Fix Applied (NOT YET TESTED)
File: `r_modules/gene_module.R` (lines 177-201)

```r
for (i in seq_along(blocks$conds)) {
  enrich <- calc_celltype_enrichment(blocks$conds[[i]], cell_labels)

  # Skip if no valid enrichment results
  if (is.null(enrich) || nrow(enrich) == 0 || all(is.na(enrich$pvalue))) {
    next
  }

  min_idx <- which.min(enrich$pvalue)
  if (length(min_idx) == 0) {
    next
  }

  best_ct <- enrich$cell_type[min_idx]
  best_pval <- enrich$pvalue[min_idx]

  if (!is.na(best_pval) && best_pval < pvalue_threshold) {
    # ... assignment logic
  }
}
```

### Next Step
Rebuild Docker image and retest with Zeisel data.

---

## Setup Instructions

### Prerequisites
- Docker Desktop
- The IRIS3 repository at `/Users/wang.13246/Documents/GitHub/IRIS3`

### Build Docker Image
```bash
cd /Users/wang.13246/Documents/GitHub/IRIS3
docker build -t iris3:test .
```

### Test Data Available
1. **Yan dataset** (small, 90 cells) - Working
   - Config: `config/yan_config.yaml`
   - Output: `output/yan_test3/`

2. **Zeisel dataset** (large, 3005 cells) - In Progress
   - Seurat object: `data/zeisel_seurat.rds`
   - Config: `config/zeisel_config.yaml`
   - Output: `output/zeisel/`

---

## Test Commands

### Run Yan Dataset (Quick Test)
```bash
docker run --rm \
  -v "/Users/wang.13246/Documents/GitHub/IRIS3/data:/data" \
  -v "/Users/wang.13246/Documents/GitHub/IRIS3/output/yan_test:/output" \
  iris3:test run /app/config/example_config.yaml -o /output
```

### Run Zeisel Dataset
```bash
docker run --rm \
  -v "/Users/wang.13246/Documents/GitHub/IRIS3/data:/data" \
  -v "/Users/wang.13246/Documents/GitHub/IRIS3/output/zeisel:/output" \
  -v "/Users/wang.13246/Documents/GitHub/IRIS3/config/zeisel_config.yaml:/app/config/config.yaml" \
  iris3:test run /app/config/config.yaml -o /output
```

### Test Seurat Object Input
```bash
docker run --rm \
  -v "/Users/wang.13246/Documents/GitHub/IRIS3/output/yan_test3:/data" \
  -v "/Users/wang.13246/Documents/GitHub/IRIS3/output/seurat_test:/output" \
  -v "/Users/wang.13246/Documents/GitHub/IRIS3/config/seurat_test.yaml:/app/config/config.yaml" \
  iris3:test run /app/config/config.yaml -o /output
```

---

## File Locations

### Key Config Files
- `config/example_config.yaml` - Yan dataset config
- `config/zeisel_config.yaml` - Zeisel dataset config
- `config/seurat_test.yaml` - Seurat object input test

### Key Code Files
- `iris3/pipeline.py` - Main pipeline orchestration
- `iris3/config.py` - Pydantic config models
- `r_modules/preprocessing.R` - Data preprocessing (includes Seurat input)
- `r_modules/gene_module.R` - Gene module assignment (HAS BUG FIX)
- `r_modules/finalize.R` - Output consolidation

### Output Format
Final output is `regulons.tsv` with columns:
- cell_type, regulon_id, tf_name, tf_motif, n_genes, rss
- ras_mean, ras_{celltype1}, ras_{celltype2}, ...
- enrichment_pval, rank, genes (full list)

---

## TODO for Next Session

### Immediate Tasks
1. [DONE] Rebuild Docker image with gene_module.R fix
   - Image ID: `ba34613d9d11`
   - Built: 2026-01-15

2. [ ] Retest Zeisel dataset
   ```bash
   docker run --rm \
     -v "/Users/wang.13246/Documents/GitHub/IRIS3/data:/data" \
     -v "/Users/wang.13246/Documents/GitHub/IRIS3/output/zeisel:/output" \
     -v "/Users/wang.13246/Documents/GitHub/IRIS3/config/zeisel_config.yaml:/app/config/config.yaml" \
     iris3:test run /app/config/config.yaml -o /output
   ```

3. [ ] Verify regulons.tsv output for Zeisel

### Optional Improvements
- [ ] Add checkpointing to skip completed steps on restart
- [ ] Improve Zeisel cell type labels (currently using Seurat clusters 0-16)
- [ ] Add progress bar for QUBIC2 (currently no progress indication)
- [ ] Clean up intermediate files automatically

---

## Recent Test Results

### Seurat Input Test (PASSED)
- Input: `output/yan_test3/seurat_obj.rds`
- Output: 94 regulons in `output/seurat_test/regulons.tsv`
- Cell types: 4_Cell_embryo (54), 8_Cell_embryo (17), Late_blastoCyst (23)
- Diverse TF annotations: MAZ, PATZ1, KLF family, SP1, etc.

### Zeisel Test (FAILED at gene_module)
- Preprocessing: PASSED (3005 cells, 18879 genes, 17 clusters)
- QUBIC2: PASSED (100 biclusters)
- Gene module: FAILED (index error - fix applied but not tested)

---

## Architecture Notes

### Pipeline Steps
1. `preprocess` - Seurat normalization, clustering, UMAP
2. `bicluster` - QUBIC2 biclustering on expression matrix
3. `gene_module` - Assign biclusters to cell types by enrichment
4. `motif_discovery` - MEME motif finding on promoter sequences
5. `tomtom` - Match motifs to JASPAR database
6. `regulon_scoring` - AUCell/WMW activity scoring
7. `finalize` - Consolidate into regulons.tsv

### Data Flow
```
Input (CSV/H5/Seurat)
  → preprocessing.R → filtered_expression.txt + cell_label.txt
  → QUBIC2 → .blocks file
  → gene_module.R → CT_*_bic/ directories with FASTA files
  → MEME → meme.xml per bicluster
  → TOMTOM → tomtom.tsv with TF matches
  → regulon_scoring.R → activity scores
  → finalize.R → regulons.tsv (final output)
```
