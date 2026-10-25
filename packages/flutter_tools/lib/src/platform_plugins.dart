// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/utils.dart';
import 'plugin_yaml_parser.dart';

/// Constant for 'pluginClass' key in plugin maps.
const kPluginClass = 'pluginClass';

/// Constant for 'fileName' key in plugin maps.
const kFileName = 'fileName';

/// Constant for 'ffiPlugin' key in plugin maps.
const kFfiPlugin = 'ffiPlugin';

/// Constant for 'sharedDarwinSource' key in plugin maps.
/// Can be set for iOS and macOS plugins.
const kSharedDarwinSource = 'sharedDarwinSource';

/// Constant for 'supportedVariants' key in plugin maps.
const kSupportedVariants = 'supportedVariants';

/// Platform variants that a Windows plugin can support.
enum PluginPlatformVariant {
  /// Win32 variant of Windows.
  win32,
}

/// Marker interface for all platform specific plugin config implementations.
abstract class PluginPlatform {
  const PluginPlatform();

  /// The plugin name defined in pubspec.yaml.
  String get name;

  Map<String, dynamic> toMap();
}

/// A plugin that has platform variants.
abstract class VariantPlatformPlugin {
  /// The platform variants supported by the plugin.
  Set<PluginPlatformVariant> get supportedVariants;
}

/// Marker interface for plugins that require a native build.
sealed class NativePlugin implements PluginPlatform {}

/// A plugin that uses platform channels to communicate with native code.
abstract class PlatformChannelPlugin implements NativePlugin {
  /// The native plugin main class defined in pubspec.yaml.
  String get pluginClass;
}

/// A plugin that uses FFI to communicate with native code.
abstract class FfiPlugin implements NativePlugin {}

/// A Dart-only plugin implementation.
abstract class DartPlugin implements PluginPlatform {
  /// The Dart plugin main class defined in pubspec.yaml.
  String get dartPluginClass;

  /// Path to file in which [dartPluginClass] is defined.
  String get dartFileName;
}

/// A native plugin for iOS or macOS that can share source in a "darwin" directory.
abstract class DarwinPlugin implements NativePlugin {
  /// Indicates the iOS and macOS native code is shareable in the subdirectory "darwin".
  bool get sharedDarwinSource;
}

/// Base class for Android plugin configurations.
sealed class AndroidPlugin extends PluginPlatform {
  const AndroidPlugin({required this.name});

  /// Parses the Android plugin configurations from the given [yaml].
  ///
  /// Returns an empty list as the parsed value if [yaml] does not declare a
  /// valid Android plugin (none of `package` with `pluginClass`,
  /// `dartPluginClass`, or `ffiPlugin: true`).
  static ParseResult<List<AndroidPlugin>> parseFromYaml(
    String name,
    YamlMap yaml, {
    required String pluginPath,
    required FileSystem fileSystem,
  }) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      parser.identifier('package'),
      parser.parseDartPluginFields(displayName: 'Android'),
    ).map((
      String? pluginClass,
      bool ffiPlugin,
      String? package,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      return <AndroidPlugin>[
        if (package != null && pluginClass != null)
          AndroidPlatformChannelPlugin(
            name: name,
            package: package,
            pluginClass: pluginClass,
            pluginPath: pluginPath,
            fileSystem: fileSystem,
          ),
        if (ffiPlugin) AndroidFfiPlugin(name: name),
        if (dartPluginFields != null)
          AndroidDartPlugin(
            name: name,
            dartPluginClass: dartPluginFields.dartPluginClass,
            dartFileName: dartPluginFields.dartFileName,
          ),
      ];
    });
  }

  static const kConfigKey = 'android';

  @override
  final String name;
}

/// Contains parameters to template an Android platform channel plugin.
class AndroidPlatformChannelPlugin extends AndroidPlugin implements PlatformChannelPlugin {
  AndroidPlatformChannelPlugin({
    required super.name,
    required this.package,
    required this.pluginClass,
    required this.pluginPath,
    required this._fileSystem,
  });

  final FileSystem _fileSystem;

  /// The plugin package name defined in pubspec.yaml.
  final String package;

  /// The native plugin main class defined in pubspec.yaml.
  @override
  final String pluginClass;

