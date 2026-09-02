// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

import 'package:flutter/src/widgets/app.dart' show WidgetsApp;
import 'package:flutter/src/widgets/banner.dart' show CheckedModeBanner;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/navigator.dart' show Navigator, RouteSettings;
import 'package:flutter/src/widgets/performance_overlay.dart' show PerformanceOverlay;
import 'package:flutter_test/flutter_test.dart';

import 'route_tester.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF333333),
      onGenerateRoute: (RouteSettings settings) {
        return TestRoute<void>(settings: settings, child: Container());
      },
    ),
  );
}

void main() {
  testWidgets('WidgetsApp control test', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsNothing);
    expect(find.byType(CheckedModeBanner), findsOneWidget);
  });

  testWidgets('showPerformanceOverlayOverride true', (WidgetTester tester) async {
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    WidgetsApp.showPerformanceOverlayOverride = true;
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsOneWidget);
    expect(find.byType(CheckedModeBanner), findsOneWidget);
    WidgetsApp.showPerformanceOverlayOverride = false;
  }, skip: isBrowser); // TODO(yjbanov): https://github.com/flutter/flutter/issues/52258

  testWidgets('showPerformanceOverlayOverride false', (WidgetTester tester) async {
    WidgetsApp.showPerformanceOverlayOverride = true;
    expect(WidgetsApp.showPerformanceOverlayOverride, true);
    WidgetsApp.showPerformanceOverlayOverride = false;
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsNothing);
    expect(find.byType(CheckedModeBanner), findsOneWidget);
  });

  testWidgets('debugAllowBannerOverride false', (WidgetTester tester) async {
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    expect(WidgetsApp.debugAllowBannerOverride, true);
    WidgetsApp.debugAllowBannerOverride = false;
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsNothing);
    expect(find.byType(CheckedModeBanner), findsNothing);
    WidgetsApp.debugAllowBannerOverride = true; // restore to default value
  });

  testWidgets('debugAllowBannerOverride true', (WidgetTester tester) async {
    WidgetsApp.debugAllowBannerOverride = false;
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    expect(WidgetsApp.debugAllowBannerOverride, false);
    WidgetsApp.debugAllowBannerOverride = true;
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsNothing);
    expect(find.byType(CheckedModeBanner), findsOneWidget);
  });
}
