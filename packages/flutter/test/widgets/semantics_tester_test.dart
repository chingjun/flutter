// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsFlag, SemanticsFlags, TextDirection, Tristate;

import 'package:flutter/src/gestures/tap.dart' show TapGestureRecognizer;
import 'package:flutter/src/painting/text_span.dart' show TextSpan;
import 'package:flutter/src/painting/text_style.dart' show TextStyle;
import 'package:flutter/src/widgets/basic.dart' show Semantics;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics tester visits last child', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    const textStyle = TextStyle();
    final recognizer = TapGestureRecognizer();
    addTearDown(recognizer.dispose);

    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <TextSpan>[
            const TextSpan(text: 'hello'),
            TextSpan(text: 'world', recognizer: recognizer..onTap = () {}),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ),
    );
    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(label: 'hello', textDirection: TextDirection.ltr),
            TestSemantics(),
          ],
        ),
      ],
    );
    expect(
      semantics,
      isNot(
        hasSemantics(expectedSemantics, ignoreTransform: true, ignoreId: true, ignoreRect: true),
      ),
    );
    semantics.dispose();
  });

  testWidgets('Semantics tester support flags as an int', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          selected: true,
          child: Container(),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              label: 'test1',
              rect: TestSemantics.fullScreen,
              flags: SemanticsFlag.hasSelectedState.index | SemanticsFlag.isSelected.index,
            ),
          ],
        ),
      ),
    );
    semantics.dispose();
  });

  testWidgets('Semantics tester support flags as a list of SemanticsFlag', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          selected: true,
          child: Container(),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              label: 'test1',
              rect: TestSemantics.fullScreen,
              flags: <SemanticsFlag>[SemanticsFlag.hasSelectedState, SemanticsFlag.isSelected],
            ),
          ],
        ),
      ),
    );
    semantics.dispose();
  });

  testWidgets('Semantics tester support flags as a SemanticsFlags', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          selected: true,
          child: Container(),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              label: 'test1',
              rect: TestSemantics.fullScreen,
              flags: SemanticsFlags(isSelected: Tristate.isTrue),
            ),
          ],
        ),
      ),
    );
    semantics.dispose();
  });
}
