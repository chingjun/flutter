// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/foundation/key.dart' show Key;
import 'package:flutter/src/rendering/box.dart' show RenderBox;
import 'package:flutter/src/widgets/basic.dart' show Positioned, SizedBox, Stack;
import 'package:flutter/src/widgets/framework.dart' show GlobalKey, Widget;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Comparing coordinates', (WidgetTester tester) async {
    final Key keyA = GlobalKey();
    final Key keyB = GlobalKey();

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Positioned(
            top: 100.0,
            left: 100.0,
            child: SizedBox(key: keyA, width: 10.0, height: 10.0),
          ),
          Positioned(
            left: 100.0,
            top: 200.0,
            child: SizedBox(key: keyB, width: 20.0, height: 10.0),
          ),
        ],
      ),
    );

    final RenderBox boxA = tester.renderObject(find.byKey(keyA));
    expect(boxA.localToGlobal(Offset.zero), equals(const Offset(100.0, 100.0)));

    final RenderBox boxB = tester.renderObject(find.byKey(keyB));
    expect(boxB.localToGlobal(Offset.zero), equals(const Offset(100.0, 200.0)));
    expect(boxB.globalToLocal(const Offset(110.0, 205.0)), equals(const Offset(10.0, 5.0)));
  });
}
