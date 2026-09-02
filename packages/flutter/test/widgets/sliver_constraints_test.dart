// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/foundation/key.dart' show Key;
import 'package:flutter/src/rendering/sliver.dart' show RenderSliver;
import 'package:flutter/src/rendering/viewport.dart' show RenderViewport;
import 'package:flutter/src/widgets/basic.dart' show Directionality, SizedBox, SliverToBoxAdapter;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, Widget;
import 'package:flutter/src/widgets/scroll_view.dart' show CustomScrollView;
import 'package:flutter/src/widgets/sliver.dart' show SliverList;
import 'package:flutter/src/widgets/viewport.dart' show Viewport;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('precedingScrollExtent is reported as infinity for Sliver of unknown size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            const SliverToBoxAdapter(child: SizedBox(width: double.infinity, height: 150.0)),
            const SliverToBoxAdapter(child: SizedBox(width: double.infinity, height: 150.0)),
            SliverList.builder(
              itemBuilder: (BuildContext context, int index) {
                if (index < 100) {
                  return const SizedBox(width: double.infinity, height: 150.0);
                } else {
                  return null;
                }
              },
            ),
            const SliverToBoxAdapter(
              key: Key('final_sliver'),
              child: SizedBox(width: double.infinity, height: 150.0),
            ),
          ],
        ),
      ),
    );

    // The last Sliver comes after a SliverList that has many more items than
    // can fit in the viewport, and the SliverList doesn't report a child count,
    // so the SliverList leads to an infinite precedingScrollExtent.
    final RenderViewport renderViewport = tester.renderObject(find.byType(Viewport));
    final RenderSliver lastRenderSliver = renderViewport.lastChild!;
    expect(lastRenderSliver.constraints.precedingScrollExtent, double.infinity);
  });
}
