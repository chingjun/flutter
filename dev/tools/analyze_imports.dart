// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Processes all_imports.csv to compute:
/// 1. A list of (file, and all its transitive imports)
/// 2. A list of (file, its direct import, number of symbols used from the import)
/// 3. Groups of "import cycles" (Strongly Connected Components).
void main(List<String> args) {
  String? csvPath;
  bool showTransitive = false;
  bool showDirect = false;
  bool showCycles = false;
  bool showSummary = false;
  String format = 'text';
  String? outputPath;
  String filter = '';
  int maxItems = 0;

  for (int i = 0; i < args.length; i++) {
    final String arg = args[i];
    if (arg == '-t' || arg == '--transitive') {
      showTransitive = true;
    } else if (arg == '-s' || arg == '--direct-symbols') {
      showDirect = true;
    } else if (arg == '-c' || arg == '--cycles') {
      showCycles = true;
    } else if (arg == '--all') {
      showTransitive = true;
      showDirect = true;
      showCycles = true;
    } else if (arg == '--summary') {
      showSummary = true;
    } else if (arg == '-f' || arg == '--format') {
      if (i + 1 < args.length) {
        format = args[++i];
      }
    } else if (arg.startsWith('--format=')) {
      format = arg.substring('--format='.length);
    } else if (arg == '-o' || arg == '--output') {
      if (i + 1 < args.length) {
        outputPath = args[++i];
      }
    } else if (arg.startsWith('--output=')) {
      outputPath = arg.substring('--output='.length);
    } else if (arg == '--filter') {
      if (i + 1 < args.length) {
        filter = args[++i];
      }
    } else if (arg.startsWith('--filter=')) {
      filter = arg.substring('--filter='.length);
    } else if (arg == '--max-items') {
      if (i + 1 < args.length) {
        maxItems = int.tryParse(args[++i]) ?? 0;
      }
    } else if (arg == '--csv') {
      if (i + 1 < args.length) {
        csvPath = args[++i];
      }
    } else if (arg.startsWith('--csv=')) {
      csvPath = arg.substring('--csv='.length);
    } else if (!arg.startsWith('-') && csvPath == null) {
      csvPath = arg;
    }
  }

  csvPath ??= _findDefaultCsv();
  final File file = File(csvPath);
  if (!file.existsSync()) {
    stderr.writeln('Error: CSV file not found at: $csvPath');
    exit(1);
  }

  if (!showTransitive && !showDirect && !showCycles && !showSummary) {
    showTransitive = true;
    showDirect = true;
    showCycles = true;
  }

  final analyzer = ImportAnalyzer(csvPath);
  analyzer.load();

  final Map<String, List<String>> transitive =
      (showTransitive || showCycles || showSummary)
          ? analyzer.computeTransitiveImports()
          : <String, List<String>>{};
  final List<DirectImportRecord> directSymbols =
      (showDirect || showSummary)
          ? analyzer.computeDirectImportSymbolCounts()
          : <DirectImportRecord>[];
  final List<List<String>> cycles =
      (showCycles || showSummary)
          ? analyzer.computeImportCycles()
          : <List<String>>[];

  if (showSummary) {
    _printSummary(analyzer, directSymbols.length, cycles);
    return;
  }

  String output;
  if (format == 'json') {
    output = _formatJson(
      analyzer,
      transitive,
      directSymbols,
      cycles,
      showTransitive: showTransitive,
      showDirect: showDirect,
      showCycles: showCycles,
      filter: filter,
    );
  } else if (format == 'csv') {
    output = _formatCsv(
      transitive,
      directSymbols,
      cycles,
      showTransitive: showTransitive,
      showDirect: showDirect,
      showCycles: showCycles,
      filter: filter,
    );
  } else {
    output = _formatText(
      analyzer,
      transitive,
      directSymbols,
      cycles,
      showTransitive: showTransitive,
      showDirect: showDirect,
      showCycles: showCycles,
      filter: filter,
      maxItems: maxItems,
    );
  }

  if (outputPath != null) {
    File(outputPath).writeAsStringSync(output);
    stdout.writeln('Results written to: $outputPath');
  } else {
    stdout.writeln(output);
  }
}

