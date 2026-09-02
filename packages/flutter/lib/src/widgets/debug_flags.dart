// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/rendering.dart';
/// @docImport 'package:flutter/scheduler.dart';
///
/// @docImport 'app.dart';
/// @docImport 'binding.dart';
/// @docImport 'focus_manager.dart';
/// @docImport 'focus_scope.dart';
/// @docImport 'framework.dart';
/// @docImport 'widget_inspector.dart';
library;

import 'dart:developer' show Timeline;

import 'package:flutter/src/foundation/assertions.dart' show FlutterError;

/// Callback type for [debugIsLocalCreationCallback].
///
/// Returns true if the given [Widget] was created in the local project
/// (i.e., is user-created, not from the framework or a package).
typedef DebugIsWidgetLocalCreationCallback = bool Function(Object widget);

/// Returns true if a [Widget] is user created.
///
/// This callback is set by [WidgetInspectorService] and used by the framework
/// to decide whether to emit user-widget-only timeline events when
/// [debugProfileBuildsEnabledUserWidgets] is true.
///
/// The default implementation always returns false, meaning no timeline events
/// are emitted for user widgets until the widget inspector is initialized.
DebugIsWidgetLocalCreationCallback debugIsLocalCreationCallback = _defaultIsWidgetLocalCreation;

bool _defaultIsWidgetLocalCreation(Object widget) => false;

// Any changes to this file should be reflected in the debugAssertAllWidgetVarsUnset()
// function below.

/// Log the dirty widgets that are built each frame.
///
/// Combined with [debugPrintBuildScope] or [debugPrintBeginFrameBanner], this
/// allows you to distinguish builds triggered by the initial mounting of a
/// widget tree (e.g. in a call to [runApp]) from the regular builds triggered
/// by the pipeline.
///
/// Combined with [debugPrintScheduleBuildForStacks], this lets you watch a
/// widget's dirty/clean lifecycle.
///
/// To get similar information but showing it on the timeline available from
/// Flutter DevTools rather than getting it in the console (where it can be
/// overwhelming), consider [debugProfileBuildsEnabled].
///
/// See also:
///
///  * [WidgetsBinding.drawFrame], which pumps the build and rendering pipeline
///    to generate a frame.
bool debugPrintRebuildDirtyWidgets = false;

/// Signature for [debugOnRebuildDirtyWidget] implementations.
typedef RebuildDirtyWidgetCallback = void Function(Object e, bool builtOnce);

/// Callback invoked for every dirty widget built each frame.
///
/// This callback is only invoked in debug builds.
///
/// See also:
///
///  * [debugPrintRebuildDirtyWidgets], which does something similar but logs
///    to the console instead of invoking a callback.
///  * [debugOnProfilePaint], which does something similar for [RenderObject]
///    painting.
///  * [WidgetInspectorService], which uses the [debugOnRebuildDirtyWidget]
///    callback to generate aggregate profile statistics describing which widget
///    rebuilds occurred when the
///    `ext.flutter.inspector.trackRebuildDirtyWidgets` service extension is
///    enabled.
RebuildDirtyWidgetCallback? debugOnRebuildDirtyWidget;

/// Log all calls to [BuildOwner.buildScope].
///
/// Combined with [debugPrintScheduleBuildForStacks], this allows you to track
/// when a [State.setState] call gets serviced.
///
/// Combined with [debugPrintRebuildDirtyWidgets] or
/// [debugPrintBeginFrameBanner], this allows you to distinguish builds
/// triggered by the initial mounting of a widget tree (e.g. in a call to
/// [runApp]) from the regular builds triggered by the pipeline.
///
/// See also:
///
///  * [WidgetsBinding.drawFrame], which pumps the build and rendering pipeline
///    to generate a frame.
bool debugPrintBuildScope = false;

/// Log the call stacks that mark widgets as needing to be rebuilt.
///
/// This is called whenever [BuildOwner.scheduleBuildFor] adds an element to the
/// dirty list. Typically this is as a result of [Element.markNeedsBuild] being
/// called, which itself is usually a result of [State.setState] being called.
///
/// To see when a widget is rebuilt, see [debugPrintRebuildDirtyWidgets].
///
/// To see when the dirty list is flushed, see [debugPrintBuildScope].
///
/// To see when a frame is scheduled, see [debugPrintScheduleFrameStacks].
bool debugPrintScheduleBuildForStacks = false;

/// Log when widgets with global keys are deactivated and log when they are
/// reactivated (retaken).
///
/// This can help track down framework bugs relating to the [GlobalKey] logic.
bool debugPrintGlobalKeyedWidgetLifecycle = false;

