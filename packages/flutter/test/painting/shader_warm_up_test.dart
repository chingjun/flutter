// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/src/painting/binding.dart' show PaintingBinding;
import 'package:flutter/src/painting/debug.dart' show debugCaptureShaderWarmUpImage;
import 'package:flutter/src/painting/shader_warm_up.dart' show ShaderWarmUp;
import 'package:flutter/src/widgets/binding.dart' show WidgetsFlutterBinding;
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  test('ShaderWarmUp', () {
    final shaderWarmUp = FakeShaderWarmUp();
    PaintingBinding.shaderWarmUp = shaderWarmUp;
    debugCaptureShaderWarmUpImage = expectAsync1((ui.Image image) => true);
    WidgetsFlutterBinding.ensureInitialized();
    expect(shaderWarmUp.ranWarmUp, true);
  });
}

class FakeShaderWarmUp extends ShaderWarmUp {
  bool ranWarmUp = false;

  @override
  Future<bool> warmUpOnCanvas(ui.Canvas canvas) {
    ranWarmUp = true;
    return Future<bool>.delayed(Duration.zero, () => true);
  }
}
