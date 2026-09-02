// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:ui' show BlendMode, Color, ColorFilter, Paint, PaintingStyle;

import 'package:flutter/src/rendering/object.dart' show PaintingContext;
import 'package:flutter/src/rendering/proxy_box.dart' show RenderProxyBox;
import 'package:flutter/src/widgets/basic.dart' show RepaintBoundary, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, LeafRenderObjectWidget;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InvertColors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const RepaintBoundary(
        child: SizedBox.square(
          dimension: 200.0,
          child: InvertColorTestWidget(color: Color.fromRGBO(255, 0, 0, 1.0)),
        ),
      ),
    );

    await expectLater(find.byType(RepaintBoundary), matchesGoldenFile('invert_colors_test.0.png'));
  });

  testWidgets('InvertColors and ColorFilter', (WidgetTester tester) async {
    await tester.pumpWidget(
      const RepaintBoundary(
        child: SizedBox.square(
          dimension: 200.0,
          child: InvertColorTestWidget(
            color: Color.fromRGBO(255, 0, 0, 1.0),
            filter: ColorFilter.mode(Color.fromRGBO(0, 255, 0, 0.5), BlendMode.plus),
          ),
        ),
      ),
    );

    await expectLater(find.byType(RepaintBoundary), matchesGoldenFile('invert_colors_test.1.png'));
  });
}

// Draws a rectangle sized by the parent widget with [color], [colorFilter],
// and [invertColors] applied for testing the invert colors.
class InvertColorTestWidget extends LeafRenderObjectWidget {
  const InvertColorTestWidget({required this.color, this.filter, super.key});

  final Color color;
  final ColorFilter? filter;

  @override
  RenderInvertColorTest createRenderObject(BuildContext context) {
    return RenderInvertColorTest(color, filter);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderInvertColorTest renderObject) {
    renderObject
      ..color = color
      ..filter = filter;
  }
}

class RenderInvertColorTest extends RenderProxyBox {
  RenderInvertColorTest(this._color, this._filter);

  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (color == value) {
      return;
    }
    _color = value;
    markNeedsPaint();
  }

  ColorFilter? get filter => _filter;
  ColorFilter? _filter;
  set filter(ColorFilter? value) {
    if (filter == value) {
      return;
    }
    _filter = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..colorFilter = filter
      ..invertColors = true;
    context.canvas.drawRect(offset & size, paint);
  }
}
