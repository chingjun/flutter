// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/cupertino/app.dart' show CupertinoApp;
import 'package:flutter/src/cupertino/colors.dart' show CupertinoColors;
import 'package:flutter/src/cupertino/theme.dart' show CupertinoThemeData;
import 'package:flutter/src/material/theme.dart' show Theme;
import 'package:flutter/src/material/theme_data.dart' show ThemeData;
import 'package:flutter/src/widgets/basic.dart' show Builder, SizedBox;
import 'package:flutter/src/widgets/framework.dart' show BuildContext;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CupertinoApp creates a Material theme with colors based off of Cupertino theme', (
    WidgetTester tester,
  ) async {
    late ThemeData appliedTheme;
    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(primaryColor: CupertinoColors.activeGreen),
        home: Builder(
          builder: (BuildContext context) {
            appliedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(appliedTheme.colorScheme.primary, CupertinoColors.activeGreen);
  });
}
