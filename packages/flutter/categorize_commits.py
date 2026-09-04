#!/usr/bin/env python3
"""
categorize_commits.py - Categorize recent commits by what areas they touch.

For each of the past N commits on origin/master, determines which areas of the
repo were modified and outputs a per-commit breakdown plus aggregate counts.

Dimensions tracked:
  framework_src  - packages/flutter/lib/    (--split-framework to separate)
  framework_test - packages/flutter/test/   (--split-framework to separate)
  framework      - packages/flutter/lib/ or test/  (default, merged)
  flutter_tools  - packages/flutter_tools/
  engine         - engine/
  deps           - DEPS
  ci_yaml        - .ci.yaml
  dev            - dev/

Usage:
    python3 categorize_commits.py [options]

Examples:
    python3 categorize_commits.py -n 500
    python3 categorize_commits.py -n 1000 --format json
    python3 categorize_commits.py -n 200 --format csv -o commits.csv
    python3 categorize_commits.py -n 500 --split-framework
    python3 categorize_commits.py -n 500 --list
"""

import argparse
import json
import subprocess
import sys
from collections import defaultdict
from typing import Dict, List, Tuple

# Raw dimensions always computed internally
_RAW_DIMENSIONS = [
    ("framework_src",  lambda f: f.startswith("packages/flutter/lib/")),
    ("framework_test", lambda f: f.startswith("packages/flutter/test/")),
    ("flutter_tools",  lambda f: f.startswith("packages/flutter_tools/")),
    ("engine",         lambda f: f.startswith("engine/")),
    ("deps",           lambda f: f == "DEPS"),
    ("ci_yaml",        lambda f: f == ".ci.yaml"),
    ("dev",            lambda f: f.startswith("dev/")),
]

# Merged key order (default)
_MERGED_KEYS = ["framework", "flutter_tools", "engine", "deps", "ci_yaml", "dev", "none_of_above"]
# Split key order
_SPLIT_KEYS = ["framework_src", "framework_test", "flutter_tools", "engine", "deps", "ci_yaml", "dev", "none_of_above"]


def _dim_keys(split: bool) -> List[str]:
    return _SPLIT_KEYS if split else _MERGED_KEYS


def find_repo_root() -> str:
    r = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True,
    )
    return r.stdout.strip() if r.returncode == 0 else "."


def get_commits(repo: str, n: int) -> List[Tuple[str, str]]:
    """Get the last N first-parent commits on origin/master."""
    r = subprocess.run(
        ["git", "log", "--oneline", "-n", str(n), "--first-parent", "origin/master"],
        cwd=repo, capture_output=True, text=True,
    )
    commits = []
    for line in r.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split(None, 1)
        commits.append((parts[0], parts[1] if len(parts) > 1 else ""))
    return commits


def get_changed_files(repo: str, sha: str) -> List[str]:
    """Get list of files changed in a commit (repo-relative paths)."""
    r = subprocess.run(
        ["git", "diff", "--name-only", f"{sha}~1", sha],
        cwd=repo, capture_output=True, text=True,
    )
    if r.returncode != 0:
        return []
    return [line for line in r.stdout.strip().split("\n") if line]


def classify_raw(changed_files: List[str]) -> Dict[str, bool]:
    """Classify which raw dimensions a set of changed files touches."""
    result = {key: False for key, _ in _RAW_DIMENSIONS}
    for f in changed_files:
        for key, matcher in _RAW_DIMENSIONS:
            if not result[key] and matcher(f):
                result[key] = True
    return result


def project_dims(raw: Dict[str, bool], split: bool) -> Dict[str, bool]:
    """Project raw dimensions into the output key set (merged or split)."""
    any_matched = any(raw.values())
    if split:
        result = {k: raw[k] for k in _SPLIT_KEYS if k != "none_of_above"}
        result["none_of_above"] = not any_matched
        return result
    # Merge framework_src and framework_test into "framework"
    merged: Dict[str, bool] = {}
    merged["framework"] = raw["framework_src"] or raw["framework_test"]
    for k in ["flutter_tools", "engine", "deps", "ci_yaml", "dev"]:
        merged[k] = raw[k]
    merged["none_of_above"] = not any_matched
    return merged


def analyze(repo: str, n: int, split: bool) -> Tuple[List[dict], dict]:
    """Analyze N commits and return per-commit records and aggregate summary."""
    commits = get_commits(repo, n)
    total = len(commits)
    dim_keys = _dim_keys(split)
    print(f"Analyzing {total} commits...", file=sys.stderr)

    records: List[dict] = []
    dim_counts = {key: 0 for key in dim_keys}
    combo_counts: Dict[str, int] = defaultdict(int)

    for i, (sha, desc) in enumerate(commits, 1):
        if i % 200 == 0:
            print(f"  Processed {i}/{total}...", file=sys.stderr)

        changed = get_changed_files(repo, sha)
        raw = classify_raw(changed)
        dims = project_dims(raw, split)

        for key in dim_keys:
            if dims[key]:
                dim_counts[key] += 1

        combo_key = "+".join(k for k in dim_keys if dims[k])
        combo_counts[combo_key] += 1

        records.append({
            "sha": sha[:12],
            "description": desc,
            "files_changed": len(changed),
            **{k: dims[k] for k in dim_keys},
        })

    # Cross-tabulation
    cross = {}
    for a in dim_keys:
        for b in dim_keys:
            cross[f"{a}+{b}"] = sum(1 for r in records if r[a] and r[b])

    summary = {
        "total_commits": total,
        "dimension_keys": dim_keys,
        "dimension_counts": dim_counts,
        "dimension_pcts": {
            k: round(v / total * 100, 1) if total else 0
            for k, v in dim_counts.items()
        },
        "combination_counts": dict(
            sorted(combo_counts.items(), key=lambda x: -x[1])
        ),
        "cross_tabulation": cross,
    }

    print(f"  Done.", file=sys.stderr)
    return records, summary