String _findDefaultCsv() {
  final List<String> candidates = [
    '/usr/local/google/home/chingjun/test/flutter-4/packages/flutter/all_imports.csv',
    'packages/flutter/all_imports.csv',
    'all_imports.csv',
  ];
  for (final String path in candidates) {
    if (File(path).existsSync()) {
      return File(path).absolute.path;
    }
  }
  return candidates[0];
}

class DirectImportRecord {
  DirectImportRecord(this.sourceFile, this.importedFile, this.symbols);

  final String sourceFile;
  final String importedFile;
  final List<String> symbols;

  int get symbolCount => symbols.length;
}

class ImportAnalyzer {
  ImportAnalyzer(this.csvPath);

  final String csvPath;
  final Map<String, Set<String>> directImports = <String, Set<String>>{};
  final Map<String, Map<String, Set<String>>> symbolUsages =
      <String, Map<String, Set<String>>>{};
  final Set<String> allNodes = <String>{};
  final Set<String> allSources = <String>{};
  int totalRows = 0;

  void load() {
    final List<String> lines = File(csvPath).readAsLinesSync();
    bool isFirst = true;
    for (final String rawLine in lines) {
      final String line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      if (isFirst) {
        isFirst = false;
        if (line.startsWith('source_file,')) {
          continue;
        }
      }
      final int firstComma = line.indexOf(',');
      if (firstComma == -1) {
        continue;
      }
      final int secondComma = line.indexOf(',', firstComma + 1);
      if (secondComma == -1) {
        continue;
      }

      totalRows++;
      final String src = line.substring(0, firstComma).trim();
      final String imp = line.substring(firstComma + 1, secondComma).trim();
      final String sym = line.substring(secondComma + 1).trim();

      if (src.isEmpty || imp.isEmpty) {
        continue;
      }

      directImports.putIfAbsent(src, () => <String>{}).add(imp);
      symbolUsages
          .putIfAbsent(src, () => <String, Set<String>>{})
          .putIfAbsent(imp, () => <String>{})
          .add(sym);

      allNodes.add(src);
      allNodes.add(imp);
      allSources.add(src);
    }
  }

  Map<String, List<String>> computeTransitiveImports() {
    final Map<String, List<String>> result = <String, List<String>>{};
    final List<String> sources = allSources.toList()..sort();

    for (final String src in sources) {
      final Set<String> visited = <String>{};
      final Queue<String> queue = Queue<String>.from(directImports[src] ?? <String>{});

      while (queue.isNotEmpty) {
        final String curr = queue.removeFirst();
        if (visited.add(curr)) {
          final Set<String>? nextNodes = directImports[curr];
          if (nextNodes != null) {
            for (final String next in nextNodes) {
              if (!visited.contains(next)) {
                queue.add(next);
              }
            }
          }
        }
      }

      final List<String> sortedVisited = visited.toList()..sort();
      result[src] = sortedVisited;
    }

    return result;
  }

  List<DirectImportRecord> computeDirectImportSymbolCounts() {
    final List<DirectImportRecord> records = <DirectImportRecord>[];
    final List<String> sources = symbolUsages.keys.toList()..sort();

    for (final String src in sources) {
      final Map<String, Set<String>> importsMap = symbolUsages[src]!;
      final List<String> imps = importsMap.keys.toList()..sort();
      for (final String imp in imps) {
        final List<String> syms = importsMap[imp]!.toList()..sort();
        records.add(DirectImportRecord(src, imp, syms));
      }
    }

    return records;
  }

