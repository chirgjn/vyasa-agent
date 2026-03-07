import subprocess
from pathlib import Path


def run(agents_md: str, dirs: list[str], tmp_path: Path) -> list[str]:
    _ = (tmp_path / "AGENTS.md").write_text(agents_md)
    for d in dirs:
        (tmp_path / d).mkdir(parents=True, exist_ok=True)
    script = Path(__file__).parent.parent / "plugin/scripts/lint-structure.sh"
    result = subprocess.run(
        ["bash", str(script), str(tmp_path / "AGENTS.md")],
        capture_output=True,
        text=True,
        cwd=tmp_path,
    )
    return result.stdout.strip().splitlines()


AGENTS_WITH_DOCS = "## Structure\n```\ndocs/   — guides\n```\n"


def test_unlisted_dir_flagged(tmp_path: Path) -> None:
    lines = run(AGENTS_WITH_DOCS, ["docs", "src"], tmp_path)
    assert any("REMAINING" in l and "src" in l and "unlisted" in l for l in lines)


def test_missing_dir_flagged(tmp_path: Path) -> None:
    agents = "## Structure\n```\ndocs/   — guides\nsrc/    — code\n```\n"
    lines = run(agents, ["docs"], tmp_path)  # src/ doesn't exist on disk
    assert any("REMAINING" in l and "src" in l and "missing" in l for l in lines)


def test_matching_structure_clean(tmp_path: Path) -> None:
    lines = run(AGENTS_WITH_DOCS, ["docs"], tmp_path)
    assert lines == []
