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
