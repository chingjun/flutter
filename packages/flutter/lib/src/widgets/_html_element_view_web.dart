// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:ui_web' as ui_web;

import 'package:flutter/src/foundation/basic_types.dart' show Factory;
import 'package:flutter/src/foundation/key.dart' show Key;
import 'package:flutter/src/gestures/events.dart' show PointerEvent;
import 'package:flutter/src/gestures/recognizer.dart' show OneSequenceGestureRecognizer;
import 'package:flutter/src/rendering/platform_view.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/src/services/platform_views.dart' show PlatformViewController, PlatformViewCreatedCallback;
import 'package:flutter/src/services/system_channels.dart' show SystemChannels;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, Widget;
import 'package:flutter/src/widgets/platform_view.dart' show ElementCreatedCallback, HtmlElementView, PlatformViewCreationParams, PlatformViewLink, PlatformViewSurface;

/// The platform-specific implementation of [HtmlElementView].
extension HtmlElementViewImpl on HtmlElementView {
  /// Creates an [HtmlElementView] that renders a DOM element with the given
  /// [tagName].
  static HtmlElementView createFromTagName({
    Key? key,
    required String tagName,
    bool isVisible = true,
    ElementCreatedCallback? onElementCreated,
    required PlatformViewHitTestBehavior hitTestBehavior,
  }) {
    return HtmlElementView(
      key: key,
      viewType: isVisible
          ? ui_web.PlatformViewRegistry.defaultVisibleViewType
          : ui_web.PlatformViewRegistry.defaultInvisibleViewType,
      onPlatformViewCreated: _createPlatformViewCallbackForElementCallback(onElementCreated),
      creationParams: <dynamic, dynamic>{'tagName': tagName},
      hitTestBehavior: hitTestBehavior,
    );
  }

  /// The implementation of [HtmlElementView.build].
  ///
  /// This is not expected to be invoked in non-web environments. It throws if
  /// that happens.
  ///
  /// The implementation on Flutter Web builds an HTML platform view and handles
  /// its lifecycle.
  Widget buildImpl(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      onCreatePlatformView: _createController,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return PlatformViewSurface(
          controller: controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: hitTestBehavior,
        );
      },
    );
  }

  /// Creates the controller and kicks off its initialization.
  _HtmlElementViewController _createController(PlatformViewCreationParams params) {
    final controller = _HtmlElementViewController(params.id, viewType, creationParams);
    controller._initialize().then((_) {
      params.onPlatformViewCreated(params.id);
      onPlatformViewCreated?.call(params.id);
    });
    return controller;
  }
}

PlatformViewCreatedCallback? _createPlatformViewCallbackForElementCallback(
  ElementCreatedCallback? onElementCreated,
) {
  if (onElementCreated == null) {
    return null;
  }
  return (int id) {
    onElementCreated(ui_web.platformViewRegistry.getViewById(id));
  };
}

class _HtmlElementViewController extends PlatformViewController {
  _HtmlElementViewController(this.viewId, this.viewType, this.creationParams);

  @override
  final int viewId;

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  final dynamic creationParams;

  bool _initialized = false;

  Future<void> _initialize() async {
    final args = <String, dynamic>{'id': viewId, 'viewType': viewType, 'params': creationParams};
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    _initialized = true;
  }

  @override
  Future<void> clearFocus() async {
    // Currently this does nothing on Flutter Web.
    // TODO(het): Implement this. See https://github.com/flutter/flutter/issues/39496
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    // We do not dispatch pointer events to HTML views because they may contain
    // cross-origin iframes, which only accept user-generated events.
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      await SystemChannels.platform_views.invokeMethod<void>('dispose', viewId);
    }
  }
}
