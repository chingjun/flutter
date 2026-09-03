// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:flutter/src/animation/animation.dart' show Animation;
import 'package:flutter/src/foundation/diagnostics.dart' show DiagnosticPropertiesBuilder, DiagnosticsProperty;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, State, StatefulWidget, TransitionBuilder, Widget;
import 'package:listen/listen.dart' show ChangeNotifier, Listenable, ValueNotifier;
import 'package:meta/meta.dart' show protected;

/// A widget that rebuilds when the given [Listenable] changes value.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=LKKgYpC-EPQ}
///
/// [AnimatedWidget] is most commonly used with [Animation] objects, which are
/// [Listenable], but it can be used with any [Listenable], including
/// [ChangeNotifier] and [ValueNotifier].
///
/// [AnimatedWidget] is most useful for widgets that are otherwise stateless. To
/// use [AnimatedWidget], subclass it and implement the build function.
///
/// {@tool dartpad}
/// This code defines a widget called `Spinner` that spins a green square
/// continually. It is built with an [AnimatedWidget].
///
/// ** See code in examples/api/lib/widgets/transitions/animated_widget.0.dart **
/// {@end-tool}
///
/// For more complex case involving additional state, consider using
/// [AnimatedBuilder] or [ListenableBuilder].
///
/// ## Relationship to [ImplicitlyAnimatedWidget]s
///
/// [AnimatedWidget]s (and their subclasses) take an explicit [Listenable] as
/// argument, which is usually an [Animation] derived from an
/// [AnimationController]. In most cases, the lifecycle of that
/// [AnimationController] has to be managed manually by the developer.
/// In contrast to that, [ImplicitlyAnimatedWidget]s (and their subclasses)
/// automatically manage their own internal [AnimationController] making those
/// classes easier to use as no external [Animation] has to be provided by the
/// developer. If you only need to set a target value for the animation and
/// configure its duration/curve, consider using (a subclass of)
/// [ImplicitlyAnimatedWidget]s instead of (a subclass of) this class.
///
/// ## Common animated widgets
///
/// A number of animated widgets ship with the framework. They are usually named
/// `FooTransition`, where `Foo` is the name of the non-animated
/// version of that widget. The subclasses of this class should not be confused
/// with subclasses of [ImplicitlyAnimatedWidget] (see above), which are usually
/// named `AnimatedFoo`. Commonly used animated widgets include:
///
///  * [ListenableBuilder], which uses a builder pattern that is useful for
///    complex [Listenable] use cases.
///  * [AnimatedBuilder], which uses a builder pattern that is useful for
///    complex [Animation] use cases.
///  * [AlignTransition], which is an animated version of [Align].
///  * [DecoratedBoxTransition], which is an animated version of [DecoratedBox].
///  * [DefaultTextStyleTransition], which is an animated version of
///    [DefaultTextStyle].
///  * [PositionedTransition], which is an animated version of [Positioned].
///  * [RelativePositionedTransition], which is an animated version of
///    [Positioned].
///  * [RotationTransition], which animates the rotation of a widget.
///  * [ScaleTransition], which animates the scale of a widget.
///  * [SizeTransition], which animates its own size.
///  * [SlideTransition], which animates the position of a widget relative to
///    its normal position.
///  * [FadeTransition], which is an animated version of [Opacity].
///  * [AnimatedModalBarrier], which is an animated version of [ModalBarrier].
abstract class AnimatedWidget extends StatefulWidget {
  /// Creates a widget that rebuilds when the given listenable changes.
  ///
  /// The [listenable] argument is required.
  const AnimatedWidget({super.key, required this.listenable});

  /// The [Listenable] to which this widget is listening.
  ///
  /// Commonly an [Animation] or a [ChangeNotifier].
  final Listenable listenable;

  /// Override this method to build widgets that depend on the state of the
  /// listenable (e.g., the current value of the animation).
  @protected
  Widget build(BuildContext context);

  /// Subclasses typically do not override this method.
  @override
  State<AnimatedWidget> createState() => _AnimatedState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Listenable>('listenable', listenable));
  }
}

class _AnimatedState extends State<AnimatedWidget> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(AnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_handleChange);
      widget.listenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) {
      return;
    }
    setState(() {
      // The listenable's state is our build state, and it changed already.
    });
  }

  @override
  Widget build(BuildContext context) => widget.build(context);
}

/// A builder that rebuilds when a given [Listenable] changes value.
///
/// [ListenableBuilder] is useful for more complex widgets that wish to listen
/// to changes in other objects as part of a larger build function. To use
/// [ListenableBuilder], construct the widget and pass it a [builder]
/// function.
///
/// Any subtype of [Listenable] (such as a [ChangeNotifier], [ValueNotifier], or
/// [Animation]) can be used with a [ListenableBuilder] to rebuild only certain
/// parts of a widget when the [Listenable] notifies its listeners. Although
/// they have identical implementations, if an [Animation] is being listened to,
/// consider using an [AnimatedBuilder] instead for better readability.
///
/// ## Performance optimizations
///
/// {@template flutter.widgets.transitions.ListenableBuilder.optimizations}
/// If the [builder] function contains a subtree that does not depend on the
/// [listenable], it is more efficient to build that subtree once instead
/// of rebuilding it on every change of the [listenable].
///
/// Performance is therefore improved by specifying any widgets that don't need
/// to change using the prebuilt [child] attribute. The [ListenableBuilder]
/// passes this [child] back to the [builder] callback so that it can be
/// incorporated into the build.
///
/// Using this pre-built [child] is entirely optional, but can improve
/// performance significantly in some cases and is therefore a good practice.
/// {@endtemplate}
///
/// {@tool dartpad}
/// This example shows how a [ListenableBuilder] can be used to listen to a
/// [FocusNode] (which is also a [ChangeNotifier]) to see when a subtree has
/// focus, and modify a decoration when its focus state changes. Only the
/// [Container] is rebuilt when the [FocusNode] changes; the rest of the tree
/// (notably the [Focus] widget) remain unchanged from frame to frame.
///
/// ** See code in examples/api/lib/widgets/transitions/listenable_builder.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [AnimatedBuilder], which has the same functionality, but is named more
///   appropriately for a builder triggered by [Animation]s.
/// * [ValueListenableBuilder], which is specialized for [ValueNotifier]s and
///   reports the new value in its builder callback.
class ListenableBuilder extends AnimatedWidget {
  /// Creates a builder that responds to changes in [listenable].
  const ListenableBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  /// The [Listenable] supplied to the constructor.
  ///
  /// {@tool dartpad}
  /// In this example, the [listenable] is a [ChangeNotifier] subclass that
  /// encapsulates a list. The [ListenableBuilder] is rebuilt each time an item
  /// is added to the list.
  ///
  /// ** See code in examples/api/lib/widgets/transitions/listenable_builder.3.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  /// * [AnimatedBuilder], a widget with identical functionality commonly
  ///   used with [Animation] [Listenable]s for better readability.
  //
  // Overridden getter to replace with documentation tailored to
  // ListenableBuilder.
  @override
  Listenable get listenable => super.listenable;

  /// Called every time the [listenable] notifies about a change.
  ///
  /// The child given to the builder should typically be part of the returned
  /// widget tree.
  final TransitionBuilder builder;

  /// The child widget to pass to the [builder].
  ///
  /// {@macro flutter.widgets.transitions.ListenableBuilder.optimizations}
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);
}