  List<List<String>> computeImportCycles() {
    int index = 0;
    final Map<String, int> indices = <String, int>{};
    final Map<String, int> lowlink = <String, int>{};
    final Set<String> onStack = <String>{};
    final List<String> stack = <String>[];
    final List<List<String>> sccs = <List<String>>[];

    void strongConnect(String node) {
      indices[node] = index;
      lowlink[node] = index;
      index++;
      stack.add(node);
      onStack.add(node);

      final Set<String> neighbors = directImports[node] ?? <String>{};
      final List<String> sortedNeighbors = neighbors.toList()..sort();

      for (final String neighbor in sortedNeighbors) {
        if (!indices.containsKey(neighbor)) {
          strongConnect(neighbor);
          lowlink[node] = min(lowlink[node]!, lowlink[neighbor]!);
        } else if (onStack.contains(neighbor)) {
          lowlink[node] = min(lowlink[node]!, indices[neighbor]!);
        }
      }

      if (lowlink[node] == indices[node]) {
        final List<String> scc = <String>[];
        while (true) {
          final String w = stack.removeLast();
          onStack.remove(w);
          scc.add(w);
          if (w == node) {
            break;
          }
        }
        if (scc.length > 1 || (scc.length == 1 && (directImports[scc[0]]?.contains(scc[0]) ?? false))) {
          scc.sort();
          sccs.add(scc);
        }
      }
    }

    final List<String> allSortedNodes = allNodes.toList()..sort();
    for (final String node in allSortedNodes) {
      if (!indices.containsKey(node)) {
        strongConnect(node);
      }
    }

    sccs.sort((List<String> a, List<String> b) {
      final int lenComp = b.length.compareTo(a.length);
      if (lenComp != 0) {
        return lenComp;
      }
      return a[0].compareTo(b[0]);
    });

    return sccs;
  }
}

void _printSummary(ImportAnalyzer analyzer, int directEdgeCount, List<List<String>> cycles) {
  stdout.writeln('=' * 80);
  stdout.writeln('IMPORT ANALYSIS SUMMARY');
  stdout.writeln('=' * 80);
  stdout.writeln('CSV File: ${analyzer.csvPath}');
  stdout.writeln('Total Rows: ${analyzer.totalRows}');
  stdout.writeln('Total Unique Files: ${analyzer.allNodes.length}');
  stdout.writeln('Total Source Files: ${analyzer.allSources.length}');
  stdout.writeln('Total Direct Import Edges: $directEdgeCount');
  stdout.writeln('Total Cycle Groups (SCCs > 1): ${cycles.length}');
  stdout.writeln('Total Files in Cycles: ${cycles.fold<int>(0, (sum, c) => sum + c.length)}');
  stdout.writeln('\nCycle Groups Breakdown:');
  for (int i = 0; i < cycles.length; i++) {
    final String base = cycles[i][0].split('/').last;
    stdout.writeln('  Group ${(i + 1).toString().padLeft(2)}: ${cycles[i].length.toString().padLeft(3)} files (e.g. $base)');
  }
  stdout.writeln('=' * 80);
}

