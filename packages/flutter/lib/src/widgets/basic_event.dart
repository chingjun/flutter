// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticPropertiesBuilder, DiagnosticsProperty, EnumProperty, IterableProperty;
import 'package:flutter/src/foundation/key.dart' show ValueKey;
import 'package:flutter/src/rendering/box.dart' show BoxConstraints, RenderBox;
import 'package:flutter/src/rendering/object.dart' show PaintingContext, RenderObject;
import 'package:flutter/src/rendering/proxy_box.dart' show HitTestBehavior, PointerCancelEventListener, PointerDownEventListener, PointerMoveEventListener, PointerPanZoomEndEventListener, PointerPanZoomStartEventListener, PointerPanZoomUpdateEventListener, PointerSignalEventListener, PointerUpEventListener, RenderAbsorbPointer, RenderIgnorePointer, RenderMetaData, RenderMouseRegion, RenderPointerListener, RenderRepaintBoundary;
import 'package:flutter/src/services/mouse_cursor.dart' show MouseCursor;
import 'package:flutter/src/services/mouse_tracking.dart' show PointerEnterEventListener, PointerExitEventListener, PointerHoverEventListener;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, SingleChildRenderObjectWidget, State, Widget;

// EVENT HANDLING: Listener, MouseRegion, RepaintBoundary, IgnorePointer,
// AbsorbPointer, MetaData.
// EVENT HANDLING

/// A widget that calls callbacks in response to common pointer events.
///
/// It listens to events that can construct gestures, such as when the
/// pointer is pressed, moved, then released or canceled.
///
/// It does not listen to events that are exclusive to mouse, such as when the
/// mouse enters, exits or hovers a region without pressing any buttons. For
/// these events, use [MouseRegion].
///
/// Rather than listening for raw pointer events, consider listening for
/// higher-level gestures using [GestureDetector].
///
/// ## Layout behavior
///
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// If it has a child, this widget defers to the child for sizing behavior. If
/// it does not have a child, it grows to fit the parent instead.
///
/// {@tool dartpad}
/// This example makes a [Container] react to being touched, showing a count of
/// the number of pointer downs and ups.
///
/// ** See code in examples/api/lib/widgets/basic/listener.0.dart **
/// {@end-tool}
class Listener extends SingleChildRenderObjectWidget {
  /// Creates a widget that forwards point events to callbacks.
  ///
  /// The [behavior] argument defaults to [HitTestBehavior.deferToChild].
  const Listener({
    super.key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerHover,
    this.onPointerCancel,
    this.onPointerPanZoomStart,
    this.onPointerPanZoomUpdate,
    this.onPointerPanZoomEnd,
    this.onPointerSignal,
    this.behavior = HitTestBehavior.deferToChild,
    super.child,
  });

  /// Called when a pointer comes into contact with the screen (for touch
  /// pointers), or has its button pressed (for mouse pointers) at this widget's
  /// location.
  final PointerDownEventListener? onPointerDown;

  /// Called when a pointer that triggered an [onPointerDown] changes position.
  final PointerMoveEventListener? onPointerMove;

  /// Called when a pointer that triggered an [onPointerDown] is no longer in
  /// contact with the screen.
  final PointerUpEventListener? onPointerUp;

  /// Called when a pointer that has not triggered an [onPointerDown] changes
  /// position.
  ///
  /// This is only fired for pointers which report their location when not down
  /// (e.g. mouse pointers, but not most touch pointers).
  final PointerHoverEventListener? onPointerHover;

  /// Called when the input from a pointer that triggered an [onPointerDown] is
  /// no longer directed towards this receiver.
  final PointerCancelEventListener? onPointerCancel;

  /// Called when a pan/zoom begins such as from a trackpad gesture.
  final PointerPanZoomStartEventListener? onPointerPanZoomStart;

  /// Called when a pan/zoom is updated.
  final PointerPanZoomUpdateEventListener? onPointerPanZoomUpdate;

  /// Called when a pan/zoom finishes.
  final PointerPanZoomEndEventListener? onPointerPanZoomEnd;

