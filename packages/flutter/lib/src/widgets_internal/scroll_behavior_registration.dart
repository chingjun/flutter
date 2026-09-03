// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file registers factory callbacks for widgets that are used by
// ScrollBehavior but whose import would create dependency cycles within
// the widgets library. It is called from WidgetsBinding.initInstances().

import 'dart:ui' show Color;

import 'package:flutter/src/painting/basic_types.dart' show AxisDirection;
import 'package:flutter/src/widgets/_windowing_callbacks.dart'
    show buildGlowingOverscrollIndicatorCallback, buildRawScrollbarCallback;
import 'package:flutter/src/widgets/framework.dart' show Widget;
import 'package:flutter/src/widgets/overscroll_indicator.dart'
    show GlowingOverscrollIndicator;
import 'package:flutter/src/widgets/scroll_controller.dart' show ScrollController;
import 'package:flutter/src/widgets/scrollbar.dart' show RawScrollbar;

/// Registers factory callbacks for scroll behavior widgets.
///
/// This must be called during binding initialization, before any
/// [ScrollBehavior] methods are invoked.
void registerScrollBehaviorCallbacks() {
  buildGlowingOverscrollIndicatorCallback ??= ({
    required Object axisDirection,
    required Object color,
    required Object child,
  }) {
    return GlowingOverscrollIndicator(
      axisDirection: axisDirection as AxisDirection,
      color: color as Color,
      child: child as Widget?,
    );
  };

  buildRawScrollbarCallback ??= ({
    required Object? controller,
    required Object child,
  }) {
    return RawScrollbar(
      controller: controller as ScrollController?,
      child: child as Widget,
    );
  };
}