String _formatText(
  ImportAnalyzer analyzer,
  Map<String, List<String>> transitive,
  List<DirectImportRecord> directSymbols,
  List<List<String>> cycles, {
  required bool showTransitive,
  required bool showDirect,
  required bool showCycles,
  required String filter,
  required int maxItems,
}) {
  final StringBuffer buf = StringBuffer();
  final String separator = '=' * 80;

  buf.writeln(separator);
  buf.writeln('FLUTTER IMPORT DEPENDENCY & CYCLE ANALYSIS');
  buf.writeln(separator);
  buf.writeln('Input CSV: ${analyzer.csvPath}');
  buf.writeln('Total CSV Rows: ${analyzer.totalRows}');
  buf.writeln('Total Unique Files: ${analyzer.allNodes.length}');
  buf.writeln('Total Source Files: ${analyzer.allSources.length}');
  buf.writeln('Total Direct Import Edges: ${directSymbols.length}');
  buf.writeln('Total Import Cycle Groups: ${cycles.length}');
  buf.writeln(separator);

  if (showTransitive) {
    final Map<String, List<String>> filtered = <String, List<String>>{};
    for (final MapEntry<String, List<String>> entry in transitive.entries) {
      if (filter.isEmpty || entry.key.contains(filter)) {
        filtered[entry.key] = entry.value;
      }
    }
    buf.writeln();
    buf.writeln('--- 1. TRANSITIVE IMPORTS (${filtered.length} files) ---');
    buf.writeln('Format: File -> [Transitive Imports Count] (List of transitively imported files)');
    buf.writeln('-' * 80);
    final List<MapEntry<String, List<String>>> entries = filtered.entries.toList();
    final int countToShow = (maxItems > 0 && entries.length > maxItems) ? maxItems : entries.length;

    for (int i = 0; i < countToShow; i++) {
      final entry = entries[i];
      buf.writeln('\nFile: ${entry.key}');
      buf.writeln('  Direct Imports Count: ${analyzer.directImports[entry.key]?.length ?? 0}');
      buf.writeln('  Transitive Imports Count: ${entry.value.length}');
      for (final String imp in entry.value) {
        buf.writeln('    - $imp');
      }
    }
    if (entries.length > countToShow) {
      buf.writeln('\n... and ${entries.length - countToShow} more files (use --max-items 0 or export to JSON/CSV).');
    }
  }

  if (showDirect) {
    final List<DirectImportRecord> filtered = directSymbols.where((r) {
      return filter.isEmpty || r.sourceFile.contains(filter) || r.importedFile.contains(filter);
    }).toList();
    buf.writeln();
    buf.writeln('--- 2. DIRECT IMPORTS AND SYMBOLS USED (${filtered.length} pairs) ---');
    buf.writeln('Format: (Source File, Direct Import, Symbols Count, Symbols List)');
    buf.writeln('-' * 80);
    final int countToShow = (maxItems > 0 && filtered.length > maxItems) ? maxItems : filtered.length;

    for (int i = 0; i < countToShow; i++) {
      final record = filtered[i];
      final List<String> syms = record.symbols;
      final String preview = syms.take(5).join(', ') + (syms.length > 5 ? ' ... (+${syms.length - 5} more)' : '');
      buf.writeln('Source: ${record.sourceFile}');
      buf.writeln('  Imports: ${record.importedFile}');
      buf.writeln('  Symbols Count: ${record.symbolCount} ($preview)');
    }
    if (filtered.length > countToShow) {
      buf.writeln('\n... and ${filtered.length - countToShow} more direct import pairs (use --max-items 0 or export to JSON/CSV).');
    }
  }

  if (showCycles) {
    buf.writeln();
    buf.writeln('--- 3. IMPORT CYCLES (${cycles.length} cycle groups detected) ---');
    buf.writeln('Definition: In each cycle group, importing ANY single file transitively imports ALL other files in the group.');
    buf.writeln('-' * 80);
    for (int i = 0; i < cycles.length; i++) {
      final List<String> cycle = cycles[i];
      buf.writeln('\n[Cycle Group #${i + 1}] (${cycle.length} files):');
      for (final String f in cycle) {
        buf.writeln('  * $f');
      }
    }
  }

  return buf.toString();
}

