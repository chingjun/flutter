// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math' as math;
import 'dart:ui' show Clip, FilterQuality, Offset, Size, TextBaseline, TextDirection;
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticLevel, DiagnosticPropertiesBuilder, DiagnosticsProperty, DoubleProperty, EnumProperty;
import 'package:flutter/src/foundation/key.dart' show Key, ValueKey;
import 'package:flutter/src/foundation/object.dart' show objectRuntimeType;
import 'package:flutter/src/painting/alignment.dart' show Alignment, AlignmentDirectional, AlignmentGeometry;
import 'package:flutter/src/painting/basic_types.dart' show Axis;
import 'package:flutter/src/painting/box_fit.dart' show BoxFit;
import 'package:flutter/src/painting/edge_insets.dart' show EdgeInsetsGeometry;
import 'package:flutter/src/rendering/box.dart' show BoxConstraints, RenderBox;
import 'package:flutter/src/rendering/custom_layout.dart' show MultiChildLayoutDelegate, MultiChildLayoutParentData, RenderCustomMultiChildLayoutBox;
import 'package:flutter/src/rendering/flex.dart' show CrossAxisAlignment;
import 'package:flutter/src/rendering/layer.dart' show LayerLink;
import 'package:flutter/src/rendering/object.dart' show RenderObject;
import 'package:flutter/src/rendering/proxy_box.dart' show RenderAspectRatio, RenderConstrainedBox, RenderFittedBox, RenderFollowerLayer, RenderFractionalTranslation, RenderIgnoreBaseline, RenderIntrinsicHeight, RenderIntrinsicWidth, RenderLeaderLayer, RenderLimitedBox, RenderOffstage, RenderTransform;
import 'package:flutter/src/rendering/rotated_box.dart' show RenderRotatedBox;
import 'package:flutter/src/rendering/shifted_box.dart' show BoxConstraintsTransform, OverflowBoxFit, RenderBaseline, RenderConstrainedOverflowBox, RenderConstraintsTransformBox, RenderCustomSingleChildLayoutBox, RenderFractionallySizedOverflowBox, RenderPadding, RenderPositionedBox, RenderSizedOverflowBox, SingleChildLayoutDelegate;
import 'package:flutter/src/widgets/directionality.dart' show Directionality;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, ElementVisitor, MultiChildRenderObjectWidget, ParentDataWidget, SingleChildRenderObjectElement, SingleChildRenderObjectWidget, StatelessWidget, Widget;
import 'package:vector_math/vector_math_64.dart' show Matrix4;

// POSITIONING AND SIZING NODES: Transform, CompositedTransformTarget,
// CompositedTransformFollower, FittedBox, FractionalTranslation, RotatedBox,
// Padding, Align, Center, CustomSingleChildLayout, CustomMultiChildLayout,
// SizedBox, ConstrainedBox, ConstraintsTransformBox, UnconstrainedBox,
// FractionallySizedBox, LimitedBox, OverflowBox, SizedOverflowBox, Offstage,
// AspectRatio, IntrinsicWidth, IntrinsicHeight, Baseline, IgnoreBaseline.
// POSITIONING AND SIZING NODES

/// A widget that applies a transformation before painting its child.
///
/// Unlike [RotatedBox], which applies a rotation prior to layout, this object
/// applies its transformation just prior to painting, which means the
/// transformation is not taken into account when calculating how much space
/// this widget's child (and thus this widget) consumes.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=9z_YNlRlWfA}
///
/// {@tool snippet}
///
/// This example rotates and skews an orange box containing text, keeping the
/// top right corner pinned to its original position.
///
/// ```dart
/// ColoredBox(
///   color: Colors.black,
///   child: Transform(
///     alignment: Alignment.topRight,
///     transform: Matrix4.skewY(0.3)..rotateZ(-math.pi / 12.0),
///     child: Container(
///       padding: const EdgeInsets.all(8.0),
///       color: const Color(0xFFE8581C),
///       child: const Text('Apartment for rent!'),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RotatedBox], which rotates the child widget during layout, not just
///    during painting.
///  * [FractionalTranslation], which applies a translation to the child
///    that is relative to the child's size.
///  * [FittedBox], which sizes and positions its child widget to fit the parent
///    according to a given [BoxFit] discipline.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Transform extends SingleChildRenderObjectWidget {
  /// Creates a widget that transforms its child.
  const Transform({
    super.key,
    required this.transform,
    this.origin,
    this.alignment,
    this.transformHitTests = true,
    this.filterQuality,
    super.child,
  });

  /// Creates a widget that transforms its child using a rotation around the
  /// center.
  ///
  /// The `angle` argument gives the rotation in clockwise radians.
  ///
  /// {@tool snippet}
  ///
  /// This example rotates an orange box containing text around its center by
  /// fifteen degrees.
  ///
  /// ```dart
  /// Transform.rotate(
  ///   angle: -math.pi / 12.0,
  ///   child: Container(
  ///     padding: const EdgeInsets.all(8.0),
  ///     color: const Color(0xFFE8581C),
  ///     child: const Text('Apartment for rent!'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [RotationTransition], which animates changes in rotation smoothly
  ///    over a given duration.
  Transform.rotate({
    super.key,
    required double angle,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    this.filterQuality,
    super.child,
  }) : transform = _computeRotation(angle);

  /// Creates a widget that transforms its child using a translation.
  ///
  /// The `offset` argument specifies the translation.
  ///
  /// {@tool snippet}
  ///
  /// This example shifts the silver-colored child down by fifteen pixels.
  ///
  /// ```dart
  /// Transform.translate(
  ///   offset: const Offset(0.0, 15.0),
  ///   child: Container(
  ///     padding: const EdgeInsets.all(8.0),
  ///     color: const Color(0xFF7F7F7F),
  ///     child: const Text('Quarter'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  Transform.translate({
    super.key,
    required Offset offset,
    this.transformHitTests = true,
    this.filterQuality,
    super.child,
  }) : transform = Matrix4.translationValues(offset.dx, offset.dy, 0.0),
       origin = null,
       alignment = null;

  /// Creates a widget that scales its child along the 2D plane.
  ///
  /// The `scaleX` argument provides the scalar by which to multiply the `x`
  /// axis, and the `scaleY` argument provides the scalar by which to multiply
  /// the `y` axis. Either may be omitted, in which case the scaling factor for
  /// that axis defaults to 1.0.
  ///
  /// For convenience, to scale the child uniformly, instead of providing
  /// `scaleX` and `scaleY`, the `scale` parameter may be used.
  ///
  /// At least one of `scale`, `scaleX`, and `scaleY` must be non-null. If
  /// `scale` is provided, the other two must be null; similarly, if it is not
  /// provided, one of the other two must be provided.
  ///
  /// The [alignment] controls the origin of the scale; by default, this is the
  /// center of the box.
  ///
  /// {@tool snippet}
  ///
  /// This example shrinks an orange box containing text such that each
  /// dimension is half the size it would otherwise be.
  ///
  /// ```dart
  /// Transform.scale(
  ///   scale: 0.5,
  ///   child: Container(
  ///     padding: const EdgeInsets.all(8.0),
  ///     color: const Color(0xFFE8581C),
  ///     child: const Text('Bad Idea Bears'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  /// * [ScaleTransition], which animates changes in scale smoothly over a given
  ///   duration.
  Transform.scale({
    super.key,
    double? scale,
    double? scaleX,
    double? scaleY,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    this.filterQuality,
    super.child,
  }) : assert(
         !(scale == null && scaleX == null && scaleY == null),
         "At least one of 'scale', 'scaleX' and 'scaleY' is required to be non-null",
       ),
       assert(
         scale == null || (scaleX == null && scaleY == null),
         "If 'scale' is non-null then 'scaleX' and 'scaleY' must be left null",
       ),
       transform = Matrix4.diagonal3Values(scale ?? scaleX ?? 1.0, scale ?? scaleY ?? 1.0, 1.0);

  /// Creates a widget that mirrors its child about the widget's center point.
  ///
  /// If `flipX` is true, the child widget will be flipped horizontally. Defaults to false.
  ///
  /// If `flipY` is true, the child widget will be flipped vertically. Defaults to false.
  ///
  /// If both are true, the child widget will be flipped both vertically and horizontally, equivalent to a 180 degree rotation.
  ///
  /// {@tool snippet}
  ///
  /// This example flips the text horizontally.
  ///
  /// ```dart
  /// Transform.flip(
  ///   flipX: true,
  ///   child: const Text('Horizontal Flip'),
  /// )
  /// ```
  /// {@end-tool}
  Transform.flip({
    super.key,
    bool flipX = false,
    bool flipY = false,
    this.origin,
    this.transformHitTests = true,
    this.filterQuality,
    super.child,
  }) : alignment = Alignment.center,
       transform = Matrix4.diagonal3Values(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0, 1.0);

  // Computes a rotation matrix for an angle in radians, attempting to keep rotations
  // at integral values for angles of 0, π/2, π, 3π/2.
  static Matrix4 _computeRotation(double radians) {
    assert(radians.isFinite, 'Cannot compute the rotation matrix for a non-finite angle: $radians');
    if (radians == 0.0) {
      return Matrix4.identity();
    }
    final double sin = math.sin(radians);
    if (sin == 1.0) {
      return _createZRotation(1.0, 0.0);
    }
    if (sin == -1.0) {
      return _createZRotation(-1.0, 0.0);
    }
    final double cos = math.cos(radians);
    if (cos == -1.0) {
      return _createZRotation(0.0, -1.0);
    }
    return _createZRotation(sin, cos);
  }

  static Matrix4 _createZRotation(double sin, double cos) {
    final result = Matrix4.zero();
    result.storage[0] = cos;
    result.storage[1] = sin;
    result.storage[4] = -sin;
    result.storage[5] = cos;
    result.storage[10] = 1.0;
    result.storage[15] = 1.0;
    return result;
  }

  /// The matrix to transform the child by during painting.
  final Matrix4 transform;

  /// The origin of the coordinate system in which to apply the matrix,
  /// described relative to the point given by [alignment].
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  ///
  /// This offset is applied in addition to any [alignment] transformation, so in this
  /// example, the child is rotated about its center, since [alignment]
  /// in [Transform.rotate] defaults to [Alignment.center]:
  ///
  /// ```dart
  /// Transform.rotate(
  ///   angle: math.pi,
  ///   child: Container(
  ///    width: 150.0,
  ///    height: 150.0,
  ///    color: Colors.blue,
  ///  ),
  /// )
  /// ```
  ///
  /// However, in this example the [origin] offset is applied after the
  /// `alignment`, so the child rotates about its bottom-right corner:
  ///
  /// ```dart
  /// Transform.rotate(
  ///   angle: math.pi,
  ///   origin: const Offset(75.0, 75.0),
  ///   child: Container(
  ///    width: 150.0,
  ///    height: 150.0,
  ///    color: Colors.blue,
  ///  ),
  /// )
  /// ```
  final Offset? origin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// When this and [origin] are both null, the origin is the upper-left corner
  /// of this render object.
  /// The default for this field is null for some constructors,
  /// and [Alignment.center] for others.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [origin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? alignment;

  /// Whether to transform registered hits into the child's resulting coordinate system.
  ///
  /// When `true`, hit coordinates within the parent's bounds are transformed to match
  /// where the child appears visually after any transformation such as translation,
  /// rotation, scaling, or skewing.
  ///
  /// When `false`, hit coordinates are not transformed, potentially causing taps to
  /// register in a different location relative to the child's visual position.
  ///
  /// **Important:** Even when [transformHitTests] is true, children cannot
  /// receive events outside the parent's bounds. Hit testing always starts
  /// with the parent's own bounds check in [RenderBox.hitTest]. If the pointer
  /// is outside the parent's bounds, [RenderBox.hitTestChildren] is not
  /// invoked and the children are not considered for hit testing.
  ///
  /// For interactive elements that need to be tappable outside their parent's
  /// original bounds, consider:
  /// - Expanding the parent widget's bounds to encompass the transformed child.
  /// - Using an [OverlayEntry] or [OverlayPortal] to place the widget in an
  ///   [Overlay].
  /// - Restructuring the widget hierarchy.
  ///
  /// {@tool snippet}
  /// This example shows a `Container` that is scaled up. Even though it appears
  /// larger, taps are only registered within the original 100x100 area of the
  /// parent `SizedBox`.
  ///
  /// ```dart
  /// Center(
  ///   child: SizedBox(
  ///     width: 100.0,
  ///     height: 100.0,
  ///     child: Transform.scale(
  ///       scale: 2.0,
  ///       child: GestureDetector(
  ///         onTap: () => debugPrint('Tapped!'),
  ///         child: const ColoredBox(
  ///           color: Colors.purple,
  ///         ),
  ///       ),
  ///     ),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// Defaults to true.
  final bool transformHitTests;

  /// The filter quality with which to apply the transform as a bitmap operation.
  ///
  /// {@template flutter.widgets.Transform.optional.FilterQuality}
  /// The transform will be applied by re-rendering the child if [filterQuality] is null,
  /// otherwise it controls the quality of an [ImageFilter.matrix] applied to a bitmap
  /// rendering of the child.
  /// {@endtemplate}
  final FilterQuality? filterQuality;

  @override
  RenderTransform createRenderObject(BuildContext context) {
    return RenderTransform(
      transform: transform,
      origin: origin,
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
      transformHitTests: transformHitTests,
      filterQuality: filterQuality,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTransform renderObject) {
    renderObject
      ..transform = transform
      ..origin = origin
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context)
      ..transformHitTests = transformHitTests
      ..filterQuality = filterQuality;
  }
}

