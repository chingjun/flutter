// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/key.dart' show UniqueKey;
import 'package:flutter/src/widgets/basic.dart' show AbsorbPointer, Column, Expanded;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/gesture_detector.dart' show GestureDetector;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

import 'button_tester.dart';

void main() {
  testWidgets('AbsorbPointers do not block siblings', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          Expanded(child: GestureDetector(onTap: () => tapped = true)),
          const Expanded(child: AbsorbPointer()),
        ],
      ),
    );
    await tester.tap(find.byType(GestureDetector));
    expect(tapped, true);
  });

  group('AbsorbPointer semantics', () {
    testWidgets('does not change semantics when not absorbing', (WidgetTester tester) async {
      final key = UniqueKey();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: AbsorbPointer(
            absorbing: false,
            child: TestButton(key: key, onPressed: () {}, child: const Text('button')),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'button',
          hasTapAction: true,
          hasFocusAction: true,
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('ignores user interactions', (WidgetTester tester) async {
      final key = UniqueKey();
      await tester.pumpWidget(
        TestWidgetsApp(
          home: AbsorbPointer(
            child: TestButton(key: key, onPressed: () {}, child: const Text('button')),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        // Tap action is blocked.
        matchesSemantics(
          label: 'button',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    });
  });
}
