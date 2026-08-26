"""
External Tool Wrappers

Wrappers for MEME Suite, BoBro, QUBIC2, and other external tools.
"""

import os
import subprocess
import shutil
import logging
from pathlib import Path
from typing import Optional
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class ToolPaths:
    """Container for external tool paths."""

    meme: Optional[Path] = None
    tomtom: Optional[Path] = None
    qubic: Optional[Path] = None
    bobro: Optional[Path] = None
    motif_db_dir: Optional[Path] = None

    @classmethod
    def from_environment(cls) -> "ToolPaths":
        """
        Discover tool paths from environment variables or system PATH.

        Environment variables:
            IRIS3_MEME_PATH: Directory containing MEME suite binaries
            IRIS3_QUBIC_PATH: Directory containing QUBIC2 binary
            IRIS3_MOTIF_DB: Directory containing motif databases
        """
        paths = cls()

        # MEME Suite
        meme_dir = os.environ.get("IRIS3_MEME_PATH", "/opt/meme/bin")
        meme_bin = Path(meme_dir) / "meme"
        if meme_bin.exists():
            paths.meme = meme_bin
            paths.tomtom = Path(meme_dir) / "tomtom"
        else:
            # Try to find in PATH
            meme_which = shutil.which("meme")
            if meme_which:
                paths.meme = Path(meme_which)
                tomtom_which = shutil.which("tomtom")
                if tomtom_which:
                    paths.tomtom = Path(tomtom_which)

        # QUBIC2
        qubic_dir = os.environ.get("IRIS3_QUBIC_PATH", "/app/tools/qubic2")
        qubic_bin = Path(qubic_dir) / "qubic"
        if qubic_bin.exists():
            paths.qubic = qubic_bin
        else:
            qubic_which = shutil.which("qubic")
            if qubic_which:
                paths.qubic = Path(qubic_which)

        # BoBro
        bobro_which = shutil.which("BoBro")
        if bobro_which:
            paths.bobro = Path(bobro_which)

        # Motif databases
        motif_db = os.environ.get("IRIS3_MOTIF_DB", "/app/motif_databases")
        if Path(motif_db).exists():
            paths.motif_db_dir = Path(motif_db)

        return paths

    def get_motif_database(self, species: str) -> Optional[Path]:
        """
        Get the motif database path for a species.

        Priority:
        1. IRIS3_MOTIF_DB environment variable (single file)
        2. Species-specific JASPAR database in /opt/meme/db/
        3. Legacy HOCOMOCOv11 databases in motif_db_dir

        Args:
            species: "Human" or "Mouse"

        Returns:
            Path to motif database file, or None if not found
        """
        # Check environment variable first (set by Docker)
        env_db = os.environ.get("IRIS3_MOTIF_DB")
        if env_db and Path(env_db).exists():
            return Path(env_db)

        # Check for JASPAR databases in standard location
        jaspar_db = Path("/opt/meme/db/JASPAR2024_CORE_vertebrates_non-redundant_pfms_meme.txt")
        if jaspar_db.exists():
            return jaspar_db

        # Fall back to legacy species-specific databases
        if not self.motif_db_dir:
            return None

        db_paths = {
            "Human": self.motif_db_dir / "HUMAN" / "HOCOMOCOv11_full_HUMAN_mono_meme_format.meme",
            "Mouse": self.motif_db_dir / "MOUSE" / "HOCOMOCOv11_full_MOUSE_mono_meme_format.meme",
        }

        db_path = db_paths.get(species)
        if db_path and db_path.exists():
            return db_path

        return None

    def validate(self) -> dict[str, bool]:
        """
        Validate that required tools are available.

        Returns:
            Dict mapping tool names to availability status
        """
        return {
            "meme": self.meme is not None and self.meme.exists(),
            "tomtom": self.tomtom is not None and self.tomtom.exists(),
            "qubic": self.qubic is not None and self.qubic.exists(),
            "bobro": self.bobro is not None and self.bobro.exists(),
        }