/// A widget that can be targeted by a [CompositedTransformFollower].
///
/// When this widget is composited during the compositing phase (which comes
/// after the paint phase, as described in [WidgetsBinding.drawFrame]), it
/// updates the [link] object so that any [CompositedTransformFollower] widgets
/// that are subsequently composited in the same frame and were given the same
/// [LayerLink] can position themselves at the same screen location.
///
/// A single [CompositedTransformTarget] can be followed by multiple
/// [CompositedTransformFollower] widgets.
///
/// The [CompositedTransformTarget] must come earlier in the paint order than
/// any linked [CompositedTransformFollower]s.
///
/// {@macro flutter.widgets.CompositedTransformFollower.overlayPortal}
///
/// See also:
///
///  * [CompositedTransformFollower], the widget that can target this one.
///  * [LeaderLayer], the layer that implements this widget's logic.
///  * [OverlayPortal.overlayChildLayoutBuilder], which achieves a similar
///    target-following effect, but also allows the follower to be sized and
///    positioned dynamically based on the target's size and position.
class CompositedTransformTarget extends SingleChildRenderObjectWidget {
  /// Creates a composited transform target widget.
  ///
  /// The [link] property must not be currently used by any other
  /// [CompositedTransformTarget] object that is in the tree.
  const CompositedTransformTarget({super.key, required this.link, super.child});

  /// The link object that connects this [CompositedTransformTarget] with one or
  /// more [CompositedTransformFollower]s.
  ///
  /// The link must not be associated with another [CompositedTransformTarget]
  /// that is also being painted.
  final LayerLink link;

  @override
  RenderLeaderLayer createRenderObject(BuildContext context) {
    return RenderLeaderLayer(link: link);
  }

  @override
  void updateRenderObject(BuildContext context, RenderLeaderLayer renderObject) {
    renderObject.link = link;
  }
}

/// A widget that follows a [CompositedTransformTarget].
///
/// When this widget is composited during the compositing phase (which comes
/// after the paint phase, as described in [WidgetsBinding.drawFrame]), it
/// applies a transformation that brings [targetAnchor] of the linked
/// [CompositedTransformTarget] and [followerAnchor] of this widget together.
/// The two anchor points will have the same global coordinates, unless [offset]
/// is not [Offset.zero], in which case [followerAnchor] will be offset by
/// [offset] in the linked [CompositedTransformTarget]'s coordinate space.
///
/// The [LayerLink] object used as the [link] must be the same object as that
/// provided to the matching [CompositedTransformTarget].
///
/// The [CompositedTransformTarget] must come earlier in the paint order than
/// this [CompositedTransformFollower].
///
/// Hit testing on descendants of this widget will only work if the target
/// position is within the box that this widget's parent considers to be
/// hittable. If the parent covers the screen, this is trivially achievable, so
/// this widget is usually used as the root of an [OverlayEntry] in an app-wide
/// [Overlay] (e.g. as created by the [MaterialApp] widget's [Navigator]).
///
/// {@template flutter.widgets.CompositedTransformFollower.overlayPortal}
/// [CompositedTransformFollower] and [CompositedTransformTarget] are
/// incompatible with [OverlayPortal.overlayChildLayoutBuilder] and thus
/// must not be used together. Consider using
/// [OverlayPortal.overlayChildLayoutBuilder] instead
/// {@endtemplate}
///
/// See also:
///
///  * [CompositedTransformTarget], the widget that this widget can target.
///  * [FollowerLayer], the layer that implements this widget's logic.
///  * [Transform], which applies an arbitrary transform to a child.
///  * [OverlayPortal.overlayChildLayoutBuilder], which achieves a similar
///    target-following effect, but also allows the follower to be sized and
///    positioned dynamically based on the target's size and position.
class CompositedTransformFollower extends SingleChildRenderObjectWidget {
  /// Creates a composited transform target widget.
  ///
  /// If the [link] property was also provided to a [CompositedTransformTarget],
  /// that widget must come earlier in the paint order.
  ///
  /// The [showWhenUnlinked] and [offset] properties must also not be null.
  const CompositedTransformFollower({
    super.key,
    required this.link,
    this.showWhenUnlinked = true,
    this.offset = Offset.zero,
    this.targetAnchor = Alignment.topLeft,
    this.followerAnchor = Alignment.topLeft,
    super.child,
  });

  /// The link object that connects this [CompositedTransformFollower] with a
  /// [CompositedTransformTarget].
  final LayerLink link;

  /// Whether to show the widget's contents when there is no corresponding
  /// [CompositedTransformTarget] with the same [link].
  ///
  /// When the widget is linked, the child is positioned such that it has the
  /// same global position as the linked [CompositedTransformTarget].
  ///
  /// When the widget is not linked, then: if [showWhenUnlinked] is true, the
  /// child is visible and not repositioned; if it is false, then child is
  /// hidden.
  final bool showWhenUnlinked;

