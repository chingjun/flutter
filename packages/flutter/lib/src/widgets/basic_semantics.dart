// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:collection' show IterableExtensions;
import 'dart:ui'
    as ui
    show SemanticsHitTestBehavior, SemanticsInputType;
import 'dart:ui' show Color, Locale, Offset, Paint, SemanticsRole, SemanticsValidationResult, Size, TextDirection, VoidCallback;
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticPropertiesBuilder, DiagnosticsProperty;
import 'package:flutter/src/foundation/key.dart' show Key, ValueKey;
import 'package:flutter/src/rendering/object.dart' show PaintingContext, RenderObject;
import 'package:flutter/src/rendering/proxy_box.dart' show HitTestBehavior, RenderBlockSemantics, RenderExcludeSemantics, RenderIndexedSemantics, RenderMergeSemantics, RenderProxyBoxWithHitTestBehavior, RenderSemanticsAnnotations;
import 'package:flutter/src/rendering/proxy_sliver.dart' show RenderSliverSemanticsAnnotations;
import 'package:flutter/src/semantics/semantics.dart' show AccessibilityFocusBlockType, AttributedString, CustomSemanticsAction, MoveCursorHandler, SemanticsHintOverrides, SemanticsProperties, SemanticsSortKey, SemanticsTag, SetSelectionHandler, SetTextHandler;
import 'package:flutter/src/widgets/directionality.dart' show Directionality;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, SingleChildRenderObjectWidget, State, StateSetter, StatefulWidget, StatelessWidget, Widget, WidgetBuilder, debugItemsHaveDuplicateKeys;
import 'package:meta/meta.dart' show immutable;

// SEMANTICS AND UTILITY NODES: _SemanticsBase, SliverSemantics, Semantics,
// MergeSemantics, BlockSemantics, ExcludeSemantics, IndexedSemantics,
// KeyedSubtree, Builder, StatefulBuilder, ColoredBox.

