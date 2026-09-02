// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/painting/basic_types.dart' show Axis;
import 'package:flutter/src/widgets/basic.dart' show Directionality, Row;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, Widget;
import 'package:flutter/src/widgets/overlay.dart' show Overlay, OverlayEntry;
import 'package:flutter/src/widgets/scroll_physics.dart' show AlwaysScrollableScrollPhysics;
import 'package:flutter/src/widgets/scroll_position.dart' show ScrollPosition;
import 'package:flutter/src/widgets/scroll_position_with_single_context.dart' show ScrollPositionWithSingleContext;
import 'package:flutter/src/widgets/scrollable.dart' show ScrollableState;
import 'package:flutter/src/widgets/single_child_scroll_view.dart' show SingleChildScrollView;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Can dispose ScrollPosition when hasPixels is false', () {
    final ScrollPosition position = ScrollPositionWithSingleContext(
      initialPixels: null,
      keepScrollOffset: false,
      physics: const AlwaysScrollableScrollPhysics(),
      context: ScrollableState(),
    );

    expect(position.hasPixels, false);
    position.dispose(); // Should not throw/assert.
  });

  testWidgets('scrollable in hidden overlay does not crash when unhidden', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/44269.
    final entry1 = OverlayEntry(
      maintainState: true,
      opaque: true,
      builder: (BuildContext context) {
        return const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: <Widget>[Text('Main')]),
        );
      },
    );
    addTearDown(() {
      entry1.remove();
      entry1.dispose();
    });

    final entry2 = OverlayEntry(
      maintainState: true,
      opaque: true,
      builder: (BuildContext context) {
        return const Text('number2');
      },
    );
    addTearDown(() {
      entry2.dispose();
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(initialEntries: <OverlayEntry>[entry1, entry2]),
      ),
    );

    entry2.remove();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
