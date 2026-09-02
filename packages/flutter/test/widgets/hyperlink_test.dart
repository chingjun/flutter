// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/foundation/key.dart' show Key;
import 'package:flutter/src/gestures/tap.dart' show TapGestureRecognizer;
import 'package:flutter/src/painting/text_span.dart' show TextSpan;
import 'package:flutter/src/rendering/box.dart' show RenderBox;
import 'package:flutter/src/widgets/basic.dart' show Center;
import 'package:flutter/src/widgets/rich_text.dart' show RichText;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can tap a hyperlink', (WidgetTester tester) async {
    var didTapLeft = false;
    final tapLeft = TapGestureRecognizer()
      ..onTap = () {
        didTapLeft = true;
      };
    addTearDown(tapLeft.dispose);

    var didTapRight = false;
    final tapRight = TapGestureRecognizer()
      ..onTap = () {
        didTapRight = true;
      };
    addTearDown(tapRight.dispose);

    const textKey = Key('text');

    await tester.pumpWidget(
      Center(
        child: RichText(
          key: textKey,
          textDirection: TextDirection.ltr,
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(text: 'xxxxxxxx', recognizer: tapLeft),
              const TextSpan(text: 'yyyyyyyy'),
              TextSpan(text: 'zzzzzzzzz', recognizer: tapRight),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byKey(textKey));

    expect(didTapLeft, isFalse);
    expect(didTapRight, isFalse);

    await tester.tapAt(box.localToGlobal(Offset.zero) + const Offset(2.0, 2.0));

    expect(didTapLeft, isTrue);
    expect(didTapRight, isFalse);

    didTapLeft = false;

    await tester.tapAt(box.localToGlobal(Offset.zero) + const Offset(30.0, 2.0));

    expect(didTapLeft, isTrue);
    expect(didTapRight, isFalse);

    didTapLeft = false;

    await tester.tapAt(box.localToGlobal(Offset(box.size.width, 0.0)) + const Offset(-2.0, 2.0));

    expect(didTapLeft, isFalse);
    expect(didTapRight, isTrue);
  });
}
