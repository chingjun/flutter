// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Size, TextDirection;

import 'package:flutter/src/animation/curves.dart' show Curves;
import 'package:flutter/src/foundation/key.dart' show Key, UniqueKey;
import 'package:flutter/src/painting/alignment.dart' show Alignment, AlignmentDirectional;
import 'package:flutter/src/rendering/box.dart' show RenderBox;
import 'package:flutter/src/rendering/flex.dart' show MainAxisAlignment, MainAxisSize;
import 'package:flutter/src/widgets/basic.dart' show Center, Column, Directionality, Row, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/implicit_animations.dart' show AnimatedAlign;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnimatedAlign.debugFillProperties', (WidgetTester tester) async {
    const box = AnimatedAlign(
      alignment: Alignment.topCenter,
      curve: Curves.ease,
      duration: Duration(milliseconds: 200),
    );
    expect(box, hasOneLineDescription);
  });

  testWidgets('AnimatedAlign alignment visual-to-directional animation', (
    WidgetTester tester,
  ) async {
    final Key target = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topRight,
          child: SizedBox(key: target, width: 100.0, height: 200.0),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(target)), const Size(100.0, 200.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(800.0, 0.0));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: AlignmentDirectional.bottomStart,
          child: SizedBox(key: target, width: 100.0, height: 200.0),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(target)), const Size(100.0, 200.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(800.0, 0.0));

    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getSize(find.byKey(target)), const Size(100.0, 200.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(800.0, 200.0));

    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.getSize(find.byKey(target)), const Size(100.0, 200.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(800.0, 400.0));
  });

  testWidgets('AnimatedAlign widthFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedAlign(
              alignment: Alignment.center,
              curve: Curves.ease,
              widthFactor: 0.5,
              duration: Duration(milliseconds: 200),
              child: SizedBox(height: 100.0, width: 100.0),
            ),
          ],
        ),
      ),
    );
    final RenderBox box = tester.renderObject<RenderBox>(find.byType(AnimatedAlign));
    expect(box.size.width, equals(50.0));
  });

  testWidgets('AnimatedAlign heightFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            AnimatedAlign(
              alignment: Alignment.center,
              curve: Curves.ease,
              heightFactor: 0.5,
              duration: Duration(milliseconds: 200),
              child: SizedBox(height: 100.0, width: 100.0),
            ),
          ],
        ),
      ),
    );
    final RenderBox box = tester.renderObject<RenderBox>(find.byType(AnimatedAlign));
    expect(box.size.height, equals(50.0));
  });

  testWidgets('AnimatedAlign null height factor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedAlign(
              alignment: Alignment.center,
              curve: Curves.ease,
              duration: Duration(milliseconds: 200),
              child: SizedBox(height: 100.0, width: 100.0),
            ),
          ],
        ),
      ),
    );
    final RenderBox box = tester.renderObject<RenderBox>(find.byType(SizedBox));
    expect(box.size, equals(const Size(100.0, 100)));
  });

  testWidgets('AnimatedAlign null widthFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.shrink(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedAlign(
                alignment: Alignment.center,
                curve: Curves.ease,
                duration: Duration(milliseconds: 200),
                child: SizedBox(height: 100.0, width: 100.0),
              ),
            ],
          ),
        ),
      ),
    );
    final RenderBox box = tester.renderObject<RenderBox>(find.byType(SizedBox).last);
    expect(box.size, equals(const Size(100.0, 100)));
  });

  testWidgets('AnimatedAlign does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.shrink(
            child: AnimatedAlign(
              alignment: Alignment.bottomCenter,
              duration: Duration(milliseconds: 50),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AnimatedAlign)), Size.zero);
  });
}
