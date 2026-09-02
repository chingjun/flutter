// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/src/foundation/binding.dart' show BindingBase;
import 'package:flutter/src/foundation/diagnostics.dart' show Diagnosticable;
import 'package:flutter/src/gestures/binding.dart' show GestureBinding;
import 'package:flutter/src/gestures/events.dart' show PointerEvent, PointerHoverEvent;
import 'package:flutter/src/gestures/hit_test.dart' show HitTestEntry, HitTestTarget;
import 'package:flutter/src/rendering/binding.dart' show RendererBinding;
import 'package:flutter/src/rendering/box.dart' show BoxHitTest, BoxHitTestResult, RenderBox;
import 'package:flutter/src/rendering/object.dart' show PipelineOwner;
import 'package:flutter/src/rendering/view.dart' show RenderView;
import 'package:flutter/src/scheduler/binding.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/src/semantics/binding.dart' show SemanticsBinding;
import 'package:flutter/src/services/binding.dart' show ServicesBinding;
import 'package:flutter/src/services/mouse_cursor.dart' show MouseCursor;
import 'package:flutter/src/services/mouse_tracking.dart' show MouseTrackerAnnotation, PointerEnterEventListener, PointerExitEventListener, PointerHoverEventListener;
import 'package:flutter_test/flutter_test.dart' show TestDefaultBinaryMessengerBinding;
import 'package:vector_math/vector_math_64.dart' show Matrix4;

class _TestHitTester extends RenderBox {
  _TestHitTester(this.hitTestOverride);

  final BoxHitTest hitTestOverride;

  @override
  bool hitTest(BoxHitTestResult result, {required ui.Offset position}) {
    return hitTestOverride(result, position);
  }
}

// A binding used to test MouseTracker, allowing the test to override hit test
// searching.
class TestMouseTrackerFlutterBinding extends BindingBase
    with
        SchedulerBinding,
        ServicesBinding,
        GestureBinding,
        SemanticsBinding,
        RendererBinding,
        TestDefaultBinaryMessengerBinding {
  @override
  void initInstances() {
    super.initInstances();
    postFrameCallbacks = <void Function(Duration)>[];
  }

  late final RenderView _renderView = RenderView(view: platformDispatcher.implicitView!);

  late final PipelineOwner _pipelineOwner = PipelineOwner(
    onSemanticsUpdate: (ui.SemanticsUpdate _) {
      assert(false);
    },
  );

  void setHitTest(BoxHitTest hitTest) {
    if (_pipelineOwner.rootNode == null) {
      _pipelineOwner.rootNode = _renderView;
      rootPipelineOwner.adoptChild(_pipelineOwner);
      addRenderView(_renderView);
    }
    _renderView.child = _TestHitTester(hitTest);
  }

  SchedulerPhase? _overridePhase;
  @override
  SchedulerPhase get schedulerPhase => _overridePhase ?? super.schedulerPhase;

  // Manually schedule a post-frame check.
  //
  // In real apps this is done by the renderer binding, but in tests we have to
  // bypass the phase assertion of [MouseTracker.schedulePostFrameCheck].
  void scheduleMouseTrackerPostFrameCheck() {
    final SchedulerPhase? lastPhase = _overridePhase;
    _overridePhase = SchedulerPhase.persistentCallbacks;
    addPostFrameCallback((_) {
      mouseTracker.updateAllDevices();
    });
    _overridePhase = lastPhase;
  }

  List<void Function(Duration)> postFrameCallbacks = <void Function(Duration)>[];

  // Proxy post-frame callbacks.
  @override
  void addPostFrameCallback(void Function(Duration) callback, {String debugLabel = 'callback'}) {
    postFrameCallbacks.add(callback);
  }

  void flushPostFrameCallbacks(Duration duration) {
    for (final void Function(Duration) callback in postFrameCallbacks) {
      callback(duration);
    }
    postFrameCallbacks.clear();
  }
}

// An object that mocks the behavior of a render object with [MouseTrackerAnnotation].
class TestAnnotationTarget with Diagnosticable implements MouseTrackerAnnotation, HitTestTarget {
  const TestAnnotationTarget({
    this.onEnter,
    this.onHover,
    this.onExit,
    this.cursor = MouseCursor.defer,
    this.validForMouseTracker = true,
  });

  @override
  final PointerEnterEventListener? onEnter;

  final PointerHoverEventListener? onHover;

  @override
  final PointerExitEventListener? onExit;

  @override
  final MouseCursor cursor;

  @override
  final bool validForMouseTracker;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerHoverEvent) {
      onHover?.call(event);
    }
  }
}

// A hit test entry that can be assigned with a [TestAnnotationTarget] and an
// optional transform matrix.
class TestAnnotationEntry extends HitTestEntry<TestAnnotationTarget> {
  TestAnnotationEntry(super.target, [Matrix4? transform])
    : transform = transform ?? Matrix4.identity();

  @override
  final Matrix4 transform;
}
