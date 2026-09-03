// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/foundation/object.dart' show objectRuntimeType;

// Notification, InheritedTheme, CapturedThemes, NotificationListener,
// LayoutChangedNotification and related types.
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

/// An [InheritedWidget] that defines visual properties like colors
/// and text styles, which the [child]'s subtree depends on.
///
/// The [wrap] method is used by [captureAll] and [CapturedThemes.wrap] to
/// construct a widget that will wrap a child in all of the inherited themes
/// which are present in a specified part of the widget tree.
///
/// A widget that's shown in a different context from the one it's built in,
/// like the contents of a new route or an overlay, will be able to see the
/// ancestor inherited themes of the context it was built in.
///
/// {@tool dartpad}
/// This example demonstrates how `InheritedTheme.capture()` can be used
/// to wrap the contents of a new route with the inherited themes that
/// are present when the route was built - but are not present when route
/// is actually shown.
///
/// If the same code is run without `InheritedTheme.capture(), the
/// new route's Text widget will inherit the "something must be wrong"
/// fallback text style, rather than the default text style defined in MyApp.
///
/// ** See code in examples/api/lib/widgets/inherited_theme/inherited_theme.0.dart **
/// {@end-tool}
abstract class InheritedTheme extends InheritedWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.

  const InheritedTheme({super.key, required super.child});

  /// Return a copy of this inherited theme with the specified [child].
  ///
  /// This implementation for [TooltipTheme] is typical:
  ///
  /// ```dart
  /// Widget wrap(BuildContext context, Widget child) {
  ///   return TooltipTheme(data: data, child: child);
  /// }
  /// ```
  Widget wrap(BuildContext context, Widget child);

  /// Returns a widget that will [wrap] `child` in all of the inherited themes
  /// which are present between `context` and the specified `to`
  /// [BuildContext].
  ///
  /// The `to` context must be an ancestor of `context`. If `to` is not
  /// specified, all inherited themes up to the root of the widget tree are
  /// captured.
  ///
  /// After calling this method, the themes present between `context` and `to`
  /// are frozen for the provided `child`. If the themes (or their theme data)
  /// change in the original subtree, those changes will not be visible to
  /// the wrapped `child` - unless this method is called again to re-wrap the
  /// child.
  static Widget captureAll(BuildContext context, Widget child, {BuildContext? to}) {
    return capture(from: context, to: to).wrap(child);
  }

  /// Returns a [CapturedThemes] object that includes all the [InheritedTheme]s
  /// between the given `from` and `to` [BuildContext]s.
  ///
  /// The `to` context must be an ancestor of the `from` context. If `to` is
  /// null, all ancestor inherited themes of `from` up to the root of the
  /// widget tree are captured.
  ///
  /// After calling this method, the themes present between `from` and `to` are
  /// frozen in the returned [CapturedThemes] object. If the themes (or their
  /// theme data) change in the original subtree, those changes will not be
  /// applied to the themes captured in the [CapturedThemes] object - unless
  /// this method is called again to re-capture the updated themes.
  ///
  /// To wrap a [Widget] in the captured themes, call [CapturedThemes.wrap].
  ///
  /// This method can be expensive if there are many widgets between `from` and
  /// `to` (it walks the element tree between those nodes).
  static CapturedThemes capture({required BuildContext from, required BuildContext? to}) {
    if (from == to) {
      // Nothing to capture.
      return CapturedThemes._(const <InheritedTheme>[]);
    }

    final themes = <InheritedTheme>[];
    final themeTypes = <Type>{};
    late bool debugDidFindAncestor;
    assert(() {
      debugDidFindAncestor = to == null;
      return true;
    }());
    from.visitAncestorElements((Element ancestor) {
      if (ancestor == to) {
        assert(() {
          debugDidFindAncestor = true;
          return true;
        }());
        return false;
      }
      if (ancestor case InheritedElement(widget: final InheritedTheme theme)) {
        final Type themeType = theme.runtimeType;
        // Only remember the first theme of any type. This assumes
        // that inherited themes completely shadow ancestors of the
        // same type.
        if (!themeTypes.contains(themeType)) {
          themeTypes.add(themeType);
          themes.add(theme);
        }
      }
      return true;
    });

    assert(
      debugDidFindAncestor,
      'The provided `to` context must be an ancestor of the `from` context.',
    );
    return CapturedThemes._(themes);
  }
}

/// Stores a list of captured [InheritedTheme]s that can be wrapped around a
/// child [Widget].
///
/// Used as return type by [InheritedTheme.capture].
class CapturedThemes {
  CapturedThemes._(this._themes);

  final List<InheritedTheme> _themes;

  /// Wraps a `child` [Widget] in the [InheritedTheme]s captured in this object.
  Widget wrap(Widget child) {
    return _CaptureAll(themes: _themes, child: child);
  }
}

class _CaptureAll extends StatelessWidget {
  const _CaptureAll({required this.themes, required this.child});

  final List<InheritedTheme> themes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = child;
    for (final InheritedTheme theme in themes) {
      wrappedChild = theme.wrap(context, wrappedChild);
    }
    return wrappedChild;
  }
}

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
