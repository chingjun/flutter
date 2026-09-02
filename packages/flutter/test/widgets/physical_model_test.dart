// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:ui' show Clip, Color, Size, TextDirection;

import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticLevel;
import 'package:flutter/src/foundation/key.dart' show Key;
import 'package:flutter/src/painting/circle_border.dart' show CircleBorder;
import 'package:flutter/src/painting/edge_insets.dart' show EdgeInsets;
import 'package:flutter/src/painting/text_style.dart' show TextStyle;
import 'package:flutter/src/rendering/proxy_box.dart' show RenderPhysicalModel, RenderPhysicalShape, ShapeBorderClipper;
import 'package:flutter/src/widgets/basic.dart' show Center, Directionality, Padding, PhysicalModel, PhysicalShape, Row;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/media_query.dart' show MediaQuery, MediaQueryData;
import 'package:flutter/src/widgets/text.dart' show DefaultTextStyle, Text;
import 'package:flutter_test/flutter_test.dart';

const Color _debugBlack = Color(0xFF000000);
const Color _debugCanvas = Color(0xFFFAFAFA);
const Color _debugText = Color(0xDD000000);

void main() {
  testWidgets('PhysicalModel updates clipBehavior in updateRenderObject', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TestWidgetsApp(home: PhysicalModel(color: _debugBlack)));

    final RenderPhysicalModel renderPhysicalModel = tester.allRenderObjects
        .whereType<RenderPhysicalModel>()
        .first;

    expect(renderPhysicalModel.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(
      const TestWidgetsApp(
        home: PhysicalModel(clipBehavior: Clip.antiAlias, color: _debugBlack),
      ),
    );

    expect(renderPhysicalModel.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('PhysicalShape updates clipBehavior in updateRenderObject', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: PhysicalShape(
          color: _debugBlack,
          clipper: ShapeBorderClipper(shape: CircleBorder()),
        ),
      ),
    );

    final RenderPhysicalShape renderPhysicalShape = tester.allRenderObjects
        .whereType<RenderPhysicalShape>()
        .first;

    expect(renderPhysicalShape.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(
      const TestWidgetsApp(
        home: PhysicalShape(
          clipBehavior: Clip.antiAlias,
          color: _debugBlack,
          clipper: ShapeBorderClipper(shape: CircleBorder()),
        ),
      ),
    );

    expect(renderPhysicalShape.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('PhysicalModel - clips when overflows and elevation is 0', (
    WidgetTester tester,
  ) async {
    const key = Key('test');
    await tester.pumpWidget(
      const MediaQuery(
        key: key,
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: TextStyle(color: _debugText, fontFamily: 'Roboto'),
            child: Padding(
              padding: EdgeInsets.all(50),
              child: Row(
                children: <Widget>[
                  PhysicalModel(
                    color: _debugCanvas,
                    child: Text('A long long long long long long long string'),
                  ),
                  PhysicalModel(
                    color: _debugCanvas,
                    child: Text('A long long long long long long long string'),
                  ),
                  PhysicalModel(
                    color: _debugCanvas,
                    child: Text('A long long long long long long long string'),
                  ),
                  PhysicalModel(
                    color: _debugCanvas,
                    child: Text('A long long long long long long long string'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    // ignore: avoid_dynamic_calls
    expect(exception.diagnostics.first.level, DiagnosticLevel.summary);
    // ignore: avoid_dynamic_calls
    expect(exception.diagnostics.first.toString(), startsWith('A RenderFlex overflowed by '));
    await expectLater(find.byKey(key), matchesGoldenFile('physical_model_overflow.png'));
  });

  testWidgets('PhysicalModel does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: PhysicalModel(color: Color(0xAABBCC00))),
      ),
    );
    expect(tester.getSize(find.byType(PhysicalModel)), Size.zero);
  });

  testWidgets('PhysicalShape does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: PhysicalShape(
            color: Color(0xAABBCC00),
            clipper: ShapeBorderClipper(shape: CircleBorder()),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(PhysicalShape)), Size.zero);
  });
}
