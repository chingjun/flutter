// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/diagnostics.dart' show shortHash;
import 'package:flutter/src/services/mouse_cursor.dart' show SystemMouseCursors;
import 'package:flutter/src/services/mouse_tracking.dart' show MouseTrackerAnnotation;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MouseTrackerAnnotation has correct toString', () {
    final annotation1 = MouseTrackerAnnotation(onEnter: (_) {}, onExit: (_) {});
    expect(
      annotation1.toString(),
      equals('MouseTrackerAnnotation#${shortHash(annotation1)}(callbacks: [enter, exit])'),
    );

    const annotation2 = MouseTrackerAnnotation();
    expect(
      annotation2.toString(),
      equals('MouseTrackerAnnotation#${shortHash(annotation2)}(callbacks: <none>)'),
    );

    final annotation3 = MouseTrackerAnnotation(onEnter: (_) {}, cursor: SystemMouseCursors.grab);
    expect(
      annotation3.toString(),
      equals(
        'MouseTrackerAnnotation#${shortHash(annotation3)}(callbacks: [enter], cursor: SystemMouseCursor(grab))',
      ),
    );
  });
}
