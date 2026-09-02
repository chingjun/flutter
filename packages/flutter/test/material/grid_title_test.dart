// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Size, TextDirection;

import 'package:flutter/src/foundation/key.dart' show Key, UniqueKey;
import 'package:flutter/src/material/app.dart' show MaterialApp;
import 'package:flutter/src/material/colors.dart' show Colors;
import 'package:flutter/src/material/grid_tile.dart' show GridTile;
import 'package:flutter/src/material/grid_tile_bar.dart' show GridTileBar;
import 'package:flutter/src/material/icons.dart' show Icons;
import 'package:flutter/src/painting/box_decoration.dart' show BoxDecoration;
import 'package:flutter/src/widgets/basic.dart' show Center, Directionality, SizedBox;
import 'package:flutter/src/widgets/container.dart' show DecoratedBox;
import 'package:flutter/src/widgets/icon.dart' show Icon;
import 'package:flutter/src/widgets/text.dart' show Text;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GridTile control test', (WidgetTester tester) async {
    final Key headerKey = UniqueKey();
    final Key footerKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: GridTile(
          header: GridTileBar(
            key: headerKey,
            leading: const Icon(Icons.thumb_up),
            title: const Text('Header'),
            subtitle: const Text('Subtitle'),
            trailing: const Icon(Icons.thumb_up),
          ),
          footer: GridTileBar(
            key: footerKey,
            title: const Text('Footer'),
            backgroundColor: Colors.black38,
          ),
          child: DecoratedBox(decoration: BoxDecoration(color: Colors.green[500])),
        ),
      ),
    );

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);

    expect(
      tester.getBottomLeft(find.byKey(headerKey)).dy,
      lessThan(tester.getTopLeft(find.byKey(footerKey)).dy),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: GridTile(child: Text('Simple')),
      ),
    );

    expect(find.text('Simple'), findsOneWidget);
  });

  testWidgets('GridTile does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox.shrink(child: GridTile(child: Text('X'))),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GridTile)), Size.zero);
  });

  testWidgets('GridTileBar does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox.shrink(child: GridTileBar(title: Text('X'))),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GridTileBar)), Size.zero);
  });
}
