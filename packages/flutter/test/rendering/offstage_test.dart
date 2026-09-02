// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Size;

import 'package:flutter/src/rendering/box.dart' show BoxConstraints, RenderBox;
import 'package:flutter/src/rendering/custom_paint.dart' show RenderCustomPaint;
import 'package:flutter/src/rendering/proxy_box.dart' show RenderConstrainedBox, RenderOffstage;
import 'package:flutter/src/rendering/shifted_box.dart' show RenderPositionedBox;
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('offstage', () {
    RenderBox child;
    var painted = false;
    // incoming constraints are tight 800x600
    final RenderBox root = RenderPositionedBox(
      child: RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(width: 800.0),
        child: RenderOffstage(
          child: RenderCustomPaint(
            painter: TestCallbackPainter(
              onPaint: () {
                painted = true;
              },
            ),
            child: child = RenderConstrainedBox(
              additionalConstraints: const BoxConstraints.tightFor(height: 10.0, width: 10.0),
            ),
          ),
        ),
      ),
    );
    expect(child.hasSize, isFalse);
    expect(painted, isFalse);
    layout(root, phase: EnginePhase.paint);
    expect(child.hasSize, isTrue);
    expect(painted, isFalse);
    expect(child.size, equals(const Size(800.0, 10.0)));
  });
}
