// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// @docImport 'editable_text.dart';
/// @docImport 'undo_history.dart';
library;

import 'package:flutter/src/foundation/object.dart' show objectRuntimeType;
import 'package:listen/listen.dart' show ChangeNotifier, ValueNotifier;
import 'package:meta/meta.dart' show immutable;

/// Represents whether the current undo stack can undo or redo.
@immutable
class UndoHistoryValue {
  /// Creates a value for whether the current undo stack can undo or redo.
  ///
  /// The [canUndo] and [canRedo] arguments must have a value, but default to
  /// false.
  const UndoHistoryValue({this.canUndo = false, this.canRedo = false});

  /// A value corresponding to an undo stack that can neither undo nor redo.
  static const UndoHistoryValue empty = UndoHistoryValue();

  /// Whether the current undo stack can perform an undo operation.
  final bool canUndo;

  /// Whether the current undo stack can perform a redo operation.
  final bool canRedo;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'UndoHistoryValue')}(canUndo: $canUndo, canRedo: $canRedo)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is UndoHistoryValue && other.canUndo == canUndo && other.canRedo == canRedo;
  }

  @override
  int get hashCode => Object.hash(canUndo.hashCode, canRedo.hashCode);
}

/// A controller for the undo history, for example for an editable text field.
///
/// Whenever a change happens to the underlying value that the [UndoHistory]
/// widget tracks, that widget updates the [value] and the controller notifies
/// it's listeners. Listeners can then read the canUndo and canRedo
/// properties of the value to discover whether [undo] or [redo] are possible.
///
/// The controller also has [undo] and [redo] methods to modify the undo
/// history.
///
/// {@tool dartpad}
/// This example creates a [TextField] with an [UndoHistoryController]
/// which provides undo and redo buttons.
///
/// ** See code in examples/api/lib/widgets/undo_history/undo_history_controller.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [EditableText], which uses the [UndoHistory] widget and allows
///   control of the underlying history using an [UndoHistoryController].
class UndoHistoryController extends ValueNotifier<UndoHistoryValue> {
  /// Creates a controller for an [UndoHistory] widget.
  UndoHistoryController({UndoHistoryValue? value}) : super(value ?? UndoHistoryValue.empty);

  /// Notifies listeners that [undo] has been called.
  final ChangeNotifier onUndo = ChangeNotifier();

  /// Notifies listeners that [redo] has been called.
  final ChangeNotifier onRedo = ChangeNotifier();

  /// Reverts the value on the stack to the previous value.
  void undo() {
    if (!value.canUndo) {
      return;
    }

    onUndo.notifyListeners();
  }

  /// Updates the value on the stack to the next value.
  void redo() {
    if (!value.canRedo) {
      return;
    }

    onRedo.notifyListeners();
  }

  @override
  void dispose() {
    onUndo.dispose();
    onRedo.dispose();
    super.dispose();
  }
}
