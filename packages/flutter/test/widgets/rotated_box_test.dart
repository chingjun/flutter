// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size, TextDirection;

import 'package:flutter/src/foundation/key.dart' show Key, UniqueKey;
import 'package:flutter/src/rendering/box.dart' show RenderBox;
import 'package:flutter/src/rendering/flex.dart' show MainAxisSize;
import 'package:flutter/src/widgets/basic.dart' show Center, Directionality, RotatedBox, Row;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/gesture_detector.dart' show GestureDetector;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Rotated box control test', (WidgetTester tester) async {
    final log = <String>[];
    final Key rotatedBoxKey = UniqueKey();

    await tester.pumpWidget(
      Center(
        child: RotatedBox(
          key: rotatedBoxKey,
          quarterTurns: 1,
          child: Row(
            textDirection: TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  log.add('left');
                },
                child: Container(width: 100.0, height: 40.0, color: const Color(0xFF0000FF)),
              ),
              GestureDetector(
                onTap: () {
                  log.add('right');
                },
                child: Container(width: 75.0, height: 65.0, color: const Color(0xFF0000FF)),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byKey(rotatedBoxKey));
    expect(box.size.width, equals(65.0));
    expect(box.size.height, equals(175.0));

    await tester.tapAt(const Offset(420.0, 280.0));
    expect(log, equals(<String>['left']));
    log.clear();

    await tester.tapAt(const Offset(380.0, 320.0));
    expect(log, equals(<String>['right']));
    log.clear();
  });

  testWidgets('RotatedBox does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RotatedBox(quarterTurns: 1)),
      ),
    );
    expect(tester.getSize(find.byType(RotatedBox)), Size.zero);
  });
}
