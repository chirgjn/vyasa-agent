import subprocess
from pathlib import Path


def run(words: list[str], docs: dict[str, str], tmp_path: Path) -> list[str]:
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir()
    for name, content in docs.items():
        _ = (docs_dir / name).write_text(content)
    script = Path(__file__).parent.parent / "scripts/tools/find-word-contexts.sh"
    result = subprocess.run(
        ["bash", str(script), str(docs_dir)] + words,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip().splitlines()


def test_word_found_in_doc(tmp_path: Path) -> None:
    lines = run(["postgres"], {"setup.md": "Use postgres for storage."}, tmp_path)
    assert any("setup.md" in l and "postgres" in l for l in lines)


def test_word_appears_in_multiple_docs(tmp_path: Path) -> None:
    docs = {
        "setup.md": "postgres is the database",
        "deploy.md": "ensure postgres is running",
    }
    lines = run(["postgres"], docs, tmp_path)
    files = [l.split(":")[0] for l in lines]
    assert any("setup.md" in f for f in files)
    assert any("deploy.md" in f for f in files)


def test_absent_word_no_output(tmp_path: Path) -> None:
    lines = run(["redis"], {"setup.md": "Use postgres for storage."}, tmp_path)
    assert lines == []


def test_multiple_words(tmp_path: Path) -> None:
    lines = run(
        ["postgres", "redis"],
        {"setup.md": "postgres here", "cache.md": "redis here"},
        tmp_path,
    )
    assert any("postgres" in l for l in lines)
    assert any("redis" in l for l in lines)
