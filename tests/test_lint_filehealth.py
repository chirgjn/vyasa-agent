import subprocess
from pathlib import Path


def run(filename: str, content: str, tmp_path: Path) -> list[str]:
    doc = tmp_path / filename
    _ = doc.write_text(content)
    script = Path(__file__).parent.parent / "plugin/scripts/lint-filehealth.sh"
    result = subprocess.run(
        ["bash", str(script), str(doc)],
        capture_output=True,
        text=True,
    )
    return result.stdout.strip().splitlines()


def test_thin_file_flagged(tmp_path: Path) -> None:
    content = "\n".join(f"line {i}" for i in range(10))
    lines = run("guide.md", content, tmp_path)
    assert any("REMAINING" in l and "thin" in l for l in lines)


def test_bloated_file_flagged(tmp_path: Path) -> None:
    content = "\n".join(f"line {i}" for i in range(210))
    lines = run("guide.md", content, tmp_path)
    assert any("REMAINING" in l and "bloated" in l for l in lines)


def test_healthy_file_clean(tmp_path: Path) -> None:
    content = "\n".join(f"line {i}" for i in range(50))
    lines = run("guide.md", content, tmp_path)
    assert not any("line-count" in l for l in lines)


def test_bad_filename_flagged(tmp_path: Path) -> None:
    content = "\n".join(f"line {i}" for i in range(50))
    lines = run("MyGuide_v2.md", content, tmp_path)
    assert any("REMAINING" in l and "filename" in l for l in lines)


def test_good_filename_clean(tmp_path: Path) -> None:
    content = "\n".join(f"line {i}" for i in range(50))
    lines = run("my-guide.md", content, tmp_path)
    assert not any("filename" in l for l in lines)


def test_index_only_flagged(tmp_path: Path) -> None:
    # 90% links
    links = "\n".join(f"- [link {i}](docs/file{i}.md)" for i in range(20))
    content = "# Index\n" + links
    lines = run("guide.md", content, tmp_path)
    assert any("REMAINING" in l and "index-only" in l for l in lines)
