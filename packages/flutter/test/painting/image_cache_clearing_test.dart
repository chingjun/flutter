// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/src/foundation/assertions.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter/src/painting/binding.dart' show imageCache;
import 'package:flutter/src/painting/image_provider.dart' show ImageConfiguration, MemoryImage;
import 'package:flutter/src/painting/image_stream.dart' show ImageInfo, ImageStream, ImageStreamListener;
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';
import '../rendering/rendering_tester.dart';

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test("Clearing images while they're pending does not crash", () async {
    final bytes = Uint8List.fromList(kTransparentImage);
    final memoryImage = MemoryImage(bytes);
    final ImageStream stream = memoryImage.resolve(ImageConfiguration.empty);
    final completer = Completer<void>();
    FlutterError.onError = (FlutterErrorDetails error) {
      completer.completeError(error.exception, error.stack);
    };
    stream.addListener(
      ImageStreamListener((ImageInfo image, bool synchronousCall) {
        completer.complete();
      }),
    );
    imageCache.clearLiveImages();
    await completer.future;
  });
}
