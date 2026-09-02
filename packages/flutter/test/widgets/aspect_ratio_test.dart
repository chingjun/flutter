// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Size, TextDirection;

import 'package:flutter/src/foundation/key.dart' show Key, UniqueKey;
import 'package:flutter/src/painting/basic_types.dart' show Axis;
import 'package:flutter/src/rendering/box.dart' show BoxConstraints, RenderBox;
import 'package:flutter/src/widgets/basic.dart' show AspectRatio, Center, ConstrainedBox, Directionality;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/placeholder.dart' show Placeholder;
import 'package:flutter/src/widgets/single_child_scroll_view.dart' show SingleChildScrollView;
import 'package:flutter_test/flutter_test.dart';

Future<Size> _getSize(WidgetTester tester, BoxConstraints constraints, double aspectRatio) async {
  final Key childKey = UniqueKey();
  await tester.pumpWidget(
    Center(
      child: ConstrainedBox(
        constraints: constraints,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(key: childKey),
        ),
      ),
    ),
  );
  final RenderBox box = tester.renderObject(find.byKey(childKey));
  return box.size;
}

void main() {
  testWidgets('Aspect ratio control test', (WidgetTester tester) async {
    expect(
      await _getSize(tester, BoxConstraints.loose(const Size(500.0, 500.0)), 2.0),
      equals(const Size(500.0, 250.0)),
    );
    expect(
      await _getSize(tester, BoxConstraints.loose(const Size(500.0, 500.0)), 0.5),
      equals(const Size(250.0, 500.0)),
    );
  });

  testWidgets('Aspect ratio infinite width', (WidgetTester tester) async {
    final Key childKey = UniqueKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AspectRatio(aspectRatio: 2.0, child: Container(key: childKey)),
          ),
        ),
      ),
    );
    final RenderBox box = tester.renderObject(find.byKey(childKey));
    expect(box.size, equals(const Size(1200.0, 600.0)));
  });

  testWidgets('AspectRatio does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: AspectRatio(aspectRatio: 2.0, child: Placeholder())),
      ),
    );
    expect(tester.getSize(find.byType(AspectRatio)), Size.zero);
  });
}
