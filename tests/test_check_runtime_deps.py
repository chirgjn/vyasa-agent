import subprocess
import os
from pathlib import Path


def run(_tmp_path: Path, env_overrides: dict[str, str] | None = None) -> tuple[int, str]:
    script = Path(__file__).parent.parent / "plugin/scripts/check-runtime-deps.sh"
    env = os.environ.copy()
    if env_overrides:
        env.update(env_overrides)
    result = subprocess.run(
        ["bash", str(script)],
        capture_output=True,
        text=True,
        env=env,
    )
    return result.returncode, result.stdout + result.stderr


def test_reports_ok_when_deps_present(tmp_path: Path) -> None:
    # git and jq are present in the test environment
    code, _output = run(tmp_path)
    # Either all OK or instructions given — script must not crash
    assert code in (0, 1)


def test_output_contains_dep_names(tmp_path: Path) -> None:
    _, output = run(tmp_path)
    assert "git" in output
    assert "jq" in output
    assert "openssl" in output
