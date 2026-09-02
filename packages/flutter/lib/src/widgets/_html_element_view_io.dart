// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/key.dart' show Key;
import 'package:flutter/src/rendering/platform_view.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, Widget;
import 'package:flutter/src/widgets/platform_view.dart' show ElementCreatedCallback, HtmlElementView;

/// The platform-specific implementation of [HtmlElementView].
extension HtmlElementViewImpl on HtmlElementView {
  /// Creates an [HtmlElementView] that renders a DOM element with the given
  /// [tagName].
  static HtmlElementView createFromTagName({
    Key? key,
    required String tagName,
    bool isVisible = true,
    ElementCreatedCallback? onElementCreated,
    required PlatformViewHitTestBehavior hitTestBehavior,
  }) {
    throw UnimplementedError('HtmlElementView is only available on Flutter Web');
  }

  /// Called from [HtmlElementView.build] to build the widget tree.
  ///
  /// This is not expected to be invoked in non-web environments. It throws if
  /// that happens.
  ///
  /// The implementation on Flutter Web builds a platform view and handles its
  /// lifecycle.
  Widget buildImpl(BuildContext context) {
    throw UnimplementedError('HtmlElementView is only available on Flutter Web');
  }
}