  /// The absolute path to the plugin in the pub cache.
  final String pluginPath;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'package': package,
      'class': pluginClass,
      // Mustache doesn't support complex types.
      'supportsEmbeddingV1': _supportedEmbeddings.contains('1'),
      'supportsEmbeddingV2': _supportedEmbeddings.contains('2'),
    };
  }

  /// Returns the version of the Android embedding.
  late final Set<String> _supportedEmbeddings = _getSupportedEmbeddings();

  Set<String> _getSupportedEmbeddings() {
    final supportedEmbeddings = <String>{};
    final String baseMainPath = _fileSystem.path.join(pluginPath, 'android', 'src', 'main');

    final mainClassCandidates = <String>[
      _fileSystem.path.join(
        baseMainPath,
        'java',
        package.replaceAll('.', _fileSystem.path.separator),
        '$pluginClass.java',
      ),
      _fileSystem.path.join(
        baseMainPath,
        'kotlin',
        package.replaceAll('.', _fileSystem.path.separator),
        '$pluginClass.kt',
      ),
    ];

    File? mainPluginClass;
    var mainClassFound = false;
    for (final mainClassCandidate in mainClassCandidates) {
      mainPluginClass = _fileSystem.file(mainClassCandidate);
      if (mainPluginClass.existsSync()) {
        mainClassFound = true;
        break;
      }
    }
    if (mainPluginClass == null || !mainClassFound) {
      assert(mainClassCandidates.length <= 2);
      throwToolExit(
        "The plugin `$name` doesn't have a main class defined in ${mainClassCandidates.join(' or ')}. "
        "This is likely to due to an incorrect `androidPackage: $package` or `mainClass` entry in the plugin's pubspec.yaml.\n"
        'If you are the author of this plugin, fix the `androidPackage` entry or move the main class to any of locations used above. '
        'Otherwise, please contact the author of this plugin and consider using a different plugin in the meanwhile. ',
      );
    }

    final String mainClassContent = mainPluginClass.readAsStringSync();
    if (mainClassContent.contains('io.flutter.embedding.engine.plugins.FlutterPlugin')) {
      supportedEmbeddings.add('2');
    } else {
      supportedEmbeddings.add('1');
    }
    if (mainClassContent.contains('PluginRegistry') && mainClassContent.contains('registerWith')) {
      supportedEmbeddings.add('1');
    }
    return supportedEmbeddings;
  }
}

/// Contains parameters for an Android FFI plugin.
class AndroidFfiPlugin extends AndroidPlugin implements FfiPlugin {
  const AndroidFfiPlugin({required super.name});

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'name': name, kFfiPlugin: true};
  }
}

/// Contains parameters for an Android Dart-only plugin.
class AndroidDartPlugin extends AndroidPlugin implements DartPlugin {
  const AndroidDartPlugin({
    required super.name,
    required this.dartPluginClass,
    String? dartFileName,
  }) : dartFileName = dartFileName ?? '$name.dart';

  @override
  final String dartPluginClass;

  @override
  final String dartFileName;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      kDartPluginClass: dartPluginClass,
      kDartFileName: dartFileName,
    };
  }
}

/// Base class for iOS plugin configurations.
sealed class IOSPlugin extends PluginPlatform {
  const IOSPlugin({required this.name});

  /// Parses the iOS plugin configurations from the given [yaml].
  ///
  /// Returns an empty list as the parsed value if [yaml] does not declare a
  /// valid iOS plugin (none of `pluginClass`, `dartPluginClass`, or
  /// `ffiPlugin: true`).
  static ParseResult<List<IOSPlugin>> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      parser.flag(kSharedDarwinSource),
      parser.parseDartPluginFields(displayName: 'iOS'),
    ).flatMap((
      String? pluginClass,
      bool ffiPlugin,
      bool sharedDarwinSource,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      if (sharedDarwinSource && pluginClass == null && !ffiPlugin) {
        return parser.invalid(
          '"$kSharedDarwinSource" cannot be specified without "$kPluginClass" or "$kFfiPlugin".',
        );
      }
      return .pass(<IOSPlugin>[
        if (pluginClass != null)
          IOSPlatformChannelPlugin(
            name: name,
            pluginClass: pluginClass,
            sharedDarwinSource: sharedDarwinSource,
          ),
        if (ffiPlugin) IOSFfiPlugin(name: name, sharedDarwinSource: sharedDarwinSource),
        if (dartPluginFields != null)
          IOSDartPlugin(
            name: name,
            dartPluginClass: dartPluginFields.dartPluginClass,
            dartFileName: dartPluginFields.dartFileName,
          ),
      ]);
    });
  }

  static const kConfigKey = 'ios';

  @override
  final String name;
}

