// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ui'
    as ui
    show ImageFilter;
import 'dart:ui' show BlendMode, Clip, Color, Path, RRect, RSuperellipse, Rect, Size;
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticPropertiesBuilder, DiagnosticsProperty, DoubleProperty, EnumProperty, FlagProperty;
import 'package:flutter/src/foundation/key.dart' show Key;
import 'package:flutter/src/painting/border_radius.dart' show BorderRadius, BorderRadiusGeometry;
import 'package:flutter/src/painting/borders.dart' show ShapeBorder;
import 'package:flutter/src/painting/box_border.dart' show BoxShape;
import 'package:flutter/src/painting/colors.dart' show ColorProperty;
import 'package:flutter/src/rendering/custom_paint.dart' show CustomPainter, RenderCustomPaint;
import 'package:flutter/src/rendering/image_filter_config.dart' show ImageFilterConfig;
import 'package:flutter/src/rendering/layer.dart' show BackdropKey;
import 'package:flutter/src/rendering/proxy_box.dart' show CustomClipper, RenderBackdropFilter, RenderClipOval, RenderClipPath, RenderClipRRect, RenderClipRSuperellipse, RenderClipRect, RenderOpacity, RenderPhysicalModel, RenderPhysicalShape, RenderShaderMask, ShaderCallback, ShapeBorderClipper;
import 'package:flutter/src/widgets/directionality.dart' show Directionality;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, InheritedWidget, SingleChildRenderObjectWidget, Widget;
import 'package:flutter/src/widgets/basic_semantics.dart' show Builder;

// PAINTING NODES: Opacity, ShaderMask, BackdropFilter, CustomPaint,
// ClipRect, ClipRRect, ClipOval, ClipPath, PhysicalModel, PhysicalShape.
// PAINTING NODES

/// A widget that makes its child partially transparent.
///
/// This class paints its child into an intermediate buffer and then blends the
/// child back into the scene partially transparent.
///
/// For values of opacity other than 0.0 and 1.0, this class is relatively
/// expensive because it requires painting the child into an intermediate
/// buffer. For the value 0.0, the child is not painted at all. For the
/// value 1.0, the child is painted immediately without an intermediate buffer.
///
/// The presence of the intermediate buffer which has a transparent background
/// by default may cause some child widgets to behave differently. For example
/// a [BackdropFilter] child will only be able to apply its filter to the content
/// between this widget and the backdrop child and may require adjusting the
/// [BackdropFilter.blendMode] property to produce the desired results.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=9hltevOHQBw}
///
/// {@tool snippet}
///
/// This example shows some [Text] when the `_visible` member field is true, and
/// hides it when it is false:
///
/// ```dart
/// Opacity(
///   opacity: _visible ? 1.0 : 0.0,
///   child: const Text("Now you see me, now you don't!"),
/// )
/// ```
/// {@end-tool}
///
/// This is more efficient than adding and removing the child widget from the
/// tree on demand.
///
/// ## Performance considerations for opacity animation
///
/// Animating an [Opacity] widget directly causes the widget (and possibly its
/// subtree) to rebuild each frame, which is not very efficient. Consider using
/// one of these alternative widgets instead:
///
///  * [AnimatedOpacity], which uses an animation internally to efficiently
///    animate opacity.
///  * [FadeTransition], which uses a provided animation to efficiently animate
///    opacity.
///
/// ## Transparent image
///
/// If only a single [Image] or [Color] needs to be composited with an opacity
/// between 0.0 and 1.0, it's much faster to directly use them without [Opacity]
/// widgets.
///
/// For example, `Container(color: Color.fromRGBO(255, 0, 0, 0.5))` is much
/// faster than `Opacity(opacity: 0.5, child: Container(color: Colors.red))`.
///
/// {@tool snippet}
///
/// The following example draws an [Image] with 0.5 opacity without using
/// [Opacity]:
///
/// ```dart
/// Image.network(
///   'https://raw.githubusercontent.com/flutter/assets-for-api-docs/main/packages/diagrams/assets/blend_mode_destination.jpeg',
///   color: const Color.fromRGBO(255, 255, 255, 0.5),
///   colorBlendMode: BlendMode.modulate
/// )
/// ```
/// {@end-tool}
///
/// Directly drawing an [Image] or [Color] with opacity is faster than using
/// [Opacity] on top of them because [Opacity] could apply the opacity to a
/// group of widgets and therefore a costly offscreen buffer will be used.
/// Drawing content into the offscreen buffer may also trigger render target
/// switches and such switching is particularly slow in older GPUs.
///
/// ## Hit testing
///
/// Setting the [opacity] to zero does not prevent hit testing from being applied
/// to the descendants of the [Opacity] widget. This can be confusing for the
/// user, who may not see anything, and may believe the area of the interface
/// where the [Opacity] is hiding a widget to be non-interactive.
///
/// With certain widgets, such as [Flow], that compute their positions only when
/// they are painted, this can actually lead to bugs (from unexpected geometry
/// to exceptions), because those widgets are not painted by the [Opacity]
/// widget at all when the [opacity] is zero.
///
/// To avoid such problems, it is generally a good idea to use an
/// [IgnorePointer] widget when setting the [opacity] to zero. This prevents
/// interactions with any children in the subtree.
///
/// See also:
///
///  * [Visibility], which can hide a child more efficiently (albeit less
///    subtly, because it is either visible or hidden, rather than allowing
///    fractional opacity values). Specifically, the [Visibility.maintain]
///    constructor is equivalent to using an opacity widget with values of
///    `0.0` or `1.0`.
///  * [ShaderMask], which can apply more elaborate effects to its child.
///  * [Transform], which applies an arbitrary transform to its child widget at
///    paint time.
///  * [SliverOpacity], the sliver version of this widget.
class Opacity extends SingleChildRenderObjectWidget {
  /// Creates a widget that makes its child partially transparent.
  ///
  /// The [opacity] argument must be between zero and one, inclusive.
  const Opacity({
    super.key,
    required this.opacity,
    this.alwaysIncludeSemantics = false,
    super.child,
  }) : assert(opacity >= 0.0 && opacity <= 1.0);

