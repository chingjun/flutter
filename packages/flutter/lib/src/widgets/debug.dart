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

import 'package:flutter/src/foundation/assertions.dart' show ErrorDescription, ErrorHint, ErrorSummary, FlutterError;
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticsNode;

import 'package:flutter/src/widgets/framework.dart' show BuildContext;
import 'package:flutter/src/widgets/localizations.dart' show Localizations, WidgetsLocalizations;
import 'package:flutter/src/widgets/lookup_boundary.dart' show LookupBoundary;
import 'package:flutter/src/widgets/media_query.dart' show MediaQuery;
import 'package:flutter/src/widgets/overlay.dart' show Overlay;

export 'debug_flags.dart';
export 'directionality.dart' show debugCheckHasDirectionality;
export 'framework.dart'
    show debugChildrenHaveDuplicateKeys, debugItemsHaveDuplicateKeys, debugWidgetBuilderValue;

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