class ToolBase:
    """Base class for external tool wrappers."""

    def __init__(self, binary_path: Path):
        """
        Initialize tool wrapper.

        Args:
            binary_path: Path to tool binary
        """
        self.binary_path = Path(binary_path)
        if not self.binary_path.exists():
            logger.warning(f"Tool binary not found: {self.binary_path}")

    def _run(self, args: list[str], **kwargs) -> subprocess.CompletedProcess:
        """Run the tool with arguments."""
        cmd = [str(self.binary_path)] + args
        logger.debug(f"Running: {' '.join(cmd)}")
        return subprocess.run(cmd, capture_output=True, text=True, **kwargs)

    def is_available(self) -> bool:
        """Check if tool binary exists."""
        return self.binary_path.exists()


class QubicTool(ToolBase):
    """Wrapper for QUBIC2 biclustering tool."""

    def run(
        self,
        input_file: Path,
        output_dir: Path,
        k: int = 20,
        q: float = 0.06,
        f: float = 0.5,
        o: int = 100,
        enable_continuous: bool = False,
    ) -> subprocess.CompletedProcess:
        """
        Run QUBIC2 biclustering.

        Args:
            input_file: Expression matrix file
            output_dir: Output directory
            k: Consistency threshold
            q: Quantile threshold
            f: Filter proportion
            o: Max output biclusters
            enable_continuous: Enable continuous mode (-C)

        Returns:
            CompletedProcess result
        """
        args = [
            "-i",
            str(input_file),
            "-q",
            str(q),
            "-k",
            str(k),
            "-o",
            str(o),
            "-f",
            str(f),
        ]
        if enable_continuous:
            args.append("-C")

        return self._run(args, cwd=output_dir)


class MEMETool(ToolBase):
    """Wrapper for MEME motif discovery tool."""

    def run(
        self,
        input_file: Path,
        output_dir: Path,
        background: Path,
        num_motifs: int = 3,
        motif_width: int = 12,
    ) -> subprocess.CompletedProcess:
        """
        Run MEME motif discovery.

        Args:
            input_file: FASTA sequence file
            output_dir: Output directory
            background: Background sequences file
            num_motifs: Number of motifs to find
            motif_width: Width of motifs

        Returns:
            CompletedProcess result
        """
        args = [
            str(input_file),
            "-nostatus",
            "-w",
            str(motif_width),
            "-allw",
            "-mod",
            "anr",
            "-revcomp",
            "-nmotifs",
            str(num_motifs),
            "-objfun",
            "de",
            "-neg",
            str(background),
            "-dna",
            "-text",
        ]
        return self._run(args, cwd=output_dir)


class TomtomTool(ToolBase):
    """Wrapper for TOMTOM motif comparison tool."""

    def run(
        self,
        query_motif: Path,
        target_database: Path,
        output_dir: Path,
        evalue_threshold: float = 0.05,
    ) -> subprocess.CompletedProcess:
        """
        Run TOMTOM motif comparison.

        Args:
            query_motif: Query motif file (MEME format)
            target_database: Target motif database
            output_dir: Output directory
            evalue_threshold: E-value threshold

        Returns:
            CompletedProcess result
        """
        args = [
            "-no-ssc",
            "-oc",
            str(output_dir),
            "-verbosity",
            "1",
            "-min-overlap",
            "5",
            "-mi",
            "1",
            "-dist",
            "pearson",
            "-evalue",
            "-thresh",
            str(evalue_threshold),
            str(query_motif),
            str(target_database),
        ]
        return self._run(args)


class BoBroTool(ToolBase):
    """Wrapper for BoBro motif discovery tool (DMINDA)."""

    def run(
        self,
        input_file: Path,
        background: Path,
        motif_length: int = 12,
        num_motifs: int = 3,
    ) -> subprocess.CompletedProcess:
        """
        Run BoBro motif discovery.

        Args:
            input_file: FASTA sequence file
            background: Background sequences file
            motif_length: Length of motifs
            num_motifs: Number of motifs to find

        Returns:
            CompletedProcess result
        """
        args = [
            "-i",
            str(input_file),
            "-l",
            str(motif_length),
            "-F",
            "-o",
            str(num_motifs),
            "-Z",
            str(background),
        ]
        return self._run(args)