/// An abstract class for building widgets that annotate their subtree with a
/// description of the meaning of the widgets.
///
/// {@template flutter.widgets.SemanticsBase}
/// Used by assistive technologies, search engines, and other semantic analysis
/// software to determine the meaning of the application.
///
/// See also:
///
///  * [SemanticsProperties], which contains a complete documentation for each
///    of the constructor parameters that belongs to semantics properties.
///  * [RenderObject.describeSemanticsConfiguration], the rendering library API
///    through which the [Semantics] widget and [SliverSemantics] sliver are
///    actually implemented.
///  * [SemanticsNode], the object used by the rendering library to represent
///    semantics in the semantics tree.
///  * [SemanticsDebugger], an overlay to help visualize the semantics tree. Can
///    be enabled using [WidgetsApp.showSemanticsDebugger],
///    [MaterialApp.showSemanticsDebugger], or [CupertinoApp.showSemanticsDebugger].
///  * [MergeSemantics], a widget which marks a subtree as being a single node for
///    accessibility purposes.
///  * [ExcludeSemantics], a widget which excludes a subtree from the semantics tree
///    (which might be useful if it is, e.g., totally decorative and not
///    important to the user).
/// {@endtemplate}
@immutable
sealed class _SemanticsBase extends SingleChildRenderObjectWidget {
  /// Creates a semantic annotation.
  ///
  /// To create a `const` instance of [_SemanticsBase], use the
  /// [_SemanticsBase.fromProperties] constructor.
  ///
  /// {@template flutter.widgets.SemanticsBase.constructor}
  /// See also:
  ///
  ///  * [SemanticsProperties], which contains a complete documentation for each
  ///    of the constructor parameters that belongs to semantics properties.
  ///  * [SemanticsSortKey] for a class that determines accessibility traversal
  ///    order.
  /// {@endtemplate}
  // Properties added to this constructor should be marked required
  // to enforce its subclasses add it to their constructors.
  _SemanticsBase({
    Key? key,
    Widget? child,
    required bool container,
    required bool explicitChildNodes,
    required bool excludeSemantics,
    required bool blockUserActions,
    required bool? enabled,
    required bool? checked,
    required bool? mixed,
    required bool? selected,
    required bool? toggled,
    required bool? button,
    required bool? slider,
    required bool? keyboardKey,
    required bool? link,
    required Uri? linkUrl,
    required bool? header,
    required int? headingLevel,
    required bool? textField,
    required bool? readOnly,
    required bool? focusable,
    required bool? focused,
    required AccessibilityFocusBlockType? accessibilityFocusBlockType,
    required bool? inMutuallyExclusiveGroup,
    required bool? obscured,
    required bool? multiline,
    required bool? scopesRoute,
    required bool? namesRoute,
    required bool? hidden,
    required bool? image,
    required bool? liveRegion,
    required bool? expanded,
    required bool? isRequired,
    required int? maxValueLength,
    required int? currentValueLength,
    required String? identifier,
    required Object? traversalParentIdentifier,
    required Object? traversalChildIdentifier,
    required String? label,
    required AttributedString? attributedLabel,
    required String? value,
    required AttributedString? attributedValue,
    required String? increasedValue,
    required AttributedString? attributedIncreasedValue,
    required String? decreasedValue,
    required AttributedString? attributedDecreasedValue,
    required String? hint,
    required AttributedString? attributedHint,
    required String? tooltip,
    required String? onTapHint,
    required String? onLongPressHint,
    required TextDirection? textDirection,
    required SemanticsSortKey? sortKey,
    required SemanticsTag? tagForChildren,
    required VoidCallback? onTap,
    required VoidCallback? onLongPress,
    required VoidCallback? onScrollLeft,
    required VoidCallback? onScrollRight,
    required VoidCallback? onScrollUp,
    required VoidCallback? onScrollDown,
    required VoidCallback? onIncrease,
    required VoidCallback? onDecrease,
    required VoidCallback? onCopy,
    required VoidCallback? onCut,
    required VoidCallback? onPaste,
    required VoidCallback? onDismiss,
    required MoveCursorHandler? onMoveCursorForwardByCharacter,
    required MoveCursorHandler? onMoveCursorBackwardByCharacter,
    required SetSelectionHandler? onSetSelection,
    required SetTextHandler? onSetText,
    required VoidCallback? onDidGainAccessibilityFocus,
    required VoidCallback? onDidLoseAccessibilityFocus,
    required VoidCallback? onFocus,
    required VoidCallback? onExpand,
    required VoidCallback? onCollapse,
    required Map<CustomSemanticsAction, VoidCallback>? customSemanticsActions,
    required SemanticsRole? role,
    required Set<String>? controlsNodes,
    required SemanticsValidationResult validationResult,
    required ui.SemanticsHitTestBehavior? hitTestBehavior,
    required ui.SemanticsInputType? inputType,
    required Locale? localeForSubtree,
    required String? minValue,
    required String? maxValue,
  }) : this.fromProperties(
         key: key,
         child: child,
         container: container,
         explicitChildNodes: explicitChildNodes,
         excludeSemantics: excludeSemantics,
         blockUserActions: blockUserActions,
         localeForSubtree: localeForSubtree,
         properties: SemanticsProperties(
           enabled: enabled,
           checked: checked,
           mixed: mixed,
           expanded: expanded,
           toggled: toggled,
           selected: selected,
           button: button,
           slider: slider,
           keyboardKey: keyboardKey,
           link: link,
           linkUrl: linkUrl,
           header: header,
           headingLevel: headingLevel,
           textField: textField,
           readOnly: readOnly,
           focusable: focusable,
           focused: focused,
           accessibilityFocusBlockType: accessibilityFocusBlockType,
           inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
           obscured: obscured,
           multiline: multiline,
           scopesRoute: scopesRoute,
           namesRoute: namesRoute,
           hidden: hidden,
           image: image,
           liveRegion: liveRegion,
           isRequired: isRequired,
           maxValueLength: maxValueLength,
           currentValueLength: currentValueLength,
           identifier: identifier,
           traversalParentIdentifier: traversalParentIdentifier,
           traversalChildIdentifier: traversalChildIdentifier,
           label: label,
           attributedLabel: attributedLabel,
           value: value,
           attributedValue: attributedValue,
           increasedValue: increasedValue,
           attributedIncreasedValue: attributedIncreasedValue,
           decreasedValue: decreasedValue,
           attributedDecreasedValue: attributedDecreasedValue,
           hint: hint,
           attributedHint: attributedHint,
           tooltip: tooltip,
           textDirection: textDirection,
           sortKey: sortKey,
           tagForChildren: tagForChildren,
           onTap: onTap,
           onLongPress: onLongPress,
           onScrollLeft: onScrollLeft,
           onScrollRight: onScrollRight,
           onScrollUp: onScrollUp,
           onScrollDown: onScrollDown,
           onIncrease: onIncrease,
           onDecrease: onDecrease,
           onCopy: onCopy,
           onCut: onCut,
           onPaste: onPaste,
           onMoveCursorForwardByCharacter: onMoveCursorForwardByCharacter,
           onMoveCursorBackwardByCharacter: onMoveCursorBackwardByCharacter,
           onDidGainAccessibilityFocus: onDidGainAccessibilityFocus,
           onDidLoseAccessibilityFocus: onDidLoseAccessibilityFocus,
           onFocus: onFocus,
           onDismiss: onDismiss,
           onSetSelection: onSetSelection,
           onSetText: onSetText,
           onExpand: onExpand,
           onCollapse: onCollapse,
           customSemanticsActions: customSemanticsActions,
           hintOverrides: onTapHint != null || onLongPressHint != null
               ? SemanticsHintOverrides(onTapHint: onTapHint, onLongPressHint: onLongPressHint)
               : null,
           role: role,
           controlsNodes: controlsNodes,
           validationResult: validationResult,
           hitTestBehavior: hitTestBehavior,
           inputType: inputType,
           minValue: minValue,
           maxValue: maxValue,
         ),
       );

