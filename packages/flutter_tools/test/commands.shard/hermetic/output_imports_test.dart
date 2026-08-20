// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/commands/output_imports.dart';
import 'package:flutter_tools/src/project_validator.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('OutputImports', () {
    late FileSystem fileSystem;
    late BufferLogger logger;
    late Directory tempDir;

    setUp(() {
      fileSystem = const LocalFileSystem();
      logger = BufferLogger.test();
      tempDir = fileSystem.systemTempDirectory.createTempSync('output_imports_test_');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on Object catch (_) {}
    });

    testWithoutContext('outputs CSV with source_file, imported_file, symbol', () async {
      final File fileB = tempDir.childFile('b.dart');
      final File fileC = tempDir.childFile('c.dart');
      final File fileA = tempDir.childFile('a.dart');
      final File filePart = tempDir.childFile('a_part.dart');
      final File csvOut = tempDir.childFile('output.csv');

      fileC.writeAsStringSync('''
class CClass {}
''');

      fileB.writeAsStringSync('''
export 'c.dart';

class BClass {
  static void staticMethod() {}
}
void bFunction() {}
const int bConst = 42;
typedef BTypedef = void Function();
mixin BMixin {}
enum BEnum { one, two }
extension BExtension on int {
  void extMethod() {}
}
''');

      filePart.writeAsStringSync('''
part of 'a.dart';

void partFunction() {
  bFunction();
}
''');

      fileA.writeAsStringSync('''
import 'b.dart';
import 'c.dart';
part 'a_part.dart';

class AClass extends CClass with BMixin implements BTypedef {
  void test(BEnum e) {
    final b = BClass();
    BClass.staticMethod();
    print(bConst);
    10.extMethod();
    String s = 'core type';
    int i = 5;
  }
}
''');

      final outputImports = OutputImports(
        fileSystem: fileSystem,
        logger: logger,
        targetPaths: <String>[tempDir.path],
        outputPath: csvOut.path,
      );

      await outputImports.run();

      expect(csvOut.existsSync(), isTrue);
      final List<String> lines = csvOut.readAsLinesSync();

      expect(lines.first, 'source_file,imported_file,symbol');

      // Verify header + sorted entries
      final List<String> dataLines = lines.sublist(1);

      final String aPath = fileA.path;
      final String aPartPath = filePart.path;
      final String bPath = fileB.path;
      final String cPath = fileC.path;

      expect(dataLines, <String>[
        '$aPath,$bPath,BClass',
        '$aPath,$bPath,BEnum',
        '$aPath,$bPath,BExtension',
        '$aPath,$bPath,BMixin',
        '$aPath,$bPath,BTypedef',
        '$aPath,$bPath,bConst',
        '$aPath,$cPath,CClass',
        '$aPartPath,$bPath,bFunction',
      ]);
    });

    testWithoutContext('handles prefixed imports and annotations', () async {
      final File fileB = tempDir.childFile('b.dart');
      final File fileA = tempDir.childFile('a.dart');
      final File csvOut = tempDir.childFile('output.csv');

      fileB.writeAsStringSync('''
class Foo {
  static const int someVal = 1;
}
const int myAnnotation = 123;
''');

      fileA.writeAsStringSync('''
import 'b.dart' as b_prefixed;

@b_prefixed.myAnnotation
class AClass {
  void test() {
    print(b_prefixed.Foo.someVal);
  }
}
''');

      final outputImports = OutputImports(
        fileSystem: fileSystem,
        logger: logger,
        targetPaths: <String>[fileA.path],
        outputPath: csvOut.path,
      );

      await outputImports.run();

      expect(csvOut.existsSync(), isTrue);
      final List<String> lines = csvOut.readAsLinesSync();
      expect(lines.first, 'source_file,imported_file,symbol');
      expect(lines.sublist(1), <String>[
        '${fileA.path},${fileB.path},Foo',
        '${fileA.path},${fileB.path},myAnnotation',
      ]);
    });

    testWithoutContext('does not include symbols from the same library or dart:core', () async {
      final File fileA = tempDir.childFile('a.dart');
      final File csvOut = tempDir.childFile('output.csv');

      fileA.writeAsStringSync('''
class LocalClass {}
void localFunc() {}

void main() {
  final l = LocalClass();
  localFunc();
  final s = 'hello';
  final list = <int>[1, 2, 3];
  print(s);
}
''');

      final outputImports = OutputImports(
        fileSystem: fileSystem,
        logger: logger,
        targetPaths: <String>[fileA.path],
        outputPath: csvOut.path,
      );

      await outputImports.run();

      expect(csvOut.existsSync(), isTrue);
      final List<String> lines = csvOut.readAsLinesSync();
      expect(lines, <String>['source_file,imported_file,symbol']);
    });
  });

  group('AnalyzeCommand with --output_imports', () {
    late FileSystem fileSystem;
    late BufferLogger logger;
    late Directory tempDir;
    late AnalyzeCommand command;
    late CommandRunner<void> runner;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      fileSystem = const LocalFileSystem();
      logger = BufferLogger.test();
      tempDir = fileSystem.systemTempDirectory.createTempSync('output_imports_cmd_test_');

      command = AnalyzeCommand(
        artifacts: Artifacts.test(),
        fileSystem: fileSystem,
        logger: logger,
        platform: FakePlatform(),
        processManager: FakeProcessManager.empty(),
        terminal: Terminal.test(),
        allProjectValidators: <ProjectValidator>[],
        suppressAnalytics: true,
      );
      runner = createTestCommandRunner(command);
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on Object catch (_) {}
    });

    testUsingContext('runs analysis and writes CSV with --output_imports', () async {
      final File fileB = tempDir.childFile('b.dart');
      final File fileA = tempDir.childFile('a.dart');
      final File csvOut = tempDir.childFile('imports.csv');

      fileB.writeAsStringSync('''
class Greeter {
  void sayHello() {}
}
''');

      fileA.writeAsStringSync('''
import 'b.dart';

void main() {
  final g = Greeter();
  g.sayHello();
}
''');

      await runner.run(<String>[
        'analyze',
        '--output_imports=${csvOut.path}',
        tempDir.path,
      ]);

      expect(csvOut.existsSync(), isTrue);
      final List<String> lines = csvOut.readAsLinesSync();
      expect(lines.first, 'source_file,imported_file,symbol');
      expect(lines.length, 2);
      expect(lines[1], '${fileA.path},${fileB.path},Greeter');
    }, overrides: <Type, Generator>{
      FileSystem: () => const LocalFileSystem(),
      ProcessManager: () => FakeProcessManager.empty(),
    });

    testUsingContext('supports --output-imports kebab-case variant', () async {
      final File fileB = tempDir.childFile('b.dart');
      final File fileA = tempDir.childFile('a.dart');
      final File csvOut = tempDir.childFile('imports2.csv');

      fileB.writeAsStringSync('''
class Foo {}
''');

      fileA.writeAsStringSync('''
import 'b.dart';

void main() {
  Foo();
}
''');

      await runner.run(<String>[
        'analyze',
        '--output-imports=${csvOut.path}',
        tempDir.path,
      ]);

      expect(csvOut.existsSync(), isTrue);
      final List<String> lines = csvOut.readAsLinesSync();
      expect(lines.first, 'source_file,imported_file,symbol');
      expect(lines.length, 2);
      expect(lines[1], '${fileA.path},${fileB.path},Foo');
    }, overrides: <Type, Generator>{
      FileSystem: () => const LocalFileSystem(),
      ProcessManager: () => FakeProcessManager.empty(),
    });
  });
}