  /// The fraction to scale the child's alpha value.
  ///
  /// An opacity of one is fully opaque. An opacity of zero is fully transparent
  /// (i.e., invisible).
  ///
  /// Values one and zero are painted with a fast path. Other values require
  /// painting the child into an intermediate buffer, which is expensive.
  final double opacity;

  /// Whether the semantic information of the children is always included.
  ///
  /// Defaults to false.
  ///
  /// When true, regardless of the opacity settings the child semantic
  /// information is exposed as if the widget were fully visible. This is
  /// useful in cases where labels may be hidden during animations that
  /// would otherwise contribute relevant semantics.
  final bool alwaysIncludeSemantics;

  @override
  RenderOpacity createRenderObject(BuildContext context) {
    return RenderOpacity(opacity: opacity, alwaysIncludeSemantics: alwaysIncludeSemantics);
  }

  @override
  void updateRenderObject(BuildContext context, RenderOpacity renderObject) {
    renderObject
      ..opacity = opacity
      ..alwaysIncludeSemantics = alwaysIncludeSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
    properties.add(
      FlagProperty(
        'alwaysIncludeSemantics',
        value: alwaysIncludeSemantics,
        ifTrue: 'alwaysIncludeSemantics',
      ),
    );
  }
}

/// A widget that applies a mask generated by a [Shader] to its child.
///
/// For example, [ShaderMask] can be used to gradually fade out the edge
/// of a child by using a [RadialGradient] mask.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=7sUL66pTQ7Q}
///
/// {@tool snippet}
///
/// This example makes the text look like it is on fire:
///
/// ```dart
/// ShaderMask(
///   shaderCallback: (Rect bounds) {
///     return RadialGradient(
///       center: Alignment.topLeft,
///       radius: 1.0,
///       colors: <Color>[Colors.yellow, Colors.deepOrange.shade900],
///       tileMode: TileMode.mirror,
///     ).createShader(bounds);
///   },
///   child: const Text(
///     "I'm burning the memories",
///     style: TextStyle(color: Colors.white),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Opacity], which can apply a uniform alpha effect to its child.
///  * [CustomPaint], which lets you draw directly on the canvas.
///  * [DecoratedBox], for another approach at decorating child widgets.
///  * [BackdropFilter], which applies an image filter to the background.
class ShaderMask extends SingleChildRenderObjectWidget {
  /// Creates a widget that applies a mask generated by a [Shader] to its child.
  const ShaderMask({
    super.key,
    required this.shaderCallback,
    this.blendMode = BlendMode.modulate,
    super.child,
  });

  /// Called to create the [dart:ui.Shader] that generates the mask.
  ///
  /// The shader callback is called with the current size of the child so that
  /// it can customize the shader to the size and location of the child.
  ///
  /// Typically this will use a [LinearGradient], [RadialGradient], or
  /// [SweepGradient] to create the [dart:ui.Shader], though the
  /// [dart:ui.ImageShader] class could also be used.
  final ShaderCallback shaderCallback;

  /// The [BlendMode] to use when applying the shader to the child.
  ///
  /// The default, [BlendMode.modulate], is useful for applying an alpha blend
  /// to the child. Other blend modes can be used to create other effects.
  final BlendMode blendMode;

  @override
  RenderShaderMask createRenderObject(BuildContext context) {
    return RenderShaderMask(shaderCallback: shaderCallback, blendMode: blendMode);
  }

  @override
  void updateRenderObject(BuildContext context, RenderShaderMask renderObject) {
    renderObject
      ..shaderCallback = shaderCallback
      ..blendMode = blendMode;
  }
}

