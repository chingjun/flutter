#!/usr/bin/env python3
"""
analyze_imports.py - Analyze Dart file imports, symbol usage, and dependency cycles.

Given an input CSV with columns (source_file, imported_file, symbol), this script computes:
1. A list of (file, and all its transitive imports)
2. A list of (file, its direct import, number of symbols used from the import)
3. Groups of "import cycles" (Strongly Connected Components), where importing any single
   file in the cycle transitively imports all other files in that cycle.

Usage:
    python3 analyze_imports.py [options] [path_to_all_imports.csv]

Examples:
    python3 analyze_imports.py
    python3 analyze_imports.py --cycles
    python3 analyze_imports.py --format json --output results.json
    python3 analyze_imports.py --direct-symbols --format csv
    python3 analyze_imports.py --transitive --filter widgets/basic.dart
"""

import argparse
import csv
import json
import os
import sys
from collections import defaultdict, deque
from typing import Dict, List, Set, Tuple

# Default path to all_imports.csv in packages/flutter
DEFAULT_CSV_PATHS = [
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "all_imports.csv"),
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "packages", "flutter", "all_imports.csv"),
    os.path.join(os.getcwd(), "packages", "flutter", "all_imports.csv"),
    os.path.join(os.getcwd(), "all_imports.csv"),
]


def find_default_csv() -> str:
    for path in DEFAULT_CSV_PATHS:
        if os.path.isfile(path):
            return os.path.abspath(path)
    return DEFAULT_CSV_PATHS[0]


