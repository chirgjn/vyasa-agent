import subprocess
import stat
from pathlib import Path


def run(agents_md: str, tmp_path: Path) -> list[str]:
    _ = (tmp_path / "AGENTS.md").write_text(agents_md)
    script = Path(__file__).parent.parent / "plugin/scripts/lint-commands.sh"
    result = subprocess.run(
        ["bash", str(script), str(tmp_path / "AGENTS.md")],
        capture_output=True,
        text=True,
        cwd=tmp_path,
    )
    return result.stdout.strip().splitlines()


def test_missing_script_flagged(tmp_path: Path) -> None:
    agents_md = "## Commands\n```bash\nscripts/tools/missing.sh\n```\n"
    lines = run(agents_md, tmp_path)
    assert any("REMAINING" in l and "missing.sh" in l for l in lines)


def test_existing_script_clean(tmp_path: Path) -> None:
    script_path = tmp_path / "scripts" / "tools" / "exists.sh"
    script_path.parent.mkdir(parents=True)
    _ = script_path.write_text("#!/usr/bin/env bash\necho hi")
    script_path.chmod(script_path.stat().st_mode | stat.S_IEXEC)
    agents_md = "## Commands\n```bash\nscripts/tools/exists.sh\n```\n"
    lines = run(agents_md, tmp_path)
    assert lines == []


def test_known_system_binary_ignored(tmp_path: Path) -> None:
    agents_md = "## Commands\n```bash\ngit status\npnpm install\n```\n"
    lines = run(agents_md, tmp_path)
    assert lines == []
