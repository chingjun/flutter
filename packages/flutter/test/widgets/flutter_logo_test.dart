// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:ui' show Size, TextDirection;

import 'package:flutter/src/foundation/key.dart' show Key, UniqueKey;
import 'package:flutter/src/widgets/basic.dart' show Center, Directionality, SizedBox;
import 'package:flutter/src/widgets/flutter_logo.dart' show FlutterLogo;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter Logo golden test', (WidgetTester tester) async {
    final Key logo = UniqueKey();
    await tester.pumpWidget(FlutterLogo(key: logo));

    await expectLater(find.byKey(logo), matchesGoldenFile('flutter_logo.png'));
  });

  testWidgets('FlutterLogo does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox.shrink(child: FlutterLogo())),
      ),
    );
    expect(tester.getSize(find.byType(FlutterLogo)), Size.zero);
  });
}
