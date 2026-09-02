// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'layout_builder.dart';
/// @docImport 'nested_scroll_view.dart';
/// @docImport 'notification_listener.dart';
/// @docImport 'scroll_notification.dart';
/// @docImport 'scroll_view.dart';
/// @docImport 'scrollable.dart';
/// @docImport 'size_changed_layout_notifier.dart';
library;

import 'package:flutter/src/foundation/object.dart' show objectRuntimeType;
import 'package:flutter/src/widgets/framework.dart' show BuildContext;
import 'package:meta/meta.dart' show mustCallSuper, protected;

/// A notification that can bubble up the widget tree.
///
/// You can determine the type of a notification using the `is` operator to
/// check the [runtimeType] of the notification.
///
/// To listen for notifications in a subtree, use a [NotificationListener].
///
/// To send a notification, call [dispatch] on the notification you wish to
/// send. The notification will be delivered to any [NotificationListener]
/// widgets with the appropriate type parameters that are ancestors of the given
/// [BuildContext].
///
/// {@tool dartpad}
/// This example shows a [NotificationListener] widget
/// that listens for [ScrollNotification] notifications. When a scroll
/// event occurs in the [NestedScrollView],
/// this widget is notified. The events could be either a
/// [ScrollStartNotification]or[ScrollEndNotification].
///
/// ** See code in examples/api/lib/widgets/notification_listener/notification.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ScrollNotification] which describes the notification lifecycle.
///  * [ScrollStartNotification] which returns the start position of scrolling.
///  * [ScrollEndNotification] which returns the end position of scrolling.
///  * [NestedScrollView] which creates a nested scroll view.
///
abstract class Notification {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Notification();

  /// Start bubbling this notification at the given build context.
  ///
  /// The notification will be delivered to any [NotificationListener] widgets
  /// with the appropriate type parameters that are ancestors of the given
  /// [BuildContext]. If the [BuildContext] is null, the notification is not
  /// dispatched.
  void dispatch(BuildContext? target) {
    target?.dispatchNotification(this);
  }

  @override
  String toString() {
    final description = <String>[];
    debugFillDescription(description);
    return '${objectRuntimeType(this, 'Notification')}(${description.join(", ")})';
  }

  /// Add additional information to the given description for use by [toString].
  ///
  /// This method makes it easier for subclasses to coordinate to provide a
  /// high-quality [toString] implementation. The [toString] implementation on
  /// the [Notification] base class calls [debugFillDescription] to collect
  /// useful information from subclasses to incorporate into its return value.
  ///
  /// Implementations of this method should start with a call to the inherited
  /// method, as in `super.debugFillDescription(description)`.
  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {}
}
