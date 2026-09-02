// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'layout_builder.dart';
/// @docImport 'nested_scroll_view.dart';
/// @docImport 'scroll_notification.dart';
/// @docImport 'scroll_view.dart';
/// @docImport 'scrollable.dart';
/// @docImport 'size_changed_layout_notifier.dart';
library;

import 'framework.dart';
import 'notification_core.dart';

export 'notification_core.dart';

/// Signature for [Notification] listeners.
///
/// Return true to cancel the notification bubbling. Return false to allow the
/// notification to continue to be dispatched to further ancestors.
///
/// [NotificationListener] is useful when listening scroll events
/// in [ListView],[NestedScrollView],[GridView] or any Scrolling widgets.
/// Used by [NotificationListener.onNotification].
typedef NotificationListenerCallback<T extends Notification> = bool Function(T notification);

/// A widget that listens for [Notification]s bubbling up the tree.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=cAnFbFoGM50}
///
/// Notifications will trigger the [onNotification] callback only if their
/// [runtimeType] is a subtype of `T`.
///
/// To dispatch notifications, use the [Notification.dispatch] method.
class NotificationListener<T extends Notification> extends ProxyWidget {
  /// Creates a widget that listens for notifications.
  const NotificationListener({super.key, required super.child, this.onNotification});

  /// Called when a notification of the appropriate type arrives at this
  /// location in the tree.
  ///
  /// Return true to cancel the notification bubbling. Return false to
  /// allow the notification to continue to be dispatched to further ancestors.
  ///
  /// Notifications vary in terms of when they are dispatched. There are two
  /// main possibilities: dispatch between frames, and dispatch during layout.
  ///
  /// For notifications that dispatch during layout, such as those that inherit
  /// from [LayoutChangedNotification], it is too late to call [State.setState]
  /// in response to the notification (as layout is currently happening in a
  /// descendant, by definition, since notifications bubble up the tree). For
  /// widgets that depend on layout, consider a [LayoutBuilder] instead.
  final NotificationListenerCallback<T>? onNotification;

  @override
  Element createElement() {
    return _NotificationElement<T>(this);
  }
}

/// An element used to host [NotificationListener] elements.
class _NotificationElement<T extends Notification> extends ProxyElement
    with NotifiableElementMixin {
  _NotificationElement(NotificationListener<T> super.widget);

  @override
  bool onNotification(Notification notification) {
    final listener = widget as NotificationListener<T>;
    if (listener.onNotification != null && notification is T) {
      return listener.onNotification!(notification);
    }
    return false;
  }

  @override
  void notifyClients(covariant ProxyWidget oldWidget) {
    // Notification tree does not need to notify clients.
  }
}

/// Indicates that the layout of one of the descendants of the object receiving
/// this notification has changed in some way, and that therefore any
/// assumptions about that layout are no longer valid.
///
/// Useful if, for instance, you're trying to align multiple descendants.
///
/// To listen for notifications in a subtree, use a
/// [NotificationListener<LayoutChangedNotification>].
///
/// To send a notification, call [dispatch] on the notification you wish to
/// send. The notification will be delivered to any [NotificationListener]
/// widgets with the appropriate type parameters that are ancestors of the given
/// [BuildContext].
///
/// In the widgets library, only the [SizeChangedLayoutNotifier] class and
/// [Scrollable] classes dispatch this notification (specifically, they dispatch
/// [SizeChangedLayoutNotification]s and [ScrollNotification]s respectively).
/// Transitions, in particular, do not. Changing one's layout in one's build
/// function does not cause this notification to be dispatched automatically. If
/// an ancestor expects to be notified for any layout change, make sure you
/// either only use widgets that never change layout, or that notify their
/// ancestors when appropriate, or alternatively, dispatch the notifications
/// yourself when appropriate.
///
/// Also, since this notification is sent when the layout is changed, it is only
/// useful for paint effects that depend on the layout. If you were to use this
/// notification to change the build, for instance, you would always be one
/// frame behind, which would look really ugly and laggy.
class LayoutChangedNotification extends Notification {
  /// Create a new [LayoutChangedNotification].
  const LayoutChangedNotification();
}
