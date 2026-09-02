// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter widgets implementing Material Design animated icons.
/// @docImport 'package:flutter/semantics.dart';
///
/// @docImport 'icons.dart';
/// @docImport 'theme.dart';
library material_animated_icons;

import 'dart:math' as math show pi;
import 'dart:ui' as ui show Canvas, Paint, Path, lerpDouble;
import 'dart:ui' show Color, Offset, PaintingStyle, Path, Size, TextDirection, clampDouble;

import 'package:flutter/src/animation/animation.dart' show Animation;
import 'package:flutter/src/rendering/custom_paint.dart' show CustomPainter, SemanticsBuilderCallback;
import 'package:flutter/src/widgets/basic.dart' show CustomPaint, Directionality, Semantics;
import 'package:flutter/src/widgets/debug.dart' show debugCheckHasDirectionality;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, StatelessWidget, Widget;
import 'package:flutter/src/widgets/icon_theme.dart' show IconTheme;
import 'package:flutter/src/widgets/icon_theme_data.dart' show IconThemeData;

part 'animated_icons/animated_icons.dart';

part 'animated_icons/animated_icons_data.dart';

part 'animated_icons/data/add_event.g.dart';

part 'animated_icons/data/arrow_menu.g.dart';

part 'animated_icons/data/close_menu.g.dart';

part 'animated_icons/data/ellipsis_search.g.dart';

part 'animated_icons/data/event_add.g.dart';

part 'animated_icons/data/home_menu.g.dart';

part 'animated_icons/data/list_view.g.dart';

part 'animated_icons/data/menu_arrow.g.dart';

part 'animated_icons/data/menu_close.g.dart';

part 'animated_icons/data/menu_home.g.dart';

part 'animated_icons/data/pause_play.g.dart';

part 'animated_icons/data/play_pause.g.dart';

part 'animated_icons/data/search_ellipsis.g.dart';

part 'animated_icons/data/view_list.g.dart';