  /// The anchor point on the linked [CompositedTransformTarget] that
  /// [followerAnchor] will line up with.
  ///
  /// {@template flutter.widgets.CompositedTransformFollower.targetAnchor}
  /// For example, when [targetAnchor] and [followerAnchor] are both
  /// [Alignment.topLeft], this widget will be top left aligned with the linked
  /// [CompositedTransformTarget]. When [targetAnchor] is
  /// [Alignment.bottomLeft] and [followerAnchor] is [Alignment.topLeft], this
  /// widget will be left aligned with the linked [CompositedTransformTarget],
  /// and its top edge will line up with the [CompositedTransformTarget]'s
  /// bottom edge.
  /// {@endtemplate}
  ///
  /// Defaults to [Alignment.topLeft].
  final Alignment targetAnchor;

  /// The anchor point on this widget that will line up with [targetAnchor] on
  /// the linked [CompositedTransformTarget].
  ///
  /// {@macro flutter.widgets.CompositedTransformFollower.targetAnchor}
  ///
  /// Defaults to [Alignment.topLeft].
  final Alignment followerAnchor;

  /// The additional offset to apply to the [targetAnchor] of the linked
  /// [CompositedTransformTarget] to obtain this widget's [followerAnchor]
  /// position.
  final Offset offset;

  @override
  RenderFollowerLayer createRenderObject(BuildContext context) {
    return RenderFollowerLayer(
      link: link,
      showWhenUnlinked: showWhenUnlinked,
      offset: offset,
      leaderAnchor: targetAnchor,
      followerAnchor: followerAnchor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..showWhenUnlinked = showWhenUnlinked
      ..offset = offset
      ..leaderAnchor = targetAnchor
      ..followerAnchor = followerAnchor;
  }
}

/// Scales and positions its child within itself according to [fit].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=T4Uehk3_wlY}
///
/// {@tool dartpad}
/// In this example, the [Placeholder] is stretched to fill the entire
/// [Container]. Try changing the fit types to see the effect on the layout of
/// the [Placeholder].
///
/// ** See code in examples/api/lib/widgets/basic/fitted_box.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [Transform], which applies an arbitrary transform to its child widget at
///   paint time.
/// * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class FittedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that scales and positions its child within itself according to [fit].
  const FittedBox({
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.none,
    super.child,
  });

  /// How to inscribe the child into the space allocated during layout.
  final BoxFit fit;

  /// How to align the child within its parent's bounds.
  ///
  /// An alignment of (-1.0, -1.0) aligns the child to the top-left corner of its
  /// parent's bounds. An alignment of (1.0, 0.0) aligns the child to the middle
  /// of the right edge of its parent's bounds.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  @override
  RenderFittedBox createRenderObject(BuildContext context) {
    return RenderFittedBox(
      fit: fit,
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFittedBox renderObject) {
    renderObject
      ..fit = fit
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context)
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxFit>('fit', fit));
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
  }
}

/// Applies a translation transformation before painting its child.
///
/// The translation is expressed as a [Offset] scaled to the child's size. For
/// example, an [Offset] with a `dx` of 0.25 will result in a horizontal
/// translation of one quarter the width of the child.
///
/// Hit tests will only be detected inside the bounds of the
/// [FractionalTranslation], even if the contents are offset such that
/// they overflow.
///
/// See also:
///
///  * [Transform], which applies an arbitrary transform to its child widget at
///    paint time.
///  * [Transform.translate], which applies an absolute offset translation
///    transformation instead of an offset scaled to the child.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class FractionalTranslation extends SingleChildRenderObjectWidget {
  /// Creates a widget that translates its child's painting.
  const FractionalTranslation({
    super.key,
    required this.translation,
    this.transformHitTests = true,
    super.child,
  });

  /// The translation to apply to the child, scaled to the child's size.
  ///
  /// For example, an [Offset] with a `dx` of 0.25 will result in a horizontal
  /// translation of one quarter the width of the child.
  final Offset translation;

  /// Whether to apply the translation when performing hit tests.
  final bool transformHitTests;

  @override
  RenderFractionalTranslation createRenderObject(BuildContext context) {
    return RenderFractionalTranslation(
      translation: translation,
      transformHitTests: transformHitTests,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFractionalTranslation renderObject) {
    renderObject
      ..translation = translation
      ..transformHitTests = transformHitTests;
  }
}

/// A widget that rotates its child by a integral number of quarter turns.
///
/// Unlike [Transform], which applies a transform just prior to painting,
/// this object applies its rotation prior to layout, which means the entire
/// rotated box consumes only as much space as required by the rotated child.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=BFE6_UglLfQ}
///
/// {@tool snippet}
///
/// This snippet rotates the child (some [Text]) so that it renders from bottom
/// to top, like an axis label on a graph:
///
/// ```dart
/// const RotatedBox(
///   quarterTurns: 3,
///   child: Text('Hello World!'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Transform], which is a paint effect that allows you to apply an
///    arbitrary transform to a child.
///  * [Transform.rotate], which applies a rotation paint effect.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class RotatedBox extends SingleChildRenderObjectWidget {
  /// A widget that rotates its child.
  const RotatedBox({super.key, required this.quarterTurns, super.child});

  /// The number of clockwise quarter turns the child should be rotated.
  final int quarterTurns;

  @override
  RenderRotatedBox createRenderObject(BuildContext context) =>
      RenderRotatedBox(quarterTurns: quarterTurns);

  @override
  void updateRenderObject(BuildContext context, RenderRotatedBox renderObject) {
    renderObject.quarterTurns = quarterTurns;
  }
}

/// A widget that insets its child by the given padding.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=oD5RtLhhubg}
///
/// When passing layout constraints to its child, padding shrinks the
/// constraints by the given padding, causing the child to layout at a smaller
/// size. Padding then sizes itself to its child's size, inflated by the
/// padding, effectively creating empty space around the child.
///
/// {@tool snippet}
///
/// This snippet creates "Hello World!" [Text] inside a [Card] that is indented
/// by sixteen pixels in each direction.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/widgets/padding.png)
///
/// ```dart
/// const Card(
///   child: Padding(
///     padding: EdgeInsets.all(16.0),
///     child: Text('Hello World!'),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// ## Design discussion
///
/// ### Why use a [Padding] widget rather than a [Container] with a [Container.padding] property?
///
/// There isn't really any difference between the two. If you supply a
/// [Container.padding] argument, [Container] builds a [Padding] widget
/// for you.
///
/// [Container] doesn't implement its properties directly. Instead, [Container]
/// combines a number of simpler widgets together into a convenient package. For
/// example, the [Container.padding] property causes the container to build a
/// [Padding] widget and the [Container.decoration] property causes the
/// container to build a [DecoratedBox] widget. If you find [Container]
/// convenient, feel free to use it. If not, feel free to build these simpler
/// widgets in whatever combination meets your needs.
///
/// In fact, the majority of widgets in Flutter are combinations of other
/// simpler widgets. Composition, rather than inheritance, is the primary
/// mechanism for building up widgets.
///
/// See also:
///
///  * [EdgeInsets], the class that is used to describe the padding dimensions.
///  * [AnimatedPadding], which animates changes in [padding] over a given
///    duration.
///  * [SliverPadding], the sliver equivalent of this widget.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Padding extends SingleChildRenderObjectWidget {
  /// Creates a widget that insets its child.
  const Padding({super.key, required this.padding, super.child});

  /// The amount of space by which to inset the child.
  final EdgeInsetsGeometry padding;

  @override
  RenderPadding createRenderObject(BuildContext context) {
    return RenderPadding(padding: padding, textDirection: Directionality.maybeOf(context));
  }

  @override
  void updateRenderObject(BuildContext context, RenderPadding renderObject) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

