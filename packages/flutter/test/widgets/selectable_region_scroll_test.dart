// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/constants.dart' show kIsWeb;
import 'package:flutter/src/widgets/framework.dart' show BuildContext;
import 'package:flutter/src/widgets/scroll_controller.dart' show ScrollController;
import 'package:flutter/src/widgets/scroll_view.dart' show ListView;
import 'package:flutter/src/widgets/selectable_region.dart' show SelectableRegion;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter/src/widgets/text_selection.dart' show emptyTextSelectionControls;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/122680.
  testWidgets(
    'SelectableRegion in ListView.builder scrolls without error on desktop web',
    (WidgetTester tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        TestWidgetsApp(
          home: ListView.builder(
            controller: scrollController,
            itemCount: 200,
            itemBuilder: (BuildContext context, int index) {
              return SelectableRegion(
                selectionControls: emptyTextSelectionControls,
                child: Text('Item $index\nLine 2\nLine 3'),
              );
            },
          ),
        ),
      );

      scrollController.jumpTo(5000);
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.desktop(),
    skip: !kIsWeb, // [intended] This test verifies web desktop behavior.
  );
}
