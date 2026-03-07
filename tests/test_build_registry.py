"""Tests for build-registry.sh script."""
import json
import subprocess
from pathlib import Path
from typing import cast


def run_build_registry(project_root: Path, output_path: Path) -> tuple[int, str]:
    """Run build-registry.sh and return (exit_code, stdout)."""
    script = Path(__file__).parent.parent / "plugin/scripts/build-registry.sh"
    result = subprocess.run(
        ["bash", str(script), str(output_path), str(project_root)],
        capture_output=True,
        text=True,
    )
    return result.returncode, result.stdout + result.stderr


def test_build_registry_creates_json(tmp_path: Path) -> None:
    """build-registry should create valid JSON registry."""
    project = tmp_path / "project"
    project.mkdir()
    _ = (project / "README.md").write_text("# README")
    (project / "docs").mkdir()
    _ = (project / "docs" / "setup.md").write_text("# Setup")

    registry_path = tmp_path / "registry.json"
    code, output = run_build_registry(project, registry_path)

    assert code == 0, f"Script failed: {output}"
    assert registry_path.exists()

    registry = cast(dict[str, dict[str, str]], json.loads(registry_path.read_text()))
    assert len(registry) == 2
    assert "doc-001" in registry
    assert "doc-002" in registry


def test_build_registry_assigns_alphabetically(tmp_path: Path) -> None:
    """Doc IDs should be assigned in alphabetical order."""
    project = tmp_path / "project"
    project.mkdir()
    _ = (project / "z-file.md").write_text("# Z")
    _ = (project / "a-file.md").write_text("# A")
    _ = (project / "m-file.md").write_text("# M")

    registry_path = tmp_path / "registry.json"
    _ = run_build_registry(project, registry_path)

    registry = cast(dict[str, dict[str, str]], json.loads(registry_path.read_text()))
    paths = [registry[f"doc-{i:03d}"]["original_path"] for i in range(1, 4)]
    assert paths == ["a-file.md", "m-file.md", "z-file.md"]


def test_build_registry_excludes_excluded_dirs(tmp_path: Path) -> None:
    """Should exclude .vyasa, node_modules, .git (not plugin/ — it's now source)."""
    project = tmp_path / "project"
    project.mkdir()

    (project / "docs").mkdir()
    _ = (project / "docs" / "good.md").write_text("# Good")

    (project / "plugin").mkdir()
    (project / "plugin" / "framework").mkdir()
    _ = (project / "plugin" / "framework" / "guide.md").write_text("# Guide")

    (project / ".vyasa").mkdir()
    _ = (project / ".vyasa" / "bad.md").write_text("# Bad")

    (project / "node_modules").mkdir()
    _ = (project / "node_modules" / "bad.md").write_text("# Bad")

    (project / ".git").mkdir()
    _ = (project / ".git" / "bad.md").write_text("# Bad")

    registry_path = tmp_path / "registry.json"
    _ = run_build_registry(project, registry_path)

    registry = cast(dict[str, dict[str, str]], json.loads(registry_path.read_text()))
    paths = [entry["original_path"] for entry in registry.values()]
    assert paths == ["docs/good.md", "plugin/framework/guide.md"], f"Got: {paths}"


def test_build_registry_stable_doc_ids(tmp_path: Path) -> None:
    """Doc IDs should be stable (same files = same IDs)."""
    project = tmp_path / "project"
    project.mkdir()
    _ = (project / "a.md").write_text("# A")
    _ = (project / "b.md").write_text("# B")
    _ = (project / "c.md").write_text("# C")

    registry1_path = tmp_path / "registry1.json"
    registry2_path = tmp_path / "registry2.json"

    # Build twice from same files
    _ = run_build_registry(project, registry1_path)
    _ = run_build_registry(project, registry2_path)

    reg1 = cast(dict[str, dict[str, str]], json.loads(registry1_path.read_text()))
    reg2 = cast(dict[str, dict[str, str]], json.loads(registry2_path.read_text()))

    assert reg1 == reg2, "Doc IDs should be stable"


def test_build_registry_verify_parse(tmp_path: Path) -> None:
    """Registry should be verified by re-parsing after write."""
    project = tmp_path / "project"
    project.mkdir()
    _ = (project / "test.md").write_text("# Test")

    registry_path = tmp_path / "registry.json"
    code, _output = run_build_registry(project, registry_path)

    assert code == 0
    # Verify it's valid JSON
    registry = cast(dict[str, dict[str, str]], json.loads(registry_path.read_text()))
    assert "doc-001" in registry


def test_build_registry_current_path_equals_original(tmp_path: Path) -> None:
    """current_path should equal original_path at creation."""
    project = tmp_path / "project"
    project.mkdir()
    (project / "docs").mkdir()
    _ = (project / "docs" / "api.md").write_text("# API")

    registry_path = tmp_path / "registry.json"
    _ = run_build_registry(project, registry_path)

    registry = cast(dict[str, dict[str, str]], json.loads(registry_path.read_text()))
    for _doc_id, entry in registry.items():
        assert entry["original_path"] == entry["current_path"]


def test_build_registry_output_is_valid_json(tmp_path: Path) -> None:
    """Registry output must be valid JSON parseable by jq."""
    project = tmp_path / "project"
    project.mkdir()
    _ = (project / "a.md").write_text("# A")
    _ = (project / "b.md").write_text("# B")

    registry_path = tmp_path / "registry.json"
    code, output = run_build_registry(project, registry_path)

    assert code == 0, f"Script failed: {output}"
    assert registry_path.exists(), "Registry file was not created"

    # Must be valid JSON
    registry = cast(dict[str, dict[str, str]], json.loads(registry_path.read_text()))
    assert len(registry) == 2