/// A widget that establishes a shared backdrop layer for all child [BackdropFilter]
/// widgets that opt into using it.
///
/// Sharing a backdrop filter layer will improve the performance of multiple
/// backdrop filters. To opt into using a shared [BackdropGroup], the special
/// [BackdropFilter.grouped] constructor must be used.
class BackdropGroup extends InheritedWidget {
  /// Create a new [BackdropGroup] widget.
  BackdropGroup({super.key, required super.child, BackdropKey? backdropKey})
    : backdropKey = backdropKey ?? BackdropKey();

  /// The backdrop key this backdrop group will use with shared child layers.
  final BackdropKey backdropKey;

  @override
  bool updateShouldNotify(covariant BackdropGroup oldWidget) {
    return oldWidget.backdropKey != backdropKey;
  }

  /// Look up the nearest [BackdropGroup], or `null` if there is not one.
  static BackdropGroup? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BackdropGroup>();
  }
}

/// A widget that applies a filter to the existing painted content and then
/// paints [child].
///
/// The filter will be applied to all the area within its parent or ancestor
/// widget's clip. If there's no clip, the filter will be applied to the full
/// screen.
///
/// The results of the filter will be blended back into the background using
/// the [blendMode] parameter.
/// {@template flutter.widgets.BackdropFilter.blendMode}
/// The only value for [blendMode] that is supported on all platforms is
/// [BlendMode.srcOver] which works well for most scenes. But that value may
/// produce surprising results when a parent of the [BackdropFilter] uses a
/// temporary buffer, or save layer, as does an [Opacity] widget. In that
/// situation, a value of [BlendMode.src] can produce more pleasing results.
/// {@endtemplate}
///
/// Multiple backdrop filters can be combined into a single rendering operation
/// by the Flutter engine if these backdrop filter widgets all share a common
/// [BackdropKey] and have equivalent filter configurations. The backdrop key
/// uniquely identifies the input for a backdrop filter, and when shared, indicates
/// that the backdrop capture can be shared and filtering can be performed once
/// if the filters are identical. This can significantly reduce the overhead of
/// using multiple backdrop filters in a scene. The key can either be provided
/// manually via the `backdropKey` constructor parameter or looked up from a
/// [BackdropGroup] inherited widget via the `.grouped` constructor.
///
/// To combine the filter passes into a single operation, the resolved filters
/// across the group must have identical properties. For example, using a "bounded"
/// blur ([ImageFilterConfig.blur] with `bounded: true` or [ui.ImageFilter.blur]
/// with non-null `bounds`) assigns unique layout bounds to each widget, which
/// prevents the engine from collapsing them into a single blur pass (though the
/// initial backdrop capture is still shared across the group).
///
/// Backdrop filters that overlap with each other should not use the same
/// backdrop key, otherwise the results may look as if only one filter is
/// applied in the overlapping regions.
///
/// The following snippet demonstrates how to use the backdrop key to allow each
/// list item to have an efficient blur. The engine will perform only one
/// backdrop blur but the results will be visually identical to multiple blurs.
///
/// ```dart
///  Widget build(BuildContext context) {
///    return BackdropGroup(
///      child: ListView.builder(
///        itemCount: 60,
///        itemBuilder: (BuildContext context, int index) {
///          return ClipRect(
///            child: BackdropFilter.grouped(
///              filter: ui.ImageFilter.blur(
///                sigmaX: 40,
///                sigmaY: 40,
///              ),
///              child: Container(
///                color: Colors.black.withValues(alpha: 0.2),
///                height: 200,
///                child: const Text('Blur item'),
///              ),
///            ),
///          );
///       }
///     ),
///   );
/// }
/// ```
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=dYRs7Q1vfYI}
///
/// {@tool snippet}
///
/// If the [BackdropFilter] needs to be applied to an area that exactly matches
/// its child, wraps the [BackdropFilter] with a clip widget that clips exactly
/// to that child.
///
/// ```dart
/// Stack(
///   fit: StackFit.expand,
///   children: <Widget>[
///     Text('0' * 10000),
///     Center(
///       child: ClipRect(  // <-- clips to the 200x200 [Container] below
///         child: BackdropFilter(
///           filter: ui.ImageFilter.blur(
///             sigmaX: 5.0,
///             sigmaY: 5.0,
///           ),
///           child: Container(
///             alignment: Alignment.center,
///             width: 200.0,
///             height: 200.0,
///             child: const Text('Hello World'),
///           ),
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// This effect is relatively expensive, especially if the filter is non-local,
/// such as a blur.
///
/// If all you want to do is apply an [ImageFilter] to a single widget
/// (as opposed to applying the filter to everything _beneath_ a widget), use
/// [ImageFiltered] instead. For that scenario, [ImageFiltered] is both
/// easier to use and less expensive than [BackdropFilter].
///
/// {@tool snippet}
///
/// This example shows how the common case of applying a [BackdropFilter] blur
/// to a single sibling can be replaced with an [ImageFiltered] widget. This code
/// is generally simpler and the performance will be improved dramatically for
/// complex filters like blurs.
///
/// The implementation below is unnecessarily expensive.
///
/// ```dart
///  Widget buildBackdrop() {
///    return Stack(
///      children: <Widget>[
///        Positioned.fill(child: Image.asset('image.png')),
///        Positioned.fill(
///          child: BackdropFilter(
///            filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
///          ),
///        ),
///      ],
///    );
///  }
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// Instead consider the following approach which directly applies a blur
/// to the child widget.
///
/// ```dart
///  Widget buildFilter() {
///    return ImageFiltered(
///      imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
///      child: Image.asset('image.png'),
///    );
///  }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ImageFiltered], which applies an [ImageFilter] to its child.
///  * [DecoratedBox], which draws a background under (or over) a widget.
///  * [Opacity], which changes the opacity of the widget itself.
///  * https://flutter.dev/go/ios-platformview-backdrop-filter-blur for details and restrictions when an iOS PlatformView needs to be blurred.
class BackdropFilter extends SingleChildRenderObjectWidget {
  /// Creates a backdrop filter.
  ///
  /// The [blendMode] argument will default to [BlendMode.srcOver] and must not be
  /// null if provided.
  ///
  /// Exactly one of [filter] or [filterConfig] must be provided.
  /// Providing both or neither will result in an assertion error.
  const BackdropFilter({
    super.key,
    this.filter,
    this.filterConfig,
    super.child,
    this.blendMode = BlendMode.srcOver,
    this.enabled = true,
    this.backdropGroupKey,
  }) : assert(
         filter != null || filterConfig != null,
         'Either filter or filterConfig must be provided.',
       ),
       assert(
         filter == null || filterConfig == null,
         'Cannot provide both a filter and a filterConfig.',
       ),
       _useSharedKey = false;