class ImportAnalyzer:
    def __init__(self, csv_path: str):
        self.csv_path = csv_path
        self.direct_imports: Dict[str, Set[str]] = defaultdict(set)
        self.direct_symbols: Dict[Tuple[str, str], Set[str]] = defaultdict(set)
        self.all_nodes: Set[str] = set()
        self.all_sources: Set[str] = set()
        self.all_imported: Set[str] = set()
        self.total_rows = 0

        self._load_csv()

    def _load_csv(self) -> None:
        if not os.path.isfile(self.csv_path):
            raise FileNotFoundError(f"Input CSV file not found: {self.csv_path}")

        with open(self.csv_path, mode="r", encoding="utf-8") as f:
            reader = csv.reader(f)
            header = next(reader, None)
            # Expect header: source_file, imported_file, symbol
            for row in reader:
                if not row or len(row) < 3:
                    continue
                self.total_rows += 1
                src, imp, sym = row[0].strip(), row[1].strip(), row[2].strip()
                if not src or not imp:
                    continue
                self.direct_imports[src].add(imp)
                if sym:
                    self.direct_symbols[(src, imp)].add(sym)
                else:
                    # In case row has empty symbol, record direct edge
                    _ = self.direct_symbols[(src, imp)]
                self.all_nodes.add(src)
                self.all_nodes.add(imp)
                self.all_sources.add(src)
                self.all_imported.add(imp)

    def compute_transitive_imports(self, include_all_nodes: bool = False) -> Dict[str, List[str]]:
        """
        Computes transitive imports for each file.
        Returns a dictionary mapping file -> sorted list of transitively imported files.
        Transitive imports are all files reachable via directed paths of length >= 1.
        """
        target_nodes = sorted(self.all_nodes if include_all_nodes else self.all_sources)
        transitive_map: Dict[str, List[str]] = {}

        for src in target_nodes:
            visited: Set[str] = set()
            queue = deque(self.direct_imports.get(src, set()))
            while queue:
                curr = queue.popleft()
                if curr not in visited:
                    visited.add(curr)
                    for nxt in self.direct_imports.get(curr, set()):
                        if nxt not in visited:
                            queue.append(nxt)
            transitive_map[src] = sorted(visited)

        return transitive_map

    def compute_direct_import_symbol_counts(self) -> List[Tuple[str, str, int, List[str]]]:
        """
        Computes direct import symbol counts for each (source_file, imported_file) pair.
        Returns a sorted list of (source_file, imported_file, symbol_count, symbols_list).
        """
        results = []
        for (src, imp), syms in self.direct_symbols.items():
            results.append((src, imp, len(syms), sorted(syms)))

        # Sort by source_file, then imported_file
        results.sort(key=lambda x: (x[0], x[1]))
        return results

    def compute_import_cycles(self) -> List[List[str]]:
        """
        Detects groups of import cycles (Strongly Connected Components with size > 1 or self-loops).
        In any such group, importing any single file will transitively import all other files in the group.
        Returns a list of cycle groups, sorted by size descending, then alphabetically.
        """
        sys_rec_limit = sys.getrecursionlimit()
        if len(self.all_nodes) * 2 > sys_rec_limit:
            sys.setrecursionlimit(max(sys_rec_limit, len(self.all_nodes) * 2))

        index = 0
        indices: Dict[str, int] = {}
        lowlink: Dict[str, int] = {}
        on_stack: Set[str] = set()
        stack: List[str] = []
        sccs: List[List[str]] = []

        def strongconnect(node: str):
            nonlocal index
            indices[node] = index
            lowlink[node] = index
            index += 1
            stack.append(node)
            on_stack.add(node)

            for neighbor in sorted(self.direct_imports.get(node, set())):
                if neighbor not in indices:
                    strongconnect(neighbor)
                    lowlink[node] = min(lowlink[node], lowlink[neighbor])
                elif neighbor in on_stack:
                    lowlink[node] = min(lowlink[node], indices[neighbor])

            if lowlink[node] == indices[node]:
                scc = []
                while True:
                    w = stack.pop()
                    on_stack.remove(w)
                    scc.append(w)
                    if w == node:
                        break
                # Only include non-trivial SCCs (size > 1 or self-loop)
                if len(scc) > 1 or (len(scc) == 1 and scc[0] in self.direct_imports.get(scc[0], set())):
                    sccs.append(sorted(scc))

        for node in sorted(self.all_nodes):
            if node not in indices:
                strongconnect(node)

        # Sort cycles by size descending, then by first filename
        sccs.sort(key=lambda c: (-len(c), c[0]))
        return sccs

    @staticmethod
    def count_lines(file_path: str) -> int:
        """Returns the number of lines in the given file, or 0 if unreadable."""
        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                return sum(1 for _ in f)
        except (OSError, IOError):
            return 0

    @staticmethod
    def count_lines_in_cycle(cycle: List[str]) -> int:
        """Returns the total line count for all files in a cycle group."""
        return sum(ImportAnalyzer.count_lines(f) for f in cycle)