  /// {@template flutter.widgets.SemanticsBase.fromProperties}
  /// Creates a semantic annotation using [SemanticsProperties].
  /// {@endtemplate}
  // Properties added to this constructor should be marked required
  // to enforce its subclasses add it to their constructors.
  const _SemanticsBase.fromProperties({
    super.key,
    super.child,
    required this.container,
    required this.explicitChildNodes,
    required this.excludeSemantics,
    required this.blockUserActions,
    required this.localeForSubtree,
    required this.properties,
  });

  /// Contains properties used by assistive technologies to make the application
  /// more accessible.
  final SemanticsProperties properties;

  /// If [container] is true, this widget will introduce a new
  /// node in the semantics tree. Otherwise, the semantics will be
  /// merged with the semantics of any ancestors (if the ancestor allows that).
  ///
  /// Setting [SemanticsProperties.identifier] also implicitly introduces a new
  /// node, even if [container] is false.
  ///
  /// Whether descendants of this widget can add their semantic information to the
  /// [SemanticsNode] introduced by this configuration is controlled by
  /// [explicitChildNodes].
  final bool container;

  /// Whether descendants of this widget are allowed to add semantic information
  /// to the [SemanticsNode] annotated by this widget.
  ///
  /// When set to false descendants are allowed to annotate [SemanticsNode]s of
  /// their parent with the semantic information they want to contribute to the
  /// semantic tree.
  /// When set to true the only way for descendants to contribute semantic
  /// information to the semantic tree is to introduce new explicit
  /// [SemanticsNode]s to the tree.
  ///
  /// If the semantics properties of this node include
  /// [SemanticsProperties.scopesRoute] set to true, then [explicitChildNodes]
  /// must be true also.
  ///
  /// This setting is often used in combination with [SemanticsConfiguration.isSemanticBoundary]
  /// to create semantic boundaries that are either writable or not for children.
  final bool explicitChildNodes;

  /// The [Locale] for widgets in the subtree.
  ///
  /// If null, the subtree will inherit the locale form ancestor widget.
  final Locale? localeForSubtree;

  /// Whether to replace all child semantics with this node.
  ///
  /// Defaults to false.
  ///
  /// When this flag is set to true, all child semantics nodes are ignored.
  /// This can be used as a convenience for cases where a child is wrapped in
  /// an [ExcludeSemantics] widget and then another [Semantics] widget.
  final bool excludeSemantics;

  /// Whether to block user interactions for the rendering subtree.
  ///
  /// Setting this to true will prevent users from interacting with The
  /// rendering object configured by this widget and its subtree through
  /// pointer-related [SemanticsAction]s in assistive technologies.
  ///
  /// The [SemanticsNode] created from this widget is still focusable by
  /// assistive technologies. Only pointer-related [SemanticsAction]s, such as
  /// [SemanticsAction.tap] or its friends, are blocked.
  ///
  /// If this widget is merged into a parent semantics node, only the
  /// [SemanticsAction]s of this widget and the widgets in the subtree are
  /// blocked.
  ///
  /// For example using [Semantics]:
  /// ```dart
  /// void _myTap() { }
  /// void _myLongPress() { }
  ///
  /// Widget build(BuildContext context) {
  ///   return Semantics(
  ///     onTap: _myTap,
  ///     child: Semantics(
  ///       blockUserActions: true,
  ///       onLongPress: _myLongPress,
  ///       child: const Text('label'),
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// The result semantics node will still have `_myTap`, but the `_myLongPress`
  /// will be blocked.
  ///
  /// and similarly using [SliverSemantics]:
  /// ```dart
  /// void _myTap() { }
  /// void _myLongPress() { }
  ///
  /// Widget build(BuildContext context) {
  ///   return CustomScrollView(
  ///     slivers: <Widget>[
  ///       SliverSemantics(
  ///         onTap: _myTap,
  ///         sliver: SliverSemantics(
  ///           blockUserActions: true,
  ///           onLongPress: _myLongPress,
  ///           sliver: const SliverToBoxAdapter(
  ///             child: Text('label'),
  ///           ),
  ///         ),
  ///       ),
  ///     ],
  ///   );
  /// }
  /// ```
  ///
  /// The result semantics node will still have `_myTap`, but the `_myLongPress`
  /// will be blocked.
  final bool blockUserActions;