/// A widget that aligns its child within itself and optionally sizes itself
/// based on the child's size.
///
/// For example, to align a box at the bottom right, you would pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with an alignment of [Alignment.bottomRight].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=g2E7yl3MwMk}
///
/// This widget will be as big as possible if its dimensions are constrained and
/// [widthFactor] and [heightFactor] are null. If a dimension is unconstrained
/// and the corresponding size factor is null then the widget will match its
/// child's size in that dimension. If a size factor is non-null then the
/// corresponding dimension of this widget will be the product of the child's
/// dimension and the size factor. For example if widthFactor is 2.0 then
/// the width of this widget will always be twice its child's width.
///
/// {@tool snippet}
///
/// The [Align] widget in this example uses one of the defined constants from
/// [Alignment], [Alignment.topRight]. This places the [FlutterLogo] in the top
/// right corner of the parent blue [Container].
///
/// ![A blue square container with the Flutter logo in the top right corner.](https://flutter.github.io/assets-for-api-docs/assets/widgets/align_constant.png)
///
/// ```dart
/// Center(
///   child: Container(
///     height: 120.0,
///     width: 120.0,
///     color: Colors.blue[50],
///     child: const Align(
///       alignment: Alignment.topRight,
///       child: FlutterLogo(
///         size: 60,
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// ## How it works
///
/// The [alignment] property describes a point in the `child`'s coordinate system
/// and a different point in the coordinate system of this widget. The [Align]
/// widget positions the `child` such that both points are lined up on top of
/// each other.
///
/// {@tool snippet}
///
/// The [Alignment] used in the following example defines two points:
///
///   * (0.2 * width of [FlutterLogo]/2 + width of [FlutterLogo]/2, 0.6 * height
///     of [FlutterLogo]/2 + height of [FlutterLogo]/2) = (36.0, 48.0) in the
///     coordinate system of the [FlutterLogo].
///   * (0.2 * width of [Align]/2 + width of [Align]/2, 0.6 * height
///     of [Align]/2 + height of [Align]/2) = (72.0, 96.0) in the
///     coordinate system of the [Align] widget (blue area).
///
/// The [Align] widget positions the [FlutterLogo] such that the two points are on
/// top of each other. In this example, the top left of the [FlutterLogo] will
/// be placed at (72.0, 96.0) - (36.0, 48.0) = (36.0, 48.0) from the top left of
/// the [Align] widget.
///
/// ![A blue square container with the Flutter logo positioned according to the
/// Alignment specified above. A point is marked at the center of the container
/// for the origin of the Alignment coordinate system.](https://flutter.github.io/assets-for-api-docs/assets/widgets/align_alignment.png)
///
/// ```dart
/// Center(
///   child: Container(
///     height: 120.0,
///     width: 120.0,
///     color: Colors.blue[50],
///     child: const Align(
///       alignment: Alignment(0.2, 0.6),
///       child: FlutterLogo(
///         size: 60,
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
///
/// The [FractionalOffset] used in the following example defines two points:
///
///   * (0.2 * width of [FlutterLogo], 0.6 * height of [FlutterLogo]) = (12.0, 36.0)
///     in the coordinate system of the [FlutterLogo].
///   * (0.2 * width of [Align], 0.6 * height of [Align]) = (24.0, 72.0) in the
///     coordinate system of the [Align] widget (blue area).
///
/// The [Align] widget positions the [FlutterLogo] such that the two points are on
/// top of each other. In this example, the top left of the [FlutterLogo] will
/// be placed at (24.0, 72.0) - (12.0, 36.0) = (12.0, 36.0) from the top left of
/// the [Align] widget.
///
/// The [FractionalOffset] class uses a coordinate system with an origin in the top-left
/// corner of the [Container] in difference to the center-oriented system used in
/// the example above with [Alignment].
///
/// ![A blue square container with the Flutter logo positioned according to the
/// FractionalOffset specified above. A point is marked at the top left corner
/// of the container for the origin of the FractionalOffset coordinate system.](https://flutter.github.io/assets-for-api-docs/assets/widgets/align_fractional_offset.png)
///
/// ```dart
/// Center(
///   child: Container(
///     height: 120.0,
///     width: 120.0,
///     color: Colors.blue[50],
///     child: const Align(
///       alignment: FractionalOffset(0.2, 0.6),
///       child: FlutterLogo(
///         size: 60,
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedAlign], which animates changes in [alignment] smoothly over a
///    given duration.
///  * [CustomSingleChildLayout], which uses a delegate to control the layout of
///    a single child.
///  * [Center], which is the same as [Align] but with the [alignment] always
///    set to [Alignment.center].
///  * [FractionallySizedBox], which sizes its child based on a fraction of its
///    own size and positions the child according to an [Alignment] value.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Align extends SingleChildRenderObjectWidget {
  /// Creates an alignment widget.
  ///
  /// The alignment defaults to [Alignment.center].
  const Align({
    super.key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    super.child,
  }) : assert(widthFactor == null || widthFactor >= 0.0),
       assert(heightFactor == null || heightFactor >= 0.0);

  /// How to align the child.
  ///
  /// The x and y values of the [Alignment] control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// See also:
  ///
  ///  * [Alignment], which has more details and some convenience constants for
  ///    common positions.
  ///  * [AlignmentDirectional], which has a horizontal coordinate orientation
  ///    that depends on the [TextDirection].
  final AlignmentGeometry alignment;

  /// If non-null, sets its width to the child's width multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be non-negative.
  final double? widthFactor;

  /// If non-null, sets its height to the child's height multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be non-negative.
  final double? heightFactor;

  @override
  RenderPositionedBox createRenderObject(BuildContext context) {
    return RenderPositionedBox(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPositionedBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
    properties.add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
  }
}

/// A widget that centers its child within itself.
///
/// This widget will be as big as possible if its dimensions are constrained and
/// [widthFactor] and [heightFactor] are null. If a dimension is unconstrained
/// and the corresponding size factor is null then the widget will match its
/// child's size in that dimension. If a size factor is non-null then the
/// corresponding dimension of this widget will be the product of the child's
/// dimension and the size factor. For example if widthFactor is 2.0 then
/// the width of this widget will always be twice its child's width.
///
/// See also:
///
///  * [Align], which lets you arbitrarily position a child within itself,
///    rather than just centering it.
///  * [Row], a widget that displays its children in a horizontal array.
///  * [Column], a widget that displays its children in a vertical array.
///  * [Container], a convenience widget that combines common painting,
///    positioning, and sizing widgets.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Center extends Align {
  /// Creates a widget that centers its child.
  const Center({super.key, super.widthFactor, super.heightFactor, super.child});
}

/// A widget that defers the layout of its single child to a delegate.
///
/// The delegate can determine the layout constraints for the child and can
/// decide where to position the child. The delegate can also determine the size
/// of the parent, but the size of the parent cannot depend on the size of the
/// child.
///
/// See also:
///
///  * [SingleChildLayoutDelegate], which controls the layout of the child.
///  * [Align], which sizes itself based on its child's size and positions
///    the child according to an [Alignment] value.
///  * [FractionallySizedBox], which sizes its child based on a fraction of its own
///    size and positions the child according to an [Alignment] value.
///  * [CustomMultiChildLayout], which uses a delegate to position multiple
///    children.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class CustomSingleChildLayout extends SingleChildRenderObjectWidget {
  /// Creates a custom single child layout.
  const CustomSingleChildLayout({super.key, required this.delegate, super.child});

  /// The delegate that controls the layout of the child.
  final SingleChildLayoutDelegate delegate;

  @override
  RenderCustomSingleChildLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomSingleChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomSingleChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}

/// Metadata for identifying children in a [CustomMultiChildLayout].
///
/// The [MultiChildLayoutDelegate.hasChild],
/// [MultiChildLayoutDelegate.layoutChild], and
/// [MultiChildLayoutDelegate.positionChild] methods use these identifiers.
class LayoutId extends ParentDataWidget<MultiChildLayoutParentData> {
  /// Marks a child with a layout identifier.
  LayoutId({Key? key, required this.id, required super.child})
    : super(key: key ?? ValueKey<Object>(id));

  /// An object representing the identity of this child.
  ///
  /// The [id] needs to be unique among the children that the
  /// [CustomMultiChildLayout] manages.
  final Object id;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is MultiChildLayoutParentData);
    final parentData = renderObject.parentData! as MultiChildLayoutParentData;
    if (parentData.id != id) {
      parentData.id = id;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => CustomMultiChildLayout;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('id', id));
  }
}

/// A widget that uses a delegate to size and position multiple children.
///
/// The delegate can determine the layout constraints for each child and can
/// decide where to position each child. The delegate can also determine the
/// size of the parent, but the size of the parent cannot depend on the sizes of
/// the children.
///
/// [CustomMultiChildLayout] is appropriate when there are complex relationships
/// between the size and positioning of multiple widgets. To control the
/// layout of a single child, [CustomSingleChildLayout] is more appropriate. For
/// simple cases, such as aligning a widget to one or another edge, the [Stack]
/// widget is more appropriate.
///
/// Each child must be wrapped in a [LayoutId] widget to identify the widget for
/// the delegate.
///
/// {@tool dartpad}
/// This example shows a [CustomMultiChildLayout] widget being used to lay out
/// colored blocks from start to finish in a cascade that has some overlap.
///
/// It responds to changes in [Directionality] by re-laying out its children.
///
/// ** See code in examples/api/lib/widgets/basic/custom_multi_child_layout.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [MultiChildLayoutDelegate], for details about how to control the layout of
///    the children.
///  * [CustomSingleChildLayout], which uses a delegate to control the layout of
///    a single child.
///  * [Stack], which arranges children relative to the edges of the container.
///  * [Flow], which provides paint-time control of its children using transform
///    matrices.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class CustomMultiChildLayout extends MultiChildRenderObjectWidget {
  /// Creates a custom multi-child layout.
  const CustomMultiChildLayout({super.key, required this.delegate, super.children});

  /// The delegate that controls the layout of the children.
  final MultiChildLayoutDelegate delegate;

  @override
  RenderCustomMultiChildLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomMultiChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomMultiChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}

