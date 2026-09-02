// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/foundation/key.dart' show Key, ValueKey;
import 'package:flutter/src/painting/alignment.dart' show Alignment;
import 'package:flutter/src/painting/basic_types.dart' show Axis;
import 'package:flutter/src/rendering/object.dart' show RenderObject;
import 'package:flutter/src/widgets/basic.dart' show Directionality;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, GlobalKey, StatelessWidget, Widget;
import 'package:flutter/src/widgets/scroll_delegate.dart' show SliverChildBuilderDelegate;
import 'package:flutter/src/widgets/scroll_view.dart' show CustomScrollView;
import 'package:flutter/src/widgets/sliver_prototype_extent_list.dart' show SliverPrototypeExtentList;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

class TestItem extends StatelessWidget {
  const TestItem({super.key, required this.item, this.width, this.height});
  final int item;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Text('Item $item', textDirection: TextDirection.ltr),
    );
  }
}

Widget buildFrame({
  int? count,
  double? width,
  double? height,
  Axis? scrollDirection,
  Key? prototypeKey,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: CustomScrollView(
      scrollDirection: scrollDirection ?? Axis.vertical,
      slivers: <Widget>[
        SliverPrototypeExtentList(
          prototypeItem: TestItem(item: -1, width: width, height: height, key: prototypeKey),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => TestItem(item: index),
            childCount: count,
          ),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('SliverPrototypeExtentList.builder test', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestWidgetsApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverPrototypeExtentList.builder(
              itemBuilder: (BuildContext context, int index) => TestItem(item: index),
              prototypeItem: const TestItem(item: -1, height: 100.0),
              itemCount: 20,
            ),
          ],
        ),
      ),
    );

    // The viewport is 600 pixels high, lazily created items are 100 pixels high.
    for (var i = 0; i < 6; i += 1) {
      final Finder item = find.widgetWithText(Container, 'Item $i');
      expect(item, findsOneWidget);
      expect(tester.getTopLeft(item).dy, i * 100.0);
      expect(tester.getSize(item).height, 100.0);
    }
    for (var i = 7; i < 20; i += 1) {
      expect(find.text('Item $i'), findsNothing);
    }
  });

  testWidgets('SliverPrototypeExtentList.builder test', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestWidgetsApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverPrototypeExtentList.builder(
              prototypeItem: const TestItem(item: -1, height: 100.0),
              itemBuilder: (BuildContext context, int index) => TestItem(item: index),
              itemCount: 8,
            ),
          ],
        ),
      ),
    );

    // The viewport is 600 pixels high, lazily created items are 100 pixels high.
    for (var i = 0; i < 6; i += 1) {
      final Finder item = find.widgetWithText(Container, 'Item $i');
      expect(item, findsOneWidget);
      expect(tester.getTopLeft(item).dy, i * 100.0);
      expect(tester.getSize(item).height, 100.0);
    }
    expect(find.text('Item 7'), findsNothing);
  });

  testWidgets('SliverPrototypeExtentList vertical scrolling basics', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(count: 20, height: 100.0));

    // The viewport is 600 pixels high, lazily created items are 100 pixels high.
    for (var i = 0; i < 6; i += 1) {
      final Finder item = find.widgetWithText(Container, 'Item $i');
      expect(item, findsOneWidget);
      expect(tester.getTopLeft(item).dy, i * 100.0);
      expect(tester.getSize(item).height, 100.0);
    }
    for (var i = 7; i < 20; i += 1) {
      expect(find.text('Item $i'), findsNothing);
    }

    // Fling scroll to the end.
    await tester.fling(find.text('Item 2'), const Offset(0.0, -200.0), 5000.0);
    await tester.pumpAndSettle();

    for (var i = 19; i >= 14; i -= 1) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    for (var i = 13; i >= 0; i -= 1) {
      expect(find.text('Item $i'), findsNothing);
    }
  });

  testWidgets('SliverPrototypeExtentList horizontal scrolling basics', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(count: 20, width: 100.0, scrollDirection: Axis.horizontal));

    // The viewport is 800 pixels wide, lazily created items are 100 pixels wide.
    for (var i = 0; i < 8; i += 1) {
      final Finder item = find.widgetWithText(Container, 'Item $i');
      expect(item, findsOneWidget);
      expect(tester.getTopLeft(item).dx, i * 100.0);
      expect(tester.getSize(item).width, 100.0);
    }
    for (var i = 9; i < 20; i += 1) {
      expect(find.text('Item $i'), findsNothing);
    }

    // Fling scroll to the end.
    await tester.fling(find.text('Item 3'), const Offset(-200.0, 0.0), 5000.0);
    await tester.pumpAndSettle();

    for (var i = 19; i >= 12; i -= 1) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    for (var i = 11; i >= 0; i -= 1) {
      expect(find.text('Item $i'), findsNothing);
    }
  });

  testWidgets('SliverPrototypeExtentList change the prototype item', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(count: 10, height: 60.0));

    // The viewport is 600 pixels high, each of the 10 items is 60 pixels high
    for (var i = 0; i < 10; i += 1) {
      expect(find.text('Item $i'), findsOneWidget);
    }

    await tester.pumpWidget(buildFrame(count: 10, height: 120.0));

    // Now the items are 120 pixels high, so only 5 fit.
    for (var i = 0; i < 5; i += 1) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    for (var i = 5; i < 10; i += 1) {
      expect(find.text('Item $i'), findsNothing);
    }

    await tester.pumpWidget(buildFrame(count: 10, height: 60.0));

    // Now they all fit again
    for (var i = 0; i < 10; i += 1) {
      expect(find.text('Item $i'), findsOneWidget);
    }
  });

  testWidgets('SliverPrototypeExtentList first item is also the prototype', (
    WidgetTester tester,
  ) async {
    final List<Widget> items = List<Widget>.generate(10, (int index) {
      return TestItem(key: ValueKey<int>(index), item: index, height: index == 0 ? 60.0 : null);
    }).toList();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPrototypeExtentList(
              prototypeItem: items[0],
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => items[index],
                childCount: 10,
              ),
            ),
          ],
        ),
      ),
    );

    // Item 0 exists in the list and as the prototype item.
    expect(tester.widgetList(find.text('Item 0', skipOffstage: false)).length, 2);

    for (var i = 1; i < 10; i += 1) {
      expect(find.text('Item $i'), findsOneWidget);
    }
  });

  testWidgets('SliverPrototypeExtentList prototypeItem paint transform is zero.', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/67117
    // This test ensures that the SliverPrototypeExtentList does not cause an
    // assertion error when calculating the paint transform of its prototypeItem.
    // The paint transform of the prototypeItem should be zero, since it is not visible.
    final GlobalKey prototypeKey = GlobalKey();
    await tester.pumpWidget(buildFrame(count: 20, height: 100.0, prototypeKey: prototypeKey));

    final RenderObject scrollView = tester.renderObject(find.byType(CustomScrollView));
    final RenderObject prototype = prototypeKey.currentContext!.findRenderObject()!;

    expect(prototype.getTransformTo(scrollView), Matrix4.zero());
  });
}