  /// Creates a backdrop filter that groups itself with the nearest parent
  /// [BackdropGroup].
  ///
  /// The [blendMode] argument will default to [BlendMode.srcOver] and must not be
  /// null if provided.
  ///
  /// This constructor will automatically look up the nearest [BackdropGroup]
  /// and will share the backdrop input with sibling and child [BackdropFilter]
  /// widgets.
  ///
  /// Exactly one of [filter] or [filterConfig] must be provided.
  /// Providing both or neither will result in an assertion error.
  const BackdropFilter.grouped({
    super.key,
    this.filter,
    this.filterConfig,
    super.child,
    this.blendMode = BlendMode.srcOver,
    this.enabled = true,
  }) : assert(
         filter != null || filterConfig != null,
         'Either filter or filterConfig must be provided.',
       ),
       assert(
         filter == null || filterConfig == null,
         'Cannot provide both a filter and a filterConfig.',
       ),
       backdropGroupKey = null,
       _useSharedKey = true;

  /// The image filter to apply to the existing painted content before painting the child.
  ///
  /// For example, consider using [ImageFilter.blur] to create a backdrop
  /// blur effect.
  ///
  /// The [filter] parameter is equivalent to [filterConfig] (with the help of
  /// the [ImageFilterConfig.new] constructor), except for features only
  /// supported by [ImageFilterConfig] (such as the `bounds` parameter in
  /// [ImageFilterConfig.blur]).
  final ui.ImageFilter? filter;

  /// The configuration for the image filter to apply to the existing painted content.
  ///
  /// For example, consider using [ImageFilterConfig.blur] to create a backdrop
  /// blur effect.
  ///
  /// The [filterConfig] parameter is equivalent to [filter] (with the help of
  /// the [ImageFilterConfig.new] constructor), except for features only
  /// supported by [ImageFilterConfig] (such as the `bounds` parameter in
  /// [ImageFilterConfig.blur]).
  final ImageFilterConfig? filterConfig;

  /// The blend mode to use to apply the filtered background content onto the background
  /// surface.
  ///
  /// {@macro flutter.widgets.BackdropFilter.blendMode}
  final BlendMode blendMode;

  /// Whether or not to apply the backdrop filter operation to the child of this
  /// widget.
  ///
  /// Prefer setting enabled to `false` instead of creating a "no-op" filter
  /// type for performance reasons.
  final bool enabled;

  /// The [BackdropKey] that identifies the backdrop this filter will apply to.
  ///
  /// The default value for the backdrop key is `null`.
  final BackdropKey? backdropGroupKey;

  // Whether to look up the [backdropKey] from a parent [BackdropGroup].
  final bool _useSharedKey;

  BackdropKey? _getBackdropGroupKey(BuildContext context) {
    if (_useSharedKey) {
      return BackdropGroup.of(context)?.backdropKey;
    }
    return backdropGroupKey;
  }

  ImageFilterConfig get _effectiveFilterConfig {
    return filterConfig ?? ImageFilterConfig(filter!);
  }

