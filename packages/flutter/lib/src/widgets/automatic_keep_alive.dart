// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'scroll_delegate.dart';
/// @docImport 'scroll_view.dart';
/// @docImport 'sliver.dart';
/// @docImport 'two_dimensional_viewport.dart';
library;

import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:flutter/src/foundation/assertions.dart' show FlutterError;
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticPropertiesBuilder, DiagnosticsProperty, FlagProperty;
import 'package:flutter/src/rendering/object.dart' show RenderObject;
import 'package:flutter/src/rendering/sliver_multi_box_adaptor.dart' show KeepAliveParentDataMixin;
import 'package:flutter/src/scheduler/binding.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/src/widgets/framework.dart' show AutomaticKeepAliveClientMixin, BuildContext, Element, KeepAliveNotification, NotificationListener, ParentDataElement, ParentDataWidget, State, StatefulWidget, Widget;
import 'package:listen/listen.dart' show Listenable;


/// Allows subtrees to request to be kept alive in lazy lists.
///
/// This widget is like [KeepAlive] but instead of being explicitly configured,
/// it listens to [KeepAliveNotification] messages from the [child] and other
/// descendants.
///
/// The subtree is kept alive whenever there is one or more descendant that has
/// sent a [KeepAliveNotification] and not yet triggered its
/// [KeepAliveNotification.handle].
///
/// To send these notifications, consider using [AutomaticKeepAliveClientMixin].
///
/// The [SliverChildBuilderDelegate] and [SliverChildListDelegate] delegates,
/// used with [SliverList] and [SliverGrid], as well as the scroll view
/// counterparts [ListView] and [GridView], have an `addAutomaticKeepAlives`
/// feature, which is enabled by default. This feature inserts
/// [AutomaticKeepAlive] widgets around each child, which in turn configure
/// [KeepAlive] widgets in response to [KeepAliveNotification]s.
///
/// The same `addAutomaticKeepAlives` feature is supported by
/// [TwoDimensionalChildBuilderDelegate] and [TwoDimensionalChildListDelegate].
///
/// {@tool dartpad}
/// This sample demonstrates how to use the [AutomaticKeepAlive] widget in
/// combination with the [AutomaticKeepAliveClientMixin] to selectively preserve
/// the state of individual items in a scrollable list.
///
/// Normally, widgets in a lazily built list like [ListView.builder] are
/// disposed of when they leave the visible area to maintain performance. This means
/// that any state inside a [StatefulWidget] would be lost unless explicitly
/// preserved.
///
/// In this example, each list item is a [StatefulWidget] that includes a
/// counter and an increment button. To preserve the state of selected items
/// (based on their index), the [AutomaticKeepAlive] widget and
/// [AutomaticKeepAliveClientMixin] are used:
///
/// - The `wantKeepAlive` getter in the item’s state class returns true for
///   even-indexed items, indicating that their state should be preserved.
/// - For odd-indexed items, `wantKeepAlive` returns false, so their state is
///   not preserved when scrolled out of view.
///
/// ** See code in examples/api/lib/widgets/keep_alive/automatic_keep_alive.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AutomaticKeepAliveClientMixin], which is a mixin with convenience
///    methods for clients of [AutomaticKeepAlive]. Used with [State]
///    subclasses.
///  * [KeepAlive] which marks a child as needing to stay alive even when it's
///    in a lazy list that would otherwise remove it.
class AutomaticKeepAlive extends StatefulWidget {
  /// Creates a widget that listens to [KeepAliveNotification]s and maintains a
  /// [KeepAlive] widget appropriately.
  const AutomaticKeepAlive({super.key, required this.child});

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<AutomaticKeepAlive> createState() => _AutomaticKeepAliveState();
}

class _AutomaticKeepAliveState extends State<AutomaticKeepAlive> {
  Map<Listenable, VoidCallback>? _handles;
  // In order to apply parent data out of turn, the child of the KeepAlive
  // widget must be the same across frames.
  late Widget _child;
  bool _keepingAlive = false;

  @override
  void initState() {
    super.initState();
    _updateChild();
  }

  @override
  void didUpdateWidget(AutomaticKeepAlive oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateChild();
  }

