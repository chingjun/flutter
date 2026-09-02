// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Canvas, Path, Rect, TextDirection;

import 'package:flutter/src/painting/borders.dart' show ShapeBorder;
import 'package:flutter/src/painting/edge_insets.dart' show EdgeInsetsDirectional, EdgeInsetsGeometry;

/// A function that logs a string.
typedef Logger = void Function(String caller);

/// A [ShapeBorder] for testing that logs its method calls.
class TestBorder extends ShapeBorder {
  /// Creates a [TestBorder] that logs to [onLog].
  const TestBorder(this.onLog);

  /// The callback that is called when a method on this border is called.
  final Logger onLog;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsetsDirectional.only(start: 1.0);

  @override
  ShapeBorder scale(double t) => TestBorder(onLog);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    onLog('getInnerPath $rect $textDirection');
    return Path();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    onLog('getOuterPath $rect $textDirection');
    return Path();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    onLog('paint $rect $textDirection');
  }
}