def format_text_output(
    analyzer: ImportAnalyzer,
    transitive: Dict[str, List[str]],
    direct_symbols: List[Tuple[str, str, int, List[str]]],
    cycles: List[List[str]],
    show_transitive: bool = True,
    show_direct: bool = True,
    show_cycles: bool = True,
    filter_pattern: str = "",
    max_items: int = 0,
) -> str:
    lines = []
    separator = "=" * 80

    lines.append(separator)
    lines.append("FLUTTER IMPORT DEPENDENCY & CYCLE ANALYSIS")
    lines.append(separator)
    lines.append(f"Input CSV: {analyzer.csv_path}")
    lines.append(f"Total CSV Rows: {analyzer.total_rows:,}")
    lines.append(f"Total Unique Files: {len(analyzer.all_nodes):,}")
    lines.append(f"Total Source Files: {len(analyzer.all_sources):,}")
    lines.append(f"Total Direct Import Edges: {len(direct_symbols):,}")
    lines.append(f"Total Import Cycle Groups: {len(cycles):,}")
    lines.append(separator)

    # 1. Transitive Imports
    if show_transitive:
        filtered_transitive = {
            k: v for k, v in transitive.items()
            if not filter_pattern or filter_pattern in k
        }
        lines.append("")
        lines.append(f"--- 1. TRANSITIVE IMPORTS ({len(filtered_transitive):,} files) ---")
        lines.append("Format: File -> [Transitive Imports Count] (List of transitively imported files)")
        lines.append("-" * 80)
        items = list(filtered_transitive.items())
        if max_items > 0 and len(items) > max_items:
            items_to_show = items[:max_items]
            has_more = len(items) - max_items
        else:
            items_to_show = items
            has_more = 0

        for src, imps in items_to_show:
            lines.append(f"\nFile: {src}")
            lines.append(f"  Direct Imports Count: {len(analyzer.direct_imports.get(src, set()))}")
            lines.append(f"  Transitive Imports Count: {len(imps)}")
            for imp in imps:
                lines.append(f"    - {imp}")

        if has_more > 0:
            lines.append(f"\n... and {has_more:,} more files (use --max-items 0 or export to JSON/CSV for full list).")

    # 2. Direct Imports & Symbol Usage
    if show_direct:
        filtered_direct = [
            (src, imp, cnt, syms) for src, imp, cnt, syms in direct_symbols
            if not filter_pattern or (filter_pattern in src or filter_pattern in imp)
        ]
        lines.append("")
        lines.append(f"--- 2. DIRECT IMPORTS AND SYMBOLS USED ({len(filtered_direct):,} pairs) ---")
        lines.append("Format: (Source File, Direct Import, Symbols Count, Symbols List)")
        lines.append("-" * 80)
        if max_items > 0 and len(filtered_direct) > max_items:
            items_to_show = filtered_direct[:max_items]
            has_more = len(filtered_direct) - max_items
        else:
            items_to_show = filtered_direct
            has_more = 0

        for src, imp, cnt, syms in items_to_show:
            syms_preview = ", ".join(syms[:5]) + (f" ... (+{len(syms)-5} more)" if len(syms) > 5 else "")
            lines.append(f"Source: {src}")
            lines.append(f"  Imports: {imp}")
            lines.append(f"  Symbols Count: {cnt} ({syms_preview})")

        if has_more > 0:
            lines.append(f"\n... and {has_more:,} more direct import pairs (use --max-items 0 or export to JSON/CSV for full list).")

    # 3. Import Cycles
    if show_cycles:
        lines.append("")
        lines.append(f"--- 3. IMPORT CYCLES ({len(cycles):,} cycle groups detected) ---")
        lines.append("Definition: In each cycle group, importing ANY single file transitively imports ALL other files in the group.")
        lines.append("-" * 80)
        for i, cycle in enumerate(cycles, 1):
            total_lines = ImportAnalyzer.count_lines_in_cycle(cycle)
            lines.append(f"\n[Cycle Group #{i}] ({len(cycle)} files, {total_lines:,} lines):")
            for f in cycle:
                lines.append(f"  * {f}")

    return "\n".join(lines)


def format_json_output(
    analyzer: ImportAnalyzer,
    transitive: Dict[str, List[str]],
    direct_symbols: List[Tuple[str, str, int, List[str]]],
    cycles: List[List[str]],
    show_transitive: bool = True,
    show_direct: bool = True,
    show_cycles: bool = True,
    filter_pattern: str = "",
) -> str:
    data = {
        "metadata": {
            "csv_path": analyzer.csv_path,
            "total_rows": analyzer.total_rows,
            "total_unique_files": len(analyzer.all_nodes),
            "total_source_files": len(analyzer.all_sources),
            "total_direct_imports": len(direct_symbols),
            "total_cycle_groups": len(cycles),
        }
    }

    if show_transitive:
        data["transitive_imports"] = {
            src: imps for src, imps in transitive.items()
            if not filter_pattern or filter_pattern in src
        }

    if show_direct:
        data["direct_imports_and_symbols"] = [
            {
                "source_file": src,
                "imported_file": imp,
                "symbols_count": cnt,
                "symbols": syms,
            }
            for src, imp, cnt, syms in direct_symbols
            if not filter_pattern or (filter_pattern in src or filter_pattern in imp)
        ]

    if show_cycles:
        data["import_cycles"] = [
            {
                "cycle_index": i,
                "file_count": len(cycle),
                "total_line_count": ImportAnalyzer.count_lines_in_cycle(cycle),
                "files": cycle,
            }
            for i, cycle in enumerate(cycles, 1)
            if not filter_pattern or any(filter_pattern in f for f in cycle)
        ]

    return json.dumps(data, indent=2)