  /// Called when a pointer signal occurs over this object.
  ///
  /// See also:
  ///
  ///  * [PointerSignalEvent], which goes into more detail on pointer signal
  ///    events.
  final PointerSignalEventListener? onPointerSignal;

  /// How to behave during hit testing.
  final HitTestBehavior behavior;

  @override
  RenderPointerListener createRenderObject(BuildContext context) {
    return RenderPointerListener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerHover: onPointerHover,
      onPointerCancel: onPointerCancel,
      onPointerPanZoomStart: onPointerPanZoomStart,
      onPointerPanZoomUpdate: onPointerPanZoomUpdate,
      onPointerPanZoomEnd: onPointerPanZoomEnd,
      onPointerSignal: onPointerSignal,
      behavior: behavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPointerListener renderObject) {
    renderObject
      ..onPointerDown = onPointerDown
      ..onPointerMove = onPointerMove
      ..onPointerUp = onPointerUp
      ..onPointerHover = onPointerHover
      ..onPointerCancel = onPointerCancel
      ..onPointerPanZoomStart = onPointerPanZoomStart
      ..onPointerPanZoomUpdate = onPointerPanZoomUpdate
      ..onPointerPanZoomEnd = onPointerPanZoomEnd
      ..onPointerSignal = onPointerSignal
      ..behavior = behavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final listeners = <String>[
      if (onPointerDown != null) 'down',
      if (onPointerMove != null) 'move',
      if (onPointerUp != null) 'up',
      if (onPointerHover != null) 'hover',
      if (onPointerCancel != null) 'cancel',
      if (onPointerPanZoomStart != null) 'panZoomStart',
      if (onPointerPanZoomUpdate != null) 'panZoomUpdate',
      if (onPointerPanZoomEnd != null) 'panZoomEnd',
      if (onPointerSignal != null) 'signal',
    ];
    properties.add(IterableProperty<String>('listeners', listeners, ifEmpty: '<none>'));
    properties.add(EnumProperty<HitTestBehavior>('behavior', behavior));
  }
}

/// A widget that tracks the movement of mice.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=1oF3pI5umck}
///
/// [MouseRegion] is used
/// when it is needed to compare the list of objects that a mouse pointer is
/// hovering over between this frame and the last frame. This means entering
/// events, exiting events, and mouse cursors.
///
/// To listen to general pointer events, use [Listener], or more preferably,
/// [GestureDetector].
///
/// ## Layout behavior
///
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// If it has a child, this widget defers to the child for sizing behavior. If
/// it does not have a child, it grows to fit the parent instead.
///
/// {@tool dartpad}
/// This example makes a [Container] react to being entered by a mouse
/// pointer, showing a count of the number of entries and exits.
///
/// ** See code in examples/api/lib/widgets/basic/mouse_region.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Listener], a similar widget that tracks pointer events when the pointer
///    has buttons pressed.
class MouseRegion extends SingleChildRenderObjectWidget {
  /// Creates a widget that forwards mouse events to callbacks.
  ///
  /// By default, all callbacks are empty, [cursor] is [MouseCursor.defer], and
  /// [opaque] is true.
  const MouseRegion({
    super.key,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.cursor = MouseCursor.defer,
    this.opaque = true,
    this.hitTestBehavior,
    super.child,
  });

  /// Triggered when a mouse pointer has entered this widget.
  ///
  /// This callback is triggered when the pointer, with or without buttons
  /// pressed, has started to be contained by the region of this widget. More
  /// specifically, the callback is triggered by the following cases:
  ///
  ///  * This widget has appeared under a pointer.
  ///  * This widget has moved to under a pointer.
  ///  * A new pointer has been added to somewhere within this widget.
  ///  * An existing pointer has moved into this widget.
  ///
  /// This callback is not always matched by an [onExit]. If the [MouseRegion]
  /// is unmounted while being hovered by a pointer, the [onExit] of the widget
  /// callback will never called. For more details, see [onExit].
  ///
  /// {@template flutter.widgets.MouseRegion.onEnter.triggerTime}
  /// The time that this callback is triggered is always between frames: either
  /// during the post-frame callbacks, or during the callback of a pointer
  /// event.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [onExit], which is triggered when a mouse pointer exits the region.
  ///  * [MouseTrackerAnnotation.onEnter], which is how this callback is
  ///    internally implemented.
  final PointerEnterEventListener? onEnter;