  TextDirection? _getTextDirection(BuildContext context) {
    if (properties.textDirection != null) {
      return properties.textDirection;
    }

    final bool containsText =
        properties.label != null ||
        properties.attributedLabel != null ||
        properties.value != null ||
        properties.attributedValue != null ||
        properties.increasedValue != null ||
        properties.attributedIncreasedValue != null ||
        properties.decreasedValue != null ||
        properties.attributedDecreasedValue != null ||
        properties.hint != null ||
        properties.attributedHint != null ||
        properties.tooltip != null;

    if (!containsText) {
      return null;
    }

    return Directionality.maybeOf(context);
  }
}

/// A sliver that annotates its subtree with a description of the meaning of
/// the slivers.
///
/// {@macro flutter.widgets.SemanticsBase}
///  * [Semantics], the widget variant of this sliver.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=lPWrd08swlw}
///
@immutable
class SliverSemantics extends _SemanticsBase {
  /// Creates a semantic annotation.
  ///
  /// To create a `const` instance of [SliverSemantics], use the
  /// [SliverSemantics.fromProperties] constructor.
  ///
  /// {@macro flutter.widgets.SemanticsBase.constructor}
  SliverSemantics({
    super.key,
    required Widget sliver,
    super.container = false,
    super.explicitChildNodes = false,
    super.excludeSemantics = false,
    super.blockUserActions = false,
    super.enabled,
    super.checked,
    super.mixed,
    super.selected,
    super.toggled,
    super.button,
    super.slider,
    super.keyboardKey,
    super.link,
    super.linkUrl,
    super.header,
    super.headingLevel,
    super.textField,
    super.readOnly,
    super.focusable,
    super.focused,
    super.accessibilityFocusBlockType,
    super.inMutuallyExclusiveGroup,
    super.obscured,
    super.multiline,
    super.scopesRoute,
    super.namesRoute,
    super.hidden,
    super.image,
    super.liveRegion,
    super.expanded,
    super.isRequired,
    super.maxValueLength,
    super.currentValueLength,
    super.identifier,
    super.traversalParentIdentifier,
    super.traversalChildIdentifier,
    super.label,
    super.attributedLabel,
    super.value,
    super.attributedValue,
    super.increasedValue,
    super.attributedIncreasedValue,
    super.decreasedValue,
    super.attributedDecreasedValue,
    super.hint,
    super.attributedHint,
    super.tooltip,
    super.onTapHint,
    super.onLongPressHint,
    super.textDirection,
    super.sortKey,
    super.tagForChildren,
    super.onTap,
    super.onLongPress,
    super.onScrollLeft,
    super.onScrollRight,
    super.onScrollUp,
    super.onScrollDown,
    super.onIncrease,
    super.onDecrease,
    super.onCopy,
    super.onCut,
    super.onPaste,
    super.onDismiss,
    super.onMoveCursorForwardByCharacter,
    super.onMoveCursorBackwardByCharacter,
    super.onSetSelection,
    super.onSetText,
    super.onDidGainAccessibilityFocus,
    super.onDidLoseAccessibilityFocus,
    super.onFocus,
    super.onExpand,
    super.onCollapse,
    super.customSemanticsActions,
    super.role,
    super.controlsNodes,
    super.validationResult = SemanticsValidationResult.none,
    super.hitTestBehavior,
    super.inputType,
    super.localeForSubtree,
    super.minValue,
    super.maxValue,
  }) : super(child: sliver);

  /// {@macro flutter.widgets.SemanticsBase.fromProperties}
  const SliverSemantics.fromProperties({
    super.key,
    super.child,
    super.container = false,
    super.explicitChildNodes = false,
    super.excludeSemantics = false,
    super.blockUserActions = false,
    super.localeForSubtree,
    required super.properties,
  }) : super.fromProperties();

