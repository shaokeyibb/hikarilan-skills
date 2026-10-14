#!/usr/bin/env python3
"""Code-site annotations for static gates: parse them, anchor them, reconcile both ways.

An annotation is a comment naming the rule, a category from that rule's closed set, and a reason:

    # gate-<rule>: <category> — <reason>
    # gate-continue: <more of the reason>

`—` may be written `--`. `//` comments work the same way. An annotation on its own line anchors
to the next line of code; one trailing code on the same line anchors to that line. Continuation
lines directly follow the marker and extend its reason.

A rule supplies only the sites it finds. `reconcile` then fails each site without an annotation,
each annotation whose anchor no longer holds a site (stale), each category outside the rule's
closed set, and each annotation without a reason. Run as a script, it prints every annotation grouped by
rule and category for periodic review.

Standard library only. Python files are tokenized, so markers inside strings are ignored; other
files are scanned line by line.
"""

from __future__ import annotations

import argparse
import io
import re
import sys
import tokenize
from collections import defaultdict
from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from pathlib import Path

_MARKER = re.compile(r"(?:#|//)\s*gate-([a-z][a-z0-9-]*):\s*([\w-]+)\s*(?:—|--)\s*(.*)$")
_CONTINUATION = re.compile(r"(?:#|//)\s*gate-continue:\s*(.*)$")


@dataclass(frozen=True)
class Annotation:
    path: str
    line: int  # where the marker is written
    anchor: int  # the code line it applies to
    rule: str
    category: str
    reason: str


@dataclass(frozen=True)
class Site:
    """One place a rule's check matched; `detail` says what it saw."""

    path: str
    line: int
    detail: str = ""


def _comments(text: str, suffix: str) -> Iterable[tuple[int, str, bool]]:
    """Yield (line, comment text, stands alone on its line)."""
    if suffix == ".py":
        lines = text.splitlines()
        try:
            for tok in tokenize.generate_tokens(io.StringIO(text).readline):
                if tok.type == tokenize.COMMENT:
                    row, col = tok.start
                    yield row, tok.string, lines[row - 1][:col].strip() == ""
        except (tokenize.TokenError, SyntaxError):
            return
        return
    for number, raw in enumerate(text.splitlines(), start=1):
        index = min((i for i in (raw.find("//"), raw.find("#")) if i >= 0), default=-1)
        if index >= 0:
            yield number, raw[index:], raw[:index].strip() == ""


def _is_code(line: str) -> bool:
    stripped = line.strip()
    return bool(stripped) and not stripped.startswith(("#", "//"))


def scan_file(path: Path, root: Path) -> list[Annotation]:
    text = path.read_text(encoding="utf-8", errors="replace")
    source_lines = text.splitlines()
    rel = path.resolve().relative_to(root.resolve()).as_posix()
    found: list[Annotation] = []
    pending: dict | None = None

    def close() -> None:
        nonlocal pending
        if pending is not None:
            pending.pop("_last")
            found.append(Annotation(**pending))
            pending = None

    for line, comment, alone in _comments(text, path.suffix):
        cont = _CONTINUATION.match(comment)
        if cont and pending is not None and alone and line == pending["_last"] + 1:
            pending["reason"] = f"{pending['reason']} {cont.group(1).strip()}".strip()
            pending["_last"] = line
            continue
        close()
        marker = _MARKER.match(comment)
        if not marker:
            continue
        anchor = line
        if alone:
            anchor = next(
                (n for n in range(line + 1, len(source_lines) + 1) if _is_code(source_lines[n - 1])),
                line,
            )
        pending = {
            "path": rel,
            "line": line,
            "anchor": anchor,
            "rule": marker.group(1),
            "category": marker.group(2),
            "reason": marker.group(3).strip(),
            "_last": line,
        }
    close()
    return found


def scan(paths: Iterable[Path], root: Path, suffixes: tuple[str, ...] = (".py",)) -> list[Annotation]:
    """Collect annotations from files and directories (directories are walked for `suffixes`)."""
    found: list[Annotation] = []
    for path in paths:
        files = sorted(p for p in path.rglob("*") if p.suffix in suffixes) if path.is_dir() else [path]
        for file in files:
            found.extend(scan_file(file, root))
    return found


def reconcile(
    rule: str,
    sites: Iterable[Site],
    annotations: Iterable[Annotation],
    categories: frozenset[str],
) -> list[str]:
    """Return one error line per problem; an empty list means the gate passes."""
    mine = [a for a in annotations if a.rule == rule]
    by_anchor = {(a.path, a.anchor): a for a in mine}
    site_keys = set()
    errors: list[str] = []
    for site in sorted(sites, key=lambda s: (s.path, s.line)):
        key = (site.path, site.line)
        site_keys.add(key)
        if key not in by_anchor:
            what = f" ({site.detail})" if site.detail else ""
            errors.append(
                f"{site.path}:{site.line}: unannotated {rule} site{what}; "
                f"fix it, or annotate: # gate-{rule}: <{'|'.join(sorted(categories))}> — <reason>"
            )
    for ann in sorted(mine, key=lambda a: (a.path, a.line)):
        if (ann.path, ann.anchor) not in site_keys:
            errors.append(f"{ann.path}:{ann.line}: stale gate-{rule} annotation; no {rule} site at line {ann.anchor}")
        if ann.category not in categories:
            errors.append(
                f"{ann.path}:{ann.line}: unknown gate-{rule} category '{ann.category}'; "
                f"expected one of {', '.join(sorted(categories))}"
            )
        if not ann.reason:
            errors.append(f"{ann.path}:{ann.line}: gate-{rule} annotation has no reason")
    return errors


def report(annotations: Iterable[Annotation], rules: Mapping[str, frozenset[str]] | None = None) -> str:
    """Every annotation grouped by rule and category, for a periodic review of the reasons."""
    grouped: dict[str, dict[str, list[Annotation]]] = defaultdict(lambda: defaultdict(list))
    for ann in annotations:
        grouped[ann.rule][ann.category].append(ann)
    out: list[str] = []
    for rule in sorted(grouped):
        total = sum(len(v) for v in grouped[rule].values())
        out.append(f"gate-{rule}: {total}")
        for category in sorted(grouped[rule]):
            unknown = rules is not None and category not in rules.get(rule, frozenset())
            out.append(f"  {category}{' (unknown category)' if unknown else ''}: {len(grouped[rule][category])}")
            for ann in sorted(grouped[rule][category], key=lambda a: (a.path, a.line)):
                out.append(f"    {ann.path}:{ann.anchor}  {ann.reason}")
    return "\n".join(out)


def main() -> None:
    parser = argparse.ArgumentParser(description="Print every gate annotation grouped by rule and category.")
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="paths in the report are relative to this")
    parser.add_argument("--suffix", action="append", default=None, help="file suffix to scan in directories (repeatable; default .py)")
    args = parser.parse_args()
    suffixes = tuple(args.suffix) if args.suffix else (".py",)
    print(report(scan(args.paths, args.root, suffixes)))


if __name__ == "__main__":
    sys.exit(main())
