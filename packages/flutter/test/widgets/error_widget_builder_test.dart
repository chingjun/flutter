// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/foundation/assertions.dart' show FlutterErrorDetails;
import 'package:flutter/src/widgets/basic.dart' show Builder, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, ErrorWidget, ErrorWidgetBuilder;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ErrorWidget.builder', (WidgetTester tester) async {
    final ErrorWidgetBuilder oldBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const Text('oopsie!', textDirection: TextDirection.ltr);
    };
    await tester.pumpWidget(
      SizedBox(
        child: Builder(
          builder: (BuildContext context) {
            throw 'test';
          },
        ),
      ),
    );
    expect(tester.takeException().toString(), 'test');
    expect(find.text('oopsie!'), findsOneWidget);
    ErrorWidget.builder = oldBuilder;
  });

  testWidgets('ErrorWidget.builder', (WidgetTester tester) async {
    final ErrorWidgetBuilder oldBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return ErrorWidget('');
    };
    await tester.pumpWidget(
      SizedBox(
        child: Builder(
          builder: (BuildContext context) {
            throw 'test';
          },
        ),
      ),
    );
    expect(tester.takeException().toString(), 'test');
    expect(find.byType(ErrorWidget), isNot(paints..paragraph()));
    ErrorWidget.builder = oldBuilder;
  });
}
