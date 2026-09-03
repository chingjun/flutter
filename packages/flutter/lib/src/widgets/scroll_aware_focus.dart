// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Functions for integrating scrollable widgets with focus traversal.
///
/// This file provides an indirection layer so that [FocusTraversalPolicy]
/// implementations can work with scrollable widgets without directly depending
/// on [Scrollable]. The [Scrollable] widget registers its implementations of
/// these functions during framework initialization.
library;


import 'package:flutter/src/animation/curves.dart' show Curve;
import 'package:flutter/src/painting/basic_types.dart' show Axis;
import 'package:flutter/src/widgets/framework.dart' show BuildContext;
import 'package:flutter/src/widgets/scroll_position.dart' show ScrollPositionAlignmentPolicy;

/// Signature for a function that looks up the nearest scrollable ancestor state.
///
/// Returns an opaque [Object] representing the scrollable state, suitable for
/// identity comparisons. Returns null if no scrollable ancestor is found.
///
/// When [axis] is provided, only scrollable ancestors in that axis are
/// considered.
typedef ScrollableLookup = Object? Function(BuildContext context, {Axis? axis});

/// Signature for a function that ensures a given context is visible within
/// its enclosing scrollable ancestors.
typedef ScrollableEnsureVisibleFunction = Future<void> Function(
  BuildContext context, {
  double alignment,
  Duration duration,
  Curve curve,
  ScrollPositionAlignmentPolicy alignmentPolicy,
});

/// Function to look up the nearest scrollable ancestor state.
///
/// This is set by the scrollable widget implementation. When null, focus
/// traversal assumes there are no scrollable ancestors.
///
/// The returned object is suitable for identity comparison only.
ScrollableLookup? scrollableMaybeOf;

/// Function to ensure a context is visible within its scrollable ancestors.
///
/// This is set by the scrollable widget implementation. When null, focus
/// traversal will not attempt to scroll to make focused items visible.
ScrollableEnsureVisibleFunction? scrollableEnsureVisible;
