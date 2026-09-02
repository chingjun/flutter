// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data' show ByteData;

import 'package:flutter/src/foundation/assertions.dart' show FlutterError;
import 'package:flutter/src/foundation/constants.dart' show kIsWeb;
import 'package:flutter/src/services/message_codec.dart' show MethodCall;
import 'package:flutter/src/services/message_codecs.dart' show JSONMessageCodec;
import 'package:flutter/src/services/scribe.dart' show Scribe;
import 'package:flutter/src/services/system_channels.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  test('when receiving an unsupported message', () async {
    final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': 'Scribe.unsupportedMessage',
    });

    final ByteData? response = await binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/scribe',
      messageBytes,
      null,
    );

    // When a MissingPluginException is thrown, it is caught and a null response
    // is returned.
    expect(response, isNull);
  }, skip: kIsWeb); // [intended]

  for (final returnValue in <bool?>[false, true, null]) {
    test('Scribe.isStylusHandwritingAvailable calls through to platform channel', () async {
      final calls = <MethodCall>[];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.scribe, (
        MethodCall methodCall,
      ) {
        calls.add(methodCall);
        return Future<bool?>.value(returnValue);
      });

      if (returnValue == null) {
        expect(() async {
          await Scribe.isStylusHandwritingAvailable();
        }, throwsA(isA<FlutterError>()));
      } else {
        expect(await Scribe.isStylusHandwritingAvailable(), returnValue);
      }

      expect(calls, hasLength(1));
      expect(calls.first.method, 'Scribe.isStylusHandwritingAvailable');
    }, skip: kIsWeb); // [intended]
  }

  for (final returnValue in <bool?>[false, true, null]) {
    test('Scribe.isFeatureAvailable calls through to platform channel', () async {
      final calls = <MethodCall>[];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.scribe, (
        MethodCall methodCall,
      ) {
        calls.add(methodCall);
        return Future<bool?>.value(returnValue);
      });

      if (returnValue == null) {
        expect(() async {
          await Scribe.isFeatureAvailable();
        }, throwsA(isA<FlutterError>()));
      } else {
        expect(await Scribe.isFeatureAvailable(), returnValue);
      }

      expect(calls, hasLength(1));
      expect(calls.first.method, 'Scribe.isFeatureAvailable');
    }, skip: kIsWeb); // [intended]
  }

  test('Scribe.startStylusHandwriting calls through to platform channel', () async {
    final calls = <MethodCall>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.scribe, (
      MethodCall methodCall,
    ) {
      calls.add(methodCall);
      return Future<void>.value();
    });

    await Scribe.startStylusHandwriting();
    expect(calls, hasLength(1));
    expect(calls.first.method, 'Scribe.startStylusHandwriting');
  }, skip: kIsWeb); // [intended]
}
