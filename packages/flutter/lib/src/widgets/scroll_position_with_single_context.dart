// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file re-exports ScrollPositionWithSingleContext from scroll_controller.dart
// to maintain backward compatibility. The class was moved to scroll_controller.dart
// to break a dependency cycle in the widgets library.

export 'package:flutter/src/widgets/scroll_controller.dart' show ScrollPositionWithSingleContext;
