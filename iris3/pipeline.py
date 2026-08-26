"""
IRIS3 Pipeline Orchestrator

Coordinates the execution of the IRIS3 regulon inference pipeline.
"""

import os
import subprocess
import shutil
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Tuple
from dataclasses import dataclass, field

from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

from iris3.config import IRIS3Config
from iris3.utils.r_runner import RRunner
from iris3.utils.tools import ToolPaths

console = Console()


@dataclass
class PipelineState:
    """Tracks pipeline execution state."""
    current_step: str = ""
    completed_steps: list = field(default_factory=list)
    failed: bool = False
    error_message: str = ""


class IRIS3Pipeline:
    """Main pipeline orchestrator for IRIS3."""

    STEPS = [
        "preprocess",
        "bicluster",
        "gene_module",
        "motif_discovery",
        "tomtom",
        "regulon_scoring",
        "finalize",
    ]

    def __init__(self, config: IRIS3Config, output_dir: Path):
        self.config = config
        self.output_dir = Path(output_dir).resolve()  # Convert to absolute path
        self.state = PipelineState()

        # Set job_id if not provided
        if not self.config.execution.job_id:
            self.config.execution.job_id = datetime.now().strftime("%Y%m%d%H%M%S")

        self.job_id = self.config.execution.job_id

        # Initialize tool paths from environment
        self.tools = ToolPaths.from_environment()

        # Initialize R runner
        r_modules_path = os.environ.get(
            "IRIS3_R_MODULES",
            Path(__file__).parent.parent / "r_modules"
        )
        self.r_runner = RRunner(r_modules_dir=Path(r_modules_path))

        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def run(self, start_step: Optional[str] = None) -> bool:
        """
        Run the full pipeline.

        Args:
            start_step: Optional step to start from (skips earlier steps)

        Returns:
            True if pipeline completed successfully
        """
        console.print(f"[bold blue]IRIS3 Pipeline[/bold blue]")
        console.print(f"Output directory: {self.output_dir}")
        console.print(f"Species: {self.config.species}")
        console.print()

        steps_to_run = self.STEPS
        if start_step:
            if start_step not in self.STEPS:
                console.print(f"[red]Unknown step: {start_step}[/red]")
                return False
            start_idx = self.STEPS.index(start_step)
            steps_to_run = self.STEPS[start_idx:]

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            for step in steps_to_run:
                task = progress.add_task(f"Running {step}...", total=None)

                try:
                    self.state.current_step = step
                    success = self._run_step(step)

                    if not success:
                        self.state.failed = True
                        progress.update(task, description=f"[red]Failed: {step}[/red]")
                        console.print(f"\n[red]Pipeline failed at step: {step}[/red]")
                        if self.state.error_message:
                            console.print(f"Error: {self.state.error_message}")
                        return False

                    self.state.completed_steps.append(step)
                    progress.update(task, description=f"[green]Completed: {step}[/green]")

                except Exception as e:
                    self.state.failed = True
                    self.state.error_message = str(e)
                    console.print(f"\n[red]Error in {step}: {e}[/red]")
                    return False

        console.print("\n[bold green]Pipeline completed successfully![/bold green]")
        return True

    def run_step(self, step: str) -> bool:
        """Run a single pipeline step."""
        if step not in self.STEPS:
            console.print(f"[red]Unknown step: {step}[/red]")
            console.print(f"Available steps: {', '.join(self.STEPS)}")
            return False

        console.print(f"[bold]Running step: {step}[/bold]")
        return self._run_step(step)

    def _run_step(self, step: str) -> bool:
        """Internal step runner."""
        step_methods = {
            "preprocess": self._step_preprocess,
            "bicluster": self._step_bicluster,
            "gene_module": self._step_gene_module,
            "motif_discovery": self._step_motif_discovery,
            "tomtom": self._step_tomtom,
            "regulon_scoring": self._step_regulon_scoring,
            "finalize": self._step_finalize,
        }

        method = step_methods.get(step)
        if method:
            return method()
        return False

    def _step_preprocess(self) -> bool:
        """Run preprocessing step."""
        console.print("  Preprocessing expression data...")

        # Build arguments for preprocessing.R
        args = [
            "--expr", str(self.config.input.expression_file),
            "--species", self.config.species,
            "--output", str(self.output_dir),
            "--jobid", self.config.execution.job_id or "iris3",
            "--resolution", str(self.config.preprocessing.resolution_seurat),
            "--n-pcs", str(self.config.preprocessing.n_pcs),
            "--n-variable-features", str(self.config.preprocessing.n_variable_features),
        ]

        if self.config.input.label_file:
            args.extend(["--labels", str(self.config.input.label_file)])

        # Pass label column for Seurat objects
        args.extend(["--label-column", self.config.input.label_column])

        if self.config.preprocessing.enable_imputation:
            args.append("--imputation")

        if self.config.preprocessing.remove_ribosome:
            args.append("--remove-ribosome")

        success, output = self.r_runner.run_script("preprocessing.R", args)

        if not success:
            self.state.error_message = f"Preprocessing failed: {output}"

        return success

    def _step_bicluster(self) -> bool:
        """Run biclustering with QUBIC2."""
        console.print("  Running QUBIC2 biclustering...")

        qubic_path = self.tools.qubic
        if not qubic_path or not qubic_path.exists():
            self.state.error_message = "QUBIC2 not found"
            return False

        job_id = self.config.execution.job_id or "iris3"
        expr_file = self.output_dir / f"{job_id}_filtered_expression.txt"

        if not expr_file.exists():
            self.state.error_message = f"Expression file not found: {expr_file}"
            return False

        # Run QUBIC2
        cmd = [
            str(qubic_path),
            "-i", str(expr_file),
            "-k", str(self.config.biclustering.k),
            "-q", str(self.config.biclustering.q),
            "-f", str(self.config.biclustering.f),
            "-o", str(self.config.biclustering.o),
        ]

        try:
            result = subprocess.run(
                cmd,
                cwd=str(self.output_dir),
                capture_output=True,
                text=True,
                timeout=3600  # 1 hour timeout
            )

            # Parse QUBIC2 .blocks file and extract genes/conditions
            # Note: QUBIC2 may return non-zero exit code on macOS even when successful
            blocks_file = expr_file.with_suffix(".txt.blocks")
            if not blocks_file.exists():
                self.state.error_message = f"QUBIC2 blocks file not found: {blocks_file}"
                return False

            genes_file = self.output_dir / f"{job_id}_blocks.gene.txt"
            conds_file = self.output_dir / f"{job_id}_blocks.conds.txt"

            with open(blocks_file, "r") as f, \
                 open(genes_file, "w") as gf, \
                 open(conds_file, "w") as cf:
                for line in f:
                    if line.startswith(" Genes ["):
                        # Format: " Genes [n]: gene1 gene2 gene3 ..."
                        genes = line.split(":", 1)[1].strip().split()
                        gf.write(" ".join(["0"] + genes) + "\n")  # Prepend bicluster index placeholder
                    elif line.startswith(" Conds ["):
                        # Format: " Conds [n]: cond1 cond2 cond3 ..."
                        conds = line.split(":", 1)[1].strip().split()
                        cf.write(" ".join(["0"] + conds) + "\n")

            return True

        except subprocess.TimeoutExpired:
            self.state.error_message = "QUBIC2 timed out"
            return False
        except Exception as e:
            self.state.error_message = str(e)
            return False

    def _step_gene_module(self) -> bool:
        """Run gene module assignment."""
        console.print("  Assigning genes to cell type modules...")

        job_id = self.config.execution.job_id or "iris3"

        args = [
            str(self.output_dir),
            job_id,
            str(self.config.motif.promoter_length),
            "",  # gene_module_file (not used)
            "",  # delimiter (not used)
        ]

        success, output = self.r_runner.run_script("gene_module.R", args)

        if not success:
            self.state.error_message = f"Gene module assignment failed: {output}"

        return success

    def _run_meme_single(self, fasta_file: Path, meme_path: Path) -> Tuple[Path, bool]:
        """Run MEME on a single FASTA file. Returns (file, success)."""
        # Output to directory so MEME creates proper meme.xml format
        meme_out_dir = fasta_file.parent / f"{fasta_file.stem}_meme"
        meme_out_dir.mkdir(exist_ok=True)

        cmd = [
            str(meme_path),
            str(fasta_file),
            "-nostatus",
            "-w", "12",
            "-mod", "anr",
            "-revcomp",
            "-nmotifs", "3",
            "-objfun", "classic",
            "-dna",
            "-oc", str(meme_out_dir),  # Output to directory (creates meme.xml)
        ]

        try:
            subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600  # 10 min per file
            )

            # Check if meme.xml was created (MEME may return non-zero with warnings)
            meme_xml = meme_out_dir / "meme.xml"
            if meme_xml.exists():
                return (fasta_file, True)

        except Exception:
            pass

        return (fasta_file, False)

    def _step_motif_discovery(self) -> bool:
        """Run motif discovery with MEME in parallel."""
        console.print("  Discovering motifs...")

        meme_path = self.tools.meme
        if not meme_path or not meme_path.exists():
            console.print("  [yellow]MEME not found - skipping motif discovery[/yellow]")
            console.print("  [yellow]Regulons will use bicluster gene lists without TF annotation[/yellow]")
            # Create placeholder regulon files from bicluster gene lists
            return self._create_regulons_from_biclusters()

        # Find FASTA files for motif discovery
        job_id = self.config.execution.job_id or "iris3"
        ct_dirs = list(self.output_dir.glob(f"{job_id}_CT_*_bic"))

        if not ct_dirs:
            console.print("  [yellow]No cell type directories found, skipping[/yellow]")
            return True

        # Collect all FASTA files
        all_fasta_files: List[Path] = []
        for ct_dir in ct_dirs:
            all_fasta_files.extend(ct_dir.glob("bic*.fa"))

        if not all_fasta_files:
            console.print("  [yellow]No FASTA files found, skipping[/yellow]")
            return True

        # Run MEME in parallel
        num_threads = self.config.execution.threads
        console.print(f"  Running MEME on {len(all_fasta_files)} files using {num_threads} threads...")

        completed = 0
        failed = 0

        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            futures = {
                executor.submit(self._run_meme_single, f, meme_path): f
                for f in all_fasta_files
            }

            for future in as_completed(futures):
                fasta_file, success = future.result()
                if success:
                    completed += 1
                else:
                    failed += 1

                # Progress update every 10 files
                if (completed + failed) % 10 == 0:
                    console.print(f"    Progress: {completed + failed}/{len(all_fasta_files)}")

        console.print(f"  MEME completed: {completed} success, {failed} failed")
        return True

    def _run_tomtom_single(self, meme_file: Path, tomtom_path: Path,
                            tomtom_dir: Path, motif_db: Path) -> Tuple[Path, bool]:
        """Run TOMTOM on a single MEME XML file. Returns (file, success)."""
        # meme_file is like {jobid}_CT_1_bic/bic1_meme/meme.xml
        # Extract CT info from grandparent directory to avoid naming collisions
        ct_dir = meme_file.parent.parent.name  # "{jobid}_CT_1_bic"
        bicluster_name = meme_file.parent.name.replace("_meme", "")  # "bic1"

        # Extract cell type suffix: "{jobid}_CT_1_bic" -> "CT_1_bic"
        if "_CT_" in ct_dir:
            ct_suffix = "CT_" + ct_dir.split("_CT_")[-1]  # "CT_1_bic"
        else:
            ct_suffix = ct_dir

        # Create unique output directory: "CT_1_bic_bic1"
        unique_name = f"{ct_suffix}_{bicluster_name}"
        output_subdir = tomtom_dir / unique_name
        output_subdir.mkdir(exist_ok=True)

        cmd = [
            str(tomtom_path),
            "-no-ssc",
            "-oc", str(output_subdir),
            "-verbosity", "1",
            "-min-overlap", "5",
            "-dist", "pearson",
            "-evalue",
            "-thresh", "0.05",
            str(meme_file),
            str(motif_db),
        ]

        try:
            subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            # Check if tomtom.tsv was created
            tomtom_tsv = output_subdir / "tomtom.tsv"
            return (meme_file, tomtom_tsv.exists())
        except Exception:
            return (meme_file, False)

    def _step_tomtom(self) -> bool:
        """Run TOMTOM motif comparison in parallel."""
        console.print("  Running TOMTOM motif comparison...")

        tomtom_path = self.tools.tomtom
        if not tomtom_path or not tomtom_path.exists():
            console.print("  [yellow]TOMTOM not found - skipping TF matching[/yellow]")
            return True

        # Find MEME XML output files (meme.xml in *_meme directories)
        meme_files = list(self.output_dir.rglob("*_meme/meme.xml"))

        if not meme_files:
            console.print("  [yellow]No MEME files found, skipping[/yellow]")
            return True

        # Create tomtom output directory
        tomtom_dir = self.output_dir / "tomtom"
        tomtom_dir.mkdir(exist_ok=True)

        # Determine motif database based on species
        motif_db = self.tools.get_motif_database(self.config.species)

        if not motif_db or not motif_db.exists():
            console.print("  [yellow]Motif database not found, skipping TOMTOM[/yellow]")
            return True

        num_threads = self.config.execution.threads
        console.print(f"  Running TOMTOM on {len(meme_files)} files using {num_threads} threads...")

        completed = 0
        failed = 0

        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            futures = {
                executor.submit(self._run_tomtom_single, f, tomtom_path, tomtom_dir, motif_db): f
                for f in meme_files
            }

            for future in as_completed(futures):
                _, success = future.result()
                if success:
                    completed += 1
                else:
                    failed += 1

        console.print(f"  TOMTOM completed: {completed} success, {failed} failed")
        return True

    def _step_regulon_scoring(self) -> bool:
        """Run regulon activity and specificity scoring."""
        console.print("  Scoring regulons...")

        job_id = self.config.execution.job_id or "iris3"

        args = [
            str(self.output_dir),
            job_id,
            "wmw_test",  # method
            str(self.config.execution.threads),
        ]

        success, output = self.r_runner.run_script("regulon_scoring.R", args)

        if not success:
            self.state.error_message = f"Regulon scoring failed: {output}"

        return success

    def _step_finalize(self) -> bool:
        """Consolidate outputs into single summary table."""
        console.print("  Finalizing outputs...")

        job_id = self.config.execution.job_id or "iris3"

        # Determine if we should keep intermediate files
        keep_intermediates = self.config.output.keep_intermediates

        args = [
            str(self.output_dir),
            job_id,
            str(keep_intermediates).upper(),
        ]

        success, output = self.r_runner.run_script("finalize.R", args)

        if not success:
            self.state.error_message = f"Finalization failed: {output}"
            return False

        # Check that output file was created
        output_file = self.output_dir / "regulons.tsv"
        if output_file.exists():
            console.print(f"  [green]Created: {output_file.name}[/green]")
            # Print summary
            with open(output_file) as f:
                lines = f.readlines()
                if len(lines) > 1:
                    console.print(f"  Total regulons: {len(lines) - 1}")
        else:
            console.print("  [yellow]Warning: regulons.tsv not created[/yellow]")

        return success

    def _create_regulons_from_biclusters(self) -> bool:
        """Create regulon gene symbol files from bicluster gene lists (when MEME is unavailable)."""
        job_id = self.config.execution.job_id or "iris3"
        ct_dirs = list(self.output_dir.glob(f"{job_id}_CT_*_bic"))

        if not ct_dirs:
            console.print("  [yellow]No cell type directories found[/yellow]")
            return True

        for ct_dir in ct_dirs:
            # Collect all gene lists from biclusters in this cell type
            gene_files = sorted(ct_dir.glob("bic*.txt"))
            all_genes = []

            for gene_file in gene_files:
                genes = gene_file.read_text().strip().split("\n")
                genes = [g.strip() for g in genes if g.strip()]
                if genes:
                    all_genes.append("\t".join(genes))

            # Write regulon gene symbol file (one line per bicluster)
            ct_name = ct_dir.name.replace(f"{job_id}_", "")
            regulon_file = self.output_dir / f"{ct_name}.regulon_gene_symbol.txt"
            regulon_file.write_text("\n".join(all_genes))

            console.print(f"  Created {regulon_file.name} with {len(all_genes)} regulons")

        return True
