// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../analyze_imports.dart';

void main() {
  final Directory tempDir = Directory.systemTemp.createTempSync('analyze_imports_test_');
  final File tempFile = File('${tempDir.path}/test_imports.csv');

  try {
    tempFile.writeAsStringSync(
      'source_file,imported_file,symbol\n'
      'A.dart,B.dart,sym1\n'
      'A.dart,B.dart,sym2\n'
      'B.dart,C.dart,sym3\n'
      'C.dart,A.dart,sym4\n'
      'C.dart,D.dart,sym5\n'
      'D.dart,E.dart,sym6\n'
      'F.dart,G.dart,sym7\n'
      'G.dart,F.dart,sym8\n'
      'H.dart,D.dart,sym9\n',
    );

    final ImportAnalyzer analyzer = ImportAnalyzer(tempFile.path);
    analyzer.load();

    // 1. Test direct imports
    final List<DirectImportRecord> direct = analyzer.computeDirectImportSymbolCounts();
    if (direct.length != 8) {
      throw StateError('Expected 8 direct import pairs, got ${direct.length}');
    }
    final DirectImportRecord ab = direct.firstWhere((r) => r.sourceFile == 'A.dart' && r.importedFile == 'B.dart');
    if (ab.symbolCount != 2 || ab.symbols[0] != 'sym1' || ab.symbols[1] != 'sym2') {
      throw StateError('A.dart -> B.dart symbol mismatch: ${ab.symbols}');
    }

    // 2. Test transitive imports
    final Map<String, List<String>> transitive = analyzer.computeTransitiveImports();
    final List<String>? transA = transitive['A.dart'];
    if (transA == null || transA.join(',') != 'A.dart,B.dart,C.dart,D.dart,E.dart') {
      throw StateError('Transitive imports for A.dart mismatch: $transA');
    }
    final List<String>? transH = transitive['H.dart'];
    if (transH == null || transH.join(',') != 'D.dart,E.dart') {
      throw StateError('Transitive imports for H.dart mismatch: $transH');
    }

    // 3. Test cycles
    final List<List<String>> cycles = analyzer.computeImportCycles();
    if (cycles.length != 2) {
      throw StateError('Expected 2 cycles, got ${cycles.length}');
    }
    if (cycles[0].join(',') != 'A.dart,B.dart,C.dart') {
      throw StateError('Cycle 1 mismatch: ${cycles[0]}');
    }
    if (cycles[1].join(',') != 'F.dart,G.dart') {
      throw StateError('Cycle 2 mismatch: ${cycles[1]}');
    }

    // Verify cycle property: every file in cycle reaches all files in cycle
    for (final List<String> cycle in cycles) {
      final Set<String> cycleSet = cycle.toSet();
      for (final String f in cycle) {
        final Set<String> trans = transitive[f]!.toSet();
        if (!cycleSet.every(trans.contains)) {
          throw StateError('File $f in cycle did not transitively reach all cycle nodes: $cycle');
        }
      }
    }

    stdout.writeln('All analyze_imports Dart tests passed successfully!');
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
