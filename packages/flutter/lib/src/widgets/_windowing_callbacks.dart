// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart' show internal;

/// A callback to create the default windowing owner.
///
/// This is set by `_window.dart` and called by `binding.dart` to break the
/// import cycle between them.
@internal
Object Function()? createDefaultWindowingOwnerCallback;