  void _updateChild() {
    _child = NotificationListener<KeepAliveNotification>(
      onNotification: _addClient,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (_handles != null) {
      for (final Listenable handle in _handles!.keys) {
        handle.removeListener(_handles![handle]!);
      }
    }
    super.dispose();
  }

  bool _addClient(KeepAliveNotification notification) {
    final Listenable handle = notification.handle;
    _handles ??= <Listenable, VoidCallback>{};
    assert(!_handles!.containsKey(handle));
    _handles![handle] = _createCallback(handle);
    handle.addListener(_handles![handle]!);
    if (!_keepingAlive) {
      _keepingAlive = true;
      final ParentDataElement<KeepAliveParentDataMixin>? childElement = _getChildElement();
      if (childElement != null) {
        // If the child already exists, update it synchronously.
        _updateParentDataOfChild(childElement);
      } else {
        // If the child doesn't exist yet, we got called during the very first
        // build of this subtree. Wait until the end of the frame to update
        // the child when the child is guaranteed to be present.
        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          if (!mounted) {
            return;
          }
          final ParentDataElement<KeepAliveParentDataMixin>? childElement = _getChildElement();
          assert(childElement != null);
          _updateParentDataOfChild(childElement!);
        }, debugLabel: 'AutomaticKeepAlive.updateParentData');
      }
    }
    return false;
  }

  /// Get the [Element] for the only [KeepAlive] child.
  ///
  /// While this widget is guaranteed to have a child, this may return null if
  /// the first build of that child has not completed yet.
  ParentDataElement<KeepAliveParentDataMixin>? _getChildElement() {
    assert(mounted);
    final element = context as Element;
    Element? childElement;
    // We use Element.visitChildren rather than context.visitChildElements
    // because we might be called during build, and context.visitChildElements
    // verifies that it is not called during build. Element.visitChildren does
    // not, instead it assumes that the caller will be careful. (See the
    // documentation for these methods for more details.)
    //
    // Here we know it's safe (with the exception outlined below) because we
    // just received a notification, which we wouldn't be able to do if we
    // hadn't built our child and its child -- our build method always builds
    // the same subtree and it always includes the node we're looking for
    // (KeepAlive) as the parent of the node that reports the notifications
    // (NotificationListener).
    //
    // If we are called during the first build of this subtree the links to the
    // children will not be hooked up yet. In that case this method returns
    // null despite the fact that we will have a child after the build
    // completes. It's the caller's responsibility to deal with this case.
    //
    // (We're only going down one level, to get our direct child.)
    element.visitChildren((Element child) {
      childElement = child;
    });
    assert(childElement == null || childElement is ParentDataElement<KeepAliveParentDataMixin>);
    return childElement as ParentDataElement<KeepAliveParentDataMixin>?;
  }

  void _updateParentDataOfChild(ParentDataElement<KeepAliveParentDataMixin> childElement) {
    childElement.applyWidgetOutOfTurn(build(context) as ParentDataWidget<KeepAliveParentDataMixin>);
  }

  VoidCallback _createCallback(Listenable handle) {
    late final VoidCallback callback;
    return callback = () {
      assert(() {
        if (!mounted) {
          throw FlutterError(
            'AutomaticKeepAlive handle triggered after AutomaticKeepAlive was disposed.\n'
            'Widgets should always trigger their KeepAliveNotification handle when they are '
            'deactivated, so that they (or their handle) do not send spurious events later '
            'when they are no longer in the tree.',
          );
        }
        return true;
      }());
      _handles!.remove(handle);
      handle.removeListener(callback);
      if (_handles!.isEmpty) {
        if (SchedulerBinding.instance.schedulerPhase.index <
            SchedulerPhase.persistentCallbacks.index) {
          // Build/layout haven't started yet so let's just schedule this for
          // the next frame.
          setState(() {
            _keepingAlive = false;
          });
        } else {
          // We were probably notified by a descendant when they were yanked out
          // of our subtree somehow. We're probably in the middle of build or
          // layout, so there's really nothing we can do to clean up this mess
          // short of just scheduling another build to do the cleanup. This is
          // very unfortunate, and means (for instance) that garbage collection
          // of these resources won't happen for another 16ms.
          //
          // The problem is there's really no way for us to distinguish these
          // cases:
          //
          //  * We haven't built yet (or missed out chance to build), but
          //    someone above us notified our descendant and our descendant is
          //    disconnecting from us. If we could mark ourselves dirty we would
          //    be able to clean everything this frame. (This is a pretty
          //    unlikely scenario in practice. Usually things change before
          //    build/layout, not during build/layout.)
          //
          //  * Our child changed, and as our old child went away, it notified
          //    us. We can't setState, since we _just_ built. We can't apply the
          //    parent data information to our child because we don't _have_ a
          //    child at this instant. We really want to be able to change our
          //    mind about how we built, so we can give the KeepAlive widget a
          //    new value, but it's too late.
          //
          //  * A deep descendant in another build scope just got yanked, and in
          //    the process notified us. We could apply new parent data
          //    information, but it may or may not get applied this frame,
          //    depending on whether said child is in the same layout scope.
          //
          //  * A descendant is being moved from one position under us to
          //    another position under us. They just notified us of the removal,
          //    at some point in the future they will notify us of the addition.
          //    We don't want to do anything. (This is why we check that
          //    _handles is still empty below.)
          //
          //  * We're being notified in the paint phase, or even in a post-frame
          //    callback. Either way it is far too late for us to make our
          //    parent lay out again this frame, so the garbage won't get
          //    collected this frame.
          //
          //  * We are being torn out of the tree ourselves, as is our
          //    descendant, and it notified us while it was being deactivated.
          //    We don't need to do anything, but we don't know yet because we
          //    haven't been deactivated yet. (This is why we check mounted
          //    below before calling setState.)
          //
          // Long story short, we have to schedule a new frame and request a
          // frame there, but this is generally a bad practice, and you should
          // avoid it if possible.
          _keepingAlive = false;
          scheduleMicrotask(() {
            if (mounted && _handles!.isEmpty) {
              // If mounted is false, we went away as well, so there's nothing to do.
              // If _handles is no longer empty, then another client (or the same
              // client in a new place) registered itself before we had a chance to
              // turn off keepalive, so again there's nothing to do.
              setState(() {
                assert(!_keepingAlive);
              });
            }
          });
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return KeepAlive(keepAlive: _keepingAlive, child: _child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(
      FlagProperty('_keepingAlive', value: _keepingAlive, ifTrue: 'keeping subtree alive'),
    );
    description.add(
      DiagnosticsProperty<Map<Listenable, VoidCallback>>(
        'handles',
        _handles,
        description: _handles != null
            ? '${_handles!.length} active client${_handles!.length == 1 ? "" : "s"}'
            : null,
        ifNull: 'no notifications ever received',
      ),
    );
  }
}

// KeepAliveNotification, KeepAliveHandle, AutomaticKeepAliveClientMixin are
// now defined in framework.dart.


/// Mark a child as needing to stay alive even when it's in a lazy list that
/// would otherwise remove it.
///
/// This widget is used in [RenderAbstractViewport]s, such as [Viewport] or
/// [TwoDimensionalViewport], to manage the lifecycle of widgets that need to
/// remain alive even when scrolled out of view.
///
/// The [SliverChildBuilderDelegate] and [SliverChildListDelegate] delegates,
/// used with [SliverList] and [SliverGrid], as well as the scroll view
/// counterparts [ListView] and [GridView], have an `addAutomaticKeepAlives`
/// feature, which is enabled by default. This feature inserts
/// [AutomaticKeepAlive] widgets around each child, which in turn configure
/// [KeepAlive] widgets in response to [KeepAliveNotification]s.
///
/// The same `addAutomaticKeepAlives` feature is supported by
/// [TwoDimensionalChildBuilderDelegate] and [TwoDimensionalChildListDelegate].
///
/// Keep-alive behavior can be managed by using [KeepAlive] directly or by
/// relying on notifications. For convenience, [AutomaticKeepAliveClientMixin]
/// may be mixed into a [State] subclass. Further details are available in the
/// documentation for [AutomaticKeepAliveClientMixin].
///
/// {@tool dartpad}
/// This sample demonstrates how to use the [KeepAlive] widget
/// to preserve the state of individual list items in a [ListView] when they are
/// scrolled out of view.
///
/// By default, [ListView.builder] only keeps the widgets currently visible in
/// the viewport alive. When an item scrolls out of view, it may be disposed to
/// free up resources. This can cause the state of [StatefulWidget]s to be lost
/// if not explicitly preserved.
///
/// In this example, each item in the list is a [StatefulWidget] that maintains
/// a counter. Tapping the "+" button increments the counter. To selectively
/// preserve the state, each item is wrapped in a [KeepAlive] widget, with the
/// keepAlive parameter set based on the item's index:
///
/// - For even-indexed items, `keepAlive: true`, so their state is preserved
///   even when scrolled off-screen.
/// - For odd-indexed items, `keepAlive: false`, so their state is discarded
///   when they are no longer visible.
///
/// ** See code in examples/api/lib/widgets/keep_alive/keep_alive.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AutomaticKeepAlive], which allows subtrees to request to be kept alive
///    in lazy lists.
///  * [AutomaticKeepAliveClientMixin], which is a mixin with convenience
///    methods for clients of [AutomaticKeepAlive]. Used with [State]
///    subclasses.
class KeepAlive extends ParentDataWidget<KeepAliveParentDataMixin> {
  /// Marks a child as needing to remain alive.
  const KeepAlive({super.key, required this.keepAlive, required super.child});

  /// Whether to keep the child alive.
  ///
  /// If this is false, it is as if this widget was omitted.
  final bool keepAlive;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is KeepAliveParentDataMixin);
    final parentData = renderObject.parentData! as KeepAliveParentDataMixin;
    if (parentData.keepAlive != keepAlive) {
      // No need to redo layout if it became true.
      parentData.keepAlive = keepAlive;
      if (!keepAlive) {
        renderObject.parent?.markNeedsLayout();
      }
    }
  }

  // We only return true if [keepAlive] is true, because turning _off_ keep
  // alive requires a layout to do the garbage collection (but turning it on
  // requires nothing, since by definition the widget is already alive and won't
  // go away _unless_ we do a layout).
  @override
  bool debugCanApplyOutOfTurn() => keepAlive;

  @override
  Type get debugTypicalAncestorWidgetClass => throw FlutterError(
    'Multiple Types are supported, use debugTypicalAncestorWidgetDescription.',
  );

  @override
  String get debugTypicalAncestorWidgetDescription =>
      'SliverWithKeepAliveWidget or TwoDimensionalViewport';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('keepAlive', keepAlive));
  }
}