/// A box with a specified size.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=EHPu_DzRfqA}
///
/// If given a child, this widget will try to size its child as close to the
/// specified [height] and [width] as possible given the parent's constraints.
/// If either the width or height is null, this widget will try to size itself to
/// match the child's size in that dimension. If the child's size depends on the
/// size of its parent, the height and width must be provided.
///
/// If not given a child, [SizedBox] will try to size itself as close to the
/// specified height and width as possible given the parent's constraints. If
/// [height] or [width] is null or unspecified, it will be treated as zero.
///
/// The [SizedBox.expand] constructor can be used to make a [SizedBox] that
/// sizes itself to fit the parent. It is equivalent to setting [width] and
/// [height] to [double.infinity].
///
/// {@tool snippet}
///
/// This snippet makes the child widget (a [Card] with some [Text]) have the
/// exact size 200x300, parental constraints permitting:
///
/// ```dart
/// const SizedBox(
///   width: 200.0,
///   height: 300.0,
///   child: Card(child: Text('Hello World!')),
/// )
/// ```
/// {@end-tool}
///
/// ## Troubleshooting
///
/// ### Why is my [SizedBox] ignored?
///
/// In Flutter's layout protocol constraints go down, and sizes go up.
/// A widget must respect the constraints passed by its parent. This can cause a
/// [SizedBox]'s values to be ignored:
///
/// {@tool snippet}
///
/// This snippet makes the [ColoredBox] size 200x200. The 100x100 size is
/// ignored because it is incompatible with its parent constraints of exactly
/// 200x200:
///
/// ```dart
/// const SizedBox(
///   width: 200.0,
///   height: 200.0,
///   child: SizedBox( // Ignored!
///     width: 100.0,
///     height: 100.0,
///     child: ColoredBox(color: Colors.green),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// This can be fixed by wrapping the child [SizedBox] in a widget that lets
/// it be any size up to the size of the parent, such as [Center] or [Align].
///
/// See also:
///
///  * [ConstrainedBox], a more generic version of this class that takes
///    arbitrary [BoxConstraints] instead of an explicit width and height.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * [FractionallySizedBox], a widget that sizes its child to a fraction of
///    the total available space.
///  * [AspectRatio], a widget that attempts to fit within the parent's
///    constraints while also sizing its child to match a given aspect ratio.
///  * [FittedBox], which sizes and positions its child widget to fit the parent
///    according to a given [BoxFit] discipline.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
///  * [Understanding constraints](https://docs.flutter.dev/ui/layout/constraints),
///    an in-depth article about layout in Flutter.
class SizedBox extends SingleChildRenderObjectWidget {
  /// Creates a fixed size box. The [width] and [height] parameters can be null
  /// to indicate that the size of the box should not be constrained in
  /// the corresponding dimension.
  const SizedBox({super.key, this.width, this.height, super.child});

  /// Creates a box that will become as large as its parent allows.
  const SizedBox.expand({super.key, super.child})
    : width = double.infinity,
      height = double.infinity;

  /// Creates a box that will become as small as its parent allows.
  const SizedBox.shrink({super.key, super.child}) : width = 0.0, height = 0.0;

  /// Creates a box with the specified size.
  SizedBox.fromSize({super.key, super.child, Size? size})
    : width = size?.width,
      height = size?.height;

  /// Creates a box whose [width] and [height] are equal.
  const SizedBox.square({super.key, super.child, double? dimension})
    : width = dimension,
      height = dimension;

  /// If non-null, requires the child to have exactly this width.
  final double? width;

  /// If non-null, requires the child to have exactly this height.
  final double? height;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: _additionalConstraints);
  }

  BoxConstraints get _additionalConstraints {
    return BoxConstraints.tightFor(width: width, height: height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = _additionalConstraints;
  }

  @override
  String toStringShort() {
    final String type = switch ((width, height)) {
      (double.infinity, double.infinity) => '${objectRuntimeType(this, 'SizedBox')}.expand',
      (0.0, 0.0) => '${objectRuntimeType(this, 'SizedBox')}.shrink',
      _ => objectRuntimeType(this, 'SizedBox'),
    };
    return key == null ? type : '$type-$key';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final DiagnosticLevel level;
    if ((width == double.infinity && height == double.infinity) ||
        (width == 0.0 && height == 0.0)) {
      level = DiagnosticLevel.hidden;
    } else {
      level = DiagnosticLevel.info;
    }
    properties.add(DoubleProperty('width', width, defaultValue: null, level: level));
    properties.add(DoubleProperty('height', height, defaultValue: null, level: level));
  }
}

/// A widget that imposes additional constraints on its child.
///
/// For example, if you wanted [child] to have a minimum height of 50.0 logical
/// pixels, you could use `const BoxConstraints(minHeight: 50.0)` as the
/// [constraints].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=o2KveVr7adg}
///
/// {@tool snippet}
///
/// This snippet makes the child widget (a [Card] with some [Text]) fill the
/// parent, by applying [BoxConstraints.expand] constraints:
///
/// ```dart
/// ConstrainedBox(
///   constraints: const BoxConstraints.expand(),
///   child: const Card(child: Text('Hello World!')),
/// )
/// ```
/// {@end-tool}
///
/// The same behavior can be obtained using the [SizedBox.expand] widget.
///
/// See also:
///
///  * [BoxConstraints], the class that describes constraints.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * [SizedBox], which lets you specify tight constraints by explicitly
///    specifying the height or width.
///  * [FractionallySizedBox], which sizes its child based on a fraction of its
///    own size and positions the child according to an [Alignment] value.
///  * [AspectRatio], a widget that attempts to fit within the parent's
///    constraints while also sizing its child to match a given aspect ratio.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class ConstrainedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that imposes additional constraints on its child.
  ConstrainedBox({super.key, required this.constraints, super.child})
    : assert(constraints.debugAssertIsValid());

  /// The additional constraints to impose on the child.
  final BoxConstraints constraints;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: constraints);
  }

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = constraints;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BoxConstraints>('constraints', constraints, showName: false),
    );
  }
}

