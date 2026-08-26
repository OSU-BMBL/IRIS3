"""
R Script Runner

Utility for executing R scripts with proper environment setup.
"""

import subprocess
import logging
from pathlib import Path
from typing import Dict, Optional, Any

logger = logging.getLogger(__name__)


class RRunner:
    """Execute R scripts with environment management."""

    def __init__(self, r_modules_dir: Optional[Path] = None):
        """
        Initialize R runner.

        Args:
            r_modules_dir: Path to r_modules directory (uses IRIS3_R_MODULES env var if not set)
        """
        self.r_modules_dir = r_modules_dir or self._find_r_modules()

    def _find_r_modules(self) -> Path:
        """Find r_modules directory."""
        import os

        # Check environment variable
        env_path = os.environ.get("IRIS3_R_MODULES")
        if env_path:
            return Path(env_path)

        # Check relative to package
        pkg_dir = Path(__file__).parent.parent.parent
        r_modules = pkg_dir / "r_modules"
        if r_modules.exists():
            return r_modules

        raise FileNotFoundError(
            "Cannot find r_modules directory. Set IRIS3_R_MODULES environment variable."
        )

    def run_script(
        self,
        script_name: str,
        args: Optional[list] = None,
        working_dir: Optional[Path] = None,
        timeout: int = 3600,
    ) -> tuple[bool, str]:
        """
        Run an R script.

        Args:
            script_name: Name of script in r_modules (e.g., 'preprocessing.R')
            args: List of arguments to pass to script (positional or --key value)
            working_dir: Working directory for script execution
            timeout: Timeout in seconds (default 1 hour)

        Returns:
            Tuple of (success: bool, output: str)

        Raises:
            FileNotFoundError: If script not found
        """
        script_path = self.r_modules_dir / script_name
        if not script_path.exists():
            raise FileNotFoundError(f"R script not found: {script_path}")

        cmd = ["Rscript", str(script_path)]

        # Add arguments (can be list of strings or dict)
        if args:
            if isinstance(args, dict):
                for key, value in args.items():
                    cmd.extend([f"--{key}", str(value)])
            elif isinstance(args, list):
                cmd.extend([str(a) for a in args])

        logger.info(f"Running R script: {script_name}")
        logger.debug(f"Command: {' '.join(cmd)}")

        try:
            result = subprocess.run(
                cmd,
                cwd=working_dir,
                capture_output=True,
                text=True,
                timeout=timeout,
            )

            if result.returncode != 0:
                logger.error(f"R script failed: {result.stderr}")
                return False, result.stderr

            return True, result.stdout

        except subprocess.TimeoutExpired:
            logger.error(f"R script timed out after {timeout}s")
            return False, f"Script timed out after {timeout} seconds"
        except Exception as e:
            logger.error(f"R script error: {e}")
            return False, str(e)

    def check_r_installation(self) -> bool:
        """Check if R is installed and accessible."""
        try:
            result = subprocess.run(
                ["Rscript", "--version"],
                capture_output=True,
                text=True,
            )
            return result.returncode == 0
        except FileNotFoundError:
            return False

    def check_packages(self, packages: list[str]) -> Dict[str, bool]:
        """
        Check if R packages are installed.

        Args:
            packages: List of package names to check

        Returns:
            Dictionary mapping package name to installed status
        """
        results = {}
        for pkg in packages:
            check_cmd = f'if (requireNamespace("{pkg}", quietly=TRUE)) cat("yes") else cat("no")'
            result = subprocess.run(
                ["Rscript", "-e", check_cmd],
                capture_output=True,
                text=True,
            )
            results[pkg] = result.stdout.strip() == "yes"
        return results
