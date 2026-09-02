// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/painting/inline_span.dart' show InlineSpan;
import 'package:flutter/src/painting/placeholder_span.dart' show PlaceholderSpan;
import 'package:flutter/src/painting/text_scaler.dart' show TextScaler;
import 'package:flutter/src/painting/text_span.dart' show TextSpan;
import 'package:flutter/src/painting/text_style.dart' show TextStyle;
import 'package:flutter/src/widgets/basic.dart' show Semantics, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show ProxyWidget, Widget;
import 'package:flutter/src/widgets/widget_span.dart' show WidgetSpan;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WidgetSpan codeUnitAt', () {
    const InlineSpan span = WidgetSpan(child: SizedBox());
    expect(span.codeUnitAt(-1), isNull);
    expect(span.codeUnitAt(0), PlaceholderSpan.placeholderCodeUnit);
    expect(span.codeUnitAt(1), isNull);
    expect(span.codeUnitAt(2), isNull);

    const InlineSpan nestedSpan = TextSpan(text: 'AAA', children: <InlineSpan>[span, span]);
    expect(nestedSpan.codeUnitAt(-1), isNull);
    expect(nestedSpan.codeUnitAt(0), 65);
    expect(nestedSpan.codeUnitAt(1), 65);
    expect(nestedSpan.codeUnitAt(2), 65);
    expect(nestedSpan.codeUnitAt(3), PlaceholderSpan.placeholderCodeUnit);
    expect(nestedSpan.codeUnitAt(4), PlaceholderSpan.placeholderCodeUnit);
    expect(nestedSpan.codeUnitAt(5), isNull);
  });

  test('WidgetSpan.extractFromInlineSpan applies the correct scaling factor', () {
    const a = WidgetSpan(child: SizedBox(), style: TextStyle(fontSize: 0));
    const b = WidgetSpan(child: SizedBox(), style: TextStyle(fontSize: 10));
    const c = WidgetSpan(child: SizedBox());
    const d = WidgetSpan(child: SizedBox(), style: TextStyle(letterSpacing: 999));

    const span = TextSpan(
      children: <InlineSpan>[
        a, // fontSize = 0.
        TextSpan(
          children: <InlineSpan>[
            b, // fontSize = 10.
            c, // fontSize = 20.
          ],
          style: TextStyle(fontSize: 20),
        ),
        d, // fontSize = 14.
      ],
    );

    double effectiveTextScaleFactorFromWidget(Widget widget) {
      final child = (widget as ProxyWidget).child as Semantics;
      final dynamic grandChild = child.child;
      final textScaleFactor = grandChild.textScaleFactor as double; // ignore: avoid_dynamic_calls
      return textScaleFactor;
    }

    final List<double> textScaleFactors = WidgetSpan.extractFromInlineSpan(
      span,
      const _QuadraticScaler(),
    ).map(effectiveTextScaleFactorFromWidget).toList();

    expect(textScaleFactors, <double>[
      0, // a
      10, // b
      20, // c
      14, // d
    ]);
  });
}

class _QuadraticScaler extends TextScaler {
  const _QuadraticScaler();

  @override
  double scale(double fontSize) => fontSize * fontSize;

  @override
  double get textScaleFactor => throw UnimplementedError();
}
