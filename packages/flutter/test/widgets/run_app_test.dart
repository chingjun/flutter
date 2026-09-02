// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/widgets/basic.dart' show Center, Directionality;
import 'package:flutter/src/widgets/binding.dart' show runApp;
import 'package:flutter/src/widgets/gesture_detector.dart' show GestureDetector;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runApp inside onPressed does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GestureDetector(
          onTap: () {
            runApp(const Center(child: Text('Done', textDirection: TextDirection.ltr)));
          },
          child: const Text('GO'),
        ),
      ),
    );
    await tester.tap(find.text('GO'));
    expect(find.text('Done'), findsOneWidget);
  });
}