/// Contains the parameters to template an iOS platform channel plugin.
class IOSPlatformChannelPlugin extends IOSPlugin implements PlatformChannelPlugin, DarwinPlugin {
  const IOSPlatformChannelPlugin({
    required super.name,
    required this.pluginClass,
    this.classPrefix = '',
    this.sharedDarwinSource = false,
  });

  /// Note, this is here only for legacy reasons. Multi-platform format
  /// always sets it to empty String.
  final String classPrefix;

  @override
  final String pluginClass;

  /// Indicates the iOS native code is shareable with macOS in
  /// the subdirectory "darwin", otherwise in the subdirectory "ios".
  @override
  final bool sharedDarwinSource;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'prefix': classPrefix,
      'class': pluginClass,
      'classVar': camelCase(snakeCase('$classPrefix$pluginClass')),
      if (sharedDarwinSource) kSharedDarwinSource: true,
    };
  }
}

/// Contains the parameters for an iOS FFI plugin.
class IOSFfiPlugin extends IOSPlugin implements FfiPlugin, DarwinPlugin {
  const IOSFfiPlugin({required super.name, this.sharedDarwinSource = false});

  /// Indicates the iOS native code is shareable with macOS in
  /// the subdirectory "darwin", otherwise in the subdirectory "ios".
  @override
  final bool sharedDarwinSource;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      kFfiPlugin: true,
      if (sharedDarwinSource) kSharedDarwinSource: true,
    };
  }
}

/// Contains the parameters for an iOS Dart-only plugin.
class IOSDartPlugin extends IOSPlugin implements DartPlugin {
  const IOSDartPlugin({required super.name, required this.dartPluginClass, String? dartFileName})
    : dartFileName = dartFileName ?? '$name.dart';

  @override
  final String dartPluginClass;

  @override
  final String dartFileName;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      kDartPluginClass: dartPluginClass,
      kDartFileName: dartFileName,
    };
  }
}

/// Base class for macOS plugin configurations.
sealed class MacOSPlugin extends PluginPlatform {
  const MacOSPlugin({required this.name});

  /// Parses the macOS plugin configurations from the given [yaml].
  ///
  /// Returns an empty list as the parsed value if [yaml] does not declare a
  /// valid macOS plugin (none of `pluginClass`, `dartPluginClass`, or
  /// `ffiPlugin: true`).
  static ParseResult<List<MacOSPlugin>> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      parser.flag(kSharedDarwinSource),
      parser.parseDartPluginFields(displayName: 'macOS'),
    ).flatMap((
      String? pluginClass,
      bool ffiPlugin,
      bool sharedDarwinSource,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      if (sharedDarwinSource && pluginClass == null && !ffiPlugin) {
        return parser.invalid(
          '"$kSharedDarwinSource" cannot be specified without "$kPluginClass" or "$kFfiPlugin".',
        );
      }
      return .pass(<MacOSPlugin>[
        if (pluginClass != null)
          MacOSPlatformChannelPlugin(
            name: name,
            pluginClass: pluginClass,
            sharedDarwinSource: sharedDarwinSource,
          ),
        if (ffiPlugin) MacOSFfiPlugin(name: name, sharedDarwinSource: sharedDarwinSource),
        if (dartPluginFields != null)
          MacOSDartPlugin(
            name: name,
            dartPluginClass: dartPluginFields.dartPluginClass,
            dartFileName: dartPluginFields.dartFileName,
          ),
      ]);
    });
  }

  static const kConfigKey = 'macos';

  @override
  final String name;
}

