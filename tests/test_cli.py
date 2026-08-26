"""Tests for IRIS3 CLI commands."""

import pytest
from pathlib import Path
from click.testing import CliRunner


@pytest.fixture
def cli_runner():
    """Create a Click test runner."""
    return CliRunner()


class TestCLIVersion:
    """Tests for version command."""

    def test_version_flag(self, cli_runner: CliRunner):
        """Test --version flag shows version."""
        from iris3.cli import cli

        result = cli_runner.invoke(cli, ["--version"])
        assert result.exit_code == 0
        assert "2.0.0" in result.output


class TestCLIInit:
    """Tests for init command."""

    def test_init_generates_template(self, cli_runner: CliRunner):
        """Test init command outputs a valid YAML template."""
        from iris3.cli import cli

        result = cli_runner.invoke(cli, ["init"])
        assert result.exit_code == 0
        # Should contain key sections
        assert "input:" in result.output
        assert "species:" in result.output
        assert "preprocessing:" in result.output
        assert "biclustering:" in result.output

    def test_init_output_is_valid_yaml(self, cli_runner: CliRunner, tmp_path: Path):
        """Test init output can be parsed as YAML."""
        import yaml
        from iris3.cli import cli

        result = cli_runner.invoke(cli, ["init"])
        assert result.exit_code == 0

        # Should be parseable YAML
        config = yaml.safe_load(result.output)
        assert "input" in config
        assert "species" in config


class TestCLIRun:
    """Tests for run command."""

    def test_run_with_valid_config(
        self, cli_runner: CliRunner, valid_config_yaml: Path, tmp_path: Path
    ):
        """Test run command accepts valid config."""
        from iris3.cli import cli

        output_dir = tmp_path / "output"
        result = cli_runner.invoke(
            cli, ["run", str(valid_config_yaml), "-o", str(output_dir), "--dry-run"]
        )

        assert result.exit_code == 0
        assert "validated" in result.output.lower() or "dry" in result.output.lower()

    def test_run_missing_config_fails(self, cli_runner: CliRunner, tmp_path: Path):
        """Test run command fails with missing config file."""
        from iris3.cli import cli

        output_dir = tmp_path / "output"
        result = cli_runner.invoke(
            cli, ["run", "/nonexistent/config.yaml", "-o", str(output_dir)]
        )

        assert result.exit_code != 0

    def test_run_requires_output_dir(self, cli_runner: CliRunner, valid_config_yaml: Path):
        """Test run command requires --output option."""
        from iris3.cli import cli

        result = cli_runner.invoke(cli, ["run", str(valid_config_yaml)])

        assert result.exit_code != 0
        assert "output" in result.output.lower() or "required" in result.output.lower()


class TestCLIQuick:
    """Tests for quick command."""

    def test_quick_with_minimal_args(
        self, cli_runner: CliRunner, sample_expression_csv: Path, tmp_path: Path
    ):
        """Test quick command with minimal arguments."""
        from iris3.cli import cli

        output_dir = tmp_path / "output"
        result = cli_runner.invoke(
            cli,
            [
                "quick",
                str(sample_expression_csv),
                "--species",
                "Human",
                "-o",
                str(output_dir),
                "--dry-run",
            ],
        )

        assert result.exit_code == 0

    def test_quick_requires_species(
        self, cli_runner: CliRunner, sample_expression_csv: Path, tmp_path: Path
    ):
        """Test quick command requires --species option."""
        from iris3.cli import cli

        output_dir = tmp_path / "output"
        result = cli_runner.invoke(
            cli, ["quick", str(sample_expression_csv), "-o", str(output_dir)]
        )

        assert result.exit_code != 0

    def test_quick_with_labels(
        self,
        cli_runner: CliRunner,
        sample_expression_csv: Path,
        sample_labels_csv: Path,
        tmp_path: Path,
    ):
        """Test quick command with optional labels file."""
        from iris3.cli import cli

        output_dir = tmp_path / "output"
        result = cli_runner.invoke(
            cli,
            [
                "quick",
                str(sample_expression_csv),
                "--species",
                "Mouse",
                "-o",
                str(output_dir),
                "--labels",
                str(sample_labels_csv),
                "--dry-run",
            ],
        )

        assert result.exit_code == 0

    def test_quick_invalid_species_fails(
        self, cli_runner: CliRunner, sample_expression_csv: Path, tmp_path: Path
    ):
        """Test quick command fails with invalid species."""
        from iris3.cli import cli

        output_dir = tmp_path / "output"
        result = cli_runner.invoke(
            cli,
            [
                "quick",
                str(sample_expression_csv),
                "--species",
                "Zebrafish",
                "-o",
                str(output_dir),
            ],
        )

        assert result.exit_code != 0


class TestCLIStep:
    """Tests for step command."""

    def test_step_valid_step_name(
        self, cli_runner: CliRunner, valid_config_yaml: Path, tmp_path: Path
    ):
        """Test step command with valid step name."""
        from iris3.cli import cli

        output_dir = tmp_path / "output"
        result = cli_runner.invoke(
            cli,
            [
                "step",
                "preprocess",
                str(valid_config_yaml),
                "-o",
                str(output_dir),
                "--dry-run",
            ],
        )

        assert result.exit_code == 0

    def test_step_invalid_step_name_fails(
        self, cli_runner: CliRunner, valid_config_yaml: Path, tmp_path: Path
    ):
        """Test step command fails with invalid step name."""
        from iris3.cli import cli

        output_dir = tmp_path / "output"
        result = cli_runner.invoke(
            cli,
            ["step", "invalid_step", str(valid_config_yaml), "-o", str(output_dir)],
        )

        assert result.exit_code != 0


class TestCLIHelp:
    """Tests for help messages."""

    def test_help_flag(self, cli_runner: CliRunner):
        """Test --help flag shows help."""
        from iris3.cli import cli

        result = cli_runner.invoke(cli, ["--help"])
        assert result.exit_code == 0
        assert "IRIS3" in result.output or "regulon" in result.output.lower()

    def test_run_help(self, cli_runner: CliRunner):
        """Test run --help shows command help."""
        from iris3.cli import cli

        result = cli_runner.invoke(cli, ["run", "--help"])
        assert result.exit_code == 0
        assert "config" in result.output.lower()
        assert "output" in result.output.lower()

    def test_quick_help(self, cli_runner: CliRunner):
        """Test quick --help shows command help."""
        from iris3.cli import cli

        result = cli_runner.invoke(cli, ["quick", "--help"])
        assert result.exit_code == 0
        assert "species" in result.output.lower()
