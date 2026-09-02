// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size, TextDirection;

import 'package:flutter/src/painting/binding.dart' show imageCache;
import 'package:flutter/src/painting/image_provider.dart' show ImageProvider;
import 'package:flutter/src/rendering/box.dart' show RenderBox;
import 'package:flutter/src/widgets/basic.dart' show Center, Directionality, SizedBox;
import 'package:flutter/src/widgets/icon_theme.dart' show IconTheme;
import 'package:flutter/src/widgets/icon_theme_data.dart' show IconThemeData;
import 'package:flutter/src/widgets/image.dart' show Image;
import 'package:flutter/src/widgets/image_icon.dart' show ImageIcon;
import 'package:flutter_test/flutter_test.dart';

import '../painting/mocks_for_image_cache.dart';

void main() {
  late ImageProvider image;

  setUpAll(() async {
    image = TestImageProvider(21, 42, image: await createTestImage(width: 10, height: 10));
  });

  testWidgets('ImageIcon sizing - no theme, default size', (WidgetTester tester) async {
    await tester.pumpWidget(Center(child: ImageIcon(image)));

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(24.0)));
    expect(find.byType(Image), findsOneWidget);

    imageCache.clear();
  });

  testWidgets('Icon opacity', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: IconTheme(data: const IconThemeData(opacity: 0.5), child: ImageIcon(image)),
      ),
    );

    expect(tester.widget<Image>(find.byType(Image)).color!.alpha, equals(128));

    imageCache.clear();
  });

  testWidgets('ImageIcon sizing - no theme, explicit size', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(child: ImageIcon(null, size: 96.0)));

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(96.0)));
  });

  testWidgets('ImageIcon sizing - sized theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: IconTheme(data: IconThemeData(size: 36.0), child: ImageIcon(null)),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(36.0)));
  });

  testWidgets('ImageIcon sizing - sized theme, explicit size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: IconTheme(data: IconThemeData(size: 36.0), child: ImageIcon(null, size: 48.0)),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(48.0)));
  });

  testWidgets('ImageIcon sizing - sizeless theme, default size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: IconTheme(data: IconThemeData(), child: ImageIcon(null)),
      ),
    );

    final RenderBox renderObject = tester.renderObject(find.byType(ImageIcon));
    expect(renderObject.size, equals(const Size.square(24.0)));
  });

  testWidgets('ImageIcon has semantics data', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IconTheme(
            data: IconThemeData(),
            child: ImageIcon(null, semanticLabel: 'test'),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(ImageIcon)),
      matchesSemantics(label: 'test', textDirection: TextDirection.ltr),
    );
    handle.dispose();
  });

  testWidgets('ImageIcon respects IconTheme color by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: const IconThemeData(color: Color(0xFF0000FF)),
          child: ImageIcon(image),
        ),
      ),
    );

    expect(tester.widget<Image>(find.byType(Image)).color, const Color(0xFF0000FF));
    imageCache.clear();
  });

  testWidgets('ImageIcon ignores IconTheme color when useOriginalColors is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: const IconThemeData(color: Color(0xFF0000FF)),
          child: ImageIcon(image, useOriginalColors: true),
        ),
      ),
    );

    expect(tester.widget<Image>(find.byType(Image)).color, null);
    imageCache.clear();
  });

  testWidgets(
    'ImageIcon throws assertion error if color is provided and useOriginalColors is true',
    (WidgetTester tester) async {
      expect(
        () => ImageIcon(image, color: const Color(0xFF0000FF), useOriginalColors: true),
        throwsAssertionError,
      );

      imageCache.clear();
    },
  );

  testWidgets('ImageIcon does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox.shrink(child: ImageIcon(image))),
      ),
    );
    expect(tester.getSize(find.byType(ImageIcon)), Size.zero);
    imageCache.clear();
  });
}