/// A container widget that applies an arbitrary transform to its constraints,
/// and sizes its child using the resulting [BoxConstraints], optionally
/// clipping, or treating the overflow as an error.
///
/// This container sizes its child using a [BoxConstraints] created by applying
/// [constraintsTransform] to its own constraints. This container will then
/// attempt to adopt the same size, within the limits of its own constraints. If
/// it ends up with a different size, it will align the child based on
/// [alignment]. If the container cannot expand enough to accommodate the entire
/// child, the child will be clipped if [clipBehavior] is not [Clip.none].
///
/// In debug mode, if [clipBehavior] is [Clip.none] and the child overflows the
/// container, a warning will be printed on the console, and black and yellow
/// striped areas will appear where the overflow occurs.
///
/// When [child] is null, this widget becomes as small as possible and never
/// overflows.
///
/// This widget can be used to ensure some of [child]'s natural dimensions are
/// honored, and get an early warning otherwise during development. For
/// instance, if [child] requires a minimum height to fully display its content,
/// [constraintsTransform] can be set to [maxHeightUnconstrained], so that if
/// the parent [RenderObject] fails to provide enough vertical space, a warning
/// will be displayed in debug mode, while still allowing [child] to grow
/// vertically:
///
/// {@tool snippet}
///
/// In the following snippet, the [Card] is guaranteed to be at least as tall as
/// its "natural" height. Unlike [UnconstrainedBox], it will become taller if
/// its "natural" height is smaller than 40 px. If the [Container] isn't high
/// enough to show the full content of the [Card], in debug mode a warning will
/// be given.
///
/// ```dart
/// Container(
///   constraints: const BoxConstraints(minHeight: 40, maxHeight: 100),
///   alignment: Alignment.center,
///   child: const ConstraintsTransformBox(
///     constraintsTransform: ConstraintsTransformBox.maxHeightUnconstrained,
///     child: Card(child: Text('Hello World!')),
///   )
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ConstrainedBox], which renders a box which imposes constraints
///    on its child.
///  * [OverflowBox], a widget that imposes additional constraints on its child,
///    and allows the child to overflow itself.
///  * [UnconstrainedBox] which allows its children to render themselves
///    unconstrained and expands to fit them.
class ConstraintsTransformBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that uses a function to transform the constraints it
  /// passes to its child. If the child overflows the parent's constraints, a
  /// warning will be given in debug mode.
  ///
  /// The `debugTransformType` argument adds a debug label to this widget.
  ///
  /// The `alignment`, `clipBehavior` and `constraintsTransform` arguments must
  /// not be null.
  const ConstraintsTransformBox({
    super.key,
    super.child,
    this.textDirection,
    this.alignment = Alignment.center,
    required this.constraintsTransform,
    this.clipBehavior = Clip.none,
    String debugTransformType = '',
  }) : _debugTransformLabel = debugTransformType;

  /// A [BoxConstraintsTransform] that always returns its argument as-is (i.e.,
  /// it is an identity function).
  ///
  /// The [ConstraintsTransformBox] becomes a proxy widget that has no effect on
  /// layout if [constraintsTransform] is set to this.
  static BoxConstraints unmodified(BoxConstraints constraints) => constraints;

  /// A [BoxConstraintsTransform] that always returns a [BoxConstraints] that
  /// imposes no constraints on either dimension (i.e. `const BoxConstraints()`).
  ///
  /// Setting [constraintsTransform] to this allows [child] to render at its
  /// "natural" size (equivalent to an [UnconstrainedBox] with `constrainedAxis`
  /// set to null).
  static BoxConstraints unconstrained(BoxConstraints constraints) => const BoxConstraints();

  /// A [BoxConstraintsTransform] that removes the width constraints from the
  /// input.
  ///
  /// Setting [constraintsTransform] to this allows [child] to render at its
  /// "natural" width (equivalent to an [UnconstrainedBox] with
  /// `constrainedAxis` set to [Axis.horizontal]).
  static BoxConstraints widthUnconstrained(BoxConstraints constraints) =>
      constraints.heightConstraints();

  /// A [BoxConstraintsTransform] that removes the height constraints from the
  /// input.
  ///
  /// Setting [constraintsTransform] to this allows [child] to render at its
  /// "natural" height (equivalent to an [UnconstrainedBox] with
  /// `constrainedAxis` set to [Axis.vertical]).
  static BoxConstraints heightUnconstrained(BoxConstraints constraints) =>
      constraints.widthConstraints();

  /// A [BoxConstraintsTransform] that removes the `maxHeight` constraint from
  /// the input.
  ///
  /// Setting [constraintsTransform] to this allows [child] to render at its
  /// "natural" height or the `minHeight` of the incoming [BoxConstraints],
  /// whichever is larger.
  static BoxConstraints maxHeightUnconstrained(BoxConstraints constraints) =>
      constraints.copyWith(maxHeight: double.infinity);

  /// A [BoxConstraintsTransform] that removes the `maxWidth` constraint from
  /// the input.
  ///
  /// Setting [constraintsTransform] to this allows [child] to render at its
  /// "natural" width or the `minWidth` of the incoming [BoxConstraints],
  /// whichever is larger.
  static BoxConstraints maxWidthUnconstrained(BoxConstraints constraints) =>
      constraints.copyWith(maxWidth: double.infinity);

  /// A [BoxConstraintsTransform] that removes both the `maxWidth` and the
  /// `maxHeight` constraints from the input.
  ///
  /// Setting [constraintsTransform] to this allows [child] to render at least
  /// its "natural" size, and grow along an axis if the incoming
  /// [BoxConstraints] has a larger minimum constraint on that axis.
  static BoxConstraints maxUnconstrained(BoxConstraints constraints) =>
      constraints.copyWith(maxWidth: double.infinity, maxHeight: double.infinity);

  static final Map<BoxConstraintsTransform, String> _debugKnownTransforms =
      <BoxConstraintsTransform, String>{
        unmodified: 'unmodified',
        unconstrained: 'unconstrained',
        widthUnconstrained: 'width constraints removed',
        heightUnconstrained: 'height constraints removed',
        maxWidthUnconstrained: 'maxWidth constraint removed',
        maxHeightUnconstrained: 'maxHeight constraint removed',
        maxUnconstrained: 'maxWidth & maxHeight constraints removed',
      };

  /// The text direction to use when interpreting the [alignment] if it is an
  /// [AlignmentDirectional].
  ///
  /// Defaults to null, in which case [Directionality.maybeOf] is used to determine
  /// the text direction.
  final TextDirection? textDirection;

  /// The alignment to use when laying out the child, if it has a different size
  /// than this widget.
  ///
  /// If this is an [AlignmentDirectional], then [textDirection] must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [Alignment] for non-[Directionality]-aware alignments.
  ///  * [AlignmentDirectional] for [Directionality]-aware alignments.
  final AlignmentGeometry alignment;

  /// {@template flutter.widgets.constraintsTransform}
  /// The function used to transform the incoming [BoxConstraints], to size
  /// [child].
  ///
  /// The function must return a [BoxConstraints] that is
  /// [BoxConstraints.isNormalized].
  ///
  /// See [ConstraintsTransformBox] for predefined common
  /// [BoxConstraintsTransform]s.
  /// {@endtemplate}
  final BoxConstraintsTransform constraintsTransform;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// {@template flutter.widgets.ConstraintsTransformBox.clipBehavior}
  /// In debug mode, if [clipBehavior] is [Clip.none], and the child overflows
  /// its constraints, a warning will be printed on the console, and black and
  /// yellow striped areas will appear where the overflow occurs. For other
  /// values of [clipBehavior], the contents are clipped accordingly.
  /// {@endtemplate}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  final String _debugTransformLabel;

  @override
  RenderConstraintsTransformBox createRenderObject(BuildContext context) {
    return RenderConstraintsTransformBox(
      textDirection: textDirection ?? Directionality.maybeOf(context),
      alignment: alignment,
      constraintsTransform: constraintsTransform,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderConstraintsTransformBox renderObject,
  ) {
    renderObject
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..constraintsTransform = constraintsTransform
      ..alignment = alignment
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));

    final String? debugTransformLabel = _debugTransformLabel.isNotEmpty
        ? _debugTransformLabel
        : _debugKnownTransforms[constraintsTransform];

    if (debugTransformLabel != null) {
      properties.add(DiagnosticsProperty<String>('constraints transform', debugTransformLabel));
    }
  }
}

/// A widget that imposes no constraints on its child, allowing it to render
/// at its "natural" size.
///
/// This allows a child to render at the size it would render if it were alone
/// on an infinite canvas with no constraints. This container will then attempt
/// to adopt the same size, within the limits of its own constraints. If it ends
/// up with a different size, it will align the child based on [alignment].
/// If the box cannot expand enough to accommodate the entire child, the
/// child will be clipped.
///
/// In debug mode, if the child overflows the container, a warning will be
/// printed on the console, and black and yellow striped areas will appear where
/// the overflow occurs.
///
/// See also:
///
///  * [ConstrainedBox], for a box which imposes constraints on its child.
///  * [Align], which loosens the constraints given to the child rather than
///    removing them entirely.
///  * [Container], a convenience widget that combines common painting,
///    positioning, and sizing widgets.
///  * [OverflowBox], a widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow
///    the parent.
///  * [ConstraintsTransformBox], a widget that sizes its child using a
///    transformed [BoxConstraints], and shows a warning if the child overflows
///    in debug mode.
class UnconstrainedBox extends StatelessWidget {
  /// Creates a widget that imposes no constraints on its child, allowing it to
  /// render at its "natural" size. If the child overflows the parents
  /// constraints, a warning will be given in debug mode.
  const UnconstrainedBox({
    super.key,
    this.child,
    this.textDirection,
    this.alignment = Alignment.center,
    this.constrainedAxis,
    this.clipBehavior = Clip.none,
  });

  /// The text direction to use when interpreting the [alignment] if it is an
  /// [AlignmentDirectional].
  final TextDirection? textDirection;

  /// The alignment to use when laying out the child.
  ///
  /// If this is an [AlignmentDirectional], then [textDirection] must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [Alignment] for non-[Directionality]-aware alignments.
  ///  * [AlignmentDirectional] for [Directionality]-aware alignments.
  final AlignmentGeometry alignment;