/// Contains the parameters to template a macOS platform channel plugin.
class MacOSPlatformChannelPlugin extends MacOSPlugin
    implements PlatformChannelPlugin, DarwinPlugin {
  const MacOSPlatformChannelPlugin({
    required super.name,
    required this.pluginClass,
    this.sharedDarwinSource = false,
  });

  @override
  final String pluginClass;

  /// Indicates the macOS native code is shareable with iOS in
  /// the subdirectory "darwin", otherwise in the subdirectory "macos".
  @override
  final bool sharedDarwinSource;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
      if (sharedDarwinSource) kSharedDarwinSource: true,
    };
  }
}

/// Contains the parameters for a macOS FFI plugin.
class MacOSFfiPlugin extends MacOSPlugin implements FfiPlugin, DarwinPlugin {
  const MacOSFfiPlugin({required super.name, this.sharedDarwinSource = false});

  /// Indicates the macOS native code is shareable with iOS in
  /// the subdirectory "darwin", otherwise in the subdirectory "macos".
  @override
  final bool sharedDarwinSource;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      kFfiPlugin: true,
      if (sharedDarwinSource) kSharedDarwinSource: true,
    };
  }
}

/// Contains the parameters for a macOS Dart-only plugin.
class MacOSDartPlugin extends MacOSPlugin implements DartPlugin {
  const MacOSDartPlugin({required super.name, required this.dartPluginClass, String? dartFileName})
    : dartFileName = dartFileName ?? '$name.dart';

  @override
  final String dartPluginClass;

  @override
  final String dartFileName;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      kDartPluginClass: dartPluginClass,
      kDartFileName: dartFileName,
    };
  }
}

/// Base class for Windows plugin configurations.
sealed class WindowsPlugin extends PluginPlatform {
  const WindowsPlugin({required this.name});

  /// Parses the Windows plugin configurations from the given [yaml].
  ///
  /// Returns an empty list as the parsed value if [yaml] does not declare a
  /// valid Windows plugin (none of `pluginClass`, `dartPluginClass`, or
  /// `ffiPlugin: true`).
  static ParseResult<List<WindowsPlugin>> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    final variants = <PluginPlatformVariant>{};
    final Object? variantList = yaml[kSupportedVariants];
    ParseResult<Set<PluginPlatformVariant>> variantsResult = .pass(variants);
    if (variantList == null) {
      // If no variant list is provided assume Win32 for backward compatibility.
      variants.add(PluginPlatformVariant.win32);
    } else if (variantList is YamlList && variantList.every((Object? e) => e is String)) {
      const variantByName = <String, PluginPlatformVariant>{'win32': PluginPlatformVariant.win32};
      for (final String variantName in variantList.cast<String>()) {
        final PluginPlatformVariant? variant = variantByName[variantName];
        if (variant != null) {
          variants.add(variant);
        }
        // Ignore unrecognized variants to make adding new variants in the
        // future non-breaking.
      }
    } else {
      variantsResult = parser.invalid('the "$kSupportedVariants" field must be a list of strings.');
    }

    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      variantsResult,
      parser.parseDartPluginFields(displayName: 'Windows'),
    ).map((
      String? pluginClass,
      bool ffiPlugin,
      Set<PluginPlatformVariant> variants,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      return <WindowsPlugin>[
        if (pluginClass != null)
          WindowsPlatformChannelPlugin(name: name, pluginClass: pluginClass, variants: variants),
        if (ffiPlugin) WindowsFfiPlugin(name: name),
        if (dartPluginFields != null)
          WindowsDartPlugin(
            name: name,
            dartPluginClass: dartPluginFields.dartPluginClass,
            dartFileName: dartPluginFields.dartFileName,
          ),
      ];
    });
  }

  static const kConfigKey = 'windows';

  @override
  final String name;
}

/// Contains the parameters to template a Windows platform channel plugin.
class WindowsPlatformChannelPlugin extends WindowsPlugin
    implements PlatformChannelPlugin, VariantPlatformPlugin {
  const WindowsPlatformChannelPlugin({
    required super.name,
    required this.pluginClass,
    this.variants = const <PluginPlatformVariant>{},
  });

  @override
  final String pluginClass;

  final Set<PluginPlatformVariant> variants;

  @override
  Set<PluginPlatformVariant> get supportedVariants => variants;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
      'filename': _filenameForCppClass(pluginClass),
    };
  }
}

