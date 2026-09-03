// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

// InheritedTheme and CapturedThemes are now defined in framework.dart
// to break the dependency cycle. This file re-exports them for backward
// compatibility.
export 'package:flutter/src/widgets/framework.dart' show CapturedThemes, InheritedTheme;
