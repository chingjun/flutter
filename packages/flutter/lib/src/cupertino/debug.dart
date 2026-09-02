// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/cupertino/localizations.dart' show CupertinoLocalizations;
import 'package:flutter/src/foundation/assertions.dart' show ErrorDescription, ErrorHint, ErrorSummary, FlutterError;
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticsNode;
import 'package:flutter/src/widgets/framework.dart' show BuildContext;
import 'package:flutter/src/widgets/localizations.dart' show Localizations;

// Examples can assume:
// late BuildContext context;

/// Asserts that the given context has a [Localizations] ancestor that contains
/// a [CupertinoLocalizations] delegate.
///
/// To call this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasCupertinoLocalizations(context));
/// ```
///
/// Always place this before any early returns, so that the invariant is checked
/// in all cases. This prevents bugs from hiding until a particular codepath is
/// hit.
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasCupertinoLocalizations(BuildContext context) {
  assert(() {
    if (Localizations.of<CupertinoLocalizations>(context, CupertinoLocalizations) == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No CupertinoLocalizations found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require CupertinoLocalizations '
          'to be provided by a Localizations widget ancestor.',
        ),
        ErrorDescription(
          'The cupertino library uses Localizations to generate messages, '
          'labels, and abbreviations.',
        ),
        ErrorHint(
          'To introduce a CupertinoLocalizations, either use a '
          'CupertinoApp at the root of your application to include them '
          'automatically, or add a Localization widget with a '
          'CupertinoLocalizations delegate.',
        ),
        ...context.describeMissingAncestor(expectedAncestorType: CupertinoLocalizations),
      ]);
    }
    return true;
  }());
  return true;
}
