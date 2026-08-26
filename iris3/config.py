"""
IRIS3 Configuration Module

Pydantic models for loading and validating YAML configuration files.
"""

from pathlib import Path
from typing import Literal, Optional

import yaml
from pydantic import BaseModel, Field, field_validator, model_validator


# Valid species (Human and Mouse only)
VALID_SPECIES = {"Human", "Mouse"}


class InputConfig(BaseModel):
    """Input file configuration."""

    expression_file: Path = Field(..., description="Path to expression matrix file")
    expression_format: Literal["auto", "csv", "tsv", "h5", "10x_folder", "rds", "qsave"] = Field(
        default="auto", description="Format of expression file"
    )
    delimiter: str = Field(default=",", description="Delimiter for CSV/TSV files")
    label_file: Optional[Path] = Field(default=None, description="Cell label file")
    label_delimiter: str = Field(default="\t", description="Delimiter for label file")
    label_column: str = Field(
        default="cell_type",
        description="Metadata column name for cell labels in Seurat objects",
    )
    gene_module_file: Optional[Path] = Field(
        default=None, description="Custom gene modules file"
    )


class PreprocessingConfig(BaseModel):
    """Preprocessing parameters."""

    resolution_seurat: float = Field(
        default=0.8, gt=0, le=5.0, description="Seurat clustering resolution"
    )
    n_pcs: int = Field(default=10, gt=0, le=100, description="Number of principal components")
    n_variable_features: int = Field(
        default=5000, gt=0, le=50000, description="Number of variable features"
    )
    enable_imputation: bool = Field(default=False, description="Enable DrImpute")
    remove_ribosome: bool = Field(default=False, description="Remove ribosomal genes")
    enable_trajectory: bool = Field(default=False, description="Enable trajectory analysis")
    use_provided_labels: bool = Field(
        default=True, description="Use provided labels instead of Seurat clustering"
    )


class BiclusteringConfig(BaseModel):
    """QUBIC2 biclustering parameters."""

    k: int = Field(default=20, gt=0, description="Consistency threshold")
    q: float = Field(default=0.06, gt=0, lt=1, description="Quantile threshold")
    f: float = Field(default=0.5, gt=0, le=1, description="Filter proportion")
    o: int = Field(default=100, gt=0, description="Max output biclusters")
    enable_continuous: bool = Field(default=False, description="Enable continuous mode (-C)")


class MotifConfig(BaseModel):
    """Motif discovery parameters."""

    promoter_length: int = Field(default=1000, gt=0, description="Promoter region length (bp)")
    min_motif_length: int = Field(default=12, gt=0, description="Minimum motif length")
    max_motif_length: int = Field(default=12, gt=0, description="Maximum motif length")
    use_meme: bool = Field(default=True, description="Use MEME (true) or BoBro only (false)")
    num_motifs: int = Field(default=3, gt=0, description="Number of motifs to discover")


class ExecutionConfig(BaseModel):
    """Execution settings."""

    threads: int = Field(default=8, gt=0, description="Number of parallel threads")
    checkpoint_interval: int = Field(
        default=1, ge=0, description="Save checkpoint after N steps (0=disabled)"
    )
    job_id: Optional[str] = Field(default=None, description="Job identifier for output files")


class OutputConfig(BaseModel):
    """Output settings."""

    keep_intermediates: bool = Field(
        default=False, description="Keep intermediate files (QUBIC2 temp, bicluster dirs)"
    )
    keep_expression: bool = Field(
        default=True, description="Keep filtered expression matrix"
    )
    keep_seurat: bool = Field(
        default=True, description="Keep Seurat RDS object"
    )


class IRIS3Config(BaseModel):
    """Main IRIS3 configuration model."""

    input: InputConfig
    species: Literal["Human", "Mouse"]
    preprocessing: PreprocessingConfig = Field(default_factory=PreprocessingConfig)
    biclustering: BiclusteringConfig = Field(default_factory=BiclusteringConfig)
    motif: MotifConfig = Field(default_factory=MotifConfig)
    execution: ExecutionConfig = Field(default_factory=ExecutionConfig)
    output: OutputConfig = Field(default_factory=OutputConfig)
    output_dir: Optional[Path] = Field(default=None, description="Output directory")

    @field_validator("species", mode="before")
    @classmethod
    def normalize_species(cls, v: str) -> str:
        """Normalize species name to proper case."""
        if isinstance(v, str):
            # Capitalize first letter
            normalized = v.capitalize()
            if normalized not in VALID_SPECIES:
                raise ValueError(
                    f"Invalid species '{v}'. Must be one of: {', '.join(VALID_SPECIES)}"
                )
            return normalized
        return v

    @classmethod
    def from_minimal(
        cls,
        expression_file: Path,
        species: str,
        label_file: Optional[Path] = None,
        output_dir: Optional[Path] = None,
        **kwargs,
    ) -> "IRIS3Config":
        """
        Create a config from minimal required parameters.

        Args:
            expression_file: Path to expression matrix
            species: Species name (Human or Mouse)
            label_file: Optional cell label file
            output_dir: Optional output directory
            **kwargs: Additional parameters to override defaults

        Returns:
            IRIS3Config instance with defaults applied
        """
        input_config = InputConfig(
            expression_file=Path(expression_file),
            label_file=Path(label_file) if label_file else None,
        )

        return cls(
            input=input_config,
            species=species,
            output_dir=Path(output_dir) if output_dir else None,
            **kwargs,
        )

    def to_yaml(self, path: Path) -> None:
        """
        Save configuration to a YAML file.

        Args:
            path: Output file path
        """
        # Convert to dict, handling Path objects
        data = self.model_dump(mode="json")
        with open(path, "w") as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)

    def to_yaml_path(self) -> Path:
        """
        Get path for temporary config file.

        Returns:
            Path to temporary config YAML
        """
        if self.output_dir:
            config_path = self.output_dir / "config.yaml"
            self.to_yaml(config_path)
            return config_path
        raise ValueError("output_dir must be set to generate config path")


def load_config(path: Path) -> IRIS3Config:
    """
    Load configuration from a YAML file.

    Args:
        path: Path to YAML config file

    Returns:
        IRIS3Config instance

    Raises:
        FileNotFoundError: If config file doesn't exist
        ValidationError: If config is invalid
    """
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")

    with open(path) as f:
        data = yaml.safe_load(f)

    return IRIS3Config(**data)
