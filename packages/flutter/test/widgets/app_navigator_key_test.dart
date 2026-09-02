// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color;

import 'package:flutter/src/animation/animation.dart' show Animation;
import 'package:flutter/src/widgets/app.dart' show WidgetsApp;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, GlobalKey;
import 'package:flutter/src/widgets/navigator.dart' show NavigatorState, Route, RouteSettings;
import 'package:flutter/src/widgets/pages.dart' show PageRouteBuilder;
import 'package:flutter/src/widgets/placeholder.dart' show Placeholder;
import 'package:flutter_test/flutter_test.dart';

Route<void> generateRoute(RouteSettings settings) => PageRouteBuilder<void>(
  settings: settings,
  pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
    return const Placeholder();
  },
);

void main() {
  testWidgets('WidgetsApp.navigatorKey', (WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      WidgetsApp(navigatorKey: key, color: const Color(0xFF112233), onGenerateRoute: generateRoute),
    );
    expect(key.currentState, isA<NavigatorState>());
    await tester.pumpWidget(
      WidgetsApp(color: const Color(0xFF112233), onGenerateRoute: generateRoute),
    );
    expect(key.currentState, isNull);
    await tester.pumpWidget(
      WidgetsApp(navigatorKey: key, color: const Color(0xFF112233), onGenerateRoute: generateRoute),
    );
    expect(key.currentState, isA<NavigatorState>());
  });
}
