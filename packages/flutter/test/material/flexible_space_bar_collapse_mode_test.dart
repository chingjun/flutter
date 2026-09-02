// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/key.dart' show Key, UniqueKey;
import 'package:flutter/src/foundation/platform.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/src/material/app.dart' show MaterialApp;
import 'package:flutter/src/material/app_bar.dart' show SliverAppBar;
import 'package:flutter/src/material/flexible_space_bar.dart' show CollapseMode, FlexibleSpaceBar;
import 'package:flutter/src/material/scaffold.dart' show Scaffold;
import 'package:flutter/src/material/theme_data.dart' show ThemeData;
import 'package:flutter/src/widgets/basic.dart' show SliverToBoxAdapter;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/scroll_view.dart' show CustomScrollView;
import 'package:flutter_test/flutter_test.dart';

final Key blockKey = UniqueKey();
const double expandedAppbarHeight = 250.0;
final Key appbarContainerKey = UniqueKey();

void main() {
  testWidgets(
    'FlexibleSpaceBar collapse mode none',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: debugDefaultTargetPlatformOverride),
          home: Scaffold(
            body: CustomScrollView(
              key: blockKey,
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: expandedAppbarHeight,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(key: appbarContainerKey),
                    collapseMode: CollapseMode.none,
                  ),
                ),
                SliverToBoxAdapter(child: Container(height: 10000.0)),
              ],
            ),
          ),
        ),
      );

      final Finder appbarContainer = find.byKey(appbarContainerKey);
      final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
      await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
      final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

      expect(topBeforeScroll.dy, equals(0.0));
      expect(topAfterScroll.dy, equals(0.0));
    },
    variant: TargetPlatformVariant.all(excluding: <TargetPlatform>{TargetPlatform.fuchsia}),
  );

  testWidgets(
    'FlexibleSpaceBar collapse mode pin',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: debugDefaultTargetPlatformOverride),
          home: Scaffold(
            body: CustomScrollView(
              key: blockKey,
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: expandedAppbarHeight,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(key: appbarContainerKey),
                    collapseMode: CollapseMode.pin,
                  ),
                ),
                SliverToBoxAdapter(child: Container(height: 10000.0)),
              ],
            ),
          ),
        ),
      );

      final Finder appbarContainer = find.byKey(appbarContainerKey);
      final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
      await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
      final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

      expect(topBeforeScroll.dy, equals(0.0));
      expect(topAfterScroll.dy, equals(-100.0));
    },
    variant: TargetPlatformVariant.all(excluding: <TargetPlatform>{TargetPlatform.fuchsia}),
  );

  testWidgets(
    'FlexibleSpaceBar collapse mode parallax',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: debugDefaultTargetPlatformOverride),
          home: Scaffold(
            body: CustomScrollView(
              key: blockKey,
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: expandedAppbarHeight,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(background: Container(key: appbarContainerKey)),
                ),
                SliverToBoxAdapter(child: Container(height: 10000.0)),
              ],
            ),
          ),
        ),
      );

      final Finder appbarContainer = find.byKey(appbarContainerKey);
      final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
      await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
      final Offset topAfterScroll = tester.getTopLeft(appbarContainer);

      expect(topBeforeScroll.dy, equals(0.0));
      expect(topAfterScroll.dy, lessThan(10.0));
      expect(topAfterScroll.dy, greaterThan(-50.0));
    },
    variant: TargetPlatformVariant.all(excluding: <TargetPlatform>{TargetPlatform.fuchsia}),
  );
}

Future<void> slowDrag(WidgetTester tester, Key widget, Offset offset) async {
  final Offset target = tester.getCenter(find.byKey(widget));
  final TestGesture gesture = await tester.startGesture(target);
  await gesture.moveBy(offset);
  await tester.pump(const Duration(milliseconds: 10));
  await gesture.up();
}
