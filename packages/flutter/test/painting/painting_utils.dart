// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:ui' as ui;

import 'package:flutter/src/foundation/binding.dart' show BindingBase;
import 'package:flutter/src/painting/binding.dart' show PaintingBinding;
import 'package:flutter/src/scheduler/binding.dart' show SchedulerBinding;
import 'package:flutter/src/services/binding.dart' show ServicesBinding;

class PaintingBindingSpy extends BindingBase
    with SchedulerBinding, ServicesBinding, PaintingBinding {
  int counter = 0;
  int get instantiateImageCodecCalledCount => counter;

  @override
  Future<ui.Codec> instantiateImageCodecWithSize(
    ui.ImmutableBuffer buffer, {
    ui.TargetImageSizeCallback? getTargetSize,
  }) {
    counter++;
    return ui.instantiateImageCodecWithSize(buffer, getTargetSize: getTargetSize);
  }

  @override
  // ignore: must_call_super
  void initLicenses() {
    // Do not include any licenses, because we're a test, and the LICENSE file
    // doesn't get generated for tests.
  }
}
