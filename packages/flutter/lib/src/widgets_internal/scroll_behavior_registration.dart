// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file registers factory callbacks for widgets that are used by
// various widget files but whose import would create dependency cycles within
// the widgets library. It is called from WidgetsBinding.initInstances().

import 'dart:ui' show Color, VoidCallback;

import 'package:flutter/src/painting/basic_types.dart' show AxisDirection;
import 'package:flutter/src/widgets/_windowing_callbacks.dart'
    show
        buildGlowingOverscrollIndicatorCallback,
        buildRawScrollbarCallback,
        buildUndoHistoryCallback,
        contextMenuControllerIsShownCallback,
        contextMenuControllerMarkNeedsBuildCallback,
        contextMenuControllerRemoveCallback,
        contextMenuControllerShowCallback,
        createContextMenuControllerCallback,
        navigatorMaybeOfContextCallback;
import 'package:flutter/src/widgets/context_menu_controller.dart' show ContextMenuController;
import 'package:flutter/src/widgets/focus_manager.dart' show FocusNode;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, Widget, WidgetBuilder;
import 'package:flutter/src/widgets/navigator.dart' show Navigator;
import 'package:flutter/src/widgets/overscroll_indicator.dart'
    show GlowingOverscrollIndicator;
import 'package:flutter/src/widgets/scroll_controller.dart' show ScrollController;
import 'package:flutter/src/widgets/scroll_aware_focus.dart' as scroll_aware_focus;
import 'package:flutter/src/widgets/scrollable.dart' show Scrollable;
import 'package:flutter/src/widgets/scrollbar.dart' show RawScrollbar;
import 'package:flutter/src/widgets/undo_history.dart' show UndoHistory;
import 'package:flutter/src/widgets/undo_history_controller.dart' show UndoHistoryController;
import 'package:listen/listen.dart' show ValueNotifier;

/// Registers factory callbacks for widgets to break dependency cycles.
///
/// This must be called during binding initialization, before any
/// widgets using these callbacks are built.
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

  buildUndoHistoryCallback ??= ({
    required Object value,
    required Object onTriggered,
    Object? shouldChangeUndoStack,
    Object? undoStackModifier,
    required Object? focusNode,
    required Object? controller,
    required Object child,
  }) {
    return UndoHistory<Object>(
      value: value as ValueNotifier<Object>,
      onTriggered: onTriggered as void Function(Object),
      shouldChangeUndoStack: shouldChangeUndoStack as bool Function(Object?, Object)?,
      undoStackModifier: undoStackModifier as Object Function(Object)?,
      focusNode: focusNode! as FocusNode,
      controller: controller as UndoHistoryController?,
      child: child as Widget,
    );
  };

  createContextMenuControllerCallback ??= ({Object? onRemove}) {
    return ContextMenuController(onRemove: onRemove as VoidCallback?);
  };

  contextMenuControllerShowCallback ??= (
    Object controller, {
    required Object context,
    required Object contextMenuBuilder,
    Object? debugRequiredFor,
  }) {
    (controller as ContextMenuController).show(
      context: context as BuildContext,
      contextMenuBuilder: contextMenuBuilder as WidgetBuilder,
      debugRequiredFor: debugRequiredFor as Widget?,
    );
  };

  contextMenuControllerRemoveCallback ??= (Object controller) {
    (controller as ContextMenuController).remove();
  };

  contextMenuControllerIsShownCallback ??= (Object controller) {
    return (controller as ContextMenuController).isShown;
  };

  contextMenuControllerMarkNeedsBuildCallback ??= (Object controller) {
    (controller as ContextMenuController).markNeedsBuild();
  };

  navigatorMaybeOfContextCallback ??= (Object context) {
    return Navigator.maybeOf(context as BuildContext)?.context;
  };

  // Register scrollable lookup functions for focus traversal integration.
  // This allows focus_traversal.dart to work with scrollable widgets
  // without directly importing scrollable.dart, breaking the dependency cycle.
  scroll_aware_focus.scrollableMaybeOf ??= Scrollable.maybeOf;
  scroll_aware_focus.scrollableEnsureVisible ??= Scrollable.ensureVisible;
}
