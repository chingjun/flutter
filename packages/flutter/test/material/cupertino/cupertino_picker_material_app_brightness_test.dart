// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Brightness;

import 'package:flutter/src/cupertino/colors.dart' show CupertinoColors;
import 'package:flutter/src/cupertino/date_picker.dart' show CupertinoDatePicker, CupertinoDatePickerMode, CupertinoTimerPicker, CupertinoTimerPickerMode;
import 'package:flutter/src/cupertino/picker.dart' show CupertinoPicker;
import 'package:flutter/src/material/app.dart' show MaterialApp;
import 'package:flutter/src/material/theme_data.dart' show ThemeData;
import 'package:flutter/src/painting/alignment.dart' show Alignment;
import 'package:flutter/src/rendering/paragraph.dart' show RenderParagraph;
import 'package:flutter/src/widgets/basic.dart' show Align, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CupertinoPicker adapts to MaterialApp dark mode', (WidgetTester tester) async {
    Widget buildCupertinoPicker(Brightness brightness) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.square(
            dimension: 300.0,
            child: CupertinoPicker(
              itemExtent: 50.0,
              onSelectedItemChanged: (_) {},
              children: List<Widget>.generate(3, (int index) {
                return SizedBox(height: 50.0, width: 300.0, child: Text(index.toString()));
              }),
            ),
          ),
        ),
      );
    }

    // CupertinoPicker with light theme.
    await tester.pumpWidget(buildCupertinoPicker(Brightness.light));
    RenderParagraph paragraph = tester.renderObject(find.text('1'));
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);

    // CupertinoPicker with dark theme.
    await tester.pumpWidget(buildCupertinoPicker(Brightness.dark));
    paragraph = tester.renderObject(find.text('1'));
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
  });

  testWidgets('CupertinoDatePicker adapts to MaterialApp dark mode', (WidgetTester tester) async {
    Widget buildDatePicker(Brightness brightness) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (DateTime neData) {},
          initialDateTime: DateTime(2018, 10, 10),
        ),
      );
    }

    // CupertinoDatePicker with light theme.
    await tester.pumpWidget(buildDatePicker(Brightness.light));
    RenderParagraph paragraph = tester.renderObject(find.text('October').first);
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);

    // CupertinoDatePicker with dark theme.
    await tester.pumpWidget(buildDatePicker(Brightness.dark));
    paragraph = tester.renderObject(find.text('October').first);
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
  });

  testWidgets('CupertinoTimerPicker adapts to MaterialApp dark mode', (WidgetTester tester) async {
    Widget buildTimerPicker(Brightness brightness) {
      return MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: CupertinoTimerPicker(
          mode: CupertinoTimerPickerMode.hm,
          onTimerDurationChanged: (Duration newDuration) {},
          initialTimerDuration: const Duration(hours: 12, minutes: 30, seconds: 59),
        ),
      );
    }

    // CupertinoTimerPicker with light theme.
    await tester.pumpWidget(buildTimerPicker(Brightness.light));
    RenderParagraph paragraph = tester.renderObject(find.text('hours'));
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);

    // CupertinoTimerPicker with light theme.
    await tester.pumpWidget(buildTimerPicker(Brightness.dark));
    paragraph = tester.renderObject(find.text('hours'));
    expect(paragraph.text.style!.color, CupertinoColors.label);
    // Text style should not return unresolved color.
    expect(paragraph.text.style!.color.toString().contains('UNRESOLVED'), isFalse);
  });
}