  @override
  RenderBackdropFilter createRenderObject(BuildContext context) {
    return RenderBackdropFilter(
      filterConfig: _effectiveFilterConfig,
      blendMode: blendMode,
      enabled: enabled,
      backdropKey: _getBackdropGroupKey(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderBackdropFilter renderObject) {
    renderObject
      ..filterConfig = _effectiveFilterConfig
      ..enabled = enabled
      ..blendMode = blendMode
      ..backdropKey = _getBackdropGroupKey(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ui.ImageFilter>('filter', filter, defaultValue: null));
    properties.add(
      DiagnosticsProperty<ImageFilterConfig>('filterConfig', filterConfig, defaultValue: null),
    );
    properties.add(EnumProperty<BlendMode>('blendMode', blendMode));
    properties.add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'));
  }
}

/// A widget that provides a canvas on which to draw during the paint phase.
///
/// When asked to paint, [CustomPaint] first asks its [painter] to paint on the
/// current canvas, then it paints its child, and then, after painting its
/// child, it asks its [foregroundPainter] to paint. The coordinate system of the
/// canvas matches the coordinate system of the [CustomPaint] object. The
/// painters are expected to paint within a rectangle starting at the origin and
/// encompassing a region of the given size. (If the painters paint outside
/// those bounds, there might be insufficient memory allocated to rasterize the
/// painting commands and the resulting behavior is undefined.) To enforce
/// painting within those bounds, consider wrapping this [CustomPaint] with a
/// [ClipRect] widget.
///
/// Painters are implemented by subclassing [CustomPainter].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=kp14Y4uHpHs}
///
/// Because custom paint calls its painters during paint, you cannot call
/// `setState` or `markNeedsLayout` during the callback (the layout for this
/// frame has already happened).
///
/// Custom painters normally size themselves to their [child]. If they do not
/// have a child, they attempt to size themselves to the specified [size], which
/// defaults to [Size.zero]. The parent [may enforce constraints on this
/// size](https://docs.flutter.dev/ui/layout/constraints).
///
/// The [isComplex] and [willChange] properties are hints to the compositor's
/// raster cache.
///
/// {@tool snippet}
///
/// This example shows how the sample custom painter shown at [CustomPainter]
/// could be used in a [CustomPaint] widget to display a background to some
/// text.
///
/// ```dart
/// CustomPaint(
///   painter: Sky(),
///   child: const Center(
///     child: Text(
///       'Once upon a time...',
///       style: TextStyle(
///         fontSize: 40.0,
///         fontWeight: FontWeight.w900,
///         color: Color(0xFFFFFFFF),
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CustomPainter], the class to extend when creating custom painters.
///  * [Canvas], the class that a custom painter uses to paint.
class CustomPaint extends SingleChildRenderObjectWidget {
  /// Creates a widget that delegates its painting.
  const CustomPaint({
    super.key,
    this.painter,
    this.foregroundPainter,
    this.size = Size.zero,
    this.isComplex = false,
    this.willChange = false,
    super.child,
  }) : assert(painter != null || foregroundPainter != null || (!isComplex && !willChange));

  /// The painter that paints before the children.
  final CustomPainter? painter;

  /// The painter that paints after the children.
  final CustomPainter? foregroundPainter;

  /// The size that this [CustomPaint] should aim for, given the layout
  /// constraints, if there is no child.
  ///
  /// Defaults to [Size.zero].
  ///
  /// If there's a child, this is ignored, and the size of the child is used
  /// instead.
  final Size size;

  /// Whether the painting is complex enough to benefit from caching.
  ///
  /// The compositor contains a raster cache that holds bitmaps of layers in
  /// order to avoid the cost of repeatedly rendering those layers on each
  /// frame. If this flag is not set, then the compositor will apply its own
  /// heuristics to decide whether the layer containing this widget is complex
  /// enough to benefit from caching.
  ///
  /// This flag can't be set to true if both [painter] and [foregroundPainter]
  /// are null because this flag will be ignored in such case.
  final bool isComplex;

  /// Whether the raster cache should be told that this painting is likely
  /// to change in the next frame.
  ///
  /// This hint tells the compositor not to cache the layer containing this
  /// widget because the cache will not be used in the future. If this hint is
  /// not set, the compositor will apply its own heuristics to decide whether
  /// the layer is likely to be reused in the future.
  ///
  /// This flag can't be set to true if both [painter] and [foregroundPainter]
  /// are null because this flag will be ignored in such case.
  final bool willChange;

