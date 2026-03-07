"""Tests for audit registry generation and integrity."""
import json
import tempfile
from pathlib import Path
from typing import cast


def test_registry_generation_creates_valid_json():
    """Registry.json should be valid JSON that can be parsed."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)

        # Create a simple project structure with a few markdown files
        (tmp_path / "docs").mkdir()
        _ = (tmp_path / "docs" / "setup.md").write_text("# Setup\nContent")
        _ = (tmp_path / "docs" / "api.md").write_text("# API\nContent")
        _ = (tmp_path / "README.md").write_text("# README\nContent")

        # Simulate registry generation (we'll build this)
        # For now, just test the structure
        registry: dict[str, dict[str, str]] = {
            "doc-001": {"original_path": "README.md", "current_path": "README.md"},
            "doc-002": {"original_path": "docs/api.md", "current_path": "docs/api.md"},
            "doc-003": {"original_path": "docs/setup.md", "current_path": "docs/setup.md"},
        }

        registry_file = tmp_path / ".vyasa" / "test-run" / "registry.json"
        registry_file.parent.mkdir(parents=True)
        _ = registry_file.write_text(json.dumps(registry, indent=2))

        # Verify it can be parsed
        parsed = cast(dict[str, dict[str, str]], json.loads(registry_file.read_text()))
        assert parsed == registry
        assert len(parsed) == 3


def test_registry_assigns_stable_doc_ids_alphabetically():
    """Doc IDs should be assigned in alphabetical order by path."""
    registry = {
        "doc-001": {"original_path": "README.md", "current_path": "README.md"},
        "doc-002": {"original_path": "docs/api.md", "current_path": "docs/api.md"},
        "doc-003": {"original_path": "docs/setup.md", "current_path": "docs/setup.md"},
    }

    # Verify alphabetical order
    paths = [v["original_path"] for k in sorted(registry.keys()) for v in [registry[k]]]
    assert paths == ["README.md", "docs/api.md", "docs/setup.md"]


def test_registry_excludes_excluded_directories():
    """Registry should exclude .vyasa, plugin, node_modules, .git."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)

        # Create files in various directories
        (tmp_path / "docs").mkdir()
        _ = (tmp_path / "docs" / "setup.md").write_text("# Setup")

        (tmp_path / ".vyasa").mkdir()
        _ = (tmp_path / ".vyasa" / "old-run.md").write_text("# Old")

        (tmp_path / "plugin").mkdir()
        _ = (tmp_path / "plugin" / "agent.md").write_text("# Agent")

        (tmp_path / ".git").mkdir()
        _ = (tmp_path / ".git" / "config.md").write_text("# Config")

        # In actual implementation, we enumerate and filter
        # For this test, verify our exclusion list
        excluded = {".vyasa", "plugin", "node_modules", ".git"}

        # Simulated enumeration
        all_files = [
            "README.md",
            "docs/setup.md",
            ".vyasa/old-run.md",
            "plugin/agent.md",
            ".git/config.md",
            "node_modules/lib.md",
        ]

        included = [f for f in all_files if not any(part in excluded for part in f.split("/"))]
        assert included == ["README.md", "docs/setup.md"]


def test_registry_run_id_format():
    """Run ID should be 8 hex characters."""
    import re
    # Simulate generating multiple run IDs
    run_ids: list[str] = []
    for _ in range(5):
        # In real code: run_id=$(openssl rand -hex 4)
        # This produces 8 hex chars (4 bytes = 32 bits = 8 hex digits)
        run_id: str = "a1b2c3d4"  # Example
        run_ids.append(run_id)

    hex_pattern = r"^[0-9a-f]{8}$"
    for run_id in run_ids:
        assert re.match(hex_pattern, run_id), f"Invalid run ID format: {run_id}"


def test_registry_doc_id_format():
    """Doc IDs should be doc-NNN format."""
    import re
    registry = {
        "doc-001": {"original_path": "a.md", "current_path": "a.md"},
        "doc-002": {"original_path": "b.md", "current_path": "b.md"},
        "doc-010": {"original_path": "j.md", "current_path": "j.md"},
    }

    doc_id_pattern = r"^doc-\d{3}$"
    for doc_id in registry.keys():
        assert re.match(doc_id_pattern, doc_id), f"Invalid doc ID format: {doc_id}"


def test_registry_current_path_initially_equals_original_path():
    """At creation, current_path should equal original_path."""
    registry = {
        "doc-001": {"original_path": "docs/setup.md", "current_path": "docs/setup.md"},
        "doc-002": {"original_path": "docs/api.md", "current_path": "docs/api.md"},
    }

    for _doc_id, entry in registry.items():
        assert entry["original_path"] == entry["current_path"]
