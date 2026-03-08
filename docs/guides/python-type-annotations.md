# Python type annotations in tests

How to keep basedpyright warnings at zero in pytest test files. For the CI
setup that enforces this, see `docs/maintenance.md`.

---

## The pattern

All warnings in this codebase trace to three root causes. Fix them once and
they don't come back.

### 1. Annotate `tmp_path` in every test function

pytest injects `tmp_path: Path` automatically. basedpyright can't infer the
type without an annotation, which cascades into warnings on every method call
(`.mkdir()`, `.write_text()`, `.read_text()`, etc.).

**Wrong — 8+ warnings from one missing annotation:**

```python
def test_registry_creates_json(tmp_path):
    project = tmp_path / "project"
    project.mkdir()                          # warning: Type of "mkdir" is unknown
    (project / "README.md").write_text("x") # warning: Type of "write_text" is unknown
```

**Right — zero warnings:**

```python
from pathlib import Path

def test_registry_creates_json(tmp_path: Path) -> None:
    project = tmp_path / "project"
    project.mkdir()
    _ = (project / "README.md").write_text("x")
```

Add `-> None` to every test function too — it's the correct return type and
basedpyright appreciates it.

### 2. Assign `.write_text()` and `.mkdir()` return values

`Path.write_text()` returns `int` (bytes written). basedpyright flags unused
call results. Assign to `_` to signal intentional discard.

```python
# Wrong
(tmp_path / "setup.md").write_text("# Setup")

# Right
_ = (tmp_path / "setup.md").write_text("# Setup")
```

`.mkdir()` returns `None`, so it doesn't trigger this warning. But if you see
`reportUnusedCallResult` on a `.mkdir()` call, the type is unknown — which
means `tmp_path` is missing its annotation (see rule 1).

### 3. Cast `json.loads()` results

`json.loads()` returns `Any`. basedpyright propagates `Any` to every access on
the result. Use `cast()` to tell it the shape.

```python
import json
from typing import cast

# Wrong
registry = json.loads(path.read_text())
for doc_id, entry in registry.items(): # warning: Type of "entry" is Any
    assert entry["original_path"] == entry["current_path"]

# Right
registry = cast(dict[str, dict[str, str]], json.loads(path.read_text()))
for _doc_id, entry in registry.items(): # clean
    assert entry["original_path"] == entry["current_path"]
```

---

## Common patterns

### Helper function that takes `tmp_path`

Helpers that accept `tmp_path` must also annotate it. If the function doesn't
actually use the parameter, prefix it with `_`.

```python
# Used
def run(content: str, tmp_path: Path) -> list[str]:
    doc = tmp_path / "guide.md"
    _ = doc.write_text(content)
    ...

# Not used — prefix with underscore
def run(_tmp_path: Path, env_overrides: dict[str, str] | None = None) -> tuple[int, str]:
    ...
```

### Unused loop variables

basedpyright flags unused variables in `for` loops. If you iterate items but
only need the value, prefix the key with `_`.

```python
# Wrong — "doc_id" is not accessed
for doc_id, entry in registry.items():
    assert entry["original_path"] == entry["current_path"]

# Right
for _doc_id, entry in registry.items():
    assert entry["original_path"] == entry["current_path"]
```

### Subprocess results in tests

When you call a helper that returns `tuple[int, str]` but only need the exit
code, unpack with `_` for the unused value.

```python
# Wrong — "output" is not accessed
code, output = run_build_registry(project, registry_path)
assert code == 0

# Right
code, _output = run_build_registry(project, registry_path)
assert code == 0

# Also right — discard both with _
_ = run_build_registry(project, registry_path)
```

---

## Pitfalls

**Don't use `type: ignore` to silence warnings.** It hides real problems and
doesn't fix the root cause. The warnings in this codebase all had clean fixes.

**`cast()` doesn't validate at runtime.** It's a type hint only — the actual
JSON shape isn't checked. If you need runtime validation, use a schema library.
`cast()` is the right choice here because the JSON comes from our own scripts
under test.

**Removing an unused import isn't always safe.** If `Path` appears only in a
type annotation and you're on Python < 3.10 without `from __future__ import
annotations`, removing it breaks at runtime. In this repo (Python ≥ 3.14), it's
safe to remove unused imports.

---

## CI enforcement

basedpyright runs in CI via the same script used locally:

```bash
scripts/tools/basedpyright-lint.sh
```

The script passes `--level error`, which filters the output to errors only — but
basedpyright exits 1 whenever any diagnostic exists, regardless of level. Keep
warnings at zero; don't rely on `--level error` to suppress them in CI.