  @override
  RenderCustomPaint createRenderObject(BuildContext context) {
    return RenderCustomPaint(
      painter: painter,
      foregroundPainter: foregroundPainter,
      preferredSize: size,
      isComplex: isComplex,
      willChange: willChange,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomPaint renderObject) {
    renderObject
      ..painter = painter
      ..foregroundPainter = foregroundPainter
      ..preferredSize = size
      ..isComplex = isComplex
      ..willChange = willChange;
  }

  @override
  void didUnmountRenderObject(RenderCustomPaint renderObject) {
    renderObject
      ..painter = null
      ..foregroundPainter = null;
  }
}

/// A widget that clips its child using a rectangle.
///
/// By default, [ClipRect] prevents its child from painting outside its
/// bounds, but the size and location of the clip rect can be customized using a
/// custom [clipper].
///
/// [ClipRect] is commonly used with these widgets, which commonly paint outside
/// their bounds:
///
///  * [CustomPaint]
///  * [CustomSingleChildLayout]
///  * [CustomMultiChildLayout]
///  * [Align] and [Center] (e.g., if [Align.widthFactor] or
///    [Align.heightFactor] is less than 1.0).
///  * [OverflowBox]
///  * [SizedOverflowBox]
///
/// {@tool snippet}
///
/// For example, by combining a [ClipRect] with an [Align], one can show just
/// the top half of an [Image]:
///
/// ```dart
/// ClipRect(
///   child: Align(
///     alignment: Alignment.topCenter,
///     heightFactor: 0.5,
///     child: Image.network(userAvatarUrl),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CustomClipper], for information about creating custom clips.
///  * [ClipRRect], for a clip with rounded corners.
///  * [ClipOval], for an elliptical clip.
///  * [ClipPath], for an arbitrarily shaped clip.
class ClipRect extends SingleChildRenderObjectWidget {
  /// Creates a rectangular clip.
  ///
  /// If [clipper] is null, the clip will match the layout size and position of
  /// the child.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  const ClipRect({super.key, this.clipper, this.clipBehavior = Clip.hardEdge, super.child});

  /// If non-null, determines which clip to use.
  final CustomClipper<Rect>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  @override
  RenderClipRect createRenderObject(BuildContext context) {
    return RenderClipRect(clipper: clipper, clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipRect renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipRect renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CustomClipper<Rect>>('clipper', clipper, defaultValue: null),
    );
  }
}

/// A widget that clips its child using a rounded rectangle.
///
/// By default, [ClipRRect] uses its own bounds as the base rectangle for the
/// clip, but the size and location of the clip can be customized using a custom
/// [clipper].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=eI43jkQkrvs}
///
/// {@tool dartpad}
/// This example shows various [ClipRRect]s applied to containers.
///
/// ** See code in examples/api/lib/widgets/basic/clip_rrect.0.dart **
/// {@end-tool}
///
/// ## Troubleshooting
///
/// ### Why doesn't my [ClipRRect] child have rounded corners?
///
/// When a [ClipRRect] is bigger than the child it contains, its rounded corners
/// could be drawn in unexpected positions. Make sure that [ClipRRect] and its child
/// have the same bounds (by shrinking the [ClipRRect] with a [FittedBox] or by
/// growing the child).
///
/// {@tool dartpad}
/// This example shows a [ClipRRect] that adds round corners to an image.
///
/// ** See code in examples/api/lib/widgets/basic/clip_rrect.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [CustomClipper], for information about creating custom clips.
///  * [ClipRect], for more efficient clips without rounded corners.
///  * [ClipRSuperellipse], for a similar clipping shape with smoother
///    transitions between the straight sides and the rounded corners. This
///    shape closely matches the rounded rectangles commonly used in Apple’s
///    design language, resembling the `RoundedRectangle` shape in SwiftUI with
///    the `.continuous` corner style.
///  * [ClipOval], for an elliptical clip.
///  * [ClipPath], for an arbitrarily shaped clip.
class ClipRRect extends SingleChildRenderObjectWidget {
  /// Creates a rounded-rectangular clip.
  ///
  /// The [borderRadius] defaults to [BorderRadius.zero], i.e. a rectangle with
  /// right-angled corners.
  ///
  /// If [clipper] is non-null, then [borderRadius] is ignored.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  const ClipRRect({
    super.key,
    this.borderRadius = BorderRadius.zero,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    super.child,
  });

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  final BorderRadiusGeometry borderRadius;

