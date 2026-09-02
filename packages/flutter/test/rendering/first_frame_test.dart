// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/src/foundation/binding.dart' show BindingBase;
import 'package:flutter/src/foundation/constants.dart' show kIsWeb;
import 'package:flutter/src/gestures/binding.dart' show GestureBinding;
import 'package:flutter/src/rendering/binding.dart' show RendererBinding;
import 'package:flutter/src/scheduler/binding.dart' show SchedulerBinding;
import 'package:flutter/src/semantics/binding.dart' show SemanticsBinding;
import 'package:flutter/src/services/binding.dart' show ServicesBinding;
import 'package:flutter/src/services/message_codec.dart' show MethodCall;
import 'package:flutter/src/services/platform_channel.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestRenderBinding();
  test('Flutter dispatches first frame event on the web only', () async {
    final completer = Completer<void>();
    const firstFrameChannel = MethodChannel('flutter/service_worker');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(firstFrameChannel, (
      MethodCall methodCall,
    ) async {
      completer.complete();
      return null;
    });

    binding.handleBeginFrame(Duration.zero);
    binding.handleDrawFrame();

    await expectLater(completer.future, completes);
  }, skip: !kIsWeb); // [intended] the test is only makes sense on the web.
}

class TestRenderBinding extends BindingBase
    with
        SchedulerBinding,
        ServicesBinding,
        GestureBinding,
        SemanticsBinding,
        RendererBinding,
        TestDefaultBinaryMessengerBinding {}
