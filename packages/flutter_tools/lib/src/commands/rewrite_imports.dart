// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import '../base/file_system.dart';
import '../base/logger.dart';

/// Implements `flutter analyze --rewrite-imports`.
///
/// For every Dart *library* file under the target path(s), this:
///   1. Collects every symbol explicitly used in the library (across all of its
///      units, including parts).
///   2. For each used symbol that is defined in `dart:ui` or `package:flutter`,
///      emits a direct `import '<defining library>' show <TopLevelName>;`.
///   3. Removes all `export` directives.
///   4. Removes the original unprefixed `dart:ui` / `package:flutter` import
///      directives (all other imports are preserved verbatim).
///
/// Only `dart:ui` and `package:flutter/...` imports are rewritten; everything
/// else (other `dart:` libraries, other packages, relative imports, and
/// prefixed `dart:ui` / `package:flutter` imports) is left untouched.
class RewriteImports {
  RewriteImports({required this.fileSystem, required this.logger, required this.targetPaths});

  final FileSystem fileSystem;
  final Logger logger;

  /// Absolute, normalized paths (files or directories) to rewrite.
  final List<String> targetPaths;

  Future<void> run() async {
    final collection = AnalysisContextCollection(
      includedPaths: targetPaths,
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    var libraryCount = 0;
    var changedCount = 0;
    for (final AnalysisContext context in collection.contexts) {
      final List<String> files =
          context.contextRoot
              .analyzedFiles()
              .where((String f) => f.endsWith('.dart'))
              .where(_isUnderTarget)
              .toList()
            ..sort();
      final processedLibraries = <String>{};
      for (final file in files) {
        final SomeResolvedLibraryResult someResult = await context.currentSession
            .getResolvedLibrary(file);
        if (someResult is! ResolvedLibraryResult) {
          // Either a part file (handled via its defining library) or a file that
          // could not be resolved.
          continue;
        }
        final String libraryPath = someResult.element.firstFragment.source.fullName;
        if (!processedLibraries.add(libraryPath)) {
          continue;
        }
        if (!_isUnderTarget(libraryPath)) {
          continue;
        }
        if (_isPublicBarrel(libraryPath)) {
          // Files directly under `lib/` (e.g. `lib/material.dart`) form the
          // package's public API and are consumed (via `export`) by downstream
          // packages such as `package:flutter_test`. Leave them untouched so the
          // public surface -- and therefore analysis of the `test/` tree --
          // keeps working.
          continue;
        }
        libraryCount += 1;
        if (_rewriteLibrary(someResult)) {
          changedCount += 1;
        }
      }
    }

    await collection.dispose();
    logger.printStatus('Rewrote imports in $changedCount of $libraryCount libraries.');
  }

  bool _isUnderTarget(String path) {
    for (final String target in targetPaths) {
      if (path == target || path.startsWith(target + fileSystem.path.separator)) {
        return true;
      }
    }
    return false;
  }

  /// Whether [path] is a library directly under a `lib/` directory (e.g.
  /// `.../lib/material.dart`), i.e. part of the package's public API surface.
  bool _isPublicBarrel(String path) {
    final String sep = fileSystem.path.separator;
    final marker = '${sep}lib$sep';
    final int idx = path.lastIndexOf(marker);
    if (idx < 0) {
      return false;
    }
    final String rest = path.substring(idx + marker.length);
    return !rest.contains(sep);
  }

  /// Whether [path] lives under a `lib/` directory (i.e. is part of the
  /// package's shipped sources, as opposed to `test/` helpers).
  bool _isUnderLib(String path) {
    final String sep = fileSystem.path.separator;
    return path.contains('${sep}lib$sep');
  }

  /// Whether an `export` directive in the file at [libraryPath] pointing at
  /// [targetCanonical] should be preserved.
  ///
  /// `dart:ui` / `package:flutter` re-exports can be recreated as direct imports
  /// in consumers, so they are stripped -- except under `lib/`, where the
  /// (untouched) public barrels depend on the re-export chain (e.g.
  /// `foundation.dart` surfacing `VoidCallback`). Any *other* re-export
  /// (`package:flutter_test`, other packages, relative test helpers) cannot be
  /// reconstructed via a `dart:ui` / `package:flutter` import and is preserved.
  bool _keepExport(String libraryPath, String targetCanonical) {
    final bool targetIsFlutterOrUi =
        targetCanonical == 'dart:ui' || targetCanonical.startsWith('package:flutter/');
    if (!targetIsFlutterOrUi) {
      return true;
    }
    return _isUnderLib(libraryPath);
  }

  /// Returns true if the library file was modified.
  bool _rewriteLibrary(ResolvedLibraryResult lib) {
    final Uri currentUri = lib.element.uri;
    final String libraryPath = lib.element.firstFragment.source.fullName;

    ResolvedUnitResult? definingUnit;
    for (final ResolvedUnitResult unit in lib.units) {
      if (unit.path == libraryPath) {
        definingUnit = unit;
        break;
      }
    }
    definingUnit ??= lib.units.isNotEmpty ? lib.units.first : null;
    if (definingUnit == null) {
      return false;
    }

    // Collect the set of top-level names that must be imported from each
    // `dart:ui` / `package:flutter` library.
    final imports = <String, SplayTreeSet<String>>{};
    void addImport(String uri, String name) {
      imports.putIfAbsent(uri, () => SplayTreeSet<String>()).add(name);
    }

    final visitor = _UsageVisitor(currentUri: currentUri, addImport: addImport);
    for (final ResolvedUnitResult unit in lib.units) {
      unit.unit.accept(visitor);
    }

    return _rewriteFile(definingUnit, currentUri, imports);
  }

  bool _rewriteFile(
    ResolvedUnitResult unit,
    Uri currentUri,
    Map<String, SplayTreeSet<String>> imports,
  ) {
    final String content = unit.content;
    final eol = content.contains('\r\n') ? '\r\n' : '\n';

    final NodeList<Directive> directives = unit.unit.directives;
    final List<ImportDirective> importDirectives = directives.whereType<ImportDirective>().toList();
    final List<ExportDirective> exportDirectives = directives.whereType<ExportDirective>().toList();
    final List<PartDirective> partDirectives = directives.whereType<PartDirective>().toList();

    // Nothing to do if there are no directives to touch and no imports to add.
    if (importDirectives.isEmpty && exportDirectives.isEmpty && imports.isEmpty) {
      return false;
    }

    // Partition the existing imports.
    //
    // An import is *removable* (dropped and rebuilt from actual usage) when it
    // is an unprefixed, unconditional import that resolves to `dart:ui` or
    // `package:flutter/...` -- this includes relative imports between library
    // files inside `package:flutter`. Everything else is *kept*.
    //
    // For each kept, unprefixed import we record the set of names it actually
    // contributes to this library's scope (honoring `show` / `hide`), so we
    // never re-import a symbol that is already available.
    final keptImports = <_ImportEntry>[];
    final coveredNames = <String>{};
    // Kept, unprefixed, show-only imports keyed by resolved URI. These can be
    // merged with a generated import for the same library so that a library is
    // only imported once.
    final mergeableByUri = <String, List<ImportDirective>>{};

    for (final directive in importDirectives) {
      final String? rawUri = directive.uri.stringValue;
      final canonical = rawUri == null ? '' : currentUri.resolve(rawUri).toString();
      final bool isFlutterOrUi = canonical == 'dart:ui' || canonical.startsWith('package:flutter/');
      final bool removable =
          rawUri != null &&
          isFlutterOrUi &&
          directive.prefix == null &&
          directive.configurations.isEmpty;
      if (removable) {
        continue;
      }

      // Contribute the kept import's unprefixed namespace to coverage. If the
      // import targets a library that we also process, some of its `export`
      // directives are being stripped, so it will stop providing the re-exported
      // symbols that ride on those stripped exports (see [_keepExport]).
      final LibraryImport? li = directive.libraryImport;
      if (li != null && li.prefix == null) {
        final LibraryElement? importedLib = li.importedLibrary;
        final String importedPath = importedLib?.firstFragment.source.fullName ?? '';
        final bool processed =
            importedLib != null && _isUnderTarget(importedPath) && !_isPublicBarrel(importedPath);
        for (final MapEntry<String, Element> e in li.namespace.definedNames2.entries) {
          if (processed && e.value.library != importedLib) {
            // A re-exported name. It survives only if the corresponding export
            // is kept. Approximate the export target by the symbol's declaring
            // library (a re-exported symbol shares its target's flutter/non-
            // flutter classification).
            final String declUri = e.value.library?.uri.toString() ?? '';
            if (!_keepExport(importedPath, declUri)) {
              continue;
            }
          }
          coveredNames.add(e.key);
          if (e.key.endsWith('=')) {
            coveredNames.add(e.key.substring(0, e.key.length - 1));
          }
        }
      }

      final bool showOnly =
          directive.prefix == null &&
          directive.configurations.isEmpty &&
          directive.combinators.isNotEmpty &&
          directive.combinators.every((Combinator c) => c is ShowCombinator);
      if (showOnly && canonical.isNotEmpty) {
        mergeableByUri.putIfAbsent(canonical, () => <ImportDirective>[]).add(directive);
      } else {
        // Group/sort by the *written* form so that relative imports (e.g. a
        // prefixed or conditional relative import) stay in the relative section.
        keptImports.add(
          _ImportEntry(
            uri: rawUri ?? canonical,
            text: content.substring(directive.offset, directive.end),
          ),
        );
      }
    }

    // Drop any needed names that are already provided by a kept import.
    for (final SplayTreeSet<String> names in imports.values) {
      names.removeAll(coveredNames);
    }
    imports.removeWhere((String uri, SplayTreeSet<String> names) => names.isEmpty);

    // Preserve mergeable kept imports whose library we are not augmenting.
    mergeableByUri.forEach((String uri, List<ImportDirective> directives) {
      if (!imports.containsKey(uri)) {
        for (final d in directives) {
          keptImports.add(
            _ImportEntry(uri: d.uri.stringValue ?? uri, text: content.substring(d.offset, d.end)),
          );
        }
      }
    });

    // Build the new show-imports, folding in any mergeable same-URI kept import.
    final newImports = <_ImportEntry>[];
    imports.forEach((String uri, SplayTreeSet<String> names) {
      final merged = SplayTreeSet<String>()..addAll(names);
      for (final ImportDirective d in mergeableByUri[uri] ?? const <ImportDirective>[]) {
        for (final ShowCombinator c in d.combinators.whereType<ShowCombinator>()) {
          for (final SimpleIdentifier id in c.shownNames) {
            merged.add(id.name);
          }
        }
      }
      if (merged.isEmpty) {
        return;
      }
      newImports.add(_ImportEntry(uri: uri, text: "import '$uri' show ${merged.join(', ')};"));
    });

    final allImports = <_ImportEntry>[...keptImports, ...newImports]..sort(_compareImports);

    // Group into dart:, package:, and relative sections separated by blank lines.
    final buffer = StringBuffer();
    var lastGroup = -1;
    var first = true;
    for (final entry in allImports) {
      final int group = _importGroup(entry.uri);
      if (!first && group != lastGroup) {
        buffer.write(eol);
      }
      if (!first) {
        buffer.write(eol);
      }
      buffer.write(entry.text);
      lastGroup = group;
      first = false;
    }

    // Preserve `export` directives that cannot be reconstructed as direct
    // `dart:ui` / `package:flutter` imports in consumers (see [_keepExport]):
    // non-flutter re-exports everywhere, and flutter/ui re-exports under `lib/`
    // (whose public barrels depend on the re-export chain, e.g.
    // `foundation.dart` surfacing `VoidCallback`).
    final keptExports = <_ImportEntry>[];
    for (final export in exportDirectives) {
      final String? rawUri = export.uri.stringValue;
      if (rawUri == null) {
        continue;
      }
      final canonical = currentUri.resolve(rawUri).toString();
      if (_keepExport(unit.path, canonical)) {
        keptExports.add(
          _ImportEntry(uri: rawUri, text: content.substring(export.offset, export.end)),
        );
      }
    }
    keptExports.sort(_compareImports);
    var firstExport = true;
    for (final entry in keptExports) {
      if (firstExport) {
        if (!first) {
          buffer.write(eol);
          buffer.write(eol);
        }
        firstExport = false;
      } else {
        buffer.write(eol);
      }
      buffer.write(entry.text);
      first = false;
    }

    // Keep part directives (verbatim) after the imports.
    for (final part in partDirectives) {
      if (!first) {
        buffer.write(eol);
      }
      buffer.write(eol);
      buffer.write(content.substring(part.offset, part.end));
      first = false;
    }

    final newBlock = buffer.toString();

    // Determine the region spanning all import/export/part directives.
    final regionDirectives = <Directive>[
      ...importDirectives,
      ...exportDirectives,
      ...partDirectives,
    ];
    if (regionDirectives.isEmpty) {
      // Only possible if imports is non-empty but there were no directives; skip
      // (a well-formed library using flutter symbols always has imports).
      return false;
    }
    int regionStart = content.length;
    var regionEnd = 0;
    for (final directive in regionDirectives) {
      if (directive.offset < regionStart) {
        regionStart = directive.offset;
      }
      if (directive.end > regionEnd) {
        regionEnd = directive.end;
      }
    }

    String newContent = content.substring(0, regionStart) + newBlock + content.substring(regionEnd);
    // Guarantee exactly one trailing end-of-line marker (eol_at_end_of_file).
    newContent = newContent.replaceAll(RegExp(r'[\r\n]+$'), '') + eol;
    if (newContent == content) {
      return false;
    }
    fileSystem.file(unit.path).writeAsStringSync(newContent);
    return true;
  }

  static int _importGroup(String uri) {
    if (uri.startsWith('dart:')) {
      return 0;
    }
    if (uri.startsWith('package:')) {
      return 1;
    }
    return 2;
  }

  static int _compareImports(_ImportEntry a, _ImportEntry b) {
    final int groupCompare = _importGroup(a.uri).compareTo(_importGroup(b.uri));
    if (groupCompare != 0) {
      return groupCompare;
    }
    final int uriCompare = a.uri.compareTo(b.uri);
    if (uriCompare != 0) {
      return uriCompare;
    }
    return a.text.compareTo(b.text);
  }
}

class _ImportEntry {
  _ImportEntry({required this.uri, required this.text});
  final String uri;
  final String text;
}

/// Walks a resolved AST and reports every explicitly-used top-level symbol from
/// `dart:ui` / `package:flutter` via [addImport].
class _UsageVisitor extends RecursiveAstVisitor<void> {
  _UsageVisitor({required this.currentUri, required this.addImport});

