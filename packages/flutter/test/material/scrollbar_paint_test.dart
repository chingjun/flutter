// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Rect, TextDirection;

import 'package:flutter/src/material/app.dart' show MaterialApp;
import 'package:flutter/src/material/app_bar.dart' show AppBar;
import 'package:flutter/src/material/scaffold.dart' show Scaffold;
import 'package:flutter/src/material/scrollbar.dart' show Scrollbar;
import 'package:flutter/src/painting/edge_insets.dart' show EdgeInsets;
import 'package:flutter/src/widgets/basic.dart' show Directionality, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/media_query.dart' show MediaQuery, MediaQueryData;
import 'package:flutter/src/widgets/scroll_view.dart' show ListView;
import 'package:flutter/src/widgets/single_child_scroll_view.dart' show SingleChildScrollView;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

const Color _kAndroidThumbIdleColor = Color(0xffbcbcbc);

Widget _buildSingleChildScrollViewWithScrollbar({
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
  Widget? child,
}) {
  return Directionality(
    textDirection: textDirection,
    child: MediaQuery(
      data: MediaQueryData(padding: padding),
      child: Scrollbar(child: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('Viewport basic test (LTR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSingleChildScrollViewWithScrollbar(
        child: const SizedBox(width: 4000.0, height: 4000.0),
      ),
    );
    expect(find.byType(Scrollbar), isNot(paints..rect()));
    await tester.fling(find.byType(SingleChildScrollView), const Offset(0.0, -10.0), 10.0);
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(796.0, 0.0, 800.0, 600.0), color: const Color(0x00000000))
        ..line(
          p1: const Offset(796.0, 0.0),
          p2: const Offset(796.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(rect: const Rect.fromLTRB(796.0, 1.5, 800.0, 91.5), color: _kAndroidThumbIdleColor),
    );
  });

  testWidgets('Viewport basic test (RTL)', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildSingleChildScrollViewWithScrollbar(
        textDirection: TextDirection.rtl,
        child: const SizedBox(width: 4000.0, height: 4000.0),
      ),
    );
    expect(find.byType(Scrollbar), isNot(paints..rect()));
    await tester.fling(find.byType(SingleChildScrollView), const Offset(0.0, -10.0), 10.0);
    expect(
      find.byType(Scrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(0.0, 0.0, 4.0, 600.0), color: const Color(0x00000000))
        ..line(
          p1: const Offset(4.0, 0.0),
          p2: const Offset(4.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(rect: const Rect.fromLTRB(0.0, 1.5, 4.0, 91.5), color: _kAndroidThumbIdleColor),
    );
  });

  testWidgets('works with MaterialApp and Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.fromLTRB(0, 20, 0, 34)),
          child: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: Scrollbar(
              child: ListView(children: const <Widget>[SizedBox(width: 4000, height: 4000)]),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // On Android it should not overscroll.
    await gesture.moveBy(const Offset(0, 100));
    // Trigger fade in animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byType(Scrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(796.0, 0.0, 800.0, 490.0), color: const Color(0x00000000))
        ..line(
          p1: const Offset(796.0, 0.0),
          p2: const Offset(796.0, 490.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(
          rect: const Rect.fromLTWH(
            796.0,
            0.0,
            4.0,
            (600.0 - 56 - 34 - 20) / 4000 * (600 - 56 - 34 - 20),
          ),
          color: _kAndroidThumbIdleColor,
        ),
    );
  });

  testWidgets("should not paint when there isn't enough space", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.fromLTRB(0, 20, 0, 34)),
          child: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: Scrollbar(
              child: ListView(children: const <Widget>[SizedBox(width: 40, height: 40)]),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
    // On Android it should not overscroll.
    await gesture.moveBy(const Offset(0, 100));
    // Trigger fade in animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Scrollbar), isNot(paints..rect()));
  });
}
