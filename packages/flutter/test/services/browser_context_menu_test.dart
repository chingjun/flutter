// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/basic_types.dart' show AsyncCallback;
import 'package:flutter/src/foundation/constants.dart' show kIsWeb;
import 'package:flutter/src/services/browser_context_menu.dart' show BrowserContextMenu;
import 'package:flutter/src/services/message_codec.dart' show MethodCall;
import 'package:flutter/src/services/system_channels.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final log = <MethodCall>[];

  Future<void> verify(AsyncCallback test, List<Object> expectations) async {
    log.clear();
    await test();
    expect(log, expectations);
  }

  group(
    'not on web',
    () {
      test('disableContextMenu asserts', () async {
        try {
          await BrowserContextMenu.disableContextMenu();
        } catch (error) {
          expect(error, isAssertionError);
        }
      });

      test('enableContextMenu asserts', () async {
        try {
          await BrowserContextMenu.enableContextMenu();
        } catch (error) {
          expect(error, isAssertionError);
        }
      });
    },
    skip: kIsWeb, // [intended]
  );

  group(
    'on web',
    () {
      group('disableContextMenu', () {
        // Make sure the context menu is enabled (default) after the test.
        tearDown(() async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.contextMenu, (MethodCall methodCall) {
                return null;
              });
          await BrowserContextMenu.enableContextMenu();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.contextMenu, null);
        });

        test('disableContextMenu calls its platform channel method', () async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.contextMenu, (MethodCall methodCall) async {
                log.add(methodCall);
                return null;
              });

          await verify(BrowserContextMenu.disableContextMenu, <Object>[
            isMethodCall('disableContextMenu', arguments: null),
          ]);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.contextMenu, null);
        });
      });

      group('enableContextMenu', () {
        test('enableContextMenu calls its platform channel method', () async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.contextMenu, (MethodCall methodCall) async {
                log.add(methodCall);
                return null;
              });

          await verify(BrowserContextMenu.enableContextMenu, <Object>[
            isMethodCall('enableContextMenu', arguments: null),
          ]);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.contextMenu, null);
        });
      });
    },
    skip: !kIsWeb, // [intended]
  );
}
