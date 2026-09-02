// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;

import 'package:flutter/src/services/message_codecs.dart' show JSONMessageCodec;
import 'package:flutter/src/services/system_channels.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';

/// Simulates a system back, like a back gesture on Android.
///
/// Sends the same platform channel message that the engine sends when it
/// receives a system back.
Future<void> simulateSystemBack() {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    const JSONMessageCodec().encodeMessage(<String, dynamic>{'method': 'popRoute'}),
    (ByteData? _) {},
  );
}
