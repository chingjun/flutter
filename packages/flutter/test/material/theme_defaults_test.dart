// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Radius;

import 'package:flutter/src/material/app.dart' show MaterialApp;
import 'package:flutter/src/material/button.dart' show RawMaterialButton;
import 'package:flutter/src/material/floating_action_button.dart' show FloatingActionButton;
import 'package:flutter/src/material/icons.dart' show Icons;
import 'package:flutter/src/material/theme_data.dart' show MaterialTapTargetSize, ThemeData;
import 'package:flutter/src/painting/border_radius.dart' show BorderRadius;
import 'package:flutter/src/painting/borders.dart' show ShapeBorder;
import 'package:flutter/src/painting/circle_border.dart' show CircleBorder;
import 'package:flutter/src/painting/edge_insets.dart' show EdgeInsets;
import 'package:flutter/src/painting/rounded_rectangle_border.dart' show RoundedRectangleBorder;
import 'package:flutter/src/rendering/box.dart' show BoxConstraints;
import 'package:flutter/src/widgets/basic.dart' show Center;
import 'package:flutter/src/widgets/icon.dart' show Icon;
import 'package:flutter_test/flutter_test.dart';

const Duration defaultButtonDuration = Duration(milliseconds: 200);

void main() {
  group('FloatingActionButton', () {
    const defaultFABConstraints = BoxConstraints.tightFor(width: 56.0, height: 56.0);
    const ShapeBorder defaultFABShape = CircleBorder();
    const ShapeBorder defaultFABShapeM3 = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    );
    const EdgeInsets defaultFABPadding = EdgeInsets.zero;

    testWidgets('Material2 - theme: ThemeData.light(), enabled: true', (WidgetTester tester) async {
      final theme = ThemeData.light(useMaterial3: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Center(
            child: FloatingActionButton(
              onPressed: () {}, // button.enabled == true
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(
        find.byType(RawMaterialButton),
      );
      expect(raw.enabled, true);
      expect(raw.textStyle!.color, const Color(0xffffffff));
      expect(raw.fillColor, const Color(0xff2196f3));
      expect(raw.elevation, 6.0);
      expect(raw.highlightElevation, 12.0);
      expect(raw.disabledElevation, 6.0);
      expect(raw.constraints, defaultFABConstraints);
      expect(raw.padding, defaultFABPadding);
      expect(raw.shape, defaultFABShape);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('Material3 - theme: ThemeData.light(), enabled: true', (WidgetTester tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Center(
            child: FloatingActionButton(
              onPressed: () {}, // button.enabled == true
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(
        find.byType(RawMaterialButton),
      );
      expect(raw.enabled, true);
      expect(raw.textStyle!.color, theme.colorScheme.onPrimaryContainer);
      expect(raw.fillColor, theme.colorScheme.primaryContainer);
      expect(raw.elevation, 6.0);
      expect(raw.highlightElevation, 6.0);
      expect(raw.disabledElevation, 6.0);
      expect(raw.constraints, defaultFABConstraints);
      expect(raw.padding, defaultFABPadding);
      expect(raw.shape, defaultFABShapeM3);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('Material2 - theme: ThemeData.light(), enabled: false', (
      WidgetTester tester,
    ) async {
      final theme = ThemeData.light(useMaterial3: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Center(
            child: FloatingActionButton(
              onPressed: null, // button.enabled == false
              child: Icon(Icons.add),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(
        find.byType(RawMaterialButton),
      );
      expect(raw.enabled, false);
      expect(raw.textStyle!.color, const Color(0xffffffff));
      expect(raw.fillColor, const Color(0xff2196f3));
      // highlightColor, disabled button can't be pressed
      // splashColor, disabled button doesn't splash
      expect(raw.elevation, 6.0);
      expect(raw.highlightElevation, 12.0);
      expect(raw.disabledElevation, 6.0);
      expect(raw.constraints, defaultFABConstraints);
      expect(raw.padding, defaultFABPadding);
      expect(raw.shape, defaultFABShape);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    testWidgets('Material3 - theme: ThemeData.light(), enabled: false', (
      WidgetTester tester,
    ) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Center(
            child: FloatingActionButton(
              onPressed: null, // button.enabled == false
              child: Icon(Icons.add),
            ),
          ),
        ),
      );

      final RawMaterialButton raw = tester.widget<RawMaterialButton>(
        find.byType(RawMaterialButton),
      );
      expect(raw.enabled, false);
      expect(raw.textStyle!.color, theme.colorScheme.onPrimaryContainer);
      expect(raw.fillColor, theme.colorScheme.primaryContainer);
      // highlightColor, disabled button can't be pressed
      // splashColor, disabled button doesn't splash
      expect(raw.elevation, 6.0);
      expect(raw.highlightElevation, 6.0);
      expect(raw.disabledElevation, 6.0);
      expect(raw.constraints, defaultFABConstraints);
      expect(raw.padding, defaultFABPadding);
      expect(raw.shape, defaultFABShapeM3);
      expect(raw.animationDuration, defaultButtonDuration);
      expect(raw.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });
}
