// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/semantics/semantics_event.dart' show Assertiveness;
import 'package:flutter/src/semantics/semantics_service.dart' show SemanticsService;
import 'package:flutter/src/services/system_channels.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Semantic announcement', (WidgetTester tester) async {
    final log = <Map<dynamic, dynamic>>[];

    Future<dynamic> handleMessage(dynamic mockMessage) async {
      final message = mockMessage as Map<dynamic, dynamic>;
      log.add(message);
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, handleMessage);

    await SemanticsService.sendAnnouncement(tester.view, 'announcement 1', TextDirection.ltr);
    await SemanticsService.sendAnnouncement(
      tester.view,
      'announcement 2',
      TextDirection.rtl,
      assertiveness: Assertiveness.assertive,
    );
    expect(
      log,
      equals(<Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'announce',
          'data': <String, dynamic>{
            'viewId': tester.view.viewId,
            'message': 'announcement 1',
            'textDirection': 1,
          },
        },
        <String, dynamic>{
          'type': 'announce',
          'data': <String, dynamic>{
            'viewId': tester.view.viewId,
            'message': 'announcement 2',
            'textDirection': 0,
            'assertiveness': 1,
          },
        },
      ]),
    );
  });
}