  /// Triggered when a pointer moves into a position within this widget without
  /// buttons pressed.
  ///
  /// Usually this is only fired for pointers which report their location when
  /// not down (e.g. mouse pointers). Certain devices also fire this event on
  /// single taps in accessibility mode.
  ///
  /// This callback is not triggered by the movement of the widget.
  ///
  /// The time that this callback is triggered is during the callback of a
  /// pointer event, which is always between frames.
  ///
  /// See also:
  ///
  ///  * [Listener.onPointerHover], which does the same job. Prefer using
  ///    [Listener.onPointerHover], since hover events are similar to other regular
  ///    events.
  final PointerHoverEventListener? onHover;

  /// Triggered when a mouse pointer has exited this widget when the widget is
  /// still mounted.
  ///
  /// This callback is triggered when the pointer, with or without buttons
  /// pressed, has stopped being contained by the region of this widget, except
  /// when the exit is caused by the disappearance of this widget. More
  /// specifically, this callback is triggered by the following cases:
  ///
  ///  * A pointer that is hovering this widget has moved away.
  ///  * A pointer that is hovering this widget has been removed.
  ///  * This widget, which is being hovered by a pointer, has moved away.
  ///
  /// And is __not__ triggered by the following case:
  ///
  ///  * This widget, which is being hovered by a pointer, has disappeared.
  ///
  /// This means that a [MouseRegion.onExit] might not be matched by a
  /// [MouseRegion.onEnter].
  ///
  /// This restriction aims to prevent a common misuse: if [State.setState] is
  /// called during [MouseRegion.onExit] without checking whether the widget is
  /// still mounted, an exception will occur. This is because the callback is
  /// triggered during the post-frame phase, at which point the widget has been
  /// unmounted. Since [State.setState] is exclusive to widgets, the restriction
  /// is specific to [MouseRegion], and does not apply to its lower-level
  /// counterparts, [RenderMouseRegion] and [MouseTrackerAnnotation].
  ///
  /// There are a few ways to mitigate this restriction:
  ///
  ///  * If the hover state is completely contained within a widget that
  ///    unconditionally creates this [MouseRegion], then this will not be a
  ///    concern, since after the [MouseRegion] is unmounted the state is no
  ///    longer used.
  ///  * Otherwise, the outer widget very likely has access to the variable that
  ///    controls whether this [MouseRegion] is present. If so, call [onExit] at
  ///    the event that turns the condition from true to false.
  ///  * In cases where the solutions above won't work, you can always
  ///    override [State.dispose] and call [onExit], or create your own widget
  ///    using [RenderMouseRegion].
  ///
  /// {@tool dartpad}
  /// The following example shows a blue rectangular that turns yellow when
  /// hovered. Since the hover state is completely contained within a widget
  /// that unconditionally creates the `MouseRegion`, you can ignore the
  /// aforementioned restriction.
  ///
  /// ** See code in examples/api/lib/widgets/basic/mouse_region.on_exit.0.dart **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// The following example shows a widget that hides its content one second
  /// after being hovered, and also exposes the enter and exit callbacks.
  /// Because the widget conditionally creates the `MouseRegion`, and leaks the
  /// hover state, it needs to take the restriction into consideration. In this
  /// case, since it has access to the event that triggers the disappearance of
  /// the `MouseRegion`, it triggers the exit callback during that event
  /// as well.
  ///
  /// ** See code in examples/api/lib/widgets/basic/mouse_region.on_exit.1.dart **
  /// {@end-tool}
  ///
  /// {@macro flutter.widgets.MouseRegion.onEnter.triggerTime}
  ///
  /// See also:
  ///
  ///  * [onEnter], which is triggered when a mouse pointer enters the region.
  ///  * [RenderMouseRegion] and [MouseTrackerAnnotation.onExit], which are how
  ///    this callback is internally implemented, but without the restriction.
  final PointerExitEventListener? onExit;

