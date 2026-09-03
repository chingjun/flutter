// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticPropertiesBuilder, DiagnosticsProperty;
import 'package:flutter/src/painting/edge_insets.dart' show EdgeInsetsGeometry;
import 'package:flutter/src/rendering/sliver.dart' show RenderSliverToBoxAdapter;
import 'package:flutter/src/rendering/sliver_padding.dart' show RenderSliverPadding;
import 'package:flutter/src/widgets/directionality.dart' show Directionality;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, SingleChildRenderObjectWidget, Widget;

// SLIVERS: SliverToBoxAdapter, SliverPadding.
// SLIVERS

/// A sliver that contains a single box widget.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=vWec9DrAbHE}
///
/// Slivers are special-purpose widgets that can be combined using a
/// [CustomScrollView] to create custom scroll effects. A [SliverToBoxAdapter]
/// is a basic sliver that creates a bridge back to one of the usual box-based
/// widgets.
///
/// _To learn more about slivers, see [CustomScrollView.slivers]._
///
/// Rather than using multiple [SliverToBoxAdapter] widgets to display multiple
/// box widgets in a [CustomScrollView], consider using [SliverList],
/// [SliverFixedExtentList], [SliverPrototypeExtentList], or [SliverGrid],
/// which are more efficient because they instantiate only those children that
/// are actually visible through the scroll view's viewport.
///
/// See also:
///
///  * [CustomScrollView], which displays a scrollable list of slivers.
///  * [SliverList], which displays multiple box widgets in a linear array.
///  * [SliverFixedExtentList], which displays multiple box widgets with the
///    same main-axis extent in a linear array.
///  * [SliverPrototypeExtentList], which displays multiple box widgets with the
///    same main-axis extent as a prototype item, in a linear array.
///  * [SliverGrid], which displays multiple box widgets in arbitrary positions.
class SliverToBoxAdapter extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.
  const SliverToBoxAdapter({super.key, super.child});

  @override
  RenderSliverToBoxAdapter createRenderObject(BuildContext context) => RenderSliverToBoxAdapter();
}

/// A sliver that applies padding on each side of another sliver.
///
/// Slivers are special-purpose widgets that can be combined using a
/// [CustomScrollView] to create custom scroll effects. A [SliverPadding]
/// is a basic sliver that insets another sliver by applying padding on each
/// side.
///
/// {@macro flutter.rendering.RenderSliverEdgeInsetsPadding}
///
/// See also:
///
///  * [CustomScrollView], which displays a scrollable list of slivers.
///  * [Padding], the box version of this widget.
class SliverPadding extends SingleChildRenderObjectWidget {
  /// Creates a sliver that applies padding on each side of another sliver.
  const SliverPadding({super.key, required this.padding, Widget? sliver}) : super(child: sliver);

  /// The amount of space by which to inset the child sliver.
  final EdgeInsetsGeometry padding;

  @override
  RenderSliverPadding createRenderObject(BuildContext context) {
    return RenderSliverPadding(padding: padding, textDirection: Directionality.of(context));
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverPadding renderObject) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}