def format_csv_output(
    transitive: Dict[str, List[str]],
    direct_symbols: List[Tuple[str, str, int, List[str]]],
    cycles: List[List[str]],
    show_transitive: bool = True,
    show_direct: bool = True,
    show_cycles: bool = True,
    filter_pattern: str = "",
) -> str:
    lines = []
    if show_direct and not (show_transitive or show_cycles):
        lines.append("source_file,imported_file,symbol_count,symbols")
        for src, imp, cnt, syms in direct_symbols:
            if not filter_pattern or (filter_pattern in src or filter_pattern in imp):
                lines.append(f'"{src}","{imp}",{cnt},"{";".join(syms)}"')
        return "\n".join(lines)

    if show_transitive and not (show_direct or show_cycles):
        lines.append("file,transitive_imports_count,transitive_imports")
        for src, imps in transitive.items():
            if not filter_pattern or filter_pattern in src:
                lines.append(f'"{src}",{len(imps)},"{";".join(imps)}"')
        return "\n".join(lines)

    if show_cycles and not (show_transitive or show_direct):
        lines.append("cycle_id,cycle_size,total_line_count,file")
        for i, cycle in enumerate(cycles, 1):
            if not filter_pattern or any(filter_pattern in f for f in cycle):
                total_lines = ImportAnalyzer.count_lines_in_cycle(cycle)
                for f in cycle:
                    lines.append(f'{i},{len(cycle)},{total_lines},"{f}"')
        return "\n".join(lines)

    # If multiple sections in CSV, output multi-section text
    lines.append("# SECTION 1: TRANSITIVE IMPORTS")
    lines.append("file,transitive_imports_count,transitive_imports")
    for src, imps in transitive.items():
        if not filter_pattern or filter_pattern in src:
            lines.append(f'"{src}",{len(imps)},"{";".join(imps)}"')

    lines.append("\n# SECTION 2: DIRECT IMPORTS AND SYMBOL COUNTS")
    lines.append("source_file,imported_file,symbol_count,symbols")
    for src, imp, cnt, syms in direct_symbols:
        if not filter_pattern or (filter_pattern in src or filter_pattern in imp):
            lines.append(f'"{src}","{imp}",{cnt},"{";".join(syms)}"')

    lines.append("\n# SECTION 3: IMPORT CYCLES")
    lines.append("cycle_id,cycle_size,total_line_count,file")
    for i, cycle in enumerate(cycles, 1):
        if not filter_pattern or any(filter_pattern in f for f in cycle):
            total_lines = ImportAnalyzer.count_lines_in_cycle(cycle)
            for f in cycle:
                lines.append(f'{i},{len(cycle)},{total_lines},"{f}"')

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Analyze imports, symbol usage, and detect dependency cycles from an all_imports.csv file."
    )
    parser.add_argument(
        "csv_file",
        nargs="?",
        default=None,
        help="Path to all_imports.csv (default: autodetected or packages/flutter/all_imports.csv)",
    )
    parser.add_argument(
        "--csv",
        dest="csv_flag",
        default=None,
        help="Explicit path to all_imports.csv",
    )
    parser.add_argument(
        "-t",
        "--transitive",
        action="store_true",
        help="Output list of (file, and all its transitive imports)",
    )
    parser.add_argument(
        "-s",
        "--direct-symbols",
        action="store_true",
        help="Output list of (file, its direct import, number of symbols used)",
    )
    parser.add_argument(
        "-c",
        "--cycles",
        action="store_true",
        help="Output groups of import cycles",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Output all three analyses (default if no specific section is specified)",
    )
    parser.add_argument(
        "-f",
        "--format",
        choices=["text", "json", "csv"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Path to write output to (default: stdout)",
    )
    parser.add_argument(
        "--filter",
        default="",
        help="Filter results by file substring/pattern",
    )
    parser.add_argument(
        "--max-items",
        type=int,
        default=0,
        help="Limit number of items to display in text preview (0 = unlimited, default: 0)",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Display summary metrics only",
    )

    args = parser.parse_args()

    csv_path = args.csv_flag or args.csv_file or find_default_csv()
    if not os.path.isfile(csv_path):
        print(f"Error: CSV file not found at '{csv_path}'", file=sys.stderr)
        sys.exit(1)

    # Initialize analyzer
    analyzer = ImportAnalyzer(csv_path)

    # Determine which sections to compute/output
    if not (args.transitive or args.direct_symbols or args.cycles):
        show_transitive = True
        show_direct = True
        show_cycles = True
    else:
        show_transitive = args.transitive or args.all
        show_direct = args.direct_symbols or args.all
        show_cycles = args.cycles or args.all

    # Compute requested parts
    transitive = analyzer.compute_transitive_imports() if (show_transitive or show_cycles or args.summary) else {}
    direct_symbols = analyzer.compute_direct_import_symbol_counts() if (show_direct or args.summary) else []
    cycles = analyzer.compute_import_cycles() if (show_cycles or args.summary) else []

    if args.summary:
        print("=" * 80)
        print("IMPORT ANALYSIS SUMMARY")
        print("=" * 80)
        print(f"CSV File: {analyzer.csv_path}")
        print(f"Total Rows: {analyzer.total_rows:,}")
        print(f"Total Unique Files: {len(analyzer.all_nodes):,}")
        print(f"Total Source Files: {len(analyzer.all_sources):,}")
        print(f"Total Direct Import Edges: {len(direct_symbols):,}")
        print(f"Total Cycle Groups (SCCs > 1): {len(cycles):,}")
        print(f"Total Files in Cycles: {sum(len(c) for c in cycles):,}")
        print(f"Total Lines in Cycles: {sum(ImportAnalyzer.count_lines_in_cycle(c) for c in cycles):,}")
        print("\nCycle Groups Breakdown:")
        for i, c in enumerate(cycles, 1):
            total_lines = ImportAnalyzer.count_lines_in_cycle(c)
            print(f"  Group {i:2d}: {len(c):3d} files, {total_lines:6,} lines (e.g. {os.path.basename(c[0])})")
        print("=" * 80)
        return

    # Format output
    if args.format == "json":
        output_str = format_json_output(
            analyzer,
            transitive,
            direct_symbols,
            cycles,
            show_transitive=show_transitive,
            show_direct=show_direct,
            show_cycles=show_cycles,
            filter_pattern=args.filter,
        )
    elif args.format == "csv":
        output_str = format_csv_output(
            transitive,
            direct_symbols,
            cycles,
            show_transitive=show_transitive,
            show_direct=show_direct,
            show_cycles=show_cycles,
            filter_pattern=args.filter,
        )
    else:
        output_str = format_text_output(
            analyzer,
            transitive,
            direct_symbols,
            cycles,
            show_transitive=show_transitive,
            show_direct=show_direct,
            show_cycles=show_cycles,
            filter_pattern=args.filter,
            max_items=args.max_items,
        )

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_str)
            if not output_str.endswith("\n"):
                f.write("\n")
        print(f"Results written to: {args.output}")
    else:
        print(output_str)


if __name__ == "__main__":
    main()