# ---------------------------------------------------------------------------
# Output formatters
# ---------------------------------------------------------------------------

def format_text(records: List[dict], summary: dict, show_list: bool) -> str:
    lines = []
    sep = "=" * 95
    n = summary["total_commits"]
    dim_keys = summary["dimension_keys"]

    lines.append(sep)
    lines.append(f"COMMIT CATEGORIZATION ({n} commits)")
    lines.append(sep)
    lines.append("")

    # Per-dimension counts
    lines.append("Dimension breakdown:")
    lines.append(f"  {'Dimension':<16s} {'Count':>6s} {'%':>7s}")
    lines.append("  " + "-" * 32)
    for key in dim_keys:
        cnt = summary["dimension_counts"][key]
        pct = summary["dimension_pcts"][key]
        bar = "#" * (cnt * 40 // max(n, 1))
        lines.append(f"  {key:<16s} {cnt:>6} {pct:>6.1f}%  {bar}")
    lines.append("")

    # Top combinations
    lines.append("Top combinations (exact set of dimensions touched):")
    lines.append(f"  {'Combination':<50s} {'Count':>6s} {'%':>7s}")
    lines.append("  " + "-" * 66)
    for combo, cnt in summary["combination_counts"].items():
        pct = cnt / n * 100 if n else 0
        lines.append(f"  {combo:<50s} {cnt:>6} {pct:>6.1f}%")
    lines.append("")

    # Cross-tabulation matrix
    lines.append("Cross-tabulation (co-occurrence counts):")
    col_w = max(len(k) for k in dim_keys) + 2
    header = f"  {'':{col_w}s}" + "".join(f"{k:>{col_w}s}" for k in dim_keys)
    lines.append(header)
    for a in dim_keys:
        row = f"  {a:{col_w}s}"
        for b in dim_keys:
            row += f"{summary['cross_tabulation'][f'{a}+{b}']:>{col_w}}"
        lines.append(row)
    lines.append("")

    # Per-commit table (only if --list)
    if show_list:
        lines.append("-" * 95)
        dim_hdrs = "".join(f"{k[:7]:>8s}" for k in dim_keys)
        lines.append(f"{'SHA':<14s} {'Description':<40s}{dim_hdrs}")
        lines.append("-" * 95)
        for r in records:
            flags = "".join(
                f"{'Y':>8s}" if r[k] else f"{'':>8s}" for k in dim_keys
            )
            lines.append(f"{r['sha']:<14s} {r['description'][:38]:<40s}{flags}")

    return "\n".join(lines)


def format_json(records: List[dict], summary: dict, show_list: bool) -> str:
    data = {"summary": summary}
    if show_list:
        data["commits"] = records
    return json.dumps(data, indent=2)


def format_csv(records: List[dict], summary: dict, show_list: bool) -> str:
    dim_keys = summary["dimension_keys"]
    lines = []
    header = ",".join(["sha", "description", "files_changed"] + dim_keys)
    lines.append(header)
    if show_list:
        for r in records:
            desc = r["description"].replace('"', '""')
            vals = [
                r["sha"],
                f'"{desc}"',
                str(r["files_changed"]),
            ] + [str(int(r[k])) for k in dim_keys]
            lines.append(",".join(vals))
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Categorize recent commits by which areas of the repo they touch.",
    )
    parser.add_argument(
        "--commits", "-n",
        type=int,
        default=500,
        help="Number of recent commits to analyze (default: 500)",
    )
    parser.add_argument(
        "--format", "-f",
        choices=["text", "json", "csv"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="Write output to file (default: stdout)",
    )
    parser.add_argument(
        "--list", "-l",
        action="store_true",
        default=False,
        help="Include the full per-commit list in the output (default: off)",
    )
    parser.add_argument(
        "--split-framework",
        action="store_true",
        default=False,
        help=(
            "Split framework into framework_src and framework_test "
            "(default: merged as 'framework')"
        ),
    )
    args = parser.parse_args()

    repo = find_repo_root()
    records, summary = analyze(repo, args.commits, args.split_framework)

    if args.format == "json":
        output = format_json(records, summary, args.list)
    elif args.format == "csv":
        output = format_csv(records, summary, args.list)
    else:
        output = format_text(records, summary, args.list)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
            if not output.endswith("\n"):
                f.write("\n")
        print(f"Results written to: {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
