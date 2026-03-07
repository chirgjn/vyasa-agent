"""Tests for vyasa-run.sh — command logging wrapper."""
import json
import subprocess
from pathlib import Path
from typing import Any, cast


SCRIPT = Path(__file__).parent.parent / "plugin/scripts/vyasa-run.sh"

LogEntry = dict[str, Any]


def run(tmp_path: Path, run_id: str, agent: str, *args: str) -> tuple[int, str, str]:
    result = subprocess.run(
        ["bash", str(SCRIPT), run_id, agent, *args],
        capture_output=True,
        text=True,
        cwd=tmp_path,
    )
    return result.returncode, result.stdout, result.stderr


def read_log(tmp_path: Path, run_id: str) -> list[LogEntry]:
    log_path = tmp_path / ".vyasa" / run_id / "commands.log"
    return [cast(LogEntry, json.loads(line)) for line in log_path.read_text().splitlines() if line.strip()]


def test_logs_start_and_done_entries(tmp_path: Path) -> None:
    code, _, _ = run(tmp_path, "abc12345", "test-agent", "echo", "hello")
    assert code == 0
    entries = read_log(tmp_path, "abc12345")
    assert len(entries) == 2
    assert entries[0]["event"] == "start"
    assert entries[1]["event"] == "done"
    assert entries[1]["exit"] == 0


def test_logs_agent_and_run_id(tmp_path: Path) -> None:
    _ = run(tmp_path, "abc12345", "my-agent", "echo", "hi")
    entries = read_log(tmp_path, "abc12345")
    assert all(e["run_id"] == "abc12345" for e in entries)
    assert all(e["agent"] == "my-agent" for e in entries)


def test_logs_command_string(tmp_path: Path) -> None:
    _ = run(tmp_path, "abc12345", "test-agent", "echo", "hello world")
    entries = read_log(tmp_path, "abc12345")
    assert "echo" in entries[0]["cmd"]
    assert "hello world" in entries[0]["cmd"]


def test_passes_through_exit_code(tmp_path: Path) -> None:
    code, _, _ = run(tmp_path, "abc12345", "test-agent", "bash", "-c", "exit 42")
    assert code == 42
    entries = read_log(tmp_path, "abc12345")
    assert entries[1]["exit"] == 42


def test_shell_expression_via_dash_c(tmp_path: Path) -> None:
    code, stdout, _ = run(tmp_path, "abc12345", "test-agent", "-c", "echo from-shell")
    assert code == 0
    assert "from-shell" in stdout
    entries = read_log(tmp_path, "abc12345")
    assert "from-shell" in entries[0]["cmd"]


def test_creates_log_directory(tmp_path: Path) -> None:
    _ = run(tmp_path, "newrun1", "test-agent", "echo", "ok")
    assert (tmp_path / ".vyasa" / "newrun1" / "commands.log").exists()


def test_multiple_runs_append_to_log(tmp_path: Path) -> None:
    _ = run(tmp_path, "abc12345", "agent-a", "echo", "first")
    _ = run(tmp_path, "abc12345", "agent-b", "echo", "second")
    entries = read_log(tmp_path, "abc12345")
    assert len(entries) == 4
    assert entries[0]["agent"] == "agent-a"
    assert entries[2]["agent"] == "agent-b"


def test_missing_args_exits_2(tmp_path: Path) -> None:
    result = subprocess.run(
        ["bash", str(SCRIPT), "abc12345"],
        capture_output=True,
        text=True,
        cwd=tmp_path,
    )
    assert result.returncode == 2