  /// If non-null, determines which clip to use.
  final CustomClipper<RRect>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  ///
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  @override
  RenderClipRRect createRenderObject(BuildContext context) {
    return RenderClipRRect(
      borderRadius: borderRadius,
      clipper: clipper,
      clipBehavior: clipBehavior,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipRRect renderObject) {
    renderObject
      ..borderRadius = borderRadius
      ..clipBehavior = clipBehavior
      ..clipper = clipper
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BorderRadiusGeometry>(
        'borderRadius',
        borderRadius,
        showName: false,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<CustomClipper<RRect>>('clipper', clipper, defaultValue: null),
    );
  }
}

/// A widget that clips its child using a rounded superellipse.
///
/// A rounded superellipse is a shape similar to a typical rounded rectangle
/// ([ClipRRect]), but with smoother transitions between the straight sides and
/// the rounded corners. It resembles the `RoundedRectangle` shape in SwiftUI
/// with the `.continuous` corner style. Technically, it is created by replacing
/// the four corners of a superellipse (also known as a Lamé curve) with
/// circular arcs.
///
/// By default, [ClipRSuperellipse] uses its own bounds as the base rectangle
/// for the clip, but the size and location of the clip can be customized using
/// a custom [clipper].
///
/// See also:
///
///  * [CustomClipper], for information about creating custom clips.
///  * [ClipRect], for more efficient clips without rounded corners.
///  * [ClipRRect], for a typical rounded rectangle, which is created by
///    replacing the four corners of a rectangle with circular arcs.
///  * [ClipOval], for an elliptical clip.
///  * [ClipPath], for an arbitrarily shaped clip.
class ClipRSuperellipse extends SingleChildRenderObjectWidget {
  /// Creates a rounded-superellipse clip.
  ///
  /// The [borderRadius] defaults to [BorderRadius.zero], i.e. a rectangle with
  /// right-angled corners.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  const ClipRSuperellipse({
    super.key,
    this.borderRadius = BorderRadius.zero,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    super.child,
  });

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  final BorderRadiusGeometry borderRadius;

  /// If non-null, determines which clip to use.
  final CustomClipper<RSuperellipse>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  ///
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  @override
  RenderClipRSuperellipse createRenderObject(BuildContext context) {
    return RenderClipRSuperellipse(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      clipper: clipper,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipRSuperellipse renderObject) {
    renderObject
      ..borderRadius = borderRadius
      ..clipBehavior = clipBehavior
      ..clipper = clipper
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BorderRadiusGeometry>(
        'borderRadius',
        borderRadius,
        showName: false,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<CustomClipper<RSuperellipse>>('clipper', clipper, defaultValue: null),
    );
  }
}

/// A widget that clips its child using an oval.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=vzWWDO6whIM}
///
/// By default, inscribes an axis-aligned oval into its layout dimensions and
/// prevents its child from painting outside that oval, but the size and
/// location of the clip oval can be customized using a custom [clipper].
///
/// {@tool snippet}
///
/// This example clips an image of a cat using an oval.
///
/// ```dart
/// ClipOval(
///   child: Image.asset('images/cat.png'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CustomClipper], for information about creating custom clips.
///  * [ClipRect], for more efficient clips without rounded corners.
///  * [ClipRRect], for a clip with rounded corners.
///  * [ClipPath], for an arbitrarily shaped clip.
class ClipOval extends SingleChildRenderObjectWidget {
  /// Creates an oval-shaped clip.
  ///
  /// If [clipper] is null, the oval will be inscribed into the layout size and
  /// position of the child.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  const ClipOval({super.key, this.clipper, this.clipBehavior = Clip.antiAlias, super.child});

  /// If non-null, determines which clip to use.
  ///
  /// The delegate returns a rectangle that describes the axis-aligned
  /// bounding box of the oval. The oval's axes will themselves also
  /// be axis-aligned.
  ///
  /// If the [clipper] delegate is null, then the oval uses the
  /// widget's bounding box (the layout dimensions of the render
  /// object) instead.
  final CustomClipper<Rect>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  ///
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  @override
  RenderClipOval createRenderObject(BuildContext context) {
    return RenderClipOval(clipper: clipper, clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipOval renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipOval renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CustomClipper<Rect>>('clipper', clipper, defaultValue: null),
    );
  }
}

/// A widget that clips its child using a path.
///
/// Calls a callback on a delegate whenever the widget is to be
/// painted. The callback returns a path and the widget prevents the
/// child from painting outside the path.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=oAUebVIb-7s}
///
/// Clipping to a path is expensive. Certain shapes have more
/// optimized widgets:
///
///  * To clip to a rectangle, consider [ClipRect].
///  * To clip to an oval or circle, consider [ClipOval].
///  * To clip to a rounded rectangle, consider [ClipRRect].
///
/// To clip to a particular [ShapeBorder], consider using either the
/// [ClipPath.shape] static method or the [ShapeBorderClipper] custom clipper
/// class.
class ClipPath extends SingleChildRenderObjectWidget {
  /// Creates a path clip.
  ///
  /// If [clipper] is null, the clip will be a rectangle that matches the layout
  /// size and location of the child. However, rather than use this default,
  /// consider using a [ClipRect], which can achieve the same effect more
  /// efficiently.
  ///
  /// If [clipBehavior] is [Clip.none], no clipping will be applied.
  const ClipPath({super.key, this.clipper, this.clipBehavior = Clip.antiAlias, super.child});

  /// Creates a shape clip.
  ///
  /// Uses a [ShapeBorderClipper] to configure the [ClipPath] to clip to the
  /// given [ShapeBorder].
  static Widget shape({
    Key? key,
    required ShapeBorder shape,
    Clip clipBehavior = Clip.antiAlias,
    Widget? child,
  }) {
    return Builder(
      key: key,
      builder: (BuildContext context) {
        return ClipPath(
          clipper: ShapeBorderClipper(shape: shape, textDirection: Directionality.maybeOf(context)),
          clipBehavior: clipBehavior,
          child: child,
        );
      },
    );
  }

