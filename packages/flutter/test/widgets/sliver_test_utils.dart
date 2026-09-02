// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/rendering/sliver.dart' show RenderSliver, SliverGeometry;
import 'package:flutter/src/widgets/framework.dart' show GlobalKey;
import 'package:flutter_test/flutter_test.dart';

/// Verify that the [RenderSliver] identified by [key] has the expected
/// [SliverGeometry.visible] and [SliverGeometry.paintExtent] properties.
void verifySliverGeometry({
  required GlobalKey key,
  required bool visible,
  required double paintExtent,
}) {
  final target = key.currentContext!.findRenderObject()! as RenderSliver;
  final SliverGeometry geometry = target.geometry!;
  expect(geometry.visible, visible);
  expect(geometry.paintExtent, paintExtent);
}
