// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/src/widgets/framework.dart';
import 'package:listen/listen.dart' show ChangeNotifier, Listenable;

// KeepAliveNotification, KeepAliveHandle, AutomaticKeepAliveClientMixin.
/// A notification sent to indicate that a subtree must be kept alive.
///
/// See also:
///
///  * [AutomaticKeepAlive], which listens to these notifications.
///  * [AutomaticKeepAliveClientMixin], which sends these notifications.
///  * [KeepAliveHandle], a convenience class for use with [handle].
class KeepAliveNotification extends Notification {
  /// Creates a notification to indicate that a subtree must be kept alive.
  const KeepAliveNotification(this.handle);

  /// A [Listenable] that will inform its clients when the widget that fired the
  /// notification no longer needs to be kept alive.
  final Listenable handle;
}

/// A [Listenable] which can be manually triggered.
///
/// Used with [KeepAliveNotification] objects as their
/// [KeepAliveNotification.handle].
class KeepAliveHandle extends ChangeNotifier {
  @override
  void dispose() {
    notifyListeners();
    super.dispose();
  }
}

/// A mixin with convenience methods for clients of [AutomaticKeepAlive].
///
/// Subclasses must implement [wantKeepAlive], and their [build] methods must
/// call `super.build` (though the return value should be ignored).
///
/// Then, whenever [wantKeepAlive]'s value changes (or might change), the
/// subclass should call [updateKeepAlive].
@optionalTypeArgs
mixin AutomaticKeepAliveClientMixin<T extends StatefulWidget> on State<T> {
  KeepAliveHandle? _keepAliveHandle;

  void _ensureKeepAlive() {
    assert(_keepAliveHandle == null);
    _keepAliveHandle = KeepAliveHandle();
    KeepAliveNotification(_keepAliveHandle!).dispatch(context);
  }

  void _releaseKeepAlive() {
    _keepAliveHandle!.dispose();
    _keepAliveHandle = null;
  }

  /// Whether the current instance should be kept alive.
  ///
  /// Call [updateKeepAlive] whenever this getter's value changes.
  @protected
  bool get wantKeepAlive;

  /// Ensures that any [AutomaticKeepAlive] ancestors are in a good state, by
  /// firing a [KeepAliveNotification] or triggering the [KeepAliveHandle] as
  /// appropriate.
  @protected
  void updateKeepAlive() {
    if (wantKeepAlive) {
      if (_keepAliveHandle == null) {
        _ensureKeepAlive();
      }
    } else {
      if (_keepAliveHandle != null) {
        _releaseKeepAlive();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (wantKeepAlive) {
      _ensureKeepAlive();
    }
  }

  @override
  void deactivate() {
    if (_keepAliveHandle != null) {
      _releaseKeepAlive();
    }
    super.deactivate();
  }

  @mustCallSuper
  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive && _keepAliveHandle == null) {
      _ensureKeepAlive();
    }
    return const _NullKeepAliveWidget();
  }
}

class _NullKeepAliveWidget extends StatelessWidget {
  const _NullKeepAliveWidget();

  @override
  Widget build(BuildContext context) {
    throw FlutterError(
      'Widgets that mix AutomaticKeepAliveClientMixin into their State must '
      'call super.build() but must ignore the return value of the superclass.',
    );
  }
}
