// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Callbacks used to break import cycles between widget files.
library;

import 'package:meta/meta.dart' show internal;

/// A callback to create the default windowing owner.
///
/// This is set by `_window.dart` and called by `binding.dart` to break the
/// import cycle between them.
@internal
Object Function()? createDefaultWindowingOwnerCallback;

/// A callback to check if the current modal route is active.
///
/// This is set by `routes.dart` and called by `tap_region.dart` to avoid
/// importing routes.dart. Returns null when there is no modal route.
@internal
bool? Function(Object context)? isCurrentModalRouteCallback;