  @override
  RenderSliverSemanticsAnnotations createRenderObject(BuildContext context) {
    return RenderSliverSemanticsAnnotations(
      container: container,
      explicitChildNodes: explicitChildNodes,
      excludeSemantics: excludeSemantics,
      blockUserActions: blockUserActions,
      properties: properties,
      localeForSubtree: localeForSubtree,
      textDirection: _getTextDirection(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverSemanticsAnnotations renderObject) {
    renderObject
      ..container = container
      ..explicitChildNodes = explicitChildNodes
      ..excludeSemantics = excludeSemantics
      ..blockUserActions = blockUserActions
      ..properties = properties
      ..textDirection = _getTextDirection(context)
      ..localeForSubtree = localeForSubtree;
  }
}

// UTILITY NODES

/// A widget that annotates the widget tree with a description of the meaning of
/// the widgets.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=NvtMt_DtFrQ}
///
/// {@macro flutter.widgets.SemanticsBase}
///  * [SliverSemantics], the sliver variant of this widget.
@immutable
class Semantics extends _SemanticsBase {
  /// Creates a semantic annotation.
  ///
  /// To create a `const` instance of [Semantics], use the
  /// [Semantics.fromProperties] constructor.
  ///
  /// {@macro flutter.widgets.SemanticsBase}
  Semantics({
    super.key,
    super.child,
    super.container = false,
    super.explicitChildNodes = false,
    super.excludeSemantics = false,
    super.blockUserActions = false,
    super.enabled,
    super.checked,
    super.mixed,
    super.selected,
    super.toggled,
    super.button,
    super.slider,
    super.keyboardKey,
    super.link,
    super.linkUrl,
    super.header,
    super.headingLevel,
    super.textField,
    super.readOnly,
    super.focusable,
    super.focused,
    super.accessibilityFocusBlockType,
    super.inMutuallyExclusiveGroup,
    super.obscured,
    super.multiline,
    super.scopesRoute,
    super.namesRoute,
    super.hidden,
    super.image,
    super.liveRegion,
    super.expanded,
    super.isRequired,
    super.maxValueLength,
    super.currentValueLength,
    super.identifier,
    super.traversalParentIdentifier,
    super.traversalChildIdentifier,
    super.label,
    super.attributedLabel,
    super.value,
    super.attributedValue,
    super.increasedValue,
    super.attributedIncreasedValue,
    super.decreasedValue,
    super.attributedDecreasedValue,
    super.hint,
    super.attributedHint,
    super.tooltip,
    super.onTapHint,
    super.onLongPressHint,
    super.textDirection,
    super.sortKey,
    super.tagForChildren,
    super.onTap,
    super.onLongPress,
    super.onScrollLeft,
    super.onScrollRight,
    super.onScrollUp,
    super.onScrollDown,
    super.onIncrease,
    super.onDecrease,
    super.onCopy,
    super.onCut,
    super.onPaste,
    super.onDismiss,
    super.onMoveCursorForwardByCharacter,
    super.onMoveCursorBackwardByCharacter,
    super.onSetSelection,
    super.onSetText,
    super.onDidGainAccessibilityFocus,
    super.onDidLoseAccessibilityFocus,
    super.onFocus,
    super.onExpand,
    super.onCollapse,
    super.customSemanticsActions,
    super.role,
    super.controlsNodes,
    super.validationResult = SemanticsValidationResult.none,
    super.hitTestBehavior,
    super.inputType,
    super.localeForSubtree,
    super.minValue,
    super.maxValue,
  });

  /// {@macro flutter.widgets.SemanticsBase.fromProperties}
  const Semantics.fromProperties({
    super.key,
    super.child,
    super.container = false,
    super.explicitChildNodes = false,
    super.excludeSemantics = false,
    super.blockUserActions = false,
    super.localeForSubtree,
    required super.properties,
  }) : super.fromProperties();

  @override
  RenderSemanticsAnnotations createRenderObject(BuildContext context) {
    return RenderSemanticsAnnotations(
      container: container,
      explicitChildNodes: explicitChildNodes,
      excludeSemantics: excludeSemantics,
      blockUserActions: blockUserActions,
      properties: properties,
      localeForSubtree: localeForSubtree,
      textDirection: _getTextDirection(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSemanticsAnnotations renderObject) {
    renderObject
      ..container = container
      ..explicitChildNodes = explicitChildNodes
      ..excludeSemantics = excludeSemantics
      ..blockUserActions = blockUserActions
      ..properties = properties
      ..textDirection = _getTextDirection(context)
      ..localeForSubtree = localeForSubtree;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('container', container));
    properties.add(DiagnosticsProperty<SemanticsProperties>('properties', this.properties));
    this.properties.debugFillProperties(properties);
  }
}

/// A widget that merges the semantics of its descendants.
///
/// Causes all the semantics of the subtree rooted at this node to be
/// merged into one node in the semantics tree. For example, if you
/// have a widget with a Text node next to a checkbox widget, this
/// could be used to merge the label from the Text node with the
/// "checked" semantic state of the checkbox into a single node that
/// had both the label and the checked state. Otherwise, the label
/// would be presented as a separate feature than the checkbox, and
/// the user would not be able to be sure that they were related.
///
/// {@tool snippet}
///
/// This snippet shows how to use [MergeSemantics] to merge the semantics of
/// a [Checkbox] and [Text] widget.
///
/// ```dart
/// MergeSemantics(
///   child: Row(
///     children: <Widget>[
///       Checkbox(
///         value: true,
///         onChanged: (bool? value) {},
///       ),
///       const Text('Settings'),
///     ],
///   ),
/// )
/// ```
/// {@end-tool}
///
/// Be aware that if two nodes in the subtree have conflicting
/// semantics, the result may be nonsensical. For example, a subtree
/// with a checked checkbox and an unchecked checkbox will be
/// presented as checked. All the labels will be merged into a single
/// string (with newlines separating each label from the other). If
/// multiple nodes in the merged subtree can handle semantic gestures,
/// the first one in tree order will be the one to receive the
/// callbacks.
class MergeSemantics extends SingleChildRenderObjectWidget {
  /// Creates a widget that merges the semantics of its descendants.
  const MergeSemantics({super.key, super.child});

  @override
  RenderMergeSemantics createRenderObject(BuildContext context) => RenderMergeSemantics();
}

/// A widget that drops the semantics of all widget that were painted before it
/// in the same semantic container.
///
/// This is useful to hide widgets from accessibility tools that are painted
/// behind a certain widget, e.g. an alert should usually disallow interaction
/// with any widget located "behind" the alert (even when they are still
/// partially visible). Similarly, an open [Drawer] blocks interactions with
/// any widget outside the drawer.
///
/// See also:
///
///  * [ExcludeSemantics] which drops all semantics of its descendants.
class BlockSemantics extends SingleChildRenderObjectWidget {
  /// Creates a widget that excludes the semantics of all widgets painted before
  /// it in the same semantic container.
  const BlockSemantics({super.key, this.blocking = true, super.child});

  /// Whether this widget is blocking semantics of all widget that were painted
  /// before it in the same semantic container.
  final bool blocking;

  @override
  RenderBlockSemantics createRenderObject(BuildContext context) =>
      RenderBlockSemantics(blocking: blocking);

  @override
  void updateRenderObject(BuildContext context, RenderBlockSemantics renderObject) {
    renderObject.blocking = blocking;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('blocking', blocking));
  }
}

/// A widget that drops all the semantics of its descendants.
///
/// When [excluding] is true, this widget (and its subtree) is excluded from
/// the semantics tree.
///
/// This can be used to hide descendant widgets that would otherwise be
/// reported but that would only be confusing. For example, the
/// material library's [Chip] widget hides the avatar since it is
/// redundant with the chip label.
///
/// See also:
///
///  * [BlockSemantics] which drops semantics of widgets earlier in the tree.
class ExcludeSemantics extends SingleChildRenderObjectWidget {
  /// Creates a widget that drops all the semantics of its descendants.
  const ExcludeSemantics({super.key, this.excluding = true, super.child});

  /// Whether this widget is excluded in the semantics tree.
  final bool excluding;

  @override
  RenderExcludeSemantics createRenderObject(BuildContext context) =>
      RenderExcludeSemantics(excluding: excluding);

  @override
  void updateRenderObject(BuildContext context, RenderExcludeSemantics renderObject) {
    renderObject.excluding = excluding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('excluding', excluding));
  }
}

/// A widget that annotates the child semantics with an index.
///
/// Semantic indexes are used by TalkBack/Voiceover to make announcements about
/// the current scroll state. Certain widgets like the [ListView] will
/// automatically provide a child index for building semantics. A user may wish
/// to manually provide semantic indexes if not all child of the scrollable
/// contribute semantics.
///
/// {@tool snippet}
///
/// The example below handles spacers in a scrollable that don't contribute
/// semantics. The automatic indexes would give the spaces a semantic index,
/// causing scroll announcements to erroneously state that there are four items
/// visible.
///
/// ```dart
/// ListView(
///   addSemanticIndexes: false,
///   semanticChildCount: 2,
///   children: const <Widget>[
///     IndexedSemantics(index: 0, child: Text('First')),
///     Spacer(),
///     IndexedSemantics(index: 1, child: Text('Second')),
///     Spacer(),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CustomScrollView], for an explanation of index semantics.
class IndexedSemantics extends SingleChildRenderObjectWidget {
  /// Creates a widget that annotated the first child semantics node with an index.
  const IndexedSemantics({super.key, required this.index, super.child});