/// Contains the parameters for a Windows FFI plugin.
class WindowsFfiPlugin extends WindowsPlugin implements FfiPlugin {
  const WindowsFfiPlugin({required super.name});

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'name': name, kFfiPlugin: true};
  }
}

/// Contains the parameters for a Windows Dart-only plugin.
class WindowsDartPlugin extends WindowsPlugin implements DartPlugin {
  const WindowsDartPlugin({
    required super.name,
    required this.dartPluginClass,
    String? dartFileName,
  }) : dartFileName = dartFileName ?? '$name.dart';

  @override
  final String dartPluginClass;

  @override
  final String dartFileName;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      kDartPluginClass: dartPluginClass,
      kDartFileName: dartFileName,
    };
  }
}

/// Base class for Linux plugin configurations.
sealed class LinuxPlugin extends PluginPlatform {
  const LinuxPlugin({required this.name});

  /// Parses the Linux plugin configurations from the given [yaml].
  ///
  /// Returns an empty list as the parsed value if [yaml] does not declare a
  /// valid Linux plugin (none of `pluginClass`, `dartPluginClass`, or
  /// `ffiPlugin: true`).
  static ParseResult<List<LinuxPlugin>> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      parser.parseDartPluginFields(displayName: 'Linux'),
    ).map((
      String? pluginClass,
      bool ffiPlugin,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      return <LinuxPlugin>[
        if (pluginClass != null) LinuxPlatformChannelPlugin(name: name, pluginClass: pluginClass),
        if (ffiPlugin) LinuxFfiPlugin(name: name),
        if (dartPluginFields != null)
          LinuxDartPlugin(
            name: name,
            dartPluginClass: dartPluginFields.dartPluginClass,
            dartFileName: dartPluginFields.dartFileName,
          ),
      ];
    });
  }

  static const kConfigKey = 'linux';

  @override
  final String name;
}

/// Contains the parameters to template a Linux platform channel plugin.
class LinuxPlatformChannelPlugin extends LinuxPlugin implements PlatformChannelPlugin {
  const LinuxPlatformChannelPlugin({required super.name, required this.pluginClass});

  @override
  final String pluginClass;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
      'filename': _filenameForCppClass(pluginClass),
    };
  }
}

/// Contains the parameters for a Linux FFI plugin.
class LinuxFfiPlugin extends LinuxPlugin implements FfiPlugin {
  const LinuxFfiPlugin({required super.name});

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'name': name, kFfiPlugin: true};
  }
}

/// Contains the parameters for a Linux Dart-only plugin.
class LinuxDartPlugin extends LinuxPlugin implements DartPlugin {
  const LinuxDartPlugin({required super.name, required this.dartPluginClass, String? dartFileName})
    : dartFileName = dartFileName ?? '$name.dart';

  @override
  final String dartPluginClass;

  @override
  final String dartFileName;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      kDartPluginClass: dartPluginClass,
      kDartFileName: dartFileName,
    };
  }
}

/// Contains the parameters to template a web plugin.
///
/// The required fields include: [name] of the plugin, the [pluginClass] that will
/// be the entry point to the plugin's implementation, and the [fileName]
/// containing the code.
class WebPlugin extends PluginPlatform {
  const WebPlugin({required this.name, required this.pluginClass, required this.fileName});

  /// Parses the Web plugin configuration from the given [yaml].
  static ParseResult<WebPlugin> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (parser.requiredIdentifier(kPluginClass), parser.requiredDartFileName(kFileName)).map(
      (String pluginClass, String fileName) =>
          WebPlugin(name: name, pluginClass: pluginClass, fileName: fileName),
    );
  }

  static const kConfigKey = 'web';

  /// The name of the plugin.
  @override
  final String name;

  /// The class containing the plugin implementation details.
  ///
  /// This class should have a static `registerWith` method defined.
  final String pluginClass;

  /// The name of the file containing the class implementation above.
  final String fileName;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'name': name, 'class': pluginClass, 'file': fileName};
  }
}

final _internalCapitalLetterRegex = RegExp(r'(?=(?!^)[A-Z])');
String _filenameForCppClass(String className) {
  return className.splitMapJoin(
    _internalCapitalLetterRegex,
    onMatch: (_) => '_',
    onNonMatch: (String n) => n.toLowerCase(),
  );
}
