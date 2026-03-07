import subprocess
from pathlib import Path


def run(content: str, tmp_path: Path) -> list[str]:
    doc = tmp_path / "guide.md"
    _ = doc.write_text(content)
    # Create a file that exists
    (tmp_path / "docs").mkdir()
    _ = (tmp_path / "docs" / "exists.md").write_text("# Exists")
    script = Path(__file__).parent.parent / "plugin/scripts/lint-refs.sh"
    result = subprocess.run(
        ["bash", str(script), str(doc)],
        capture_output=True,
        text=True,
        cwd=tmp_path,
    )
    return result.stdout.strip().splitlines()


def test_broken_ref_flagged(tmp_path: Path) -> None:
    lines = run("See `docs/missing.md` for details.", tmp_path)
    assert any("REMAINING" in l and "missing.md" in l for l in lines)


def test_existing_ref_clean(tmp_path: Path) -> None:
    lines = run("See `docs/exists.md` for details.", tmp_path)
    assert lines == []


def test_multiple_refs_only_broken_flagged(tmp_path: Path) -> None:
    lines = run("See `docs/exists.md` and `docs/gone.md`.", tmp_path)
    assert len(lines) == 1
    assert "gone.md" in lines[0]
