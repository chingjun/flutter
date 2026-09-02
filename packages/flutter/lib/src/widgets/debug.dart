// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/rendering.dart';
/// @docImport 'package:flutter/scheduler.dart';
///
/// @docImport 'binding.dart';
/// @docImport 'focus_manager.dart';
/// @docImport 'focus_scope.dart';
/// @docImport 'widget_inspector.dart';
library;

import 'basic.dart';
import 'framework.dart';
import 'localizations.dart';
import 'lookup_boundary.dart';
import 'media_query.dart';
import 'overlay.dart';

export 'debug_flags.dart';
// debugChildrenHaveDuplicateKeys, debugItemsHaveDuplicateKeys, and
// debugWidgetBuilderValue are defined in framework.dart (to avoid a cyclic
// import) and re-exported here for backward compatibility.
export 'framework.dart'
    show debugChildrenHaveDuplicateKeys, debugItemsHaveDuplicateKeys, debugWidgetBuilderValue;
// debugCheckHasTable is defined in table.dart (to avoid a cyclic import)
// and re-exported here for backward compatibility.
export 'table.dart' show debugCheckHasTable;

// Examples can assume:
// late BuildContext context;
// List<Widget> children = <Widget>[];
// List<Widget> items = <Widget>[];


/// Asserts that the given context has a [MediaQuery] ancestor.
///
/// Used by various widgets to make sure that they are only used in an
/// appropriate context.
///
/// To invoke this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasMediaQuery(context));
/// ```
///
/// Always place this before any early returns, so that the invariant is checked
/// in all cases. This prevents bugs from hiding until a particular codepath is
/// hit.
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasMediaQuery(BuildContext context) {
  assert(() {
    if (context.widget is! MediaQuery &&
        context.getElementForInheritedWidgetOfExactType<MediaQuery>() == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No MediaQuery widget ancestor found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require a MediaQuery widget ancestor.',
        ),
        context.describeWidget('The specific widget that could not find a MediaQuery ancestor was'),
        context.describeOwnershipChain('The ownership chain for the affected widget is'),
        ErrorHint(
          'No MediaQuery ancestor could be found starting from the context '
          'that was passed to MediaQuery.of(). This can happen because the '
          'context used is not a descendant of a View widget, which introduces '
          'a MediaQuery.',
        ),
      ]);
    }
    return true;
  }());
  return true;
}

/// Asserts that the given context has a [Directionality] ancestor.
///
/// Used by various widgets to make sure that they are only used in an
/// appropriate context.
///
/// To invoke this function, use the following pattern, typically in the
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

/// Asserts that the given context has a [Localizations] ancestor that contains
/// a [WidgetsLocalizations] delegate.
///
/// To call this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasWidgetsLocalizations(context));
/// ```
///
/// Always place this before any early returns, so that the invariant is checked
/// in all cases. This prevents bugs from hiding until a particular codepath is
/// hit.
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasWidgetsLocalizations(BuildContext context) {
  assert(() {
    if (Localizations.of<WidgetsLocalizations>(context, WidgetsLocalizations) == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No WidgetsLocalizations found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require WidgetsLocalizations '
          'to be provided by a Localizations widget ancestor.',
        ),
        ErrorDescription(
          'The widgets library uses Localizations to generate messages, '
          'labels, and abbreviations.',
        ),
        ErrorHint(
          'To introduce a WidgetsLocalizations, either use a '
          'WidgetsApp at the root of your application to include them '
          'automatically, or add a Localization widget with a '
          'WidgetsLocalizations delegate.',
        ),
        ...context.describeMissingAncestor(expectedAncestorType: WidgetsLocalizations),
      ]);
    }
    return true;
  }());
  return true;
}

/// Asserts that the given context has an [Overlay] ancestor.
///
/// To call this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasOverlay(context));
/// ```
///
/// Always place this before any early returns, so that the invariant is checked
/// in all cases. This prevents bugs from hiding until a particular codepath is
/// hit.
///
/// This method can be expensive (it walks the element tree).
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasOverlay(BuildContext context) {
  assert(() {
    if (LookupBoundary.findAncestorWidgetOfExactType<Overlay>(context) == null) {
      final bool hiddenByBoundary = LookupBoundary.debugIsHidingAncestorWidgetOfExactType<Overlay>(
        context,
      );
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'No Overlay widget found${hiddenByBoundary ? ' within the closest LookupBoundary' : ''}.',
        ),
        if (hiddenByBoundary)
          ErrorDescription(
            'There is an ancestor Overlay widget, but it is hidden by a LookupBoundary.',
          ),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require an Overlay '
          'widget ancestor within the closest LookupBoundary.\n'
          'An overlay lets widgets float on top of other widget children.',
        ),
        ErrorHint(
          'To introduce an Overlay widget, you can either directly '
          'include one, or use a widget that contains an Overlay itself, '
          'such as a Navigator or WidgetsApp.',
        ),
        ...context.describeMissingAncestor(expectedAncestorType: Overlay),
      ]);
    }
    return true;
  }());
  return true;
}
