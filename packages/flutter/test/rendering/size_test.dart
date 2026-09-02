// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Size;

import 'package:flutter/src/rendering/box.dart' show BoxConstraints, RenderBox;
import 'package:flutter/src/rendering/proxy_box.dart' show RenderConstrainedBox;
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('Stack can layout with top, right, bottom, left 0.0', () {
    final RenderBox box = RenderConstrainedBox(
      additionalConstraints: BoxConstraints.tight(const Size(100.0, 100.0)),
    );

    layout(box, constraints: const BoxConstraints());

    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));
    expect(box.size, equals(const Size(100.0, 100.0)));
    expect(box.size.runtimeType.toString(), equals('_DebugSize'));
  });
}
