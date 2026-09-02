// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;

import 'package:flutter/src/scheduler/binding.dart' show SchedulerBinding;
import 'package:flutter/src/services/message_codecs.dart' show StringCodec;
import 'package:flutter/src/widgets/binding.dart' show WidgetsFlutterBinding;
import 'package:flutter/src/widgets/placeholder.dart' show Placeholder;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attachRootWidget will schedule a frame', () async {
    final binding = WidgetsFlutterBindingWithTestBinaryMessenger();
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
    // Framework starts with detached statue. Sends resumed signal to enable frame.
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed')!;
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      message,
      (_) {},
    );

    binding.attachRootWidget(const Placeholder());
    expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
  });
}

class WidgetsFlutterBindingWithTestBinaryMessenger extends WidgetsFlutterBinding
    with TestDefaultBinaryMessengerBinding {}
