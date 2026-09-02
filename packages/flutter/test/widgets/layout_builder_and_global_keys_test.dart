// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/rendering/box.dart' show BoxConstraints;
import 'package:flutter/src/rendering/sliver.dart' show SliverConstraints;
import 'package:flutter/src/widgets/basic.dart' show Builder, Directionality, Row, SizedBox, SliverToBoxAdapter;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, GlobalKey, State, StatefulWidget, StatelessWidget, Widget;
import 'package:flutter/src/widgets/layout_builder.dart' show LayoutBuilder;
import 'package:flutter/src/widgets/placeholder.dart' show Placeholder;
import 'package:flutter/src/widgets/scroll_view.dart' show CustomScrollView;
import 'package:flutter/src/widgets/sliver_layout_builder.dart' show SliverLayoutBuilder;
import 'package:flutter_test/flutter_test.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class StatefulWrapper extends StatefulWidget {
  const StatefulWrapper({super.key, required this.child});

  final Widget child;

  @override
  StatefulWrapperState createState() => StatefulWrapperState();
}

class StatefulWrapperState extends State<StatefulWrapper> {
  void trigger() {
    setState(() {
      /* for test purposes */
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  testWidgets('Moving global key inside a LayoutBuilder', (WidgetTester tester) async {
    final key = GlobalKey<StatefulWrapperState>();
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Wrapper(
            child: StatefulWrapper(key: key, child: Container(height: 100.0)),
          );
        },
      ),
    );
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          key.currentState!.trigger();
          return StatefulWrapper(key: key, child: Container(height: 100.0));
        },
      ),
    );

    expect(tester.takeException(), null);
  });

  testWidgets('Moving GlobalKeys out of LayoutBuilder', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/146379.
    final GlobalKey widgetKey = GlobalKey(debugLabel: 'widget key');
    final Widget widgetWithKey = Builder(
      builder: (BuildContext context) {
        Directionality.of(context);
        return SizedBox(key: widgetKey);
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) => widgetWithKey,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) => const Placeholder(),
            ),
            widgetWithKey,
          ],
        ),
      ),
    );

    expect(tester.takeException(), null);
    expect(find.byKey(widgetKey), findsOneWidget);
  });

  testWidgets('Moving global key inside a SliverLayoutBuilder', (WidgetTester tester) async {
    final key = GlobalKey<StatefulWrapperState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              builder: (BuildContext context, SliverConstraints constraint) {
                return SliverToBoxAdapter(
                  child: Wrapper(
                    child: StatefulWrapper(key: key, child: Container(height: 100.0)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverLayoutBuilder(
              builder: (BuildContext context, SliverConstraints constraint) {
                key.currentState!.trigger();
                return SliverToBoxAdapter(
                  child: StatefulWrapper(key: key, child: Container(height: 100.0)),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), null);
  });
}
