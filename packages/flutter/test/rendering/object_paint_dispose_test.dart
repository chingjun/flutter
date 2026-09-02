// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Canvas, Paint, Size;

import 'package:flutter/src/rendering/custom_paint.dart' show CustomPainter;
import 'package:flutter/src/rendering/layer.dart' show Layer;
import 'package:flutter/src/rendering/object.dart' show RenderObject;
import 'package:flutter/src/widgets/basic.dart' show CustomPaint, RepaintBoundary, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show GlobalKey;
import 'package:flutter/src/widgets/placeholder.dart' show Placeholder;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tracks picture layers accurately when painting is interleaved with a pushLayer', (
    WidgetTester tester,
  ) async {
    // Creates a RenderObject that will paint into multiple picture layers.
    // Asserts that both layers get a handle, and that all layers get correctly
    // released.
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        child: CustomPaint(
          key: key,
          painter: SimplePainter(),
          foregroundPainter: SimplePainter(),
          child: const RepaintBoundary(child: Placeholder()),
        ),
      ),
    );

    final List<Layer> layers = tester.binding.renderView.debugLayer!.depthFirstIterateChildren();

    final RenderObject renderObject = key.currentContext!.findRenderObject()!;

    for (final layer in layers) {
      expect(layer.debugDisposed, false);
    }

    await tester.pumpWidget(const SizedBox());

    for (final layer in layers) {
      expect(layer.debugDisposed, true);
    }
    expect(renderObject.debugDisposed, true);
  });
}

class SimplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(Paint());
  }

  @override
  bool shouldRepaint(SimplePainter oldDelegate) => true;
}
