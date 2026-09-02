// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;

import 'package:flutter/src/foundation/binding.dart' show BindingBase;
import 'package:flutter/src/scheduler/binding.dart' show SchedulerBinding;
import 'package:flutter/src/services/binary_messenger.dart' show MessageHandler;
import 'package:flutter/src/services/binding.dart' show ServicesBinding;
import 'package:flutter/src/services/message_codec.dart' show MethodCall;
import 'package:flutter/src/services/message_codecs.dart' show StandardMethodCodec;
import 'package:flutter/src/services/system_channels.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';

class _TestBinding extends BindingBase with SchedulerBinding, ServicesBinding {
  @override
  Future<void> initializationComplete() async {
    return super.initializationComplete();
  }

  @override
  TestDefaultBinaryMessenger get defaultBinaryMessenger =>
      super.defaultBinaryMessenger as TestDefaultBinaryMessenger;

  @override
  TestDefaultBinaryMessenger createBinaryMessenger() {
    Future<ByteData?> keyboardHandler(ByteData? message) async {
      return const StandardMethodCodec().encodeSuccessEnvelope(<int, int>{1: 1});
    }

    return TestDefaultBinaryMessenger(
      super.createBinaryMessenger(),
      outboundHandlers: <String, MessageHandler>{'flutter/keyboard': keyboardHandler},
    );
  }
}

void main() {
  final binding = _TestBinding();

  test('can send message on completion of binding initialization', () async {
    var called = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      MethodCall method,
    ) async {
      if (method.method == 'System.initializationComplete') {
        called = true;
      }
      return null;
    });
    await binding.initializationComplete();
    expect(called, isTrue);
  });
}
