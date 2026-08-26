# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IRIS3 (Integrated Cell-type-specific Regulon Inference Server) is a PHP web application that processes scRNA-seq data to identify cell-type-specific regulons. Users upload expression matrices via `web/submit.php`, which generates a bash pipeline script (`qsub.sh`) that orchestrates R/Bash tools for analysis.

**Live instance**: https://bmbl.bmi.osumc.edu/iris3/

## Architecture

```
web/submit.php → creates data/{jobid}/qsub.sh → runs pipeline steps:
  1. genefilter.R (Seurat preprocessing)
  2. qubic2 (biclustering)
  3. cts_gene_list.R (gene annotation)
  4. get_motif.sh → DMINDA/MEME (motif discovery)
  5. get_tomtom.sh → merge_tomtom.R (TF matching)
  6. sort_regulon.R (AUCell ranking)
  7. prepare_heatmap.R (visualization)
```

**Stack**: PHP 7+ / Smarty templates / R 3.6+ / Bash / Perl (email) / QUBIC2 / MEME Suite

## Key Paths (Hardcoded)

| Purpose | Path |
|---------|------|
| Working dir | `./data/{jobid}/` (relative to web/) |
| Upload archive | `/var/www/html_archive/iris3_upload/{jobid}/` |
| Base path | `$BASE` defined in `web/config/common.php` |
| Background seqs | `program/bg_data/{Human,Mouse}.bg.fa` |

## Config Files (Not in Repo)

Create these in `web/config/`:
- `common.php` — defines `$BASE` path variable
- `smarty.php` — Smarty template setup
- `tools.php` — utility functions

## Job State Files

Jobs tracked via files in `data/{jobid}/`:
- `running_status.txt` — current pipeline step
- `error_message.txt` — errors if any
- `done` — completion marker
- `info.txt` — job parameters (CSV format)

## R Dependencies

Core: Seurat, AUCell, GSVA, GenomicAlignments, ensembldb, tidyverse
Bioconductor DBs: BSgenome.*, TxDb.*, org.*.eg.db (Human, Mouse, plus 4 others)
Optional: DrImpute, slingshot, destiny, Monocle

## External Tools Required

- QUBIC2 binary at `program/qubic2/qubic`
- MEME Suite (meme, tomtom commands)
- DMINDA tools in `program/dminda/`
- Sendmail/Postfix for email notifications

## Species Support

Human (hg38), Mouse (mm10), C. elegans (ce11), Yeast (sacCer3), Zebrafish (danRer10), Drosophila (dm6)

## Dockerization Notes

For stable Docker deployment:
1. Replace hardcoded `/var/www/html*` paths with environment variables
2. Bundle all R/Bioconductor dependencies
3. Include QUBIC2, MEME Suite, DMINDA binaries
4. Mount volumes for `data/` and upload directories
5. Config files should be generated from environment variables
