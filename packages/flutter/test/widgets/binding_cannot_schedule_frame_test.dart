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
  test('Can only schedule frames after widget binding attaches the root widget', () async {
    final binding = WidgetsFlutterBindingWithTestBinaryMessenger();
    expect(SchedulerBinding.instance.framesEnabled, isFalse);
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
    // Sends a message to notify that the engine is ready to accept frames.
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed')!;
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      message,
      (_) {},
    );

    // Enables the semantics should not schedule any frames if the root widget
    // has not been attached.
    expect(binding.semanticsEnabled, isFalse);
    binding.ensureSemantics();
    expect(binding.semanticsEnabled, isTrue);
    expect(SchedulerBinding.instance.framesEnabled, isFalse);
    expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);

    // The widget binding should be ready to produce frames after it attaches
    // the root widget.
    binding.attachRootWidget(const Placeholder());
    expect(SchedulerBinding.instance.framesEnabled, isTrue);
    expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
  });
}

class WidgetsFlutterBindingWithTestBinaryMessenger extends WidgetsFlutterBinding
    with TestDefaultBinaryMessengerBinding {}