  /// The axis to retain constraints on, if any.
  ///
  /// If not set, or set to null (the default), neither axis will retain its
  /// constraints. If set to [Axis.vertical], then vertical constraints will
  /// be retained, and if set to [Axis.horizontal], then horizontal constraints
  /// will be retained.
  final Axis? constrainedAxis;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  BoxConstraintsTransform _axisToTransform(Axis? constrainedAxis) {
    return switch (constrainedAxis) {
      Axis.horizontal => ConstraintsTransformBox.heightUnconstrained,
      Axis.vertical => ConstraintsTransformBox.widthUnconstrained,
      null => ConstraintsTransformBox.unconstrained,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ConstraintsTransformBox(
      textDirection: textDirection,
      alignment: alignment,
      clipBehavior: clipBehavior,
      constraintsTransform: _axisToTransform(constrainedAxis),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<Axis>('constrainedAxis', constrainedAxis, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}

/// A widget that sizes its child to a fraction of the total available space.
/// For more details about the layout algorithm, see
/// [RenderFractionallySizedOverflowBox].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=PEsY654EGZ0}
///
/// {@tool dartpad}
/// This sample shows a [FractionallySizedBox] whose one child is 50% of
/// the box's size per the width and height factor parameters, and centered
/// within that box by the alignment parameter.
///
/// ** See code in examples/api/lib/widgets/basic/fractionally_sized_box.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Align], which sizes itself based on its child's size and positions
///    the child according to an [Alignment] value.
///  * [OverflowBox], a widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow the
///    parent.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class FractionallySizedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that sizes its child to a fraction of the total available space.
  ///
  /// If non-null, the [widthFactor] and [heightFactor] arguments must be
  /// non-negative.
  const FractionallySizedBox({
    super.key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    super.child,
  }) : assert(widthFactor == null || widthFactor >= 0.0),
       assert(heightFactor == null || heightFactor >= 0.0);

  /// {@template flutter.widgets.basic.fractionallySizedBox.widthFactor}
  /// If non-null, the fraction of the incoming width given to the child.
  ///
  /// If non-null, the child is given a tight width constraint that is the max
  /// incoming width constraint multiplied by this factor.
  ///
  /// If null, the incoming width constraints are passed to the child
  /// unmodified.
  /// {@endtemplate}
  final double? widthFactor;

  /// {@template flutter.widgets.basic.fractionallySizedBox.heightFactor}
  /// If non-null, the fraction of the incoming height given to the child.
  ///
  /// If non-null, the child is given a tight height constraint that is the max
  /// incoming height constraint multiplied by this factor.
  ///
  /// If null, the incoming height constraints are passed to the child
  /// unmodified.
  /// {@endtemplate}
  final double? heightFactor;

  /// {@template flutter.widgets.basic.fractionallySizedBox.alignment}
  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  /// {@endtemplate}
  final AlignmentGeometry alignment;

  @override
  RenderFractionallySizedOverflowBox createRenderObject(BuildContext context) {
    return RenderFractionallySizedOverflowBox(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFractionallySizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
    properties.add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
  }
}

/// A box that limits its size only when it's unconstrained.
///
/// If this widget's maximum width is unconstrained then its child's width is
/// limited to [maxWidth]. Similarly, if this widget's maximum height is
/// unconstrained then its child's height is limited to [maxHeight].
///
/// This has the effect of giving the child a natural dimension in unbounded
/// environments. For example, by providing a [maxHeight] to a widget that
/// normally tries to be as big as possible, the widget will normally size
/// itself to fit its parent, but when placed in a vertical list, it will take
/// on the given height.
///
/// This is useful when composing widgets that normally try to match their
/// parents' size, so that they behave reasonably in lists (which are
/// unbounded).
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=uVki2CIzBTs}
///
/// See also:
///
///  * [ConstrainedBox], which applies its constraints in all cases, not just
///    when the incoming constraints are unbounded.
///  * [SizedBox], which lets you specify tight constraints by explicitly
///    specifying the height or width.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class LimitedBox extends SingleChildRenderObjectWidget {
  /// Creates a box that limits its size only when it's unconstrained.
  ///
  /// The [maxWidth] and [maxHeight] arguments must not be negative.
  const LimitedBox({
    super.key,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    super.child,
  }) : assert(maxWidth >= 0.0),
       assert(maxHeight >= 0.0);

  /// The maximum width limit to apply in the absence of a
  /// [BoxConstraints.maxWidth] constraint.
  final double maxWidth;

  /// The maximum height limit to apply in the absence of a
  /// [BoxConstraints.maxHeight] constraint.
  final double maxHeight;

  @override
  RenderLimitedBox createRenderObject(BuildContext context) {
    return RenderLimitedBox(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  @override
  void updateRenderObject(BuildContext context, RenderLimitedBox renderObject) {
    renderObject
      ..maxWidth = maxWidth
      ..maxHeight = maxHeight;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('maxWidth', maxWidth, defaultValue: double.infinity));
    properties.add(DoubleProperty('maxHeight', maxHeight, defaultValue: double.infinity));
  }
}

/// A widget that imposes different constraints on its child than it gets
/// from its parent, possibly allowing the child to overflow the parent.
///
/// {@tool dartpad}
/// This example shows how an [OverflowBox] is used, and what its effect is.
///
/// ** See code in examples/api/lib/widgets/basic/overflowbox.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [RenderConstrainedOverflowBox] for details about how [OverflowBox] is
///    rendered.
///  * [SizedOverflowBox], a widget that is a specific size but passes its
///    original constraints through to its child, which may then overflow.
///  * [ConstrainedBox], a widget that imposes additional constraints on its
///    child.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * [SizedBox], a box with a specified size.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class OverflowBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that lets its child overflow itself.
  const OverflowBox({
    super.key,
    this.alignment = Alignment.center,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.fit = OverflowBoxFit.max,
    super.child,
  });

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The minimum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double? minWidth;

  /// The maximum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double? maxWidth;

  /// The minimum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double? minHeight;

  /// The maximum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double? maxHeight;

  /// The way to size the render object.
  ///
  /// This only affects scenario when the child does not indeed overflow.
  /// If set to [OverflowBoxFit.deferToChild], the render object will size itself to
  /// match the size of its child within the constraints of its parent or be
  /// as small as the parent allows if no child is set. If set to
  /// [OverflowBoxFit.max] (the default), the render object will size itself
  /// to be as large as the parent allows.
  final OverflowBoxFit fit;

  @override
  RenderConstrainedOverflowBox createRenderObject(BuildContext context) {
    return RenderConstrainedOverflowBox(
      alignment: alignment,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      fit: fit,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..minWidth = minWidth
      ..maxWidth = maxWidth
      ..minHeight = minHeight
      ..maxHeight = maxHeight
      ..fit = fit
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DoubleProperty('minWidth', minWidth, defaultValue: null));
    properties.add(DoubleProperty('maxWidth', maxWidth, defaultValue: null));
    properties.add(DoubleProperty('minHeight', minHeight, defaultValue: null));
    properties.add(DoubleProperty('maxHeight', maxHeight, defaultValue: null));
    properties.add(EnumProperty<OverflowBoxFit>('fit', fit));
  }
}

/// A widget that is a specific size but passes its original constraints
/// through to its child, which may then overflow.
///
/// See also:
///
///  * [OverflowBox], A widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow the
///    parent.
///  * [ConstrainedBox], a widget that imposes additional constraints on its
///    child.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class SizedOverflowBox extends SingleChildRenderObjectWidget {
  /// Creates a widget of a given size that lets its child overflow.
  const SizedOverflowBox({
    super.key,
    required this.size,
    this.alignment = Alignment.center,
    super.child,
  });

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The size this widget should attempt to be.
  final Size size;

  @override
  RenderSizedOverflowBox createRenderObject(BuildContext context) {
    return RenderSizedOverflowBox(
      alignment: alignment,
      requestedSize: size,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..requestedSize = size
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DiagnosticsProperty<Size>('size', size, defaultValue: null));
  }
}

/// A widget that lays the child out as if it was in the tree, but without
/// painting anything, without making the child available for hit testing, and
/// without taking any room in the parent.
///
/// Offstage children are still active: they can receive focus and have keyboard
/// input directed to them.
///
/// Animations continue to run in offstage children, and therefore use battery
/// and CPU time, regardless of whether the animations end up being visible.
///
/// [Offstage] can be used to measure the dimensions of a widget without
/// bringing it on screen (yet). To hide a widget from view while it is not
/// needed, prefer removing the widget from the tree entirely rather than
/// keeping it alive in an [Offstage] subtree.
///
/// {@tool dartpad}
/// This example shows a [FlutterLogo] widget when the `_offstage` member field
/// is false, and hides it without any room in the parent when it is true. When
/// offstage, this app displays a button to get the logo size, which will be
/// displayed in a [SnackBar].
///
/// ** See code in examples/api/lib/widgets/basic/offstage.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Visibility], which can hide a child more efficiently (albeit less
///    subtly).
///  * [TickerMode], which can be used to disable animations in a subtree.
///  * [SliverOffstage], the sliver version of this widget.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Offstage extends SingleChildRenderObjectWidget {
  /// Creates a widget that visually hides its child.
  const Offstage({super.key, this.offstage = true, super.child});

  /// Whether the child is hidden from the rest of the tree.
  ///
  /// If true, the child is laid out as if it was in the tree, but without
  /// painting anything, without making the child available for hit testing, and
  /// without taking any room in the parent.
  ///
  /// Offstage children are still active: they can receive focus and have keyboard
  /// input directed to them.
  ///
  /// Animations continue to run in offstage children, and therefore use battery
  /// and CPU time, regardless of whether the animations end up being visible.
  ///
  /// If false, the child is included in the tree as normal.
  final bool offstage;

  @override
  RenderOffstage createRenderObject(BuildContext context) => RenderOffstage(offstage: offstage);

  @override
  void updateRenderObject(BuildContext context, RenderOffstage renderObject) {
    renderObject.offstage = offstage;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('offstage', offstage));
  }

  @override
  SingleChildRenderObjectElement createElement() => _OffstageElement(this);
}

class _OffstageElement extends SingleChildRenderObjectElement {
  _OffstageElement(Offstage super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (!(widget as Offstage).offstage) {
      super.debugVisitOnstageChildren(visitor);
    }
  }
}

