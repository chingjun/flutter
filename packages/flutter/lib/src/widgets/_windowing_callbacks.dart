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

/// A callback to look up the nearest [AutofillGroupState].
///
/// Set by `autofill.dart`, called by `editable_text.dart`.
@internal
Object? Function(Object context)? maybeOfAutofillGroupCallback;

/// A callback to look up the [ModalRoute] for a given [BuildContext].
///
/// Set by `routes.dart`, called by `widget_inspector.dart`.
/// Returns the [ModalRoute] as an Object? (to avoid importing routes.dart).
@internal
Object? Function(Object context)? modalRouteOfCallback;

/// A callback to check if a [ModalRoute] is current.
///
/// Set by `routes.dart`, called by `widget_inspector.dart`.
@internal
bool Function(Object route)? modalRouteIsCurrentCallback;

/// A callback to check if a [ModalRoute] is offstage.
///
/// Set by `routes.dart`, called by `widget_inspector.dart`.
@internal
bool Function(Object route)? modalRouteIsOffstageCallback;

/// A callback to look up the [ScrollNotificationObserverState].
///
/// Set by `scroll_notification_observer.dart`, called by `editable_text.dart`.
@internal
Object? Function(Object context)? scrollNotificationObserverMaybeOfCallback;

/// A callback to map a macOS selector name to an [Intent].
///
/// Set by `default_text_editing_shortcuts.dart`, called by `editable_text.dart`.
@internal
Object? Function(String selectorName)? intentForMacOSSelectorCallback;

/// A callback to add a listener to a [ScrollNotificationObserverState].
///
/// Set by `scroll_notification_observer.dart`, called by `editable_text.dart`.
@internal
void Function(Object observer, Object listener)? scrollNotificationObserverAddListenerCallback;

/// A callback to remove a listener from a [ScrollNotificationObserverState].
///
/// Set by `scroll_notification_observer.dart`, called by `editable_text.dart`.
@internal
void Function(Object observer, Object listener)? scrollNotificationObserverRemoveListenerCallback;

/// A callback to transform [DebugCreator] properties for error reporting.
///
/// Set by `widget_inspector.dart`, called by `binding.dart`.
@internal
Iterable<Object> Function(Iterable<Object> properties)? debugTransformDebugCreatorCallback;

/// A callback to initialize widget inspector service extensions.
///
/// Set by `widget_inspector.dart`, called by `binding.dart`.
@internal
void Function(Object registerServiceExtensionFn)? widgetInspectorInitServiceExtensionsCallback;

/// A callback to perform reassemble on the widget inspector.
///
/// Set by `widget_inspector.dart`, called by `binding.dart`.
@internal
void Function()? widgetInspectorPerformReassembleCallback;

/// A callback to build a [GlowingOverscrollIndicator] widget.
///
/// Set by `overscroll_indicator.dart`, called by `scroll_configuration.dart`.
@internal
Object Function({required Object axisDirection, required Object color, required Object child})? buildGlowingOverscrollIndicatorCallback;

/// A callback to build a [RawScrollbar] widget.
///
/// Set by `scrollbar.dart`, called by `scroll_configuration.dart`.
@internal
Object Function({required Object? controller, required Object child})? buildRawScrollbarCallback;

/// A callback to write scroll state to page storage.
///
/// Set by `page_storage.dart`, called by `scroll_position.dart`.
@internal
void Function(Object context, Object? value)? pageStorageWriteStateCallback;

/// A callback to read scroll state from page storage.
///
/// Set by `page_storage.dart`, called by `scroll_position.dart`.
@internal
Object? Function(Object context)? pageStorageReadStateCallback;

/// A callback to perform accessibility evaluations and return formatted results.
///
/// Set by `_accessibility_evaluations.dart`, called by `binding.dart`.
/// Takes the evaluation type, parameters, and the binding, and returns
/// the formatted result map.
@internal
Future<Map<String, Object>> Function(String type, Map<String, String> parameters, Object binding)? performAccessibilityEvaluationCallback;

/// A getter for the root element used by accessibility evaluations.
///
/// Set by `binding.dart`, used by `_accessibility_evaluations.dart`.
@internal
Object? Function()? accessibilityRootElementGetter;

/// A callback to get [DefaultSelectionStyle] properties from a [BuildContext].
///
/// Returns a record of (selectionColor, mouseCursor).
/// Set by `default_selection_style.dart`, called by `text.dart`.
@internal
({Object? selectionColor, Object? mouseCursor}) Function(Object context)? defaultSelectionStyleOfCallback;

/// The default selection color fallback.
///
/// Set by `default_selection_style.dart`, called by `text.dart`.
@internal
Object? defaultSelectionStyleDefaultColor;

/// A callback to create a [PlatformSelectableRegionContextMenu] widget.
///
/// Set by `_platform_selectable_region_context_menu_io.dart`,
/// called by `selectable_region.dart`.
@internal
Object Function({required Object child})? buildPlatformSelectableRegionContextMenuCallback;

/// A callback for [PlatformSelectableRegionContextMenu.attach].
///
/// Set by `_platform_selectable_region_context_menu_io.dart`,
/// called by `selectable_region.dart`.
@internal
void Function(Object client)? platformSelectableRegionContextMenuAttachCallback;

/// A callback for [PlatformSelectableRegionContextMenu.detach].
///
/// Set by `_platform_selectable_region_context_menu_io.dart`,
/// called by `selectable_region.dart`.
@internal
void Function(Object client)? platformSelectableRegionContextMenuDetachCallback;

/// A callback for [PrimaryScrollController.maybeOf].
///
/// Set by `primary_scroll_controller.dart`, called by `scrollable_helpers.dart`.
@internal
Object? Function(Object context)? primaryScrollControllerMaybeOfCallback;

/// A callback for [PrimaryScrollController.of].
///
/// Set by `primary_scroll_controller.dart`, called by `scrollable_helpers.dart`.
@internal
Object Function(Object context)? primaryScrollControllerOfCallback;
