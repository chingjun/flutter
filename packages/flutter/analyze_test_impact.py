#!/usr/bin/env python3
"""
analyze_test_impact.py - Analyze how many tests each commit would trigger.

Uses the analyzer-resolved import graph (all_imports.csv) to determine which
test files transitively depend on each changed library file. For each of the
past N commits, reports how many tests would be triggered by the changes vs
running the full test suite.

Usage:
    python3 analyze_test_impact.py [options]

Examples:
    python3 analyze_test_impact.py --commits 500
    python3 analyze_test_impact.py --commits 200 --format json
    python3 analyze_test_impact.py --csv all_imports.csv --commits 100
"""

import argparse
import csv
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from typing import Dict, List, Optional, Set, Tuple


def find_repo_root() -> str:
    """Find the git repo root from the current directory."""
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True,
    )
    if result.returncode == 0:
        return result.stdout.strip()
    # Fallback: walk up from script location
    path = os.path.dirname(os.path.abspath(__file__))
    while path != os.path.dirname(path):
        if os.path.isdir(os.path.join(path, ".git")):
            return path
        path = os.path.dirname(path)
    return os.getcwd()


def find_default_csv(repo_root: str) -> str:
    """Find the default all_imports.csv file."""
    candidates = [
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "all_imports.csv"),
        os.path.join(repo_root, "packages", "flutter", "all_imports.csv"),
    ]
    for path in candidates:
        if os.path.isfile(path):
            return os.path.abspath(path)
    return candidates[0]


# ---------------------------------------------------------------------------
# Import graph from CSV (analyzer-resolved, lib files only)
# ---------------------------------------------------------------------------

def build_lib_graph(csv_path: str) -> Tuple[Dict[str, Set[str]], Set[str]]:
    """
    Build a forward import graph from the all_imports.csv file.

    Returns:
        graph: dict mapping source file -> set of imported files
        all_files: set of all files in the graph
    """
    graph: Dict[str, Set[str]] = defaultdict(set)
    all_files: Set[str] = set()

    with open(csv_path, encoding="utf-8") as f:
        reader = csv.reader(f)
        next(reader)  # skip header
        for row in reader:
            if len(row) < 3:
                continue
            src, imp = row[0].strip(), row[1].strip()
            if not src or not imp or src == imp:
                continue
            src = os.path.normpath(src)
            imp = os.path.normpath(imp)
            graph[src].add(imp)
            all_files.add(src)
            all_files.add(imp)

    return graph, all_files


def build_reverse_graph(graph: Dict[str, Set[str]]) -> Dict[str, Set[str]]:
    """Build a reverse graph: for each file, which files import it."""
    rev: Dict[str, Set[str]] = defaultdict(set)
    for src, deps in graph.items():
        for dep in deps:
            rev[dep].add(src)
    return rev


# ---------------------------------------------------------------------------
# Test file import graph (parsed from source)
# ---------------------------------------------------------------------------

def resolve_import_uri(
    uri: str, from_file: str, lib_dir: str, package_roots: Dict[str, str],
) -> Optional[str]:
    """Resolve a Dart import/export URI to an absolute file path."""
    if uri.startswith("dart:"):
        return None
    if uri.startswith("package:"):
        m = re.match(r"package:(\w+)/(.*)", uri)
        if m:
            pkg, path = m.group(1), m.group(2)
            if pkg in package_roots:
                resolved = os.path.join(package_roots[pkg], "lib", path)
                if os.path.isfile(resolved):
                    return os.path.normpath(resolved)
        return None
    # Relative import
    resolved = os.path.normpath(os.path.join(os.path.dirname(from_file), uri))
    if os.path.isfile(resolved):
        return resolved
    return None


def parse_dart_imports(filepath: str) -> List[str]:
    """Parse import/export URIs from a Dart file."""
    uris: List[str] = []
    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if "@docImport" in line:
                    continue
                m = re.match(r"(?:import|export)\s+'([^']+)'", line)
                if m:
                    uris.append(m.group(1))
    except IOError:
        pass
    return uris


def collect_test_deps(
    test_dir: str, lib_dir: str, package_roots: Dict[str, str],
) -> Tuple[Set[str], Dict[str, Set[str]]]:
    """
    Walk the test directory, find all test files, and build their import graph.

    Returns:
        test_files: set of *_test.dart file paths
        test_graph: dict mapping test/helper file -> set of imported files
    """
    test_files: Set[str] = set()
    test_graph: Dict[str, Set[str]] = defaultdict(set)

    for root, _, fnames in os.walk(test_dir):
        for fn in fnames:
            if not fn.endswith(".dart"):
                continue
            fp = os.path.normpath(os.path.join(root, fn))
            if fn.endswith("_test.dart"):
                test_files.add(fp)
            for uri in parse_dart_imports(fp):
                resolved = resolve_import_uri(uri, fp, lib_dir, package_roots)
                if resolved:
                    test_graph[fp].add(resolved)

    return test_files, test_graph