  /// The index used to annotate the first child semantics node.
  final int index;

  @override
  RenderIndexedSemantics createRenderObject(BuildContext context) =>
      RenderIndexedSemantics(index: index);

  @override
  void updateRenderObject(BuildContext context, RenderIndexedSemantics renderObject) {
    renderObject.index = index;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<int>('index', index));
  }
}

/// A widget that builds its child.
///
/// Useful for attaching a key to an existing widget.
class KeyedSubtree extends StatelessWidget {
  /// Creates a widget that builds its child while assigning it a key.
  ///
  /// This is useful when you want to preserve the state of a widget when it moves
  /// around in the widget tree by associating it with a consistent key.
  const KeyedSubtree({super.key, required this.child});

  /// Creates a KeyedSubtree for child with a key that's based on the child's existing key or childIndex.
  KeyedSubtree.wrap(this.child, int childIndex)
    : super(key: ValueKey<Object>(child.key ?? childIndex));

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Wrap each item in a KeyedSubtree whose key is based on the item's existing key or
  /// the sum of its list index and `baseIndex`.
  static List<Widget> ensureUniqueKeysForList(List<Widget> items, {int baseIndex = 0}) {
    if (items.isEmpty) {
      return items;
    }

    final itemsWithUniqueKeys = <Widget>[
      for (final (int i, Widget item) in items.indexed) KeyedSubtree.wrap(item, baseIndex + i),
    ];

    assert(!debugItemsHaveDuplicateKeys(itemsWithUniqueKeys));
    return itemsWithUniqueKeys;
  }

