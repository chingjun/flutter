// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticLevel;
import 'package:flutter/src/widgets/basic.dart' show Builder, Directionality, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, GlobalKey, InheritedElement;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InheritedWidget dependencies show up in diagnostic properties', (
    WidgetTester tester,
  ) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        key: key,
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (BuildContext context) {
            Directionality.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    final element = key.currentContext! as InheritedElement;
    expect(
      element.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'Directionality-[GlobalKey#00000](textDirection: ltr)\n'
        '└Builder(dependencies: [Directionality-[GlobalKey#00000]])\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );

    await tester.pumpWidget(
      Directionality(
        key: key,
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (BuildContext context) {
            Directionality.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      element.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'Directionality-[GlobalKey#00000](textDirection: rtl)\n'
        '└Builder(dependencies: [Directionality-[GlobalKey#00000]])\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });
}
