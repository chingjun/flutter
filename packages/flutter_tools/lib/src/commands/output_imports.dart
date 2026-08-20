// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';

/// Implements `flutter analyze --output_imports=<file>`.
///
/// Analyzes Dart files under [targetPaths], collects every imported symbol used
/// in each file and where that symbol is imported from, and writes the results to
/// [outputPath] as a CSV file with columns: `source_file,imported_file,symbol`.
class OutputImports {
  OutputImports({
    required this.fileSystem,
    required this.logger,
    required this.targetPaths,
    required this.outputPath,
    ResourceProvider? resourceProvider,
  }) : _resourceProvider = resourceProvider ?? PhysicalResourceProvider.INSTANCE;

  final FileSystem fileSystem;
  final Logger logger;

  /// Absolute, normalized paths (files or directories) to analyze.
  final List<String> targetPaths;

  /// File path where the CSV output should be written.
  final String outputPath;

  final ResourceProvider _resourceProvider;

  Future<void> run() async {
    final collection = AnalysisContextCollection(
      includedPaths: targetPaths,
      resourceProvider: _resourceProvider,
    );

    final entries = <_ImportUsageEntry>[];
    final processedUnits = <String>{};

    for (final AnalysisContext context in collection.contexts) {
      final List<String> files =
          context.contextRoot
              .analyzedFiles()
              .where((String f) => f.endsWith('.dart'))
              .toList()
            ..sort();

      for (final file in files) {
        final SomeResolvedLibraryResult someResult = await context.currentSession
            .getResolvedLibrary(file);
        if (someResult is! ResolvedLibraryResult) {
          continue;
        }

        final LibraryElement libraryElement = someResult.element;
        for (final ResolvedUnitResult unit in someResult.units) {
          final String unitPath = unit.path;
          if (!processedUnits.add(unitPath)) {
            continue;
          }
          if (!_isUnderTarget(unitPath)) {
            continue;
          }

          final visitor = _UsageVisitor(currentLibrary: libraryElement);
          unit.unit.accept(visitor);

          for (final _SymbolRecord record in visitor.symbols) {
            entries.add(
              _ImportUsageEntry(
                sourceFile: unitPath,
                importedFile: record.importedFile,
                symbol: record.symbol,
              ),
            );
          }
        }
      }
    }

    await collection.dispose();

    // Deduplicate entries and sort deterministically.
    final List<_ImportUsageEntry> uniqueEntries = entries.toSet().toList()
      ..sort((_ImportUsageEntry a, _ImportUsageEntry b) {
        final int c1 = a.sourceFile.compareTo(b.sourceFile);
        if (c1 != 0) {
          return c1;
        }
        final int c2 = a.importedFile.compareTo(b.importedFile);
        if (c2 != 0) {
          return c2;
        }
        return a.symbol.compareTo(b.symbol);
      });

    final buffer = StringBuffer();
    buffer.writeln('source_file,imported_file,symbol');
    for (final entry in uniqueEntries) {
      buffer.writeln(
        '${_csvEscape(entry.sourceFile)},${_csvEscape(entry.importedFile)},${_csvEscape(entry.symbol)}',
      );
    }

    final File outputFile = fileSystem.file(outputPath);
    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsStringSync(buffer.toString());

    logger.printStatus('Exported ${uniqueEntries.length} imported symbols to $outputPath');
  }

  bool _isUnderTarget(String path) {
    for (final String target in targetPaths) {
      if (path == target ||
          path.startsWith(target + fileSystem.path.separator) ||
          path.startsWith('$target/')) {
        return true;
      }
    }
    return false;
  }

  static String _csvEscape(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

@immutable
class _ImportUsageEntry {
  const _ImportUsageEntry({
    required this.sourceFile,
    required this.importedFile,
    required this.symbol,
  });

  final String sourceFile;
  final String importedFile;
  final String symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ImportUsageEntry &&
          runtimeType == other.runtimeType &&
          sourceFile == other.sourceFile &&
          importedFile == other.importedFile &&
          symbol == other.symbol;

  @override
  int get hashCode => Object.hash(sourceFile, importedFile, symbol);
}

class _SymbolRecord {
  _SymbolRecord({required this.importedFile, required this.symbol});

  final String importedFile;
  final String symbol;
}

class _UsageVisitor extends RecursiveAstVisitor<void> {
  _UsageVisitor({required this.currentLibrary});

  final LibraryElement currentLibrary;
  final List<_SymbolRecord> symbols = <_SymbolRecord>[];

  @override
  void visitImportDirective(ImportDirective node) {}
  @override
  void visitExportDirective(ExportDirective node) {}
  @override
  void visitLibraryDirective(LibraryDirective node) {}
  @override
  void visitPartDirective(PartDirective node) {}
  @override
  void visitPartOfDirective(PartOfDirective node) {}
  @override
  void visitComment(Comment node) {}

  @override
  void visitNamedType(NamedType node) {
    _record(node.element);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      Element? element = node.element;
      if (element == null) {
        final AstNode? parent = node.parent;
        if (parent is AssignmentExpression && identical(parent.leftHandSide, node)) {
          element = parent.writeElement ?? parent.readElement;
        } else if (parent is PostfixExpression && identical(parent.operand, node)) {
          element = parent.writeElement ?? parent.readElement;
        } else if (parent is PrefixExpression && identical(parent.operand, node)) {
          element = parent.writeElement ?? parent.readElement;
        }
      }
      _record(element);
    }
    super.visitSimpleIdentifier(node);
  }

  void _record(Element? rawElement) {
    if (rawElement == null) {
      return;
    }
    final Element element = rawElement.baseElement;
    if (element is PrefixElement || element is LibraryElement) {
      return;
    }

    final Element? enclosing = element.enclosingElement;
    if (enclosing is LibraryElement) {
      _maybeAdd(element);
    } else if (enclosing is ExtensionElement) {
      _maybeAdd(enclosing);
    }
  }

  void _maybeAdd(Element element) {
    final LibraryElement? library = element.library;
    String? name = element.name;
    if (library == null || name == null || name.isEmpty) {
      return;
    }
    // Setters expose a trailing `=` in some contexts.
    if (name.endsWith('=')) {
      name = name.substring(0, name.length - 1);
    }
    if (name.startsWith('_')) {
      return;
    }
    // Exclude symbols declared in the current library.
    if (library == currentLibrary || library.uri == currentLibrary.uri) {
      return;
    }
    // Exclude dart:core symbols.
    if (library.uri.scheme == 'dart' && library.uri.path == 'core') {
      return;
    }

    final String importedFilePath = library.firstFragment.source.fullName;
    if (importedFilePath.isEmpty) {
      return;
    }

    symbols.add(_SymbolRecord(importedFile: importedFilePath, symbol: name));
  }
}
