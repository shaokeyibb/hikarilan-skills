#!/usr/bin/env python3
"""List legacy tests that cover nothing the kept suite does not already cover.

Inputs are two coverage.py data files (SQLite):

  --keep     coverage of the suite you are keeping (end-to-end scenarios plus
             failure-mode tests). Contexts are not needed.
  --legacy   coverage of the suite you want to prune, recorded with one dynamic
             context per test:
               pytest --cov=<pkg> --cov-branch --cov-context=test
             or, without pytest-cov, `[run] dynamic_context = test_function`.

The unit compared is the arc (from-line -> to-line) when both files recorded
branches, otherwise the line. Each legacy test lands in one of two groups:

  deletable        every unit it covers is also covered by the kept suite.
                   All tests in this group can be deleted together.
  needs-scenario   it covers units the kept suite misses (the gap). Its gap
                   units are split into exclusive (no other legacy test covers
                   them) and shared (other legacy tests cover them too).
                   Write a scenario through a public entry point for that
                   behaviour, re-measure, then delete.

Only the standard library is used; coverage.py does not need to be importable.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path

SUPPORTED_SCHEMA = 7
# pytest-cov appends the test phase to each context name.
_PHASE_SUFFIX = re.compile(r"\|(setup|run|teardown)$")

Unit = tuple[str, int, int]  # (relative path, from line, to line); lines use to == from


def _numbits_to_lines(blob: bytes) -> list[int]:
    # Same encoding as coverage.numbits: bit i of byte j marks line j * 8 + i.
    return [j * 8 + i for j, byte in enumerate(blob) for i in range(8) if byte & (1 << i)]


def _open(path: Path) -> sqlite3.Connection:
    if not path.is_file():
        sys.exit(f"error: {path} is not a file")
    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        (version,) = conn.execute("select version from coverage_schema").fetchone()
    except sqlite3.DatabaseError as exc:
        sys.exit(f"error: {path} is not a coverage.py SQLite data file ({exc})")
    if version != SUPPORTED_SCHEMA:
        sys.exit(f"error: {path} has coverage schema {version}; this script reads schema {SUPPORTED_SCHEMA}")
    return conn


def _has_arcs(conn: sqlite3.Connection) -> bool:
    row = conn.execute("select value from meta where key = 'has_arcs'").fetchone()
    return bool(row) and row[0] in ("1", "True", "true")


def _relative(path: str, root: Path) -> str:
    try:
        return os.path.relpath(path, root)
    except ValueError:  # different drive on Windows
        return path


def _units_by_context(conn: sqlite3.Connection, root: Path, arcs: bool) -> dict[str, set[Unit]]:
    by_context: dict[str, set[Unit]] = defaultdict(set)
    if _has_arcs(conn):
        rows = conn.execute(
            "select context.context, file.path, arc.fromno, arc.tono "
            "from arc join file on arc.file_id = file.id join context on arc.context_id = context.id"
        )
        for context, path, fromno, tono in rows:
            rel = _relative(path, root)
            if arcs:
                by_context[context].add((rel, fromno, tono))
            else:
                # Branch data compared against line data: an arc's positive endpoints are executed lines.
                by_context[context].update((rel, n, n) for n in (fromno, tono) if n > 0)
    else:
        rows = conn.execute(
            "select context.context, file.path, line_bits.numbits "
            "from line_bits join file on line_bits.file_id = file.id "
            "join context on line_bits.context_id = context.id"
        )
        for context, path, numbits in rows:
            rel = _relative(path, root)
            by_context[context].update((rel, n, n) for n in _numbits_to_lines(numbits))
    return by_context


def _test_id(context: str) -> str:
    return _PHASE_SUFFIX.sub("", context)


def _test_file(test_id: str) -> str:
    if "::" in test_id:
        return test_id.split("::", 1)[0]
    return test_id.rsplit(".", 1)[0]


def _format_unit(unit: Unit) -> str:
    path, start, end = unit
    return f"{path}:{start}" if start == end else f"{path}:{start}->{end}"


def analyse(keep_path: Path, legacy_path: Path, keep_root: Path, legacy_root: Path) -> dict:
    keep_conn, legacy_conn = _open(keep_path), _open(legacy_path)
    arcs = _has_arcs(keep_conn) and _has_arcs(legacy_conn)

    kept: set[Unit] = set()
    for units in _units_by_context(keep_conn, keep_root, arcs).values():
        kept |= units

    per_test: dict[str, set[Unit]] = defaultdict(set)
    for context, units in _units_by_context(legacy_conn, legacy_root, arcs).items():
        if context == "":  # code run outside any test (imports, collection)
            continue
        per_test[_test_id(context)] |= units
    if not per_test:
        sys.exit(f"error: {legacy_path} has no per-test contexts; record it with --cov-context=test")

    gap_owners: dict[Unit, int] = defaultdict(int)
    for units in per_test.values():
        for unit in units - kept:
            gap_owners[unit] += 1

    deletable, needs_scenario = [], []
    for test_id in sorted(per_test):
        gap = per_test[test_id] - kept
        if not gap:
            deletable.append(test_id)
            continue
        exclusive = sorted(u for u in gap if gap_owners[u] == 1)
        shared = sorted(u for u in gap if gap_owners[u] > 1)
        needs_scenario.append(
            {
                "test": test_id,
                "exclusive": [_format_unit(u) for u in exclusive],
                "shared": [_format_unit(u) for u in shared],
            }
        )

    by_file: dict[str, dict[str, int]] = defaultdict(lambda: {"deletable": 0, "needs_scenario": 0})
    for test_id in deletable:
        by_file[_test_file(test_id)]["deletable"] += 1
    for item in needs_scenario:
        by_file[_test_file(item["test"])]["needs_scenario"] += 1

    return {
        "unit": "arc" if arcs else "line",
        "legacy_tests": len(per_test),
        "gap_units": len(gap_owners),
        "deletable": deletable,
        "needs_scenario": needs_scenario,
        "by_file": dict(sorted(by_file.items())),
    }


def _print_report(result: dict, limit: int) -> None:
    print(f"unit: {result['unit']}")
    print(f"legacy tests: {result['legacy_tests']}")
    print(f"units covered by legacy tests but not by the kept suite: {result['gap_units']}")
    print(f"deletable: {len(result['deletable'])}    needs scenario: {len(result['needs_scenario'])}")
    print()
    print("by test file (deletable / needs scenario):")
    for path, counts in result["by_file"].items():
        print(f"  {path}: {counts['deletable']} / {counts['needs_scenario']}")
    if result["needs_scenario"]:
        print()
        print("needs scenario (gap units; exclusive first):")
        for item in result["needs_scenario"]:
            units = item["exclusive"] + [f"{u} (shared)" for u in item["shared"]]
            shown = ", ".join(units[:limit]) + (f", ... +{len(units) - limit}" if len(units) > limit else "")
            print(f"  {item['test']}: {shown}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--keep", type=Path, required=True, help="coverage data of the suite you keep")
    parser.add_argument("--legacy", type=Path, required=True, help="coverage data of the suite to prune, with per-test contexts")
    parser.add_argument("--keep-root", type=Path, default=Path.cwd(), help="checkout the --keep data was recorded in (default: cwd)")
    parser.add_argument("--legacy-root", type=Path, default=Path.cwd(), help="checkout the --legacy data was recorded in (default: cwd)")
    parser.add_argument("--json", type=Path, help="also write the full result as JSON to this path")
    parser.add_argument("--limit", type=int, default=8, help="gap units shown per test in the text report")
    args = parser.parse_args()

    result = analyse(args.keep, args.legacy, args.keep_root.resolve(), args.legacy_root.resolve())
    _print_report(result, args.limit)
    if args.json:
        args.json.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