  final Uri currentUri;
  final void Function(String uri, String name) addImport;

  // Do not descend into directives (their combinators contain identifiers that
  // resolve to elements) or documentation comments (references there do not
  // require imports).
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
    // A prefixed type (`prefix.Foo`) is served by the (kept) prefixed import.
    if (node.importPrefix == null) {
      _record(node.element, prefixed: false);
    }
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      Element? element = node.element;
      // For a write target (`foo = ...`, `foo += ...`, `foo++`) the read
      // `element` is null; the resolved setter lives on the enclosing compound
      // assignment / increment expression instead.
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
      _record(element, prefixed: _isPrefixed(node));
    }
    super.visitSimpleIdentifier(node);
  }

  bool _isPrefixed(SimpleIdentifier node) {
    final AstNode? parent = node.parent;
    if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
      return parent.prefix.element is PrefixElement;
    }
    if (parent is MethodInvocation && identical(parent.methodName, node)) {
      final Expression? target = parent.target;
      return target is SimpleIdentifier && target.element is PrefixElement;
    }
    if (parent is PropertyAccess && identical(parent.propertyName, node)) {
      final Expression target = parent.target ?? parent.realTarget;
      return target is SimpleIdentifier && target.element is PrefixElement;
    }
    return false;
  }

  void _record(Element? rawElement, {required bool prefixed}) {
    if (rawElement == null || prefixed) {
      return;
    }
    final Element element = rawElement.baseElement;
    if (element is PrefixElement || element is LibraryElement) {
      return;
    }

    final Element? enclosing = element.enclosingElement;
    if (enclosing is LibraryElement) {
      // A genuine top-level reference.
      _maybeAdd(element);
    } else if (enclosing is ExtensionElement) {
      // Extension members require the extension itself to be in scope.
      _maybeAdd(enclosing);
    }
    // Otherwise this is an instance/static member (rides along with its type) or
    // a local declaration; nothing to import.
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
    final Uri uri = library.uri;
    if (uri == currentUri) {
      return;
    }
    final String? importUri = _publicImportUri(uri);
    if (importUri == null) {
      return;
    }
    addImport(importUri, name);
  }

  /// Maps the library that *declares* a symbol to the URI that should be used to
  /// import it.
  ///
  /// `dart:ui` and `package:flutter` symbols are imported directly from their
  /// (private) defining library -- that is the whole point of the rewrite, and
  /// it is allowed because those files live in the same package. Symbols from
  /// other packages are imported from that package's public entrypoint instead
  /// of a private `src/` library, to avoid `implementation_imports` violations.
  /// `dart:core` is implicitly available and never imported.
  String? _publicImportUri(Uri uri) {
    if (uri.scheme == 'file') {
      // A symbol declared in a non-`package:` library (e.g. a test helper under
      // `test/`). Import it via a relative path from the current file.
      if (currentUri.scheme != 'file') {
        return uri.toString();
      }
      return _relativeImport(currentUri, uri);
    }
    if (uri.scheme == 'dart') {
      if (uri.path == 'core') {
        return null;
      }
      return uri.toString();
    }
    if (uri.scheme != 'package') {
      return uri.toString();
    }
    final List<String> segments = uri.pathSegments;
    final String package = segments.isNotEmpty ? segments.first : '';
    if (package == 'flutter') {
      return uri.toString();
    }
    // vector_math and characters expose their symbols through a specific public
    // library rather than `package:<name>/<name>.dart`.
    if (package == 'vector_math') {
      return 'package:vector_math/vector_math_64.dart';
    }
    if (package == 'characters') {
      return 'package:characters/characters.dart';
    }
    // Any other package: if the symbol is declared under `src/`, redirect to the
    // conventional public library `package:<name>/<name>.dart`.
    if (segments.length > 1 && segments[1] == 'src') {
      return 'package:$package/$package.dart';
    }
    return uri.toString();
  }

  /// Computes a relative import path (POSIX separators) from the [from] library
  /// file to the [to] library file. Both must be `file:` URIs.
  static String _relativeImport(Uri from, Uri to) {
    final fromSegs = List<String>.from(from.pathSegments);
    final toSegs = List<String>.from(to.pathSegments);
    // Drop the importing file's own name; we care about its directory.
    if (fromSegs.isNotEmpty) {
      fromSegs.removeLast();
    }
    var common = 0;
    while (common < fromSegs.length &&
        common < toSegs.length - 1 &&
        fromSegs[common] == toSegs[common]) {
      common += 1;
    }
    final parts = <String>[
      for (var i = common; i < fromSegs.length; i++) '..',
      ...toSegs.sublist(common),
    ];
    return parts.join('/');
  }
}