  @override
  Widget build(BuildContext context) => child;
}

/// A stateless utility widget whose [build] method uses its
/// [builder] callback to create the widget's child.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=xXNOkIuSYuA}
///
/// This widget is an inline alternative to defining a [StatelessWidget]
/// subclass. For example, instead of defining a widget as follows:
///
/// ```dart
/// class Foo extends StatelessWidget {
///   const Foo({super.key});
///   @override
///   Widget build(BuildContext context) => const Text('foo');
/// }
/// ```
///
/// ...and using it in the usual way:
///
/// ```dart
/// // continuing from previous example...
/// const Center(child: Foo())
/// ```
///
/// ...one could instead define and use it in a single step, without
/// defining a new widget class:
///
/// ```dart
/// Center(
///   child: Builder(
///     builder: (BuildContext context) => const Text('foo'),
///   ),
/// )
/// ```
///
/// The difference between either of the previous examples and
/// creating a child directly without an intervening widget, is the
/// extra [BuildContext] element that the additional widget adds. This
/// is particularly noticeable when the tree contains an inherited
/// widget that is referred to by a method like [Scaffold.of],
/// which visits the child widget's BuildContext ancestors.
///
/// In the following example the button's `onPressed` callback is unable
/// to find the enclosing [ScaffoldState] with [Scaffold.of]:
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Center(
///       child: TextButton(
///         onPressed: () {
///           // Fails because Scaffold.of() doesn't find anything
///           // above this widget's context.
///           print(Scaffold.of(context).hasAppBar);
///         },
///         child: const Text('hasAppBar'),
///       )
///     ),
///   );
/// }
/// ```
///
/// A [Builder] widget introduces an additional [BuildContext] element
/// and so the [Scaffold.of] method succeeds.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: Builder(
///       builder: (BuildContext context) {
///         return Center(
///           child: TextButton(
///             onPressed: () {
///               print(Scaffold.of(context).hasAppBar);
///             },
///             child: const Text('hasAppBar'),
///           ),
///         );
///       },
///     ),
///   );
/// }
/// ```
///
/// See also:
///
///  * [StatefulBuilder], A stateful utility widget whose [build] method uses its
///    [builder] callback to create the widget's child.
class Builder extends StatelessWidget {
  /// Creates a widget that delegates its build to a callback.
  const Builder({super.key, required this.builder});

  /// Called to obtain the child widget.
  ///
  /// This function is called whenever this widget is included in its parent's
  /// build and the old widget (if any) that it synchronizes with has a distinct
  /// object identity. Typically the parent's build method will construct
  /// a new tree of widgets and so a new Builder child will not be [identical]
  /// to the corresponding old one.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

/// Signature for the builder callback used by [StatefulBuilder].
///
/// Call `setState` to schedule the [StatefulBuilder] to rebuild.
typedef StatefulWidgetBuilder = Widget Function(BuildContext context, StateSetter setState);

/// A platonic widget that both has state and calls a closure to obtain its child widget.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=syvT63CosNE}
///
/// The [StateSetter] function passed to the [builder] is used to invoke a
/// rebuild instead of a typical [State]'s [State.setState].
///
/// Since the [builder] is re-invoked when the [StateSetter] is called, any
/// variables that represents state should be kept outside the [builder] function.
///
/// {@tool snippet}
///
/// This example shows using an inline StatefulBuilder that rebuilds and that
/// also has state.
///
/// ```dart
/// await showDialog<void>(
///   context: context,
///   builder: (BuildContext context) {
///     int? selectedRadio = 0;
///     return AlertDialog(
///       content: StatefulBuilder(
///         builder: (BuildContext context, StateSetter setState) {
///           return RadioGroup<int>(
///             groupValue: selectedRadio,
///             onChanged: (int? value) {
///               setState(() => selectedRadio = value);
///             },
///             child: Column(
///               mainAxisSize: MainAxisSize.min,
///               children: List<Widget>.generate(4, (int index) {
///                 return Radio<int>(value: index);
///               }),
///             ),
///           );
///         },
///       ),
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Builder], the platonic stateless widget.
class StatefulBuilder extends StatefulWidget {
  /// Creates a widget that both has state and delegates its build to a callback.
  const StatefulBuilder({super.key, required this.builder});

  /// Called to obtain the child widget.
  ///
  /// This function is called whenever this widget is included in its parent's
  /// build and the old widget (if any) that it synchronizes with has a distinct
  /// object identity. Typically the parent's build method will construct
  /// a new tree of widgets and so a new Builder child will not be [identical]
  /// to the corresponding old one.
  final StatefulWidgetBuilder builder;

  @override
  State<StatefulBuilder> createState() => _StatefulBuilderState();
}

class _StatefulBuilderState extends State<StatefulBuilder> {
  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
}

/// A widget that paints its area with a specified [Color] and then draws its
/// child on top of that color.
class ColoredBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that paints its area with the specified [Color].
  const ColoredBox({required this.color, this.isAntiAlias = true, super.child, super.key});

  /// The color to paint the background area with.
  final Color color;

  /// {@template flutter.widgets.ColoredBox.isAntiAlias}
  /// Whether to apply anti-aliasing when painting the box.
  ///
  /// Defaults to `true`.
  ///
  /// When `true`, the painted box will have smooth edges. This is crucial for
  /// animations and transformations (such as rotation or scaling) where the
  /// widget's edges may not align perfectly with the physical pixel grid.
  /// Anti-aliasing allows for sub-pixel rendering, which prevents a 'jagged'
  /// appearance during motion and ensures visually smooth transitions.
  ///
  /// Set this to `false` for specific use cases where multiple `ColoredBox`
  /// widgets are positioned adjacent to each other to form a larger, seamless
  /// area of solid color. With anti-aliasing enabled (`true`), faint seams or
  /// gaps might appear between the boxes due to the semi-transparent pixels at
  /// their edges. Disabling anti-aliasing ensures that the boxes align perfectly
  /// without such visual artifacts.
  ///
  /// See also:
  ///
  ///  * [Paint.isAntiAlias], the underlying property that this controls.
  /// {@endtemplate}
  final bool isAntiAlias;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderColoredBox(color: color, isAntiAlias: isAntiAlias);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderColoredBox)
      ..color = color
      ..isAntiAlias = isAntiAlias;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color>('color', color));
    properties.add(DiagnosticsProperty<bool>('isAntiAlias', isAntiAlias, defaultValue: true));
  }
}

class _RenderColoredBox extends RenderProxyBoxWithHitTestBehavior {
  _RenderColoredBox({required Color color, required bool isAntiAlias})
    : _color = color,
      _isAntiAlias = isAntiAlias,
      super(behavior: HitTestBehavior.opaque);

  /// The fill color for this render object.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value == _color) {
      return;
    }
    _color = value;
    markNeedsPaint();
  }

  bool get isAntiAlias => _isAntiAlias;
  bool _isAntiAlias;
  set isAntiAlias(bool value) {
    if (value == _isAntiAlias) {
      return;
    }
    _isAntiAlias = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // It's tempting to want to optimize out this `drawRect()` call if the
    // color is transparent (alpha==0), but doing so would be incorrect. See
    // https://github.com/flutter/flutter/pull/72526#issuecomment-749185938 for
    // a good description of why.
    if (size > Size.zero) {
      context.canvas.drawRect(
        offset & size,
        Paint()
          ..isAntiAlias = isAntiAlias
          ..color = color,
      );
    }
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }
}
