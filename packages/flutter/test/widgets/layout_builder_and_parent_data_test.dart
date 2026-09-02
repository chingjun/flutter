// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDirection;

import 'package:flutter/src/rendering/box.dart' show BoxConstraints;
import 'package:flutter/src/widgets/basic.dart' show Column, Expanded, Row, SizedBox;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, State, StatefulWidget, Widget;
import 'package:flutter/src/widgets/layout_builder.dart' show LayoutBuilder;
import 'package:flutter_test/flutter_test.dart';

class SizeChanger extends StatefulWidget {
  const SizeChanger({super.key, required this.child});

  final Widget child;

  @override
  SizeChangerState createState() => SizeChangerState();
}

class SizeChangerState extends State<SizeChanger> {
  bool _flag = false;

  void trigger() {
    setState(() {
      _flag = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      children: <Widget>[SizedBox(height: _flag ? 50.0 : 100.0, width: 100.0, child: widget.child)],
    );
  }
}

void main() {
  testWidgets('Applying parent data inside a LayoutBuilder', (WidgetTester tester) async {
    var frame = 1;
    await tester.pumpWidget(
      SizeChanger(
        // when this is triggered, the child LayoutBuilder will build again
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              children: <Widget>[
                Expanded(
                  flex:
                      frame, // this is different after the next pump, so that the parentData has to be applied again
                  child: Container(height: 100.0),
                ),
              ],
            );
          },
        ),
      ),
    );
    frame += 1;
    tester.state<SizeChangerState>(find.byType(SizeChanger)).trigger();
    await tester.pump();
  });
}
