"""
IRIS3 Command Line Interface

Click-based CLI for running IRIS3 regulon inference pipeline.
"""

from pathlib import Path
from typing import Optional

import click
from pydantic import ValidationError
from rich.console import Console

from iris3 import __version__
from iris3.config import IRIS3Config, load_config
from iris3.pipeline import IRIS3Pipeline

console = Console()

# Valid pipeline steps (matches IRIS3Pipeline.STEPS)
VALID_STEPS = IRIS3Pipeline.STEPS


@click.group()
@click.version_option(version=__version__, prog_name="iris3")
def cli():
    """IRIS3: Integrated Cell-type-specific Regulon Inference for scRNA-seq

    Identify cell-type-specific regulons from single-cell RNA-seq data.
    """
    pass


@cli.command()
@click.argument("config_file", type=click.Path(exists=True))
@click.option(
    "--output",
    "-o",
    type=click.Path(),
    required=True,
    help="Output directory for results",
)
@click.option(
    "--threads",
    "-t",
    type=int,
    default=None,
    help="Number of parallel threads (overrides config)",
)
@click.option(
    "--resume",
    is_flag=True,
    help="Resume from last checkpoint",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Validate config without running pipeline",
)
def run(
    config_file: str,
    output: str,
    threads: Optional[int],
    resume: bool,
    dry_run: bool,
):
    """Run the full IRIS3 pipeline.

    CONFIG_FILE: Path to YAML configuration file
    """
    try:
        config = load_config(Path(config_file))
        config.output_dir = Path(output)

        if threads is not None:
            config.execution.threads = threads

        if dry_run:
            console.print("[green]Configuration validated successfully.[/green]")
            console.print(f"  Species: {config.species}")
            console.print(f"  Input: {config.input.expression_file}")
            console.print(f"  Output: {config.output_dir}")
            console.print(f"  Threads: {config.execution.threads}")
            console.print("\n[dim]Dry run - pipeline not executed.[/dim]")
            return

        # Run the pipeline
        pipeline = IRIS3Pipeline(config, Path(output))
        start_step = None
        if resume:
            # TODO: Load checkpoint to determine start step
            pass
        success = pipeline.run(start_step=start_step)
        if not success:
            raise click.Abort()

    except ValidationError as e:
        console.print(f"[red]Configuration error:[/red]\n{e}")
        raise click.Abort()
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise click.Abort()


@cli.command()
@click.argument("expression_file", type=click.Path(exists=True))
@click.option(
    "--species",
    type=click.Choice(["Human", "Mouse"], case_sensitive=False),
    required=True,
    help="Species (Human or Mouse)",
)
@click.option(
    "--output",
    "-o",
    type=click.Path(),
    required=True,
    help="Output directory for results",
)
@click.option(
    "--labels",
    type=click.Path(exists=True),
    default=None,
    help="Optional cell labels file",
)
@click.option(
    "--threads",
    "-t",
    type=int,
    default=8,
    help="Number of parallel threads",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Validate config without running pipeline",
)
def quick(
    expression_file: str,
    species: str,
    output: str,
    labels: Optional[str],
    threads: int,
    dry_run: bool,
):
    """Quick run with minimal configuration.

    EXPRESSION_FILE: Path to expression matrix (CSV/TSV/H5)
    """
    try:
        config = IRIS3Config.from_minimal(
            expression_file=Path(expression_file),
            species=species,
            label_file=Path(labels) if labels else None,
            output_dir=Path(output),
        )
        config.execution.threads = threads

        if dry_run:
            console.print("[green]Configuration created successfully.[/green]")
            console.print(f"  Species: {config.species}")
            console.print(f"  Input: {config.input.expression_file}")
            if labels:
                console.print(f"  Labels: {config.input.label_file}")
            console.print(f"  Output: {config.output_dir}")
            console.print(f"  Threads: {config.execution.threads}")
            console.print("\n[dim]Dry run - pipeline not executed.[/dim]")
            return

        # Run the pipeline
        pipeline = IRIS3Pipeline(config, Path(output))
        success = pipeline.run()
        if not success:
            raise click.Abort()

    except ValidationError as e:
        console.print(f"[red]Configuration error:[/red]\n{e}")
        raise click.Abort()
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise click.Abort()


@cli.command()
@click.argument("step", type=click.Choice(VALID_STEPS, case_sensitive=False))
@click.argument("config_file", type=click.Path(exists=True))
@click.option(
    "--output",
    "-o",
    type=click.Path(),
    required=True,
    help="Output directory for results",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Validate config without running step",
)
def step(step: str, config_file: str, output: str, dry_run: bool):
    """Run a single pipeline step.

    STEP: Pipeline step to run (preprocess, bicluster, gene_module, etc.)

    CONFIG_FILE: Path to YAML configuration file
    """
    try:
        config = load_config(Path(config_file))
        config.output_dir = Path(output)

        if dry_run:
            console.print(f"[green]Will run step: {step}[/green]")
            console.print(f"  Config: {config_file}")
            console.print(f"  Output: {config.output_dir}")
            console.print("\n[dim]Dry run - step not executed.[/dim]")
            return

        # Run single step
        pipeline = IRIS3Pipeline(config, Path(output))
        success = pipeline.run_step(step)
        if not success:
            raise click.Abort()

    except ValidationError as e:
        console.print(f"[red]Configuration error:[/red]\n{e}")
        raise click.Abort()
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}")
        raise click.Abort()


@cli.command()
def init():
    """Generate a template configuration file.

    Outputs a YAML template to stdout that can be redirected to a file:

        iris3 init > config.yaml
    """
    template = """\
# IRIS3 Configuration Template
# Generated by: iris3 init

input:
  # Required: Path to expression matrix
  expression_file: "path/to/expression.csv"
  # Format: auto, csv, tsv, h5, 10x_folder
  expression_format: "auto"
  # Delimiter for CSV/TSV files
  delimiter: ","
  # Optional: Cell labels file
  label_file: null
  # Optional: Custom gene modules file
  gene_module_file: null

# Required: Species (Human or Mouse)
species: "Human"

preprocessing:
  # Seurat clustering resolution (0.1-5.0)
  resolution_seurat: 0.8
  # Number of principal components
  n_pcs: 10
  # Number of highly variable features
  n_variable_features: 5000
  # Enable DrImpute imputation
  enable_imputation: false
  # Remove ribosomal genes
  remove_ribosome: false
  # Enable trajectory analysis
  enable_trajectory: false

biclustering:
  # QUBIC2 consistency threshold
  k: 20
  # Quantile threshold
  q: 0.06
  # Filter proportion
  f: 0.5
  # Max output biclusters
  o: 100

motif:
  # Promoter region length (bp)
  promoter_length: 1000
  # Motif length range
  min_motif_length: 12
  max_motif_length: 12
  # Use MEME (true) or BoBro only (false)
  use_meme: true

execution:
  # Number of parallel threads
  threads: 8
  # Checkpoint interval (0 to disable)
  checkpoint_interval: 1
"""
    click.echo(template)


if __name__ == "__main__":
    cli()