  /// The mouse cursor for mouse pointers that are hovering over the region.
  ///
  /// When a mouse enters the region, its cursor will be changed to the [cursor].
  /// When the mouse leaves the region, the cursor will be decided by the region
  /// found at the new location.
  ///
  /// The [cursor] defaults to [MouseCursor.defer], deferring the choice of
  /// cursor to the next region behind it in hit-test order.
  final MouseCursor cursor;

  /// Whether this widget should prevent other [MouseRegion]s visually behind it
  /// from detecting the pointer.
  ///
  /// This changes the list of regions that a pointer hovers, thus affecting how
  /// their [onHover], [onEnter], [onExit], and [cursor] behave.
  ///
  /// If [opaque] is true, this widget will absorb the mouse pointer and
  /// prevent this widget's siblings (or any other widgets that are not
  /// ancestors or descendants of this widget) from detecting the mouse
  /// pointer even when the pointer is within their areas.
  ///
  /// If [opaque] is false, this object will not affect how [MouseRegion]s
  /// behind it behave, which will detect the mouse pointer as long as the
  /// pointer is within their areas.
  ///
  /// This defaults to true.
  final bool opaque;

  /// How to behave during hit testing.
  ///
  /// This defaults to [HitTestBehavior.opaque] if null.
  final HitTestBehavior? hitTestBehavior;

