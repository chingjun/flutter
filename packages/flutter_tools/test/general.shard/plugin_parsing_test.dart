// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';

const _kTestPluginName = 'test_plugin_name';
const _kTestPluginPath = 'test_plugin_path';

void main() {
  testWithoutContext('Plugin creation from the legacy format', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'androidPackage: com.flutter.dev\n'
        'iosPrefix: FLT\n'
        'pluginClass: SamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    final androidPlugin =
        plugin.platforms[AndroidPlugin.kConfigKey]!.single as AndroidPlatformChannelPlugin;
    final iosPlugin = plugin.platforms[IOSPlugin.kConfigKey]!.single as IOSPlatformChannelPlugin;

    expect(iosPlugin.pluginClass, 'SamplePlugin');
    expect(iosPlugin.classPrefix, 'FLT');
    expect(iosPlugin.sharedDarwinSource, isFalse);
    expect(androidPlugin.pluginClass, 'SamplePlugin');
    expect(androidPlugin.package, 'com.flutter.dev');
  });

  testWithoutContext('Plugin creation from the multi-platform format', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  package: com.flutter.dev\n'
        '  pluginClass: ASamplePlugin\n'
        ' ios:\n'
        '  pluginClass: ISamplePlugin\n'
        '  sharedDarwinSource: true\n'
        ' linux:\n'
        '  pluginClass: LSamplePlugin\n'
        ' macos:\n'
        '  pluginClass: MSamplePlugin\n'
        '  sharedDarwinSource: true\n'
        ' web:\n'
        '  pluginClass: WebSamplePlugin\n'
        '  fileName: web_plugin.dart\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    final androidPlugin =
        plugin.platforms[AndroidPlugin.kConfigKey]!.single as AndroidPlatformChannelPlugin;
    final iosPlugin = plugin.platforms[IOSPlugin.kConfigKey]!.single as IOSPlatformChannelPlugin;
    final linuxPlugin =
        plugin.platforms[LinuxPlugin.kConfigKey]!.single as LinuxPlatformChannelPlugin;
    final macOSPlugin =
        plugin.platforms[MacOSPlugin.kConfigKey]!.single as MacOSPlatformChannelPlugin;
    final webPlugin = plugin.platforms[WebPlugin.kConfigKey]!.single as WebPlugin;
    final windowsPlugin =
        plugin.platforms[WindowsPlugin.kConfigKey]!.single as WindowsPlatformChannelPlugin;

    expect(iosPlugin.pluginClass, 'ISamplePlugin');
    expect(iosPlugin.classPrefix, '');
    expect(iosPlugin.sharedDarwinSource, isTrue);
    expect(androidPlugin.pluginClass, 'ASamplePlugin');
    expect(androidPlugin.package, 'com.flutter.dev');
    expect(linuxPlugin.pluginClass, 'LSamplePlugin');
    expect(macOSPlugin.pluginClass, 'MSamplePlugin');
    expect(macOSPlugin.sharedDarwinSource, isTrue);
    expect(webPlugin.pluginClass, 'WebSamplePlugin');
    expect(webPlugin.fileName, 'web_plugin.dart');
    expect(windowsPlugin.pluginClass, 'WinSamplePlugin');
  });

  testWithoutContext(
    'Plugin parsing of unknown fields are allowed (allows some future compatibility)',
    () {
      final fileSystem = MemoryFileSystem.test();
      const pluginYamlRaw =
          'implements: same_plugin\n' // this should be ignored by the tool
          'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n'
          '  pluginClass: ASamplePlugin\n'
          '  anUnknownField: ASamplePlugin\n' // this should be ignored by the tool
          ' ios:\n'
          '  pluginClass: ISamplePlugin\n'
          ' linux:\n'
          '  pluginClass: LSamplePlugin\n'
          ' macos:\n'
          '  pluginClass: MSamplePlugin\n'
          ' web:\n'
          '  pluginClass: WebSamplePlugin\n'
          '  fileName: web_plugin.dart\n'
          ' windows:\n'
          '  pluginClass: WinSamplePlugin\n';

      final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      final plugin = Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      );

      final androidPlugin =
          plugin.platforms[AndroidPlugin.kConfigKey]!.single as AndroidPlatformChannelPlugin;
      final iosPlugin = plugin.platforms[IOSPlugin.kConfigKey]!.single as IOSPlatformChannelPlugin;
      final linuxPlugin =
          plugin.platforms[LinuxPlugin.kConfigKey]!.single as LinuxPlatformChannelPlugin;
      final macOSPlugin =
          plugin.platforms[MacOSPlugin.kConfigKey]!.single as MacOSPlatformChannelPlugin;
      final webPlugin = plugin.platforms[WebPlugin.kConfigKey]!.single as WebPlugin;
      final windowsPlugin =
          plugin.platforms[WindowsPlugin.kConfigKey]!.single as WindowsPlatformChannelPlugin;

      expect(iosPlugin.pluginClass, 'ISamplePlugin');
      expect(iosPlugin.classPrefix, '');
      expect(iosPlugin.sharedDarwinSource, isFalse);
      expect(androidPlugin.pluginClass, 'ASamplePlugin');
      expect(androidPlugin.package, 'com.flutter.dev');
      expect(linuxPlugin.pluginClass, 'LSamplePlugin');
      expect(macOSPlugin.pluginClass, 'MSamplePlugin');
      expect(macOSPlugin.sharedDarwinSource, isFalse);
      expect(webPlugin.pluginClass, 'WebSamplePlugin');
      expect(webPlugin.fileName, 'web_plugin.dart');
      expect(windowsPlugin.pluginClass, 'WinSamplePlugin');
    },
  );

  testWithoutContext('Plugin parsing allows for Dart-only plugins without a pluginClass', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'implements: same_plugin\n' // this should be ignored by the tool
        'platforms:\n'
        ' android:\n'
        '  dartPluginClass: ASamplePlugin\n'
        ' ios:\n'
        '  dartPluginClass: ISamplePlugin\n'
        ' linux:\n'
        '  dartPluginClass: LSamplePlugin\n'
        ' macos:\n'
        '  dartPluginClass: MSamplePlugin\n'
        ' windows:\n'
        '  dartPluginClass: WinSamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    final androidPlugin = plugin.platforms[AndroidPlugin.kConfigKey]!.single as AndroidDartPlugin;
    final iOSPlugin = plugin.platforms[IOSPlugin.kConfigKey]!.single as IOSDartPlugin;
    final linuxPlugin = plugin.platforms[LinuxPlugin.kConfigKey]!.single as LinuxDartPlugin;
    final macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey]!.single as MacOSDartPlugin;
    final windowsPlugin = plugin.platforms[WindowsPlugin.kConfigKey]!.single as WindowsDartPlugin;

    expect(androidPlugin.dartPluginClass, 'ASamplePlugin');
    expect(iOSPlugin.dartPluginClass, 'ISamplePlugin');
    expect(linuxPlugin.dartPluginClass, 'LSamplePlugin');
    expect(macOSPlugin.dartPluginClass, 'MSamplePlugin');
    expect(windowsPlugin.dartPluginClass, 'WinSamplePlugin');
  });

  testWithoutContext('Plugin parsing allows a dartFileName field with dartPluginClass', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  dartPluginClass: AndroidClass\n'
        '  dartFileName: src/android_class.dart\n'
        ' ios:\n'
        '  dartPluginClass: IosClass\n'
        '  dartFileName: src/ios_class.dart\n'
        ' linux:\n'
        '  dartPluginClass: LinuxClass\n'
        '  dartFileName: src/linux_class.dart\n'
        ' macos:\n'
        '  dartPluginClass: MacOSClass\n'
        '  dartFileName: src/macos_class.dart\n'
        ' windows:\n'
        '  dartPluginClass: WindowsClass\n'
        '  dartFileName: src/windows_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    expect(plugin.pluginDartClassPlatforms, <String, DartPluginClassAndFilePair>{
      'android': const (dartClass: 'AndroidClass', dartFileName: 'src/android_class.dart'),
      'ios': const (dartClass: 'IosClass', dartFileName: 'src/ios_class.dart'),
      'linux': const (dartClass: 'LinuxClass', dartFileName: 'src/linux_class.dart'),
      'macos': const (dartClass: 'MacOSClass', dartFileName: 'src/macos_class.dart'),
      'windows': const (dartClass: 'WindowsClass', dartFileName: 'src/windows_class.dart'),
    });
  });

  testWithoutContext('dartFileName without dartPluginClass throws (Android)', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  package: com.example\n'
        '  pluginClass: AndroidClass\n'
        '  dartFileName: src/android_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in Android platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext('dartFileName without dartPluginClass throws (iOS)', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' ios:\n'
        '  pluginClass: IosClass\n'
        '  dartFileName: src/ios_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in iOS platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext('dartFileName without dartPluginClass throws (Linux)', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' linux:\n'
        '  pluginClass: LinuxClass\n'
        '  dartFileName: src/linux_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in Linux platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext('dartFileName without dartPluginClass throws (MacOS)', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' macos:\n'
        '  pluginClass: MacOSClass\n'
        '  dartFileName: src/macos_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in macOS platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext('dartFileName without dartPluginClass throws (Windows)', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' windows:\n'
        '  pluginClass: WindowsClass\n'
        '  dartFileName: src/windows_class.dart\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            '"dartFileName" cannot be specified without "dartPluginClass" in Windows platform of plugin "$_kTestPluginName"',
      ),
    );
  });

  testWithoutContext(
    'Plugin parsing of legacy format and multi-platform format together is not allowed '
    'and fatal error message contains plugin name',
    () {
      final FileSystem fileSystem = MemoryFileSystem.test();
      const pluginYamlRaw =
          'androidPackage: com.flutter.dev\n'
          'platforms:\n'
          ' android:\n'
          '  package: com.flutter.dev\n';

      final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;

      expect(
        () => Plugin.fromYaml(
          _kTestPluginName,
          _kTestPluginPath,
          pluginYaml,
          null,
          const <String>[],
          isDevDependency: false,
          fileSystem: fileSystem,
        ),
        throwsToolExit(message: _kTestPluginName),
      );
    },
  );

  testWithoutContext('Plugin parsing allows a default_package field', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  default_package: sample_package_android\n'
        ' ios:\n'
        '  default_package: sample_package_ios\n'
        ' linux:\n'
        '  default_package: sample_package_linux\n'
        ' macos:\n'
        '  default_package: sample_package_macos\n'
        ' web:\n'
        '  default_package: sample_package_web\n'
        ' windows:\n'
        '  default_package: sample_package_windows\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    expect(plugin.platforms, <String, List<PluginPlatform>>{});
    expect(plugin.defaultPackagePlatforms, <String, String>{
      'android': 'sample_package_android',
      'ios': 'sample_package_ios',
      'linux': 'sample_package_linux',
      'macos': 'sample_package_macos',
      'windows': 'sample_package_windows',
    });
    expect(plugin.pluginDartClassPlatforms, <String, String>{});
  });

  testWithoutContext('Desktop plugin parsing allows a dartPluginClass field', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' linux:\n'
        '  dartPluginClass: LinuxClass\n'
        ' macos:\n'
        '  dartPluginClass: MacOSClass\n'
        ' windows:\n'
        '  dartPluginClass: WindowsClass\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    expect(plugin.pluginDartClassPlatforms, <String, DartPluginClassAndFilePair>{
      'linux': const (dartClass: 'LinuxClass', dartFileName: 'test_plugin_name.dart'),
      'macos': const (dartClass: 'MacOSClass', dartFileName: 'test_plugin_name.dart'),
      'windows': const (dartClass: 'WindowsClass', dartFileName: 'test_plugin_name.dart'),
    });
  });

  testWithoutContext('Windows allows supported mode lists', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n'
        '  supportedVariants:\n'
        '    - win32\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    final windowsPlugin =
        plugin.platforms[WindowsPlugin.kConfigKey]!.single as WindowsPlatformChannelPlugin;
    expect(windowsPlugin.supportedVariants, <PluginPlatformVariant>[PluginPlatformVariant.win32]);
  });

  testWithoutContext('Web plugin tool exits if fileName field missing', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' web:\n'
        '  pluginClass: WebSamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            'The plugin `$_kTestPluginName` is missing the required field `fileName` in pubspec.yaml',
      ),
    );
  });

  testWithoutContext('Windows assumes win32 when no variants are given', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    final windowsPlugin =
        plugin.platforms[WindowsPlugin.kConfigKey]!.single as WindowsPlatformChannelPlugin;
    expect(windowsPlugin.supportedVariants, <PluginPlatformVariant>[PluginPlatformVariant.win32]);
  });

  testWithoutContext('Windows ignores unknown variants', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n'
        '  supportedVariants:\n'
        '    - not_yet_invented_variant\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    final windowsPlugin =
        plugin.platforms[WindowsPlugin.kConfigKey]!.single as WindowsPlatformChannelPlugin;
    expect(windowsPlugin.supportedVariants, <PluginPlatformVariant>{});
  });

  testWithoutContext('Plugin parsing throws a fatal error on an empty plugin', () {
    final fileSystem = MemoryFileSystem.test();
    final pluginYaml = loadYaml('') as YamlMap?;

    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(message: 'Invalid "plugin" specification.'),
    );
  });

  testWithoutContext('Plugin parsing throws a fatal error on empty platforms', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw = 'platforms:\n';
    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;

    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(message: 'Invalid "platforms" specification.'),
    );
  });

  test('Plugin parsing throws a fatal error on an empty platform key', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(message: 'Invalid "android" plugin specification.'),
    );
  });

  testWithoutContext('Plugin parsing reports all errors across platforms at once', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        ' ios:\n'
        '  pluginClass: IosClass\n'
        '  dartFileName: src/ios_class.dart\n'
        ' linux:\n'
        '  dartPluginClass: LinuxClass\n'
        '  dartFileName: ../invalid_path.dart\n'
        ' web:\n'
        '  pluginClass: "Invalid Class"\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            'Invalid plugin specification $_kTestPluginName.\n'
            'Invalid "android" plugin specification.\n'
            '"dartFileName" cannot be specified without "dartPluginClass" in iOS platform of plugin "$_kTestPluginName"\n'
            'The plugin `$_kTestPluginName` has an invalid `dartFileName` for platform `linux` in pubspec.yaml.\n'
            'Invalid "web" plugin specification: the "pluginClass" field must be a valid identifier, optionally with dot-separated segments.\n'
            'The plugin `$_kTestPluginName` is missing the required field `fileName` in pubspec.yaml',
      ),
    );
  });

  testWithoutContext('Plugin parsing allows an empty web platform key', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  ffiPlugin: true\n'
        ' web:\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    expect(plugin.platforms.keys, contains(AndroidPlugin.kConfigKey));
    expect(plugin.platforms.keys, isNot(contains(WebPlugin.kConfigKey)));
    expect(Plugin.validatePluginYaml(pluginYaml, packageName: _kTestPluginName), isEmpty);
  });

  testWithoutContext('Plugin parsing rejects non-string implements, non-bool flags, and non-string supportedVariants', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'implements: 123\n'
        'platforms:\n'
        ' android:\n'
        '  ffiPlugin: "true"\n'
        ' ios:\n'
        '  pluginClass: IosClass\n'
        '  sharedDarwinSource: "yes"\n'
        ' windows:\n'
        '  pluginClass: WinClass\n'
        '  supportedVariants:\n'
        '   - 1\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            'Invalid plugin specification $_kTestPluginName.\n'
            'Invalid "android" plugin specification: the "ffiPlugin" field must be a boolean.\n'
            'Invalid "ios" plugin specification: the "sharedDarwinSource" field must be a boolean.\n'
            'Invalid "windows" plugin specification: the "supportedVariants" field must be a list of strings.\n'
            'Invalid "implements" specification.',
      ),
    );
  });

  testWithoutContext('Plugin parsing rejects invalid dartPluginClass next to default_package', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' linux:\n'
        '  default_package: some_package\n'
        '  dartPluginClass: "Invalid Class"\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    expect(
      () => Plugin.fromYaml(
        _kTestPluginName,
        _kTestPluginPath,
        pluginYaml,
        null,
        const <String>[],
        isDevDependency: false,
        fileSystem: fileSystem,
      ),
      throwsToolExit(
        message:
            'Invalid plugin specification $_kTestPluginName.\n'
            'Invalid "linux" plugin specification: the "dartPluginClass" field must be a valid identifier, optionally with dot-separated segments.',
      ),
    );
  });

  testWithoutContext(
    'Plugin parsing rejects sharedDarwinSource without pluginClass or ffiPlugin',
    () {
      final fileSystem = MemoryFileSystem.test();
      const pluginYamlRaw =
          'platforms:\n'
          ' ios:\n'
          '  sharedDarwinSource: true\n'
          ' macos:\n'
          '  dartPluginClass: MacOSClass\n'
          '  sharedDarwinSource: true\n';

      final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
      expect(
        () => Plugin.fromYaml(
          _kTestPluginName,
          _kTestPluginPath,
          pluginYaml,
          null,
          const <String>[],
          isDevDependency: false,
          fileSystem: fileSystem,
        ),
        throwsToolExit(
          message:
              'Invalid plugin specification $_kTestPluginName.\n'
              'Invalid "ios" plugin specification: "sharedDarwinSource" cannot be specified without "pluginClass" or "ffiPlugin".\n'
              'Invalid "macos" plugin specification: "sharedDarwinSource" cannot be specified without "pluginClass" or "ffiPlugin".',
        ),
      );
    },
  );

  testWithoutContext('Plugin parsing allows sharedDarwinSource with ffiPlugin', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' ios:\n'
        '  ffiPlugin: true\n'
        '  sharedDarwinSource: true\n'
        ' macos:\n'
        '  ffiPlugin: true\n'
        '  sharedDarwinSource: true\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    final iosPlugin = plugin.platforms[IOSPlugin.kConfigKey]!.single as IOSFfiPlugin;
    final macOSPlugin = plugin.platforms[MacOSPlugin.kConfigKey]!.single as MacOSFfiPlugin;

    expect(iosPlugin.sharedDarwinSource, isTrue);
    expect(macOSPlugin.sharedDarwinSource, isTrue);
    expect(iosPlugin.toMap(), <String, Object>{
      'name': _kTestPluginName,
      'ffiPlugin': true,
      'sharedDarwinSource': true,
    });
    expect(macOSPlugin.toMap(), <String, Object>{
      'name': _kTestPluginName,
      'ffiPlugin': true,
      'sharedDarwinSource': true,
    });
  });

  testWithoutContext('Plugin parsing creates FFI plugin instances across all platforms', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  ffiPlugin: true\n'
        '  dartPluginClass: AndroidDartFfi\n'
        ' ios:\n'
        '  ffiPlugin: true\n'
        ' linux:\n'
        '  ffiPlugin: true\n'
        ' macos:\n'
        '  ffiPlugin: true\n'
        ' windows:\n'
        '  ffiPlugin: true\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    expect(plugin.platforms[AndroidPlugin.kConfigKey], <Matcher>[
      isA<AndroidFfiPlugin>(),
      isA<AndroidDartPlugin>(),
    ]);
    expect(plugin.platforms[IOSPlugin.kConfigKey], <Matcher>[isA<IOSFfiPlugin>()]);
    expect(plugin.platforms[LinuxPlugin.kConfigKey], <Matcher>[isA<LinuxFfiPlugin>()]);
    expect(plugin.platforms[MacOSPlugin.kConfigKey], <Matcher>[isA<MacOSFfiPlugin>()]);
    expect(plugin.platforms[WindowsPlugin.kConfigKey], <Matcher>[isA<WindowsFfiPlugin>()]);
    expect(plugin.platforms[AndroidPlugin.kConfigKey]![0].toMap(), <String, Object>{
      'name': _kTestPluginName,
      'ffiPlugin': true,
    });
    expect(plugin.platforms[AndroidPlugin.kConfigKey]![1].toMap(), <String, Object>{
      'name': _kTestPluginName,
      'dartPluginClass': 'AndroidDartFfi',
      'dartFileName': 'test_plugin_name.dart',
    });
    expect(plugin.platforms[LinuxPlugin.kConfigKey]!.single.toMap(), <String, Object>{
      'name': _kTestPluginName,
      'ffiPlugin': true,
    });
    expect(plugin.platforms[WindowsPlugin.kConfigKey]!.single.toMap(), <String, Object>{
      'name': _kTestPluginName,
      'ffiPlugin': true,
    });
    expect(plugin.pluginDartClassPlatforms, <String, DartPluginClassAndFilePair>{
      'android': const (dartClass: 'AndroidDartFfi', dartFileName: 'test_plugin_name.dart'),
    });
  });

  testWithoutContext('Plugin parsing creates multiple plugin instances when a platform specifies multiple plugin types', () {
    final fileSystem = MemoryFileSystem.test();
    const pluginYamlRaw =
        'platforms:\n'
        ' android:\n'
        '  package: com.flutter.dev\n'
        '  pluginClass: ASamplePlugin\n'
        '  ffiPlugin: true\n'
        '  dartPluginClass: ADartPlugin\n'
        ' ios:\n'
        '  pluginClass: ISamplePlugin\n'
        '  ffiPlugin: true\n'
        '  dartPluginClass: IDartPlugin\n'
        ' linux:\n'
        '  pluginClass: LSamplePlugin\n'
        '  ffiPlugin: true\n'
        '  dartPluginClass: LDartPlugin\n'
        ' macos:\n'
        '  pluginClass: MSamplePlugin\n'
        '  ffiPlugin: true\n'
        '  dartPluginClass: MDartPlugin\n'
        ' windows:\n'
        '  pluginClass: WinSamplePlugin\n'
        '  ffiPlugin: true\n'
        '  dartPluginClass: WinDartPlugin\n';

    final pluginYaml = loadYaml(pluginYamlRaw) as YamlMap;
    final plugin = Plugin.fromYaml(
      _kTestPluginName,
      _kTestPluginPath,
      pluginYaml,
      null,
      const <String>[],
      isDevDependency: false,
      fileSystem: fileSystem,
    );

    expect(plugin.platforms[AndroidPlugin.kConfigKey], <Matcher>[
      isA<AndroidPlatformChannelPlugin>(),
      isA<AndroidFfiPlugin>(),
      isA<AndroidDartPlugin>(),
    ]);
    expect(plugin.platforms[IOSPlugin.kConfigKey], <Matcher>[
      isA<IOSPlatformChannelPlugin>(),
      isA<IOSFfiPlugin>(),
      isA<IOSDartPlugin>(),
    ]);
    expect(plugin.platforms[LinuxPlugin.kConfigKey], <Matcher>[
      isA<LinuxPlatformChannelPlugin>(),
      isA<LinuxFfiPlugin>(),
      isA<LinuxDartPlugin>(),
    ]);
    expect(plugin.platforms[MacOSPlugin.kConfigKey], <Matcher>[
      isA<MacOSPlatformChannelPlugin>(),
      isA<MacOSFfiPlugin>(),
      isA<MacOSDartPlugin>(),
    ]);
    expect(plugin.platforms[WindowsPlugin.kConfigKey], <Matcher>[
      isA<WindowsPlatformChannelPlugin>(),
      isA<WindowsFfiPlugin>(),
      isA<WindowsDartPlugin>(),
    ]);
    expect(plugin.pluginDartClassPlatforms, <String, DartPluginClassAndFilePair>{
      'android': const (dartClass: 'ADartPlugin', dartFileName: 'test_plugin_name.dart'),
      'ios': const (dartClass: 'IDartPlugin', dartFileName: 'test_plugin_name.dart'),
      'linux': const (dartClass: 'LDartPlugin', dartFileName: 'test_plugin_name.dart'),
      'macos': const (dartClass: 'MDartPlugin', dartFileName: 'test_plugin_name.dart'),
      'windows': const (dartClass: 'WinDartPlugin', dartFileName: 'test_plugin_name.dart'),
    });
  });
}
