// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show VoidCallback;

import 'package:flutter/src/painting/edge_insets.dart' show EdgeInsets;
import 'package:flutter/src/rendering/box.dart' show BoxConstraints;
import 'package:flutter/src/rendering/proxy_box.dart' show HitTestBehavior;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, StatelessWidget, Widget;
import 'package:flutter/src/widgets/gesture_detector.dart' show GestureDetector;

/// A minimal ListTile widget for testing purposes to avoid relying on
/// widgets from material.dart.
/// See https://github.com/flutter/flutter/issues/177415.
class TestListTile extends StatelessWidget {
  const TestListTile({super.key, this.title, this.onTap});

  final Widget? title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      constraints: const BoxConstraints(minHeight: 56.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: title,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
    }

    return content;
  }
}
