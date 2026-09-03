// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'dart:ui' show TextDirection;

import 'package:flutter/src/foundation/assertions.dart' show ErrorDescription, ErrorHint, ErrorSummary, FlutterError;
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticPropertiesBuilder, DiagnosticsNode, EnumProperty;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, Element, ElementVisitor, InheritedElement, InheritedWidget, Widget;

// BIDIRECTIONAL TEXT SUPPORT

/// An [InheritedElement] that has hundreds of dependencies but will
/// infrequently change. This provides a performance tradeoff where building
/// the [Widget]s is faster but performing updates is slower.
///
/// |                     | _UbiquitousInheritedElement | InheritedElement |
/// |---------------------|------------------------------|------------------|
/// | insert (best case)  | O(1)                         | O(1)             |
/// | insert (worst case) | O(1)                         | O(n)             |
/// | search (best case)  | O(n)                         | O(1)             |
/// | search (worst case) | O(n)                         | O(n)             |
///
/// Insert happens when building the [Widget] tree, search happens when updating
/// [Widget]s.
class _UbiquitousInheritedElement extends InheritedElement {
  /// Creates an element that uses the given widget as its configuration.
  _UbiquitousInheritedElement(super.widget);

  @override
  void setDependencies(Element dependent, Object? value) {
    // This is where the cost of [InheritedElement] is incurred during build
    // time of the widget tree. Omitting this bookkeeping is where the
    // performance savings come from.
    assert(value == null);
  }

  @override
  Object? getDependencies(Element dependent) {
    return null;
  }

  @override
  void notifyClients(InheritedWidget oldWidget) {
    _recurseChildren(this, (Element element) {
      if (element.doesDependOnInheritedElement(this)) {
        notifyDependent(oldWidget, element);
      }
    });
  }

  static void _recurseChildren(Element element, ElementVisitor visitor) {
    element.visitChildren((Element child) {
      _recurseChildren(child, visitor);
    });
    visitor(element);
  }
}

/// See also:
///
///  * [_UbiquitousInheritedElement], the [Element] for [_UbiquitousInheritedWidget].
abstract class _UbiquitousInheritedWidget extends InheritedWidget {
  const _UbiquitousInheritedWidget({super.key, required super.child});

  @override
  InheritedElement createElement() => _UbiquitousInheritedElement(this);
}

/// A widget that determines the ambient directionality of text and
/// text-direction-sensitive render objects.
///
/// For example, [Padding] depends on the [Directionality] to resolve
/// [EdgeInsetsDirectional] objects into absolute [EdgeInsets] objects.
///
/// {@tool snippet}
///
/// This example uses a right-to-left [TextDirection] and draws a blue box with
/// a right margin of 8 pixels.
///
/// ```dart
/// Directionality(
///   textDirection: TextDirection.rtl,
///   child: Container(
///     margin: const EdgeInsetsDirectional.only(start: 8),
///     color: Colors.blue,
///   ),
/// )
/// ```
/// {@end-tool}
class Directionality extends _UbiquitousInheritedWidget {
  /// Creates a widget that determines the directionality of text and
  /// text-direction-sensitive render objects.
  const Directionality({super.key, required this.textDirection, required super.child});

  /// The text direction for this subtree.
  final TextDirection textDirection;

  /// The text direction from the closest instance of this class that encloses
  /// the given context.
  ///
  /// If there is no [Directionality] ancestor widget in the tree at the given
  /// context, then this will throw a descriptive [FlutterError] in debug mode
  /// and an exception in release mode.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TextDirection textDirection = Directionality.of(context);
  /// ```
  ///
  /// See also:
  ///
  ///  * [maybeOf], which will return null if no [Directionality] ancestor
  ///    widget is in the tree.
  static TextDirection of(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final Directionality widget = context.dependOnInheritedWidgetOfExactType<Directionality>()!;
    return widget.textDirection;
  }

  /// The text direction from the closest instance of this class that encloses
  /// the given context.
  ///
  /// If there is no [Directionality] ancestor widget in the tree at the given
  /// context, then this will return null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TextDirection? textDirection = Directionality.maybeOf(context);
  /// ```
  ///
  /// See also:
  ///
  ///  * [of], which will throw if no [Directionality] ancestor widget is in the
  ///    tree.
  static TextDirection? maybeOf(BuildContext context) {
    final Directionality? widget = context.dependOnInheritedWidgetOfExactType<Directionality>();
    return widget?.textDirection;
  }

  @override
  bool updateShouldNotify(Directionality oldWidget) => textDirection != oldWidget.textDirection;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
  }
}

/// Asserts that the given context has a [Directionality] ancestor.
///
/// Used by various widgets to make sure that they are only used in an
/// appropriate context.
///
/// To call this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasDirectionality(context));
/// ```
///
/// To improve the error messages you can add some extra color using the
/// named arguments.
///
///  * why: explain why the direction is needed, for example "to resolve
///    the 'alignment' argument". Should be an adverb phrase describing why.
///  * hint: explain why this might be happening, for example "The default
///    value of the 'alignment' argument of the $runtimeType widget is an
///    AlignmentDirectional value.". Should be a fully punctuated sentence.
///  * alternative: provide additional advice specific to the situation,
///    especially an alternative to providing a Directionality ancestor.
///    For example, "Alternatively, consider specifying the 'textDirection'
///    argument.". Should be a fully punctuated sentence.
///
/// Each one can be null, in which case it is skipped (this is the default).
/// If they are non-null, they are included in the order above, interspersed
/// with the more generic advice regarding [Directionality].
///
/// Always place this before any early returns, so that the invariant is checked
/// in all cases. This prevents bugs from hiding until a particular codepath is
/// hit.
///
/// Does nothing if asserts are disabled. Always returns true.
///
/// See also:
///
///  * [debugCheckHasDirectionality], which is a similar, but more general
///    painting-library level function.
bool debugCheckHasDirectionality(
  BuildContext context, {
  String? why,
  String? hint,
  String? alternative,
}) {
  assert(() {
    if (context.widget is! Directionality &&
        context.getElementForInheritedWidgetOfExactType<Directionality>() == null) {
      why = why == null ? '' : ' $why';
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No Directionality widget found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require a Directionality widget ancestor$why.\n',
        ),
        if (hint != null) ErrorHint(hint),
        context.describeWidget(
          'The specific widget that could not find a Directionality ancestor was',
        ),
        context.describeOwnershipChain('The ownership chain for the affected widget is'),
        ErrorHint(
          'Typically, the Directionality widget is introduced by the WidgetsApp '
          'widget at the top of your application widget tree. It '
          'determines the ambient reading direction and is used, for example, to '
          'determine how to lay out text, how to interpret "start" and "end" '
          'values, and to resolve EdgeInsetsDirectional, '
          'AlignmentDirectional, and other *Directional objects.',
        ),
        if (alternative != null) ErrorHint(alternative),
      ]);
    }
    return true;
  }());
  return true;
}
