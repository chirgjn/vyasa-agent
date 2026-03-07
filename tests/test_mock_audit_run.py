"""Mock audit run demonstrating Phase 1 infrastructure end-to-end."""
import json
import subprocess
from pathlib import Path
from typing import cast


def test_mock_audit_run_phase_1_infrastructure(tmp_path: Path) -> None:
    """
    Simulate a complete Phase 1 audit:
    1. Generate run-id
    2. Create directory structure
    3. Build registry
    4. Create mock Phase 1 reports
    5. Parse phase summaries
    6. Verify gate logic would work
    """
    # Step 1: Generate run-id (8 hex chars)
    result = subprocess.run(
        ["openssl", "rand", "-hex", "4"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    run_id = result.stdout.strip()
    assert len(run_id) == 8

    # Step 2: Create project structure
    project = tmp_path / "project"
    project.mkdir()

    # Create markdown files (in various directories to test alphabetical ordering)
    _ = (project / "README.md").write_text("# Project README\nProject overview.")
    _ = (project / "AGENTS.md").write_text("# Agents\nAgent definitions.")

    (project / "docs").mkdir()
    _ = (project / "docs" / "setup.md").write_text("# Setup Guide\nHow to set up.")
    _ = (project / "docs" / "api.md").write_text("# API Reference\nAPI documentation.")

    (project / "plugin").mkdir()
    (project / "plugin" / "framework").mkdir()
    _ = (project / "plugin" / "framework" / "managing-project-information.md").write_text(
        "# Managing Project Information\nHow to organize docs."
    )

    # Step 3: Create audit directories
    audit_dir = project / ".vyasa" / run_id
    registry_dir = audit_dir
    reports_dir = audit_dir / "reports" / "phase-1" / "doc-audit"
    reports_dir.mkdir(parents=True, exist_ok=True)

    # Step 4: Build registry
    build_script = Path(__file__).parent.parent / "plugin/scripts/build-registry.sh"
    result = subprocess.run(
        ["bash", str(build_script), str(registry_dir / "registry.json"), str(project)],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, f"Registry build failed: {result.stderr}"

    # Verify registry
    registry = cast(dict[str, dict[str, str]], json.loads((registry_dir / "registry.json").read_text()))
    assert len(registry) == 5, f"Expected 5 docs, got {len(registry)}"

    # Verify alphabetical ordering
    expected_paths = [
        "AGENTS.md",
        "README.md",
        "docs/api.md",
        "docs/setup.md",
        "plugin/framework/managing-project-information.md",
    ]
    actual_paths = [registry[f"doc-{i:03d}"]["original_path"] for i in range(1, 6)]
    assert actual_paths == expected_paths, f"Order mismatch: {actual_paths}"

    # Step 5: Create mock Phase 1 reports (simulating doc-audit results)
    reports_data: list[dict[str, str]] = [
        # doc-001: AGENTS.md
        {
            "doc_id": "doc-001",
            "phase": "1 — doc-audit",
            "findings": "0 errors, 0 warnings, 0 info",
            "content": """Document passed all checks.

PHASE SUMMARY
Doc-ID: doc-001
Phase: 1 — doc-audit
Findings: 0 errors, 0 warnings, 0 info
""",
        },
        # doc-002: README.md
        {
            "doc_id": "doc-002",
            "phase": "1 — doc-audit",
            "findings": "0 errors, 0 warnings, 0 info",
            "content": """Document passed all checks.

PHASE SUMMARY
Doc-ID: doc-002
Phase: 1 — doc-audit
Findings: 0 errors, 0 warnings, 0 info
""",
        },
        # doc-003: docs/api.md
        {
            "doc_id": "doc-003",
            "phase": "1 — doc-audit",
            "findings": "0 errors, 1 warning, 0 info",
            "content": """[CHECK 4 — IS THE FILENAME CORRECT AND DESCRIPTIVE]
Severity: Warning
Doc-ID: doc-003
Found: Filename is "api.md" but content describes an API client library, not the API itself.
Impact: Misleading filename; readers may expect server API documentation.
Recommendation: Consider renaming to "api-client.md" for clarity, or expand scope to cover server API.

PHASE SUMMARY
Doc-ID: doc-003
Phase: 1 — doc-audit
Findings: 0 errors, 1 warning, 0 info
Context: API documentation filename ambiguous — consider renaming for clarity.
""",
        },
        # doc-004: docs/setup.md
        {
            "doc_id": "doc-004",
            "phase": "1 — doc-audit",
            "findings": "0 errors, 0 warnings, 0 info",
            "content": """Document passed all checks.

PHASE SUMMARY
Doc-ID: doc-004
Phase: 1 — doc-audit
Findings: 0 errors, 0 warnings, 0 info
""",
        },
        # doc-005: plugin/framework/managing-project-information.md
        {
            "doc_id": "doc-005",
            "phase": "1 — doc-audit",
            "findings": "0 errors, 0 warnings, 0 info",
            "content": """Document passed all checks.

PHASE SUMMARY
Doc-ID: doc-005
Phase: 1 — doc-audit
Findings: 0 errors, 0 warnings, 0 info
""",
        },
    ]

    for report_data in reports_data:
        report_file = reports_dir / f"{report_data['doc_id']}.md"
        _ = report_file.write_text(report_data["content"])

    # Step 6: Parse phase summaries from all reports
    parse_script = Path(__file__).parent.parent / "plugin/scripts/parse-phase-summary.sh"

    phase_1_summaries: dict[str, dict[str, str]] = {}
    for report_data in reports_data:
        report_file = reports_dir / f"{report_data['doc_id']}.md"
        result = subprocess.run(
            ["bash", str(parse_script), str(report_file)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, f"Parse failed for {report_data['doc_id']}: {result.stderr}"
        summary = cast(dict[str, str], json.loads(result.stdout))
        phase_1_summaries[report_data["doc_id"]] = summary

    # Step 7: Verify gate logic (orchestrator's gate after Phase 1)
    proceed: list[tuple[str, dict[str, str]]] = []
    proceed_with_context: list[tuple[str, dict[str, str]]] = []
    skip: list[tuple[str, dict[str, str]]] = []

    for doc_id, summary in phase_1_summaries.items():
        findings_line = summary["findings"]
        error_count = int(findings_line.split()[0]) if "error" in findings_line else 0

        if error_count > 0:
            skip.append((doc_id, summary))
        elif summary["context"]:
            proceed_with_context.append((doc_id, summary))
        else:
            proceed.append((doc_id, summary))

    # Verify gate decisions
    assert len(proceed) == 4, f"Expected 4 docs to proceed, got {len(proceed)}"
    assert len(proceed_with_context) == 1, f"Expected 1 doc to proceed with context, got {len(proceed_with_context)}"
    assert len(skip) == 0, f"Expected 0 docs to skip, got {len(skip)}"

    # Verify context was extracted
    context_doc = proceed_with_context[0]
    assert "API documentation filename" in context_doc[1]["context"]

    # Step 8: Verify registry integrity
    parsed_registry = cast(dict[str, dict[str, str]], json.loads((registry_dir / "registry.json").read_text()))
    assert len(parsed_registry) == len(registry)
    for _doc_id, entry in parsed_registry.items():
        assert entry["original_path"] == entry["current_path"]
        assert "md" in entry["original_path"]

    print(f"\nMock audit completed successfully:")
    print(f"  Run ID: {run_id}")
    print(f"  Documents: {len(registry)}")
    print(f"  Phase 1 complete:")
    print(f"    - Proceed: {len(proceed)}")
    print(f"    - Proceed with context: {len(proceed_with_context)}")
    print(f"    - Skip: {len(skip)}")
    print(f"  Registry integrity verified: OK")
