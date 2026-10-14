#!/usr/bin/env python3
"""Example gate built on site_annotations: broad exception handlers need a site annotation.

A handler catching everything (`except:`, `except Exception`, `except BaseException`) is allowed
only where the code says why:

    # gate-broad-except: boundary — the plugin host must survive any plugin failure
    except Exception:

Categories: `boundary` (a process or plugin boundary that must not die) and `cleanup` (the
handler re-raises after releasing a resource). Copy this file as the template for a new rule:
only `find_sites` and `CATEGORIES` change.

    python example_broad_except_gate.py src/          # gate: exit 1 on any error
    python site_annotations.py src/                   # review every annotation
"""

from __future__ import annotations

import argparse
import ast
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from site_annotations import Site, reconcile, scan  # noqa: E402

RULE = "broad-except"
CATEGORIES = frozenset({"boundary", "cleanup"})
_BROAD = {"Exception", "BaseException"}


def _is_broad(handler: ast.ExceptHandler) -> bool:
    if handler.type is None:
        return True
    names = handler.type.elts if isinstance(handler.type, ast.Tuple) else [handler.type]
    return any(isinstance(n, ast.Name) and n.id in _BROAD for n in names)


def find_sites(files: list[Path], root: Path) -> list[Site]:
    sites: list[Site] = []
    for file in files:
        tree = ast.parse(file.read_text(encoding="utf-8"), filename=str(file))
        rel = file.resolve().relative_to(root.resolve()).as_posix()
        for node in ast.walk(tree):
            if isinstance(node, ast.ExceptHandler) and _is_broad(node):
                sites.append(Site(rel, node.lineno, ast.unparse(node.type) if node.type else "bare except"))
    return sites


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    files = sorted({f for p in args.paths for f in (p.rglob("*.py") if p.is_dir() else [p])})
    errors = reconcile(RULE, find_sites(files, args.root), scan(files, args.root), CATEGORIES)
    for line in errors:
        print(line)
    print(f"gate-{RULE}: {'FAIL' if errors else 'ok'} ({len(errors)} error(s), {len(files)} file(s))")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
