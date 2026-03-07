"""Integration tests for full-audit Phase 1 infrastructure."""
import json
import subprocess
from pathlib import Path
from typing import cast


def test_full_audit_generates_valid_run_id() -> None:
    """generate-run-id.sh should produce a valid 8-hex-char run ID."""
    script = Path(__file__).parent.parent / "plugin/scripts/generate-run-id.sh"
    result = subprocess.run(
        ["bash", str(script)],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    run_id = result.stdout.strip()
    assert len(run_id) == 8
    assert all(c in "0123456789abcdef" for c in run_id)


def test_full_audit_creates_run_directory(tmp_path: Path) -> None:
    """full-audit should create .vyasa/<run-id>/reports directory."""
    run_id = "test1234"
    run_dir = tmp_path / ".vyasa" / run_id / "reports"

    run_dir.mkdir(parents=True, exist_ok=True)

    assert run_dir.exists()
    assert run_dir.is_dir()


def test_full_audit_registry_from_project(tmp_path: Path) -> None:
    """full-audit should build registry from project files."""
    project = tmp_path / "project"
    project.mkdir()

    _ = (project / "README.md").write_text("# README")
    (project / "docs").mkdir()
    _ = (project / "docs" / "api.md").write_text("# API")
    _ = (project / "docs" / "setup.md").write_text("# Setup")

    run_id = "test5678"
    registry_dir = tmp_path / ".vyasa" / run_id
    registry_dir.mkdir(parents=True, exist_ok=True)

    build_script = Path(__file__).parent.parent / "plugin/scripts/build-registry.sh"
    result = subprocess.run(
        ["bash", str(build_script), str(registry_dir / "registry.json"), str(project)],
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, f"Registry build failed: {result.stderr}"
    assert (registry_dir / "registry.json").exists()

    registry = cast(dict[str, dict[str, str]], json.loads((registry_dir / "registry.json").read_text()))
    assert len(registry) == 3
    assert "doc-001" in registry
    assert "doc-002" in registry
    assert "doc-003" in registry

    paths = [registry[f"doc-{i:03d}"]["original_path"] for i in range(1, 4)]
    assert paths == ["README.md", "docs/api.md", "docs/setup.md"]


def test_doc_audit_report_structure(tmp_path: Path) -> None:
    """Simulated doc-audit report should have PHASE SUMMARY block."""
    report = """[CHECK 1 — DOES THIS DOCUMENT NEED TO EXIST]
Severity: Warning
Doc-ID: doc-001
Found: Document is thin (12 lines).
Impact: Thin files add indirection without value.
Recommendation: Consider merging into a related document or expanding content.

PHASE SUMMARY
Doc-ID: doc-001
Phase: 1 — doc-audit
Findings: 0 errors, 1 warning, 0 info
Context: Thin file — consider merging or expanding.
"""

    report_file = tmp_path / "doc-001.md"
    _ = report_file.write_text(report)

    parse_script = Path(__file__).parent.parent / "plugin/scripts/parse-phase-summary.sh"
    result = subprocess.run(
        ["bash", str(parse_script), str(report_file)],
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, f"Parse failed: {result.stderr}"

    summary = cast(dict[str, str], json.loads(result.stdout))
    assert summary["doc_id"] == "doc-001"
    assert "1 — doc-audit" in summary["phase"]
    assert "1 warning" in summary["findings"]
    assert "Thin file" in summary["context"]


def test_phase_summary_missing_is_error(tmp_path: Path) -> None:
    """Report without PHASE SUMMARY should be treated as error."""
    bad_report = """[CHECK 1 — SOME CHECK]
Severity: Warning
Doc-ID: doc-042
Found: Something wrong.
Impact: Impact statement.
Recommendation: Fix recommendation.
"""

    report_file = tmp_path / "doc-042.md"
    _ = report_file.write_text(bad_report)

    parse_script = Path(__file__).parent.parent / "plugin/scripts/parse-phase-summary.sh"
    result = subprocess.run(
        ["bash", str(parse_script), str(report_file)],
        capture_output=True,
        text=True,
    )

    assert result.returncode == 1, "Should fail when PHASE SUMMARY is missing"


def test_phase_summary_context_optional(tmp_path: Path) -> None:
    """PHASE SUMMARY context field is optional."""
    report_no_context = """Document passed all checks.

PHASE SUMMARY
Doc-ID: doc-099
Phase: 1 — doc-audit
Findings: 0 errors, 0 warnings, 0 info
"""

    report_file = tmp_path / "doc-099.md"
    _ = report_file.write_text(report_no_context)

    parse_script = Path(__file__).parent.parent / "plugin/scripts/parse-phase-summary.sh"
    result = subprocess.run(
        ["bash", str(parse_script), str(report_file)],
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0
    summary = cast(dict[str, str], json.loads(result.stdout))
    assert summary["context"] == ""