String _formatJson(
  ImportAnalyzer analyzer,
  Map<String, List<String>> transitive,
  List<DirectImportRecord> directSymbols,
  List<List<String>> cycles, {
  required bool showTransitive,
  required bool showDirect,
  required bool showCycles,
  required String filter,
}) {
  final Map<String, dynamic> data = <String, dynamic>{
    'metadata': <String, dynamic>{
      'csv_path': analyzer.csvPath,
      'total_rows': analyzer.totalRows,
      'total_unique_files': analyzer.allNodes.length,
      'total_source_files': analyzer.allSources.length,
      'total_direct_imports': directSymbols.length,
      'total_cycle_groups': cycles.length,
    },
  };

  if (showTransitive) {
    final Map<String, List<String>> filtered = <String, List<String>>{};
    for (final MapEntry<String, List<String>> entry in transitive.entries) {
      if (filter.isEmpty || entry.key.contains(filter)) {
        filtered[entry.key] = entry.value;
      }
    }
    data['transitive_imports'] = filtered;
  }

  if (showDirect) {
    data['direct_imports_and_symbols'] = directSymbols
        .where((r) => filter.isEmpty || r.sourceFile.contains(filter) || r.importedFile.contains(filter))
        .map((r) => <String, dynamic>{
              'source_file': r.sourceFile,
              'imported_file': r.importedFile,
              'symbols_count': r.symbolCount,
              'symbols': r.symbols,
            })
        .toList();
  }

  if (showCycles) {
    final List<Map<String, dynamic>> cyclesList = <Map<String, dynamic>>[];
    for (int i = 0; i < cycles.length; i++) {
      final List<String> cycle = cycles[i];
      if (filter.isEmpty || cycle.any((f) => f.contains(filter))) {
        cyclesList.add(<String, dynamic>{
          'cycle_index': i + 1,
          'file_count': cycle.length,
          'files': cycle,
        });
      }
    }
    data['import_cycles'] = cyclesList;
  }

  return const JsonEncoder.withIndent('  ').convert(data);
}

String _formatCsv(
  Map<String, List<String>> transitive,
  List<DirectImportRecord> directSymbols,
  List<List<String>> cycles, {
  required bool showTransitive,
  required bool showDirect,
  required bool showCycles,
  required String filter,
}) {
  final StringBuffer buf = StringBuffer();

  if (showDirect && !showTransitive && !showCycles) {
    buf.writeln('source_file,imported_file,symbol_count,symbols');
    for (final DirectImportRecord r in directSymbols) {
      if (filter.isEmpty || r.sourceFile.contains(filter) || r.importedFile.contains(filter)) {
        buf.writeln('"${r.sourceFile}","${r.importedFile}",${r.symbolCount},"${r.symbols.join(';')}"');
      }
    }
    return buf.toString();
  }

  if (showTransitive && !showDirect && !showCycles) {
    buf.writeln('file,transitive_imports_count,transitive_imports');
    for (final MapEntry<String, List<String>> entry in transitive.entries) {
      if (filter.isEmpty || entry.key.contains(filter)) {
        buf.writeln('"${entry.key}",${entry.value.length},"${entry.value.join(';')}"');
      }
    }
    return buf.toString();
  }

  if (showCycles && !showTransitive && !showDirect) {
    buf.writeln('cycle_id,cycle_size,file');
    for (int i = 0; i < cycles.length; i++) {
      final List<String> cycle = cycles[i];
      if (filter.isEmpty || cycle.any((f) => f.contains(filter))) {
        for (final String f in cycle) {
          buf.writeln('${i + 1},${cycle.length},"$f"');
        }
      }
    }
    return buf.toString();
  }

  buf.writeln('# SECTION 1: TRANSITIVE IMPORTS');
  buf.writeln('file,transitive_imports_count,transitive_imports');
  for (final MapEntry<String, List<String>> entry in transitive.entries) {
    if (filter.isEmpty || entry.key.contains(filter)) {
      buf.writeln('"${entry.key}",${entry.value.length},"${entry.value.join(';')}"');
    }
  }

  buf.writeln('\n# SECTION 2: DIRECT IMPORTS AND SYMBOL COUNTS');
  buf.writeln('source_file,imported_file,symbol_count,symbols');
  for (final DirectImportRecord r in directSymbols) {
    if (filter.isEmpty || r.sourceFile.contains(filter) || r.importedFile.contains(filter)) {
      buf.writeln('"${r.sourceFile}","${r.importedFile}",${r.symbolCount},"${r.symbols.join(';')}"');
    }
  }

  buf.writeln('\n# SECTION 3: IMPORT CYCLES');
  buf.writeln('cycle_id,cycle_size,file');
  for (int i = 0; i < cycles.length; i++) {
    final List<String> cycle = cycles[i];
    if (filter.isEmpty || cycle.any((f) => f.contains(filter))) {
      for (final String f in cycle) {
        buf.writeln('${i + 1},${cycle.length},"$f"');
      }
    }
  }

  return buf.toString();
}
