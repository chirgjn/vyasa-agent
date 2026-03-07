import subprocess
from pathlib import Path


def run(agents_md: str, docs: dict[str, str], tmp_path: Path) -> list[str]:
    """Write agents_md and docs to tmp_path, run lint-routing.sh, return output lines."""
    agents_file = tmp_path / "AGENTS.md"
    _ = agents_file.write_text(agents_md)
    _ = (tmp_path / "layout.md").write_text("---\ndocs: docs/\n---\n")
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    for name, content in docs.items():
        _ = (docs_dir / name).write_text(content)
    script = Path(__file__).parent.parent / "plugin/scripts/lint-routing.sh"
    result = subprocess.run(
        ["bash", str(script), str(agents_file)],
        capture_output=True,
        text=True,
        cwd=tmp_path,
    )
    return result.stdout.strip().splitlines()


def test_orphan_doc_gets_stub_entry(tmp_path: Path) -> None:
    agents_md = "## Routing\n| When you are... | Read |\n|---|---|\n"
    lines = run(agents_md, {"setup.md": "# Setup"}, tmp_path)
    assert any("FIXED" in l and "setup.md" in l for l in lines)
    agents_content = (tmp_path / "AGENTS.md").read_text()
    assert "docs/setup.md" in agents_content


def test_broken_routing_entry_removed(tmp_path: Path) -> None:
    agents_md = "## Routing\n| When you are setting up | docs/gone.md |\n|---|---|\n"
    lines = run(agents_md, {}, tmp_path)
    assert any("FIXED" in l and "gone.md" in l for l in lines)
    agents_content = (tmp_path / "AGENTS.md").read_text()
    assert "gone.md" not in agents_content


def test_valid_routing_no_output(tmp_path: Path) -> None:
    agents_md = "## Routing\n| When you are setting up | docs/setup.md |\n|---|---|\n"
    lines = run(agents_md, {"setup.md": "# Setup"}, tmp_path)
    assert lines == []