  @override
  RenderMouseRegion createRenderObject(BuildContext context) {
    return RenderMouseRegion(
      onEnter: onEnter,
      onHover: onHover,
      onExit: onExit,
      cursor: cursor,
      opaque: opaque,
      hitTestBehavior: hitTestBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMouseRegion renderObject) {
    renderObject
      ..onEnter = onEnter
      ..onHover = onHover
      ..onExit = onExit
      ..cursor = cursor
      ..opaque = opaque
      ..hitTestBehavior = hitTestBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final listeners = <String>[
      if (onEnter != null) 'enter',
      if (onExit != null) 'exit',
      if (onHover != null) 'hover',
    ];
    properties.add(IterableProperty<String>('listeners', listeners, ifEmpty: '<none>'));
    properties.add(DiagnosticsProperty<MouseCursor>('cursor', cursor, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('opaque', opaque, defaultValue: true));
  }
}

/// A widget that creates a separate display list for its child.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=cVAGLDuc2xE}
///
/// This widget creates a separate display list for its child, which
/// can improve performance if the subtree repaints at different times than
/// the surrounding parts of the tree.
///
/// This is useful since [RenderObject.paint] may be triggered even if its
/// associated [Widget] instances did not change or rebuild. A [RenderObject]
/// will repaint whenever any [RenderObject] that shares the same [Layer] is
/// marked as being dirty and needing paint (see [RenderObject.markNeedsPaint]),
/// such as when an ancestor scrolls or when an ancestor or descendant animates.
///
/// Containing [RenderObject.paint] to parts of the render subtree that are
/// actually visually changing using [RepaintBoundary] explicitly or implicitly
/// is therefore critical to minimizing redundant work and improving the app's
/// performance.
///
/// When a [RenderObject] is flagged as needing to paint via
/// [RenderObject.markNeedsPaint], the nearest ancestor [RenderObject] with
/// [RenderObject.isRepaintBoundary], up to possibly the root of the application,
/// is requested to repaint. That nearest ancestor's [RenderObject.paint] method
/// will cause _all_ of its descendant [RenderObject]s to repaint in the same
/// layer.
///
/// [RepaintBoundary] is therefore used, both while propagating the
/// `markNeedsPaint` flag up the render tree and while traversing down the
/// render tree via [PaintingContext.paintChild], to strategically contain
/// repaints to the render subtree that visually changed for performance. This
/// is done because the [RepaintBoundary] widget creates a [RenderObject] that
/// always has a [Layer], decoupling ancestor render objects from the descendant
/// render objects.
///
/// [RepaintBoundary] has the further side-effect of possibly hinting to the
/// engine that it should further optimize animation performance if the render
/// subtree behind the [RepaintBoundary] is sufficiently complex and is static
/// while the surrounding tree changes frequently. In those cases, the engine
/// may choose to pay a one time cost of rasterizing and caching the pixel
/// values of the subtree for faster future GPU re-rendering speed.
///
/// Several framework widgets insert [RepaintBoundary] widgets to mark natural
/// separation points in applications. For instance, contents in Material Design
/// drawers typically don't change while the drawer opens and closes, so
/// repaints are automatically contained to regions inside or outside the drawer
/// when using the [Drawer] widget during transitions.
///
/// See also:
///
///  * [debugRepaintRainbowEnabled], a debugging flag to help visually monitor
///    render tree repaints in a running app.
///  * [debugProfilePaintsEnabled], a debugging flag to show render tree
///    repaints in Flutter DevTools' timeline view.
class RepaintBoundary extends SingleChildRenderObjectWidget {
  /// Creates a widget that isolates repaints.
  const RepaintBoundary({super.key, super.child});

  /// Wraps the given child in a [RepaintBoundary].
  ///
  /// The key for the [RepaintBoundary] is derived either from the child's key
  /// (if the child has a non-null key) or from the given `childIndex`.
  RepaintBoundary.wrap(Widget child, int childIndex)
    : super(key: ValueKey<Object>(child.key ?? childIndex), child: child);

  /// Wraps each of the given children in [RepaintBoundary]s.
  ///
  /// The key for each [RepaintBoundary] is derived either from the wrapped
  /// child's key (if the wrapped child has a non-null key) or from the wrapped
  /// child's index in the list.
  static List<RepaintBoundary> wrapAll(List<Widget> widgets) => <RepaintBoundary>[
    for (int i = 0; i < widgets.length; ++i) RepaintBoundary.wrap(widgets[i], i),
  ];

  @override
  RenderRepaintBoundary createRenderObject(BuildContext context) => RenderRepaintBoundary();
}

/// A widget that is invisible during hit testing.
///
/// When [ignoring] is true, this widget (and its subtree) is invisible
/// to hit testing. It still consumes space during layout and paints its child
/// as usual. It just cannot be the target of located events, because it returns
/// false from [RenderBox.hitTest].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=qV9pqHWxYgI}
///
/// {@tool dartpad}
/// The following sample has an [IgnorePointer] widget wrapping the `Column`
/// which contains a button.
/// When [ignoring] is set to `true` anything inside the `Column` can
/// not be tapped. When [ignoring] is set to `false` anything
/// inside the `Column` can be tapped.
///
/// ** See code in examples/api/lib/widgets/basic/ignore_pointer.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// The following sample shows an [IgnorePointer] and an [AbsorbPointer] side
/// by side, each wrapping a box that partially covers a tappable target
/// behind it in a stack. Tapping the overlapping region on the
/// [IgnorePointer] side taps the target behind: the [IgnorePointer] is
/// invisible to hit testing, so the pointer event goes through to the next
/// target in the stack. Tapping the same region on the [AbsorbPointer] side
/// does nothing: the [AbsorbPointer] absorbs the pointer events itself, so
/// neither its child nor the target behind it receives the tap.
///
/// ** See code in examples/api/lib/widgets/basic/absorb_pointer.0.dart **
/// {@end-tool}
///
/// ## Semantics
///
/// Using this class may also affect how the semantics subtree underneath is
/// collected.
///
/// {@template flutter.widgets.IgnorePointer.semantics}
/// If [ignoring] is true, pointer-related [SemanticsAction]s are removed from
/// the semantics subtree. Otherwise, the subtree remains untouched.
/// {@endtemplate}
///
/// See also:
///
///  * [AbsorbPointer], which also prevents its children from receiving pointer
///    events but is itself visible to hit testing.
///  * [SliverIgnorePointer], the sliver version of this widget.
class IgnorePointer extends SingleChildRenderObjectWidget {
  /// Creates a widget that is invisible to hit testing.
  const IgnorePointer({super.key, this.ignoring = true, super.child});

  /// Whether this widget is ignored during hit testing.
  ///
  /// Regardless of whether this widget is ignored during hit testing, it will
  /// still consume space during layout and be visible during painting.
  ///
  /// {@macro flutter.widgets.IgnorePointer.semantics}
  ///
  /// Defaults to true.
  final bool ignoring;

  @override
  RenderIgnorePointer createRenderObject(BuildContext context) {
    return RenderIgnorePointer(ignoring: ignoring);
  }

  @override
  void updateRenderObject(BuildContext context, RenderIgnorePointer renderObject) {
    renderObject.ignoring = ignoring;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('ignoring', ignoring));
  }
}

/// A widget that absorbs pointers during hit testing.
///
/// When [absorbing] is true, this widget prevents its subtree from receiving
/// pointer events by terminating hit testing at itself. It still consumes space
/// during layout and paints its child as usual. It just prevents its children
/// from being the target of located events, because it returns true from
/// [RenderBox.hitTest].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=65HoWqBboI8}
///
/// {@tool dartpad}
/// The following sample shows an [AbsorbPointer] and an [IgnorePointer] side
/// by side, each wrapping a box that partially covers a tappable target
/// behind it in a stack. Tapping the overlapping region on the
/// [AbsorbPointer] side does nothing: the [AbsorbPointer] absorbs the pointer
/// events itself, so neither its child nor the target behind it receives the
/// tap. Tapping the same region on the [IgnorePointer] side taps the target
/// behind: the [IgnorePointer] is invisible to hit testing, so the pointer
/// event goes through to the next target in the stack.
///
/// ** See code in examples/api/lib/widgets/basic/absorb_pointer.0.dart **
/// {@end-tool}
///
/// ## Semantics
///
/// Using this class may also affect how the semantics subtree underneath is
/// collected.
///
/// {@template flutter.widgets.AbsorbPointer.semantics}
/// If [absorbing] is true, pointer-related [SemanticsAction]s are removed from
/// the semantics subtree. Otherwise, the subtree remains untouched.
/// {@endtemplate}
///
/// See also:
///
///  * [IgnorePointer], which also prevents its children from receiving pointer
///    events but is itself invisible to hit testing.
class AbsorbPointer extends SingleChildRenderObjectWidget {
  /// Creates a widget that absorbs pointers during hit testing.
  const AbsorbPointer({super.key, this.absorbing = true, super.child});

