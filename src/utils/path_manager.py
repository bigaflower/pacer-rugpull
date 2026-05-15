from __future__ import annotations

import os
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]


def _resolve_to_project(path_str: str) -> Path:
    """Turn a user-provided path into an absolute path anchored at repo root when needed."""
    path = Path(path_str).expanduser()
    if not path.is_absolute():
        path = PROJECT_ROOT / path
    return path


def get_output_dir(preferred_name: str = "output") -> Path:
    override = os.getenv("PADG_OUTPUT_DIR")
    if override:
        return _resolve_to_project(override)
    return PROJECT_ROOT / preferred_name