/// Adds [Timeline] events for every Widget built.
///
/// The timing information this flag exposes is not representative of the actual
/// cost of building, because the overhead of adding timeline events is
/// significant relative to the time each object takes to build. However, it can
/// expose unexpected widget behavior in the timeline.
///
/// In debug builds, additional information is included in the trace (such as
/// the properties of widgets being built). Collecting this data is
/// expensive and further makes these traces non-representative of actual
/// performance. This data is omitted in profile builds.
///
/// For more information about performance debugging in Flutter, see
/// <https://docs.flutter.dev/perf/ui-performance>.
///
/// See also:
///
///  * [debugPrintRebuildDirtyWidgets], which does something similar but
///    reporting the builds to the console.
///  * [debugProfileLayoutsEnabled], which does something similar for layout,
///    and [debugPrintLayouts], its console equivalent.
///  * [debugProfilePaintsEnabled], which does something similar for painting.
///  * [debugProfileBuildsEnabledUserWidgets], which adds events for user-created
///    [Widget] build times and incurs less overhead.
///  * [debugEnhanceBuildTimelineArguments], which enhances the trace with
///    debugging information related to [Widget] builds.
bool debugProfileBuildsEnabled = false;

/// Adds [Timeline] events for every user-created [Widget] built.
///
/// A user-created [Widget] is any [Widget] that is constructed in the root
/// library. Often [Widget]s contain child [Widget]s that are constructed in
/// libraries (for example, a [TextButton] having a [RichText] child). Timeline
/// events for those children will be omitted with this flag. This works for any
/// [Widget] not just ones declared in the root library.
///
/// See also:
///
///  * [debugProfileBuildsEnabled], which functions similarly but shows events
///    for every widget and has a higher overhead cost.
///  * [debugEnhanceBuildTimelineArguments], which enhances the trace with
///    debugging information related to [Widget] builds.
bool debugProfileBuildsEnabledUserWidgets = false;

/// Adds debugging information to [Timeline] events related to [Widget] builds.
///
/// This flag will only add [Timeline] event arguments for debug builds.
/// Additional arguments will be added for the "BUILD" [Timeline] event and for
/// all [Widget] build [Timeline] events, which are the [Timeline] events that
/// are added when either of [debugProfileBuildsEnabled] and
/// [debugProfileBuildsEnabledUserWidgets] are true. The debugging information
/// that will be added in trace arguments includes stats around [Widget] dirty
/// states and [Widget] diagnostic information (i.e. [Widget] properties).
///
/// See also:
///
///  * [debugProfileBuildsEnabled], which adds [Timeline] events for every
///    [Widget] built.
///  * [debugProfileBuildsEnabledUserWidgets], which adds [Timeline] events for
///    every user-created [Widget] built.
///  * [debugEnhanceLayoutTimelineArguments], which does something similar for
///    events related to [RenderObject] layouts.
///  * [debugEnhancePaintTimelineArguments], which does something similar for
///    events related to [RenderObject] paints.
bool debugEnhanceBuildTimelineArguments = false;

/// Show banners for deprecated widgets.
bool debugHighlightDeprecatedWidgets = false;

/// Causes each [Focus] widget to paint a box around its bounds.
///
/// Different colors indicate different focus states:
///
///  * Green: the node has primary focus.
///  * Blue: the node is in the focus chain but does not
///    have primary focus (i.e., it is an ancestor of the primary focus).
///  * Cyan: the node is focusable and participates in focus traversal.
///  * Yellow: the node skips focus traversal ([FocusNode.skipTraversal] is true)
///    but can still receive focus directly.
///  * Red: the node cannot receive focus ([FocusNode.canRequestFocus] is false).
///
/// Enabling this causes each [Focus] widget to wrap its child with a widget,
/// which can cause state loss if the child is a stateful widget that isn't keyed.
///
/// This has no effect in release builds.
///
/// See also:
///
///  * [FocusNode], which manages focus for a widget subtree.
///  * [debugFocusChanges], which logs to the console when focus changes occur.
bool debugPaintFocusBoxes = false;

/// Returns true if none of the widget library debug variables have been changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// See [the widgets library](widgets/widgets-library.html) for a complete list.
bool debugAssertAllWidgetVarsUnset(String reason) {
  assert(() {
    if (debugPrintRebuildDirtyWidgets ||
        debugPrintBuildScope ||
        debugPrintScheduleBuildForStacks ||
        debugPrintGlobalKeyedWidgetLifecycle ||
        debugProfileBuildsEnabled ||
        debugHighlightDeprecatedWidgets ||
        debugProfileBuildsEnabledUserWidgets ||
        debugPaintFocusBoxes) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}

/// If true, forces the performance overlay to be visible in all instances.
///
/// Used by the `showPerformanceOverlay` VM service extension.
///
/// This variable backs [WidgetsApp.showPerformanceOverlayOverride].
bool debugShowPerformanceOverlayOverride = false;

/// If false, prevents the debug banner from being visible.
///
/// Used by the `debugAllowBanner` VM service extension.
///
/// This is how `flutter run` turns off the banner when you take a screen shot
/// with "s".
///
/// This variable backs [WidgetsApp.debugAllowBannerOverride].
bool debugAllowBannerOverrideFlag = true;
