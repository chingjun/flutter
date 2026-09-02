// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:flutter/src/foundation/binding.dart' show BindingBase;
import 'package:flutter/src/painting/binding.dart' show PaintingBinding;
import 'package:flutter/src/scheduler/binding.dart' show SchedulerBinding;
import 'package:flutter/src/services/binding.dart' show ServicesBinding;
import 'package:flutter/src/services/system_channels.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PaintingBinding with memory pressure before initInstances', () async {
    // Observed in devicelab: the device sends a memory pressure event
    // to us before the binding is initialized, so as soon as the
    // ServicesBinding's initInstances sets up the callbacks, we get a
    // call. Previously this would happen synchronously during
    // initInstances (and before the imageCache was initialized, which
    // was a problem), but now it happens asynchronously just after.

    ui.channelBuffers.push(
      SystemChannels.system.name,
      SystemChannels.system.codec.encodeMessage(<String, dynamic>{'type': 'memoryPressure'}),
      (ByteData? responseData) {
        // The result is: SystemChannels.system.codec.decodeMessage(responseData)
        // ...but we ignore it for the purposes of this test.
      },
    );

    final binding = TestPaintingBinding();
    expect(binding._handled, isFalse);
    expect(binding.imageCache, isNotNull);
    expect(binding.imageCache.currentSize, 0);

    await null; // allow microtasks to run
    expect(binding._handled, isTrue);
  });
}

class TestPaintingBinding extends BindingBase
    with SchedulerBinding, ServicesBinding, PaintingBinding {
  @override
  void handleMemoryPressure() {
    super.handleMemoryPressure();
    _handled = true;
  }

  bool _handled = false;
}
