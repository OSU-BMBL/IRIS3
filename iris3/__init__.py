"""
IRIS3: Integrated Cell-type-specific Regulon Inference Server for scRNA-seq

A command-line tool for identifying cell-type-specific regulons from single-cell RNA-seq data.
"""

__version__ = "2.0.0"
__author__ = "BMBL Lab"

from iris3.config import IRIS3Config, load_config

__all__ = ["IRIS3Config", "load_config", "__version__"]
