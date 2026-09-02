// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, RRect, Radius, Rect, TextDirection;

import 'package:flutter/src/cupertino/app.dart' show CupertinoApp;
import 'package:flutter/src/cupertino/nav_bar.dart' show CupertinoNavigationBar;
import 'package:flutter/src/cupertino/page_scaffold.dart' show CupertinoPageScaffold;
import 'package:flutter/src/cupertino/scrollbar.dart' show CupertinoScrollbar;
import 'package:flutter/src/painting/edge_insets.dart' show EdgeInsets;
import 'package:flutter/src/widgets/basic.dart' show Directionality, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/media_query.dart' show MediaQuery, MediaQueryData;
import 'package:flutter/src/widgets/scroll_physics.dart' show AlwaysScrollableScrollPhysics, BouncingScrollPhysics;
import 'package:flutter/src/widgets/scroll_view.dart' show ListView;
import 'package:flutter/src/widgets/single_child_scroll_view.dart' show SingleChildScrollView;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

const Color _kScrollbarColor = Color(0x59000000);

// The `y` offset has to be larger than `ScrollDragController._bigThresholdBreakDistance`
// to prevent [motionStartDistanceThreshold] from affecting the actual drag distance.
const Offset _kGestureOffset = Offset(0, -25);
const Radius _kScrollbarRadius = Radius.circular(1.5);

void main() {
  testWidgets('Paints iOS spec', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(),
          child: CupertinoScrollbar(
            child: SingleChildScrollView(child: SizedBox(width: 4000.0, height: 4000.0)),
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoScrollbar), isNot(paints..rrect()));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(SingleChildScrollView)),
    );
    await gesture.moveBy(_kGestureOffset);
    // Move back to original position.
    await gesture.moveBy(Offset.zero.translate(-_kGestureOffset.dx, -_kGestureOffset.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byType(CupertinoScrollbar),
      paints..rrect(
        color: _kScrollbarColor,
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            800.0 - 3 - 3, // Screen width - margin - thickness.
            3.0, // Initial position is the top margin.
            3, // Thickness.
            // Fraction in viewport * scrollbar height - top, bottom margin.
            600.0 / 4000.0 * (600.0 - 2 * 3),
          ),
          _kScrollbarRadius,
        ),
      ),
    );
  });

  testWidgets('Paints iOS spec with nav bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.fromLTRB(0, 20, 0, 34)),
          child: CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Title'),
              backgroundColor: Color(0x11111111),
            ),
            child: CupertinoScrollbar(
              child: ListView(children: const <Widget>[SizedBox(width: 4000, height: 4000)]),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
    await gesture.moveBy(_kGestureOffset);
    // Move back to original position.
    await gesture.moveBy(Offset(-_kGestureOffset.dx, -_kGestureOffset.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byType(CupertinoScrollbar),
      paints..rrect(
        color: _kScrollbarColor,
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            800.0 - 3 - 3, // Screen width - margin - thickness.
            44 + 20 + 3.0, // nav bar height + top margin
            3, // Thickness.
            // Fraction visible * (viewport size - padding - margin)
            // where Fraction visible = (viewport size - padding) / content size
            (600.0 - 34 - 44 - 20) / 4000.0 * (600.0 - 2 * 3 - 34 - 44 - 20),
          ),
          _kScrollbarRadius,
        ),
      ),
    );
  });

  testWidgets("should not paint when there isn't enough space", (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.fromLTRB(0, 20, 0, 34)),
          child: CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Title'),
              backgroundColor: Color(0x11111111),
            ),
            child: CupertinoScrollbar(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                children: const <Widget>[SizedBox(width: 10, height: 10)],
              ),
            ),
          ),
        ),
      ),
    );
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
    await gesture.moveBy(_kGestureOffset);
    // Move back to original position.
    await gesture.moveBy(Offset(-_kGestureOffset.dx, -_kGestureOffset.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CupertinoScrollbar), isNot(paints..rrect()));

    // The scrollbar should not appear even when overscrolled.
    final TestGesture overscrollGesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await overscrollGesture.moveBy(_kGestureOffset);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CupertinoScrollbar), isNot(paints..rrect()));
  });
}