/// A widget that attempts to size the child to a specific aspect ratio.
///
/// The aspect ratio is expressed as a ratio of width to height. For example, a
/// 16:9 width:height aspect ratio would have a value of 16.0/9.0.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=XcnP3_mO_Ms}
///
/// The [AspectRatio] widget uses a finite iterative process to compute the
/// appropriate constraints for the child, and then lays the child out a single
/// time with those constraints. This iterative process is efficient and does
/// not require multiple layout passes.
///
/// The widget first tries the largest width permitted by the layout
/// constraints, and determines the height of the widget by applying the given
/// aspect ratio to the width, expressed as a ratio of width to height.
///
/// If the maximum width is infinite, the initial width is determined
/// by applying the aspect ratio to the maximum height instead.
///
/// The widget then examines if the computed dimensions are compatible with the
/// parent's constraints; if not, the dimensions are recomputed a second time,
/// taking those constraints into account.
///
/// If the widget does not find a feasible size after consulting each
/// constraint, the widget will eventually select a size for the child that
/// meets the layout constraints but fails to meet the aspect ratio constraints.
///
/// {@tool dartpad}
/// This examples shows how [AspectRatio] sets the width when its parent's width
/// constraint is infinite. Since the parent's allowed height is a fixed value,
/// the actual width is determined via the given [aspectRatio].
///
/// In this example, the height is fixed at 100.0 and the aspect ratio is set to
/// 16 / 9, making the width 100.0 / 9 * 16.
///
/// ** See code in examples/api/lib/widgets/basic/aspect_ratio.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This second example uses an aspect ratio of 2.0, and layout constraints that
/// require the width to be between 0.0 and 100.0, and the height to be between
/// 0.0 and 100.0. The widget selects a width of 100.0 (the biggest allowed) and
/// a height of 50.0 (to match the aspect ratio).
///
/// ** See code in examples/api/lib/widgets/basic/aspect_ratio.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This third example is similar to the second, but with the aspect ratio set
/// to 0.5. The widget still selects a width of 100.0 (the biggest allowed), and
/// attempts to use a height of 200.0. Unfortunately, that violates the
/// constraints because the child can be at most 100.0 pixels tall. The widget
/// will then take that value and apply the aspect ratio again to obtain a width
/// of 50.0. That width is permitted by the constraints and the child receives a
/// width of 50.0 and a height of 100.0. If the width were not permitted, the
/// widget would continue iterating through the constraints.
///
/// ** See code in examples/api/lib/widgets/basic/aspect_ratio.2.dart **
/// {@end-tool}
///
/// ## Setting the aspect ratio in unconstrained situations
///
/// When using a widget such as [FittedBox], the constraints are unbounded. This
/// results in [AspectRatio] being unable to find a suitable set of constraints
/// to apply. In that situation, consider explicitly setting a size using
/// [SizedBox] instead of setting the aspect ratio using [AspectRatio]. The size
/// is then scaled appropriately by the [FittedBox].
///
/// See also:
///
///  * [Align], a widget that aligns its child within itself and optionally
///    sizes itself based on the child's size.
///  * [ConstrainedBox], a widget that imposes additional constraints on its
///    child.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class AspectRatio extends SingleChildRenderObjectWidget {
  /// Creates a widget with a specific aspect ratio.
  ///
  /// The [aspectRatio] argument must be a finite number greater than zero.
  const AspectRatio({super.key, required this.aspectRatio, super.child})
    : assert(aspectRatio > 0.0);

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  @override
  RenderAspectRatio createRenderObject(BuildContext context) =>
      RenderAspectRatio(aspectRatio: aspectRatio);

  @override
  void updateRenderObject(BuildContext context, RenderAspectRatio renderObject) {
    renderObject.aspectRatio = aspectRatio;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('aspectRatio', aspectRatio));
  }
}

/// A widget that sizes its child to the child's maximum intrinsic width.
///
/// This class is useful, for example, when unlimited width is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable width. Additionally, putting a
/// [Column] inside an [IntrinsicWidth] will allow all [Column] children to be
/// as wide as the widest child.
///
/// The constraints that this widget passes to its child will adhere to the
/// parent's constraints, so if the constraints are not large enough to satisfy
/// the child's maximum intrinsic width, then the child will get less width
/// than it otherwise would. Likewise, if the minimum width constraint is
/// larger than the child's maximum intrinsic width, the child will be given
/// more width than it otherwise would.
///
/// If [stepWidth] is non-null, the child's width will be snapped to a multiple
/// of the [stepWidth]. Similarly, if [stepHeight] is non-null, the child's
/// height will be snapped to a multiple of the [stepHeight].
///
/// This class is relatively expensive, because it adds a speculative layout
/// pass before the final layout phase. Avoid using it where possible. In the
/// worst case, this widget can result in a layout that is O(N²) in the depth of
/// the tree.
///
/// See also:
///
///  * [Align], a widget that aligns its child within itself. This can be used
///    to loosen the constraints passed to the [RenderIntrinsicWidth],
///    allowing the [RenderIntrinsicWidth]'s child to be smaller than that of
///    its parent.
///  * [Row], which when used with [CrossAxisAlignment.stretch] can be used
///    to loosen just the width constraints that are passed to the
///    [RenderIntrinsicWidth], allowing the [RenderIntrinsicWidth]'s child's
///    width to be smaller than that of its parent.
///  * [The catalog of layout widgets](https://flutter.dev/widgets/layout/).
class IntrinsicWidth extends SingleChildRenderObjectWidget {
  /// Creates a widget that sizes its child to the child's intrinsic width.
  ///
  /// This class is relatively expensive. Avoid using it where possible.
  const IntrinsicWidth({super.key, this.stepWidth, this.stepHeight, super.child})
    : assert(stepWidth == null || stepWidth >= 0.0),
      assert(stepHeight == null || stepHeight >= 0.0);

  /// If non-null, force the child's width to be a multiple of this value.
  ///
  /// If null or 0.0 the child's width will be the same as its maximum
  /// intrinsic width.
  ///
  /// This value must not be negative.
  ///
  /// See also:
  ///
  ///  * [RenderBox.getMaxIntrinsicWidth], which defines a widget's max
  ///    intrinsic width in general.
  final double? stepWidth;

  /// If non-null, force the child's height to be a multiple of this value.
  ///
  /// If null or 0.0 the child's height will not be constrained.
  ///
  /// This value must not be negative.
  final double? stepHeight;

  double? get _stepWidth => stepWidth == 0.0 ? null : stepWidth;
  double? get _stepHeight => stepHeight == 0.0 ? null : stepHeight;

  @override
  RenderIntrinsicWidth createRenderObject(BuildContext context) {
    return RenderIntrinsicWidth(stepWidth: _stepWidth, stepHeight: _stepHeight);
  }

  @override
  void updateRenderObject(BuildContext context, RenderIntrinsicWidth renderObject) {
    renderObject
      ..stepWidth = _stepWidth
      ..stepHeight = _stepHeight;
  }
}

/// A widget that sizes its child to the child's intrinsic height.
///
/// This class is useful, for example, when unlimited height is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable height. Additionally, putting a
/// [Row] inside an [IntrinsicHeight] will allow all [Row] children to be as tall
/// as the tallest child.
///
/// The constraints that this widget passes to its child will adhere to the
/// parent's constraints, so if the constraints are not large enough to satisfy
/// the child's maximum intrinsic height, then the child will get less height
/// than it otherwise would. Likewise, if the minimum height constraint is
/// larger than the child's maximum intrinsic height, the child will be given
/// more height than it otherwise would.
///
/// This class is relatively expensive, because it adds a speculative layout
/// pass before the final layout phase. Avoid using it where possible. In the
/// worst case, this widget can result in a layout that is O(N²) in the depth of
/// the tree.
///
/// See also:
///
///  * [Align], a widget that aligns its child within itself. This can be used
///    to loosen the constraints passed to the [RenderIntrinsicHeight],
///    allowing the [RenderIntrinsicHeight]'s child to be smaller than that of
///    its parent.
///  * [Column], which when used with [CrossAxisAlignment.stretch] can be used
///    to loosen just the height constraints that are passed to the
///    [RenderIntrinsicHeight], allowing the [RenderIntrinsicHeight]'s child's
///    height to be smaller than that of its parent.
///  * [The catalog of layout widgets](https://flutter.dev/widgets/layout/).
class IntrinsicHeight extends SingleChildRenderObjectWidget {
  /// Creates a widget that sizes its child to the child's intrinsic height.
  ///
  /// This class is relatively expensive. Avoid using it where possible.
  const IntrinsicHeight({super.key, super.child});

  @override
  RenderIntrinsicHeight createRenderObject(BuildContext context) => RenderIntrinsicHeight();
}

/// A widget that positions its child according to the child's baseline.
///
/// This widget shifts the child down such that the child's baseline (or the
/// bottom of the child, if the child has no baseline) is [baseline]
/// logical pixels below the top of this box, then sizes this box to
/// contain the child. If [baseline] is less than the distance from
/// the top of the child to the baseline of the child, then the child
/// is top-aligned instead.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=8ZaFk0yvNlI}
///
/// See also:
///
///  * [Align], a widget that aligns its child within itself and optionally
///    sizes itself based on the child's size.
///  * [Center], a widget that centers its child within itself.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Baseline extends SingleChildRenderObjectWidget {
  /// Creates a widget that positions its child according to the child's baseline.
  const Baseline({super.key, required this.baseline, required this.baselineType, super.child});

  /// The number of logical pixels from the top of this box at which to position
  /// the child's baseline.
  final double baseline;

  /// The type of baseline to use for positioning the child.
  final TextBaseline baselineType;

  @override
  RenderBaseline createRenderObject(BuildContext context) {
    return RenderBaseline(baseline: baseline, baselineType: baselineType);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBaseline renderObject) {
    renderObject
      ..baseline = baseline
      ..baselineType = baselineType;
  }
}

/// A widget that causes the parent to ignore the [child] for the purposes
/// of baseline alignment.
///
/// See also:
///
///  * [Baseline], a widget that positions a child relative to a baseline.
class IgnoreBaseline extends SingleChildRenderObjectWidget {
  /// Creates a widget that ignores the child for baseline alignment purposes.
  const IgnoreBaseline({super.key, super.child});

  @override
  RenderIgnoreBaseline createRenderObject(BuildContext context) {
    return RenderIgnoreBaseline();
  }
}
