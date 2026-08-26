"""Tests for IRIS3 configuration loading and validation."""

import pytest
from pathlib import Path
from pydantic import ValidationError


class TestConfigLoading:
    """Tests for loading configuration from YAML files."""

    def test_load_valid_config(self, valid_config_yaml: Path):
        """Test loading a fully specified valid config."""
        from iris3.config import load_config

        config = load_config(valid_config_yaml)

        assert config.species == "Human"
        assert config.preprocessing.resolution_seurat == 0.8
        assert config.preprocessing.n_pcs == 10
        assert config.biclustering.k == 20
        assert config.execution.threads == 4

    def test_load_minimal_config_with_defaults(self, minimal_config_yaml: Path):
        """Test that minimal config gets default values applied."""
        from iris3.config import load_config

        config = load_config(minimal_config_yaml)

        # Required fields
        assert config.species == "Human"
        assert config.input.expression_file is not None

        # Default values should be applied
        assert config.preprocessing.resolution_seurat == 0.8
        assert config.preprocessing.n_pcs == 10
        assert config.preprocessing.n_variable_features == 5000
        assert config.preprocessing.enable_imputation is False
        assert config.biclustering.k == 20
        assert config.execution.threads == 8  # default

    def test_load_nonexistent_file_raises_error(self):
        """Test that loading a nonexistent file raises FileNotFoundError."""
        from iris3.config import load_config

        with pytest.raises(FileNotFoundError):
            load_config(Path("/nonexistent/config.yaml"))


class TestConfigValidation:
    """Tests for configuration validation."""

    def test_invalid_species_raises_error(self, invalid_species_config_yaml: Path):
        """Test that invalid species raises ValidationError."""
        from iris3.config import load_config

        with pytest.raises(ValidationError) as exc_info:
            load_config(invalid_species_config_yaml)

        # Check that the error mentions species
        error_str = str(exc_info.value)
        assert "species" in error_str.lower()

    def test_missing_expression_file_raises_error(self, tmp_path: Path):
        """Test that missing expression_file raises ValidationError."""
        from iris3.config import load_config

        config_content = """
species: "Human"
"""
        config_path = tmp_path / "no_input.yaml"
        config_path.write_text(config_content)

        with pytest.raises(ValidationError):
            load_config(config_path)

    def test_missing_species_raises_error(self, tmp_path: Path, sample_expression_csv: Path):
        """Test that missing species raises ValidationError."""
        from iris3.config import load_config

        config_content = f"""
input:
  expression_file: "{sample_expression_csv}"
"""
        config_path = tmp_path / "no_species.yaml"
        config_path.write_text(config_content)

        with pytest.raises(ValidationError):
            load_config(config_path)

    def test_invalid_preprocessing_values(self, tmp_path: Path, sample_expression_csv: Path):
        """Test validation of preprocessing parameter ranges."""
        from iris3.config import load_config

        config_content = f"""
input:
  expression_file: "{sample_expression_csv}"
species: "Human"
preprocessing:
  resolution_seurat: -0.5  # Should be positive
  n_pcs: 0  # Should be > 0
"""
        config_path = tmp_path / "invalid_preproc.yaml"
        config_path.write_text(config_content)

        with pytest.raises(ValidationError):
            load_config(config_path)


class TestConfigModel:
    """Tests for IRIS3Config model methods."""

    def test_from_minimal_factory(self, sample_expression_csv: Path):
        """Test creating config from minimal parameters."""
        from iris3.config import IRIS3Config

        config = IRIS3Config.from_minimal(
            expression_file=sample_expression_csv,
            species="Human",
        )

        assert config.species == "Human"
        assert config.input.expression_file == sample_expression_csv
        # Defaults applied
        assert config.preprocessing.resolution_seurat == 0.8

    def test_from_minimal_with_labels(
        self, sample_expression_csv: Path, sample_labels_csv: Path
    ):
        """Test creating config with label file."""
        from iris3.config import IRIS3Config

        config = IRIS3Config.from_minimal(
            expression_file=sample_expression_csv,
            species="Mouse",
            label_file=sample_labels_csv,
        )

        assert config.species == "Mouse"
        assert config.input.label_file == sample_labels_csv

    def test_to_yaml(self, valid_config_yaml: Path, tmp_path: Path):
        """Test serializing config back to YAML."""
        from iris3.config import load_config

        config = load_config(valid_config_yaml)
        output_path = tmp_path / "output_config.yaml"
        config.to_yaml(output_path)

        assert output_path.exists()

        # Reload and verify
        config2 = load_config(output_path)
        assert config2.species == config.species
        assert config2.preprocessing.n_pcs == config.preprocessing.n_pcs


class TestSpeciesValidation:
    """Tests for species-specific validation."""

    def test_valid_human_species(self, sample_expression_csv: Path):
        """Test Human species is valid."""
        from iris3.config import IRIS3Config

        config = IRIS3Config.from_minimal(
            expression_file=sample_expression_csv,
            species="Human",
        )
        assert config.species == "Human"

    def test_valid_mouse_species(self, sample_expression_csv: Path):
        """Test Mouse species is valid."""
        from iris3.config import IRIS3Config

        config = IRIS3Config.from_minimal(
            expression_file=sample_expression_csv,
            species="Mouse",
        )
        assert config.species == "Mouse"

    def test_case_insensitive_species(self, sample_expression_csv: Path):
        """Test species validation is case-insensitive."""
        from iris3.config import IRIS3Config

        config = IRIS3Config.from_minimal(
            expression_file=sample_expression_csv,
            species="human",  # lowercase
        )
        # Should normalize to proper case
        assert config.species == "Human"
