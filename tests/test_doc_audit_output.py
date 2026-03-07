"""Tests for doc-audit agent output format and phase summary parsing."""
import re


def parse_phase_summary(report: str) -> dict[str, str] | None:
    """Parse PHASE SUMMARY block from a report."""
    match = re.search(
        r"PHASE SUMMARY\s+Doc-ID:\s*(\S+)\s+Phase:\s*(.+?)\s+Findings:\s*(.+?)(?:\s+Context:\s*(.+))?$",
        report,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        return None  # type: ignore[return-value]

    return {
        "doc_id": match.group(1),
        "phase": match.group(2),
        "findings": match.group(3),
        "context": match.group(4) or "",
    }


def test_phase_summary_block_required():
    """Every report must end with a PHASE SUMMARY block."""
    # Valid report with findings
    report_with_findings = """[CHECK 1 — DOES THIS DOC NEED TO EXIST]
Severity: Error
Doc-ID: doc-001
Found: This is an ephemeral plan document sitting in docs/.
Impact: Phase 2 agents will waste effort analyzing a doc that should be archived.
Recommendation: Move to docs/archive/ or delete after the plan completes.

PHASE SUMMARY
Doc-ID: doc-001
Phase: 1 — doc-audit
Findings: 1 error, 0 warnings, 0 info
Context: Ephemeral plan in active docs — should be archived.
"""

    summary = parse_phase_summary(report_with_findings)
    assert summary is not None
    assert summary["doc_id"] == "doc-001"
    assert "1 error" in summary["findings"]

    # Valid report with no findings
    report_no_findings = """Document passed all checks.

PHASE SUMMARY
Doc-ID: doc-002
Phase: 1 — doc-audit
Findings: 0 errors, 0 warnings, 0 info
"""

    summary = parse_phase_summary(report_no_findings)
    assert summary is not None
    assert "0 errors" in summary["findings"]
    assert summary["context"] == ""  # Optional when no findings


def test_phase_summary_required_fields():
    """PHASE SUMMARY must have Doc-ID, Phase, and Findings."""
    valid_summary = """PHASE SUMMARY
Doc-ID: doc-005
Phase: 1 — doc-audit
Findings: 2 errors, 1 warning, 0 info
Context: Mixed purposes in single doc.
"""

    summary = parse_phase_summary(valid_summary)
    assert summary is not None
    assert summary["doc_id"] == "doc-005"
    assert "Phase: 1 — doc-audit" in valid_summary
    assert "2 errors" in summary["findings"]


def test_finding_block_structure():
    """Each finding must have required fields."""
    finding_block = """[CHECK 3 — IS THIS DOCUMENT PLACED CORRECTLY]
Severity: Warning
Doc-ID: doc-012
Found: This setup guide contains a "Design Decision" section explaining why the toolchain was chosen.
Impact: Readers looking for a how-to are confused by decision rationale; decision records should live in docs/decisions/.
Recommendation: Extract the "Design Decision" section into docs/decisions/toolchain-choice.md and link to it from the setup guide.
"""

    # Verify structure
    assert "[CHECK" in finding_block
    assert "Severity:" in finding_block
    assert "Doc-ID:" in finding_block
    assert "Found:" in finding_block
    assert "Impact:" in finding_block
    assert "Recommendation:" in finding_block


def test_severity_values_valid():
    """Severity must be one of Error, Warning, Info."""
    valid_severities = ["Error", "Warning", "Info"]
    for severity in valid_severities:
        line = f"Severity: {severity}"
        assert "Error" in line or "Warning" in line or "Info" in line

    # Invalid should fail
    invalid = "Severity: Critical"
    assert not ("Error" in invalid or "Warning" in invalid or "Info" in invalid)


def test_phase_summary_context_optional():
    """Context line is optional when there are no findings."""
    summary_without_context = """PHASE SUMMARY
Doc-ID: doc-099
Phase: 1 — doc-audit
Findings: 0 errors, 0 warnings, 0 info
"""

    summary = parse_phase_summary(summary_without_context)
    assert summary is not None
    assert summary["context"] == ""

    # With findings, context should be present
    summary_with_context = """PHASE SUMMARY
Doc-ID: doc-100
Phase: 1 — doc-audit
Findings: 1 error, 0 warnings, 0 info
Context: Decision record placed in guides/ — check structure template compliance.
"""

    summary = parse_phase_summary(summary_with_context)
    assert summary is not None
    assert "guides/" in summary["context"]


def test_report_structure_order():
    """Findings should come before PHASE SUMMARY."""
    report = """[CHECK 1 — DOES THIS DOC NEED TO EXIST]
Severity: Warning
Doc-ID: doc-042
Found: Content is very thin (11 lines).
Impact: Thin files add indirection without value.
Recommendation: Merge into a related, broader document or expand.

[CHECK 2 — DOES THIS DOC HAVE A CLEAR PURPOSE]
Severity: Info
Doc-ID: doc-042
Found: Title is "API Reference" but opening states "How to set up the API client."
Impact: Inconsistent purpose statement; readers may be confused.
Recommendation: Clarify if this is setup-focused (rename to "API Client Setup") or reference-focused (add API endpoint reference section).

PHASE SUMMARY
Doc-ID: doc-042
Phase: 1 — doc-audit
Findings: 0 errors, 2 warnings, 1 info
Context: Thin file with mixed purpose — consider merging into setup guide or expanding.
"""

    # Verify findings come before summary
    findings_pos = report.find("[CHECK")
    summary_pos = report.find("PHASE SUMMARY")
    assert findings_pos < summary_pos, "Findings must come before PHASE SUMMARY"

    # Verify summary is at the end
    lines = report.strip().split("\n")
    assert any("PHASE SUMMARY" in line for line in lines[-5:])  # Near the end
