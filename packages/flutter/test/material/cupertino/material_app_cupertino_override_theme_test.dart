// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Brightness, Color;

import 'package:flutter/src/cupertino/colors.dart' show CupertinoDynamicColor;
import 'package:flutter/src/cupertino/interface_level.dart' show CupertinoUserInterfaceLevel, CupertinoUserInterfaceLevelData;
import 'package:flutter/src/cupertino/theme.dart' show CupertinoTheme, CupertinoThemeData;
import 'package:flutter/src/material/app.dart' show MaterialApp;
import 'package:flutter/src/material/color_scheme.dart' show ColorScheme;
import 'package:flutter/src/material/theme_data.dart' show ThemeData;
import 'package:flutter/src/widgets/basic.dart' show Builder;
import 'package:flutter/src/widgets/framework.dart' show BuildContext;
import 'package:flutter/src/widgets/media_query.dart' show MediaQuery, MediaQueryData;
import 'package:flutter/src/widgets/placeholder.dart' show Placeholder;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A color that depends on color vibrancy, accessibility contrast, as well as user
  // interface elevation.
  const dynamicColor = CupertinoDynamicColor(
    color: Color(0xFF000000),
    darkColor: Color(0xFF000001),
    elevatedColor: Color(0xFF000002),
    highContrastColor: Color(0xFF000003),
    darkElevatedColor: Color(0xFF000004),
    darkHighContrastColor: Color(0xFF000005),
    highContrastElevatedColor: Color(0xFF000006),
    darkHighContrastElevatedColor: Color(0xFF000007),
  );

  testWidgets('dynamic color works in cupertino override theme in MaterialApp', (
    WidgetTester tester,
  ) async {
    Color? color;

    CupertinoDynamicColor typedColor() => color! as CupertinoDynamicColor;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: dynamicColor,
          ),
        ),
        home: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.base,
            child: Builder(
              builder: (BuildContext context) {
                color = CupertinoTheme.of(context).primaryColor;
                return const Placeholder();
              },
            ),
          ),
        ),
      ),
    );

    // Explicit brightness is respected.
    expect(typedColor().value, dynamicColor.darkColor.value);
    color = null;

    // Changing dependencies works.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: dynamicColor,
          ),
        ),
        home: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark, highContrast: true),
          child: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.elevated,
            child: Builder(
              builder: (BuildContext context) {
                color = CupertinoTheme.of(context).primaryColor;
                return const Placeholder();
              },
            ),
          ),
        ),
      ),
    );

    expect(typedColor().value, dynamicColor.darkHighContrastElevatedColor.value);
  });

  testWidgets('dynamic color does not work in a material theme', (WidgetTester tester) async {
    Color? color;

    await tester.pumpWidget(
      MaterialApp(
        // This will create a MaterialBasedCupertinoThemeData with primaryColor set to `dynamicColor`.
        theme: ThemeData(colorScheme: const ColorScheme.dark(primary: dynamicColor)),
        home: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark, highContrast: true),
          child: CupertinoUserInterfaceLevel(
            data: CupertinoUserInterfaceLevelData.elevated,
            child: Builder(
              builder: (BuildContext context) {
                color = CupertinoTheme.of(context).primaryColor;
                return const Placeholder();
              },
            ),
          ),
        ),
      ),
    );

    // The color is not resolved.
    expect(color, dynamicColor);
    expect(color, isNot(dynamicColor.darkHighContrastElevatedColor));
  });
}