  /// If non-null, determines which clip to use.
  ///
  /// The default clip, which is used if this property is null, is the
  /// bounding box rectangle of the widget. [ClipRect] is a more
  /// efficient way of obtaining that effect.
  final CustomClipper<Path>? clipper;

  /// {@macro flutter.rendering.ClipRectLayer.clipBehavior}
  ///
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  @override
  RenderClipPath createRenderObject(BuildContext context) {
    return RenderClipPath(clipper: clipper, clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipPath renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipPath renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CustomClipper<Path>>('clipper', clipper, defaultValue: null),
    );
  }
}

/// A widget representing a physical layer that clips its children to a shape.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=XgUOSS30OQk}
///
/// Physical layers cast shadows based on an [elevation] which is nominally in
/// logical pixels, coming vertically out of the rendering surface.
///
/// For shapes that cannot be expressed as a rectangle with rounded corners use
/// [PhysicalShape].
///
/// See also:
///
///  * [AnimatedPhysicalModel], which animates property changes smoothly over
///    a given duration.
///  * [DecoratedBox], which can apply more arbitrary shadow effects.
///  * [ClipRect], which applies a clip to its child.
class PhysicalModel extends SingleChildRenderObjectWidget {
  /// Creates a physical model with a rounded-rectangular clip.
  ///
  /// The [color] is required; physical things have a color.
  ///
  /// The [shape], [elevation], [color], [clipBehavior], and [shadowColor] must
  /// not be null. Additionally, the [elevation] must be non-negative.
  const PhysicalModel({
    super.key,
    this.shape = BoxShape.rectangle,
    this.clipBehavior = Clip.none,
    this.borderRadius,
    this.elevation = 0.0,
    required this.color,
    this.shadowColor = const Color(0xFF000000),
    super.child,
  }) : assert(elevation >= 0.0);

  /// The type of shape.
  final BoxShape shape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This is ignored if the [shape] is not [BoxShape.rectangle].
  final BorderRadius? borderRadius;

  /// The z-coordinate relative to the parent at which to place this physical
  /// object.
  ///
  /// The value is non-negative.
  final double elevation;

  /// The background color.
  final Color color;

  /// The shadow color.
  final Color shadowColor;

  @override
  RenderPhysicalModel createRenderObject(BuildContext context) {
    return RenderPhysicalModel(
      shape: shape,
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPhysicalModel renderObject) {
    renderObject
      ..shape = shape
      ..clipBehavior = clipBehavior
      ..borderRadius = borderRadius
      ..elevation = elevation
      ..color = color
      ..shadowColor = shadowColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxShape>('shape', shape));
    properties.add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('shadowColor', shadowColor));
  }
}

/// A widget representing a physical layer that clips its children to a path.
///
/// Physical layers cast shadows based on an [elevation] which is nominally in
/// logical pixels, coming vertically out of the rendering surface.
///
/// [PhysicalModel] does the same but only supports shapes that can be expressed
/// as rectangles with rounded corners.
///
/// {@tool dartpad}
/// This example shows how to use a [PhysicalShape] on a centered [SizedBox]
/// to clip it to a rounded rectangle using a [ShapeBorderClipper] and give it
/// an orange color along with a shadow.
///
/// ** See code in examples/api/lib/widgets/basic/physical_shape.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ShapeBorderClipper], which converts a [ShapeBorder] to a [CustomClipper], as
///    needed by this widget.
class PhysicalShape extends SingleChildRenderObjectWidget {
  /// Creates a physical model with an arbitrary shape clip.
  ///
  /// The [color] is required; physical things have a color.
  ///
  /// The [elevation] must be non-negative.
  const PhysicalShape({
    super.key,
    required this.clipper,
    this.clipBehavior = Clip.none,
    this.elevation = 0.0,
    required this.color,
    this.shadowColor = const Color(0xFF000000),
    super.child,
  }) : assert(elevation >= 0.0);

  /// Determines which clip to use.
  ///
  /// If the path in question is expressed as a [ShapeBorder] subclass,
  /// consider using the [ShapeBorderClipper] delegate class to adapt the
  /// shape for use with this widget.
  final CustomClipper<Path> clipper;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The z-coordinate relative to the parent at which to place this physical
  /// object.
  ///
  /// The value is non-negative.
  final double elevation;

  /// The background color.
  final Color color;

  /// When elevation is non zero the color to use for the shadow color.
  final Color shadowColor;

  @override
  RenderPhysicalShape createRenderObject(BuildContext context) {
    return RenderPhysicalShape(
      clipper: clipper,
      clipBehavior: clipBehavior,
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPhysicalShape renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior
      ..elevation = elevation
      ..color = color
      ..shadowColor = shadowColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<Path>>('clipper', clipper));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('shadowColor', shadowColor));
  }
}