  /// Whether this widget absorbs pointers during hit testing.
  ///
  /// Regardless of whether this render object absorbs pointers during hit
  /// testing, it will still consume space during layout and be visible during
  /// painting.
  ///
  /// {@macro flutter.widgets.AbsorbPointer.semantics}
  ///
  /// Defaults to true.
  final bool absorbing;

  @override
  RenderAbsorbPointer createRenderObject(BuildContext context) {
    return RenderAbsorbPointer(absorbing: absorbing);
  }

  @override
  void updateRenderObject(BuildContext context, RenderAbsorbPointer renderObject) {
    renderObject.absorbing = absorbing;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
  }
}

/// Holds opaque meta data in the render tree.
///
/// Useful for decorating the render tree with information that will be consumed
/// later. For example, you could store information in the render tree that will
/// be used when the user interacts with the render tree but has no visual
/// impact prior to the interaction.
class MetaData extends SingleChildRenderObjectWidget {
  /// Creates a widget that hold opaque meta data.
  ///
  /// The [behavior] argument defaults to [HitTestBehavior.deferToChild].
  const MetaData({
    super.key,
    this.metaData,
    this.behavior = HitTestBehavior.deferToChild,
    super.child,
  });

  /// Opaque meta data ignored by the render tree.
  final dynamic metaData;

  /// How to behave during hit testing.
  final HitTestBehavior behavior;

  @override
  RenderMetaData createRenderObject(BuildContext context) {
    return RenderMetaData(metaData: metaData, behavior: behavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderMetaData renderObject) {
    renderObject
      ..metaData = metaData
      ..behavior = behavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HitTestBehavior>('behavior', behavior));
    properties.add(DiagnosticsProperty<dynamic>('metaData', metaData));
  }
}
