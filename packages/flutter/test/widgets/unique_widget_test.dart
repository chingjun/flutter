// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, GlobalKey, State, Widget;
import 'package:flutter/src/widgets/unique_widget.dart' show UniqueWidget;
import 'package:flutter_test/flutter_test.dart';

class TestUniqueWidget extends UniqueWidget<TestUniqueWidgetState> {
  const TestUniqueWidget({required super.key});

  @override
  TestUniqueWidgetState createState() => TestUniqueWidgetState();
}

class TestUniqueWidgetState extends State<TestUniqueWidget> {
  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  testWidgets('Unique widget control test', (WidgetTester tester) async {
    final widget = TestUniqueWidget(key: GlobalKey<TestUniqueWidgetState>());

    await tester.pumpWidget(widget);

    final TestUniqueWidgetState state = widget.currentState!;

    expect(state, isNotNull);

    await tester.pumpWidget(Container(child: widget));

    expect(widget.currentState, equals(state));
  });
}