# ---------------------------------------------------------------------------
# Transitive reverse dependency computation
# ---------------------------------------------------------------------------

def transitive_reverse_dependents(
    seeds: Set[str], rev_graph: Dict[str, Set[str]],
) -> Set[str]:
    """
    Compute the set of all files that transitively depend on any seed file.

    Uses BFS on the reverse graph: starting from each seed, follow reverse
    edges to find everything that directly or indirectly imports a seed.
    """
    visited: Set[str] = set()
    queue = list(seeds)
    while queue:
        node = queue.pop()
        if node in visited:
            continue
        visited.add(node)
        for dependent in rev_graph.get(node, ()):
            if dependent not in visited:
                queue.append(dependent)
    return visited


# ---------------------------------------------------------------------------
# Git operations
# ---------------------------------------------------------------------------

def get_flutter_commits(repo: str, n: int) -> List[Tuple[str, str]]:
    """
    Get the last N commits on origin/master that touched packages/flutter/lib
    or packages/flutter/test.

    Returns a list of (sha, description) tuples.
    """
    r = subprocess.run(
        [
            "git", "log", "--oneline", "-n", str(n),
            "--first-parent", "origin/master",
            "--", "packages/flutter/lib/", "packages/flutter/test/",
        ],
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


# ---------------------------------------------------------------------------
# Change classification heuristics
# ---------------------------------------------------------------------------

def classify_change(changed_files: List[str]) -> str:
    """
    Classify a commit's change set using heuristics:
      - "framework-only": Only packages/flutter/lib/ files changed.
      - "test-only":      Only packages/flutter/test/ files changed.
      - "framework+test": Both lib/ and test/ changed.
      - "non-flutter":    No packages/flutter/ changes (engine, dev, tools, etc.).
      - "mixed":          Flutter changes plus non-flutter changes.
    """
    has_lib = False
    has_test = False
    has_non_flutter = False

    for f in changed_files:
        if f.startswith("packages/flutter/lib/"):
            has_lib = True
        elif f.startswith("packages/flutter/test/"):
            has_test = True
        elif not f.startswith("packages/flutter/"):
            has_non_flutter = True

    if has_lib and not has_test and not has_non_flutter:
        return "framework-only"
    if has_test and not has_lib and not has_non_flutter:
        return "test-only"
    if has_lib and has_test and not has_non_flutter:
        return "framework+test"
    if not has_lib and not has_test:
        return "non-flutter"
    return "mixed"


# ---------------------------------------------------------------------------
# Per-commit impact analysis
# ---------------------------------------------------------------------------

def analyze_commit(
    repo: str,
    sha: str,
    desc: str,
    combined_rev: Dict[str, Set[str]],
    test_files: Set[str],
    total_tests: int,
) -> Optional[dict]:
    """
    Analyze a single commit to determine test impact.

    Returns a dict with commit info and test counts, or None if skipped.
    """
    changed = get_changed_files(repo, sha)
    if not changed:
        return None

    change_type = classify_change(changed)

    # Resolve changed files to absolute paths
    fl_lib = [
        os.path.normpath(os.path.join(repo, f))
        for f in changed if f.startswith("packages/flutter/lib/")
    ]
    fl_test = [
        os.path.normpath(os.path.join(repo, f))
        for f in changed if f.startswith("packages/flutter/test/")
    ]

    if not fl_lib and not fl_test:
        return None

    # Compute targeted tests via transitive reverse dependencies
    affected = transitive_reverse_dependents(set(fl_lib), combined_rev)
    targeted_tests = affected & test_files

    # Also include directly changed test files
    for t in fl_test:
        if t in test_files:
            targeted_tests.add(t)

    targeted = len(targeted_tests)
    savings = total_tests - targeted
    savings_pct = (savings / total_tests * 100) if total_tests > 0 else 0

    return {
        "sha": sha[:12],
        "description": desc,
        "change_type": change_type,
        "lib_files_changed": len(fl_lib),
        "test_files_changed": len(fl_test),
        "total_tests": total_tests,
        "targeted_tests": targeted,
        "savings": savings,
        "savings_pct": round(savings_pct, 1),
    }


# ---------------------------------------------------------------------------
# Output formatting
# ---------------------------------------------------------------------------

def compute_summary(results: List[dict]) -> dict:
    """Compute summary statistics from per-commit results."""
    if not results:
        return {}

    total_all = sum(r["total_tests"] for r in results)
    total_targeted = sum(r["targeted_tests"] for r in results)
    total_savings = total_all - total_targeted
    savings_pcts = sorted(r["savings_pct"] for r in results)
    n = len(savings_pcts)
    median = (
        savings_pcts[n // 2]
        if n % 2 == 1
        else (savings_pcts[n // 2 - 1] + savings_pcts[n // 2]) / 2
    )

    # Distribution buckets
    buckets = {"0%": 0, "1-25%": 0, "26-50%": 0, "51-75%": 0, "76-100%": 0}
    for pct in savings_pcts:
        if pct == 0:
            buckets["0%"] += 1
        elif pct <= 25:
            buckets["1-25%"] += 1
        elif pct <= 50:
            buckets["26-50%"] += 1
        elif pct <= 75:
            buckets["51-75%"] += 1
        else:
            buckets["76-100%"] += 1

    # Breakdown by change type
    type_breakdown = defaultdict(lambda: {"count": 0, "all": 0, "targeted": 0})
    for r in results:
        tb = type_breakdown[r["change_type"]]
        tb["count"] += 1
        tb["all"] += r["total_tests"]
        tb["targeted"] += r["targeted_tests"]

    return {
        "commits_analyzed": len(results),
        "total_test_runs_all": total_all,
        "total_test_runs_targeted": total_targeted,
        "total_savings": total_savings,
        "overall_savings_pct": round(
            total_savings / total_all * 100 if total_all else 0, 1
        ),
        "mean_savings_pct": round(sum(savings_pcts) / n, 1),
        "median_savings_pct": round(median, 1),
        "avg_tests_per_commit_all": round(total_all / n),
        "avg_tests_per_commit_targeted": round(total_targeted / n),
        "savings_distribution": buckets,
        "change_type_breakdown": {
            k: {
                "count": v["count"],
                "total_test_runs": v["all"],
                "targeted_test_runs": v["targeted"],
                "savings_pct": round(
                    (v["all"] - v["targeted"]) / v["all"] * 100 if v["all"] else 0, 1
                ),
            }
            for k, v in sorted(type_breakdown.items())
        },
    }


def format_text(summary: dict, results: List[dict]) -> str:
    """Format results as human-readable text."""
    lines = []
    sep = "=" * 90
    lines.append(sep)
    lines.append("TEST IMPACT ANALYSIS")
    lines.append(sep)
    lines.append(f"Commits analyzed:                  {summary['commits_analyzed']}")
    lines.append(f"Total test-runs (all tests):        {summary['total_test_runs_all']:>10,}")
    lines.append(f"Total test-runs (targeted):         {summary['total_test_runs_targeted']:>10,}")
    lines.append(f"Total savings:                      {summary['total_savings']:>10,}  ({summary['overall_savings_pct']}%)")
    lines.append(f"Avg tests/commit (all):             {summary['avg_tests_per_commit_all']:>10,}")
    lines.append(f"Avg tests/commit (targeted):        {summary['avg_tests_per_commit_targeted']:>10,}")
    lines.append(f"Mean savings per commit:            {summary['mean_savings_pct']:>9}%")
    lines.append(f"Median savings per commit:          {summary['median_savings_pct']:>9}%")
    lines.append("")

    lines.append("Savings distribution:")
    for bucket, count in summary["savings_distribution"].items():
        bar = "#" * (count * 40 // max(summary["commits_analyzed"], 1))
        lines.append(f"  {bucket:>8s}: {count:>4} commits  {bar}")
    lines.append("")

    lines.append("Breakdown by change type:")
    lines.append(f"  {'Type':<20s} {'Count':>6s} {'All':>10s} {'Targeted':>10s} {'Savings':>8s}")
    lines.append("  " + "-" * 58)
    for ctype, info in summary["change_type_breakdown"].items():
        lines.append(
            f"  {ctype:<20s} {info['count']:>6} "
            f"{info['total_test_runs']:>10,} "
            f"{info['targeted_test_runs']:>10,} "
            f"{info['savings_pct']:>7}%"
        )
    lines.append("")

    # Per-commit detail
    lines.append("-" * 90)
    hdr = (
        f"{'SHA':<14s} {'Description':<40s} {'Type':<16s} "
        f"{'Lib':>3s} {'Tst':>3s} {'Tgt':>5s} {'Save%':>6s}"
    )
    lines.append(hdr)
    lines.append("-" * 90)
    for r in results:
        lines.append(
            f"{r['sha']:<14s} {r['description'][:38]:<40s} {r['change_type']:<16s} "
            f"{r['lib_files_changed']:>3} {r['test_files_changed']:>3} "
            f"{r['targeted_tests']:>5} {r['savings_pct']:>5.1f}%"
        )
    lines.append("-" * 90)
    lines.append(
        f"{'TOTAL':<14s} {'':<40s} {'':<16s} "
        f"{'':>3s} {'':>3s} "
        f"{summary['total_test_runs_targeted']:>5} {summary['overall_savings_pct']:>5.1f}%"
    )

    return "\n".join(lines)


def format_json(summary: dict, results: List[dict]) -> str:
    """Format results as JSON."""
    return json.dumps({"summary": summary, "commits": results}, indent=2)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description=(
            "Analyze how many tests each recent commit would trigger, "
            "using the analyzer-resolved import graph."
        ),
    )
    parser.add_argument(
        "--csv",
        default=None,
        help="Path to all_imports.csv (default: auto-detected)",
    )
    parser.add_argument(
        "--commits", "-n",
        type=int,
        default=500,
        help="Number of recent flutter commits to analyze (default: 500)",
    )
    parser.add_argument(
        "--format", "-f",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="Write output to this file (default: stdout)",
    )
    args = parser.parse_args()

    repo = find_repo_root()
    csv_path = args.csv or find_default_csv(repo)
    flutter_lib = os.path.join(repo, "packages", "flutter", "lib")
    flutter_test = os.path.join(repo, "packages", "flutter", "test")

    if not os.path.isfile(csv_path):
        print(f"Error: CSV file not found at '{csv_path}'", file=sys.stderr)
        print(
            "Run:  flutter analyze --output-imports=packages/flutter/all_imports.csv "
            "packages/flutter/lib/",
            file=sys.stderr,
        )
        sys.exit(1)

    # Package roots for resolving test imports
    package_roots: Dict[str, str] = {}
    pkg_dir = os.path.join(repo, "packages")
    if os.path.isdir(pkg_dir):
        for pkg in os.listdir(pkg_dir):
            p = os.path.join(pkg_dir, pkg)
            if os.path.isdir(p) and os.path.isfile(os.path.join(p, "pubspec.yaml")):
                package_roots[pkg] = p

    # 1. Build the lib import graph from the analyzer CSV
    print("Building analyzer-resolved import graph...", file=sys.stderr)
    lib_graph, lib_files = build_lib_graph(csv_path)
    lib_rev = build_reverse_graph(lib_graph)
    print(f"  Lib files: {len(lib_files)}", file=sys.stderr)
    print(
        f"  Lib edges: {sum(len(v) for v in lib_graph.values())}",
        file=sys.stderr,
    )

    # 2. Build the test import graph by parsing test source files
    print("Building test import graph...", file=sys.stderr)
    test_files, test_graph = collect_test_deps(flutter_test, flutter_lib, package_roots)
    print(f"  Test files: {len(test_files)}", file=sys.stderr)

    # 3. Merge test edges into the lib reverse graph so that transitive
    #    reverse deps of a lib file include the test files that import it.
    combined_rev: Dict[str, Set[str]] = defaultdict(set)
    for node, deps in lib_rev.items():
        combined_rev[node].update(deps)
    for test_fp, imports in test_graph.items():
        for imp in imports:
            combined_rev[imp].add(test_fp)

    total_tests = len(test_files)
    print(f"  Combined reverse-graph nodes: {len(combined_rev)}", file=sys.stderr)
    print(file=sys.stderr)

    # 4. Fetch commits and analyze each one
    commits = get_flutter_commits(repo, args.commits)
    print(
        f"Analyzing {len(commits)} commits on origin/master...", file=sys.stderr,
    )

    results: List[dict] = []
    for i, (sha, desc) in enumerate(commits, 1):
        if i % 100 == 0:
            print(f"  Processed {i}/{len(commits)} commits...", file=sys.stderr)
        r = analyze_commit(repo, sha, desc, combined_rev, test_files, total_tests)
        if r is not None:
            results.append(r)

    print(f"  Done. {len(results)} commits with flutter changes.", file=sys.stderr)
    print(file=sys.stderr)

    # 5. Compute summary and format output
    summary = compute_summary(results)
    if args.format == "json":
        output = format_json(summary, results)
    else:
        output = format_text(summary, results)

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
