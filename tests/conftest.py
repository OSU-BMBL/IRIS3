"""Pytest fixtures for IRIS3 tests"""

import pytest
from pathlib import Path
import tempfile
import shutil


@pytest.fixture
def tmp_output_dir(tmp_path: Path) -> Path:
    """Create a temporary output directory."""
    output_dir = tmp_path / "output"
    output_dir.mkdir()
    return output_dir


@pytest.fixture
def sample_expression_csv(tmp_path: Path) -> Path:
    """Create a minimal expression matrix CSV for testing."""
    csv_content = """Gene,Cell1,Cell2,Cell3,Cell4
TP53,10.5,0.0,5.2,8.1
BRCA1,0.0,15.3,2.1,0.5
MYC,20.1,18.4,22.0,19.5
GAPDH,100.2,98.5,102.1,99.8
"""
    csv_path = tmp_path / "expression.csv"
    csv_path.write_text(csv_content)
    return csv_path


@pytest.fixture
def sample_labels_csv(tmp_path: Path) -> Path:
    """Create a minimal cell labels CSV for testing."""
    csv_content = """Cell,Label
Cell1,TypeA
Cell2,TypeA
Cell3,TypeB
Cell4,TypeB
"""
    csv_path = tmp_path / "labels.csv"
    csv_path.write_text(csv_content)
    return csv_path


@pytest.fixture
def valid_config_yaml(tmp_path: Path, sample_expression_csv: Path) -> Path:
    """Create a valid YAML config file for testing."""
    config_content = f"""
input:
  expression_file: "{sample_expression_csv}"
  expression_format: "csv"
  delimiter: ","

species: "Human"

preprocessing:
  resolution_seurat: 0.8
  n_pcs: 10
  n_variable_features: 5000
  enable_imputation: false
  remove_ribosome: false

biclustering:
  k: 20
  q: 0.06
  f: 0.5
  o: 100

motif:
  promoter_length: 1000
  min_motif_length: 12
  max_motif_length: 12

execution:
  threads: 4
"""
    config_path = tmp_path / "config.yaml"
    config_path.write_text(config_content)
    return config_path


@pytest.fixture
def minimal_config_yaml(tmp_path: Path, sample_expression_csv: Path) -> Path:
    """Create a minimal YAML config with only required fields."""
    config_content = f"""
input:
  expression_file: "{sample_expression_csv}"

species: "Human"
"""
    config_path = tmp_path / "minimal_config.yaml"
    config_path.write_text(config_content)
    return config_path


@pytest.fixture
def invalid_species_config_yaml(tmp_path: Path, sample_expression_csv: Path) -> Path:
    """Create a config with invalid species."""
    config_content = f"""
input:
  expression_file: "{sample_expression_csv}"

species: "Zebrafish"
"""
    config_path = tmp_path / "invalid_config.yaml"
    config_path.write_text(config_content)
    return config_path
