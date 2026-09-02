// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size;

import 'package:flutter/src/cupertino/desktop_text_selection_toolbar.dart' show CupertinoDesktopTextSelectionToolbar;
import 'package:flutter/src/cupertino/desktop_text_selection_toolbar_button.dart' show CupertinoDesktopTextSelectionToolbarButton;
import 'package:flutter/src/cupertino/text_selection_toolbar.dart' show CupertinoTextSelectionToolbar;
import 'package:flutter/src/cupertino/text_selection_toolbar_button.dart' show CupertinoTextSelectionToolbarButton;
import 'package:flutter/src/foundation/constants.dart' show kIsWeb;
import 'package:flutter/src/foundation/platform.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/src/material/adaptive_text_selection_toolbar.dart' show AdaptiveTextSelectionToolbar;
import 'package:flutter/src/material/app.dart' show MaterialApp;
import 'package:flutter/src/material/colors.dart' show Colors;
import 'package:flutter/src/material/desktop_text_selection_toolbar.dart' show DesktopTextSelectionToolbar;
import 'package:flutter/src/material/desktop_text_selection_toolbar_button.dart' show DesktopTextSelectionToolbarButton;
import 'package:flutter/src/material/scaffold.dart' show Scaffold;
import 'package:flutter/src/material/text_selection.dart' show materialTextSelectionHandleControls;
import 'package:flutter/src/material/text_selection_toolbar.dart' show TextSelectionToolbar;
import 'package:flutter/src/material/text_selection_toolbar_text_button.dart' show TextSelectionToolbarTextButton;
import 'package:flutter/src/painting/text_style.dart' show TextStyle;
import 'package:flutter/src/services/clipboard.dart' show Clipboard, ClipboardData;
import 'package:flutter/src/services/system_channels.dart' show SystemChannels;
import 'package:flutter/src/services/text_editing.dart' show TextSelection;
import 'package:flutter/src/widgets/basic.dart' show Builder, Center, SizedBox;
import 'package:flutter/src/widgets/container.dart' show Container;
import 'package:flutter/src/widgets/context_menu_button_item.dart' show ContextMenuButtonItem, ContextMenuButtonType;
import 'package:flutter/src/widgets/editable_text.dart' show EditableText, EditableTextState, TextEditingController;
import 'package:flutter/src/widgets/focus_manager.dart' show FocusNode;
import 'package:flutter/src/widgets/framework.dart' show BuildContext, GlobalKey, Widget;
import 'package:flutter/src/widgets/scroll_view.dart' show ListView;
import 'package:flutter/src/widgets/text_selection.dart' show ClipboardStatus;
import 'package:flutter/src/widgets/text_selection_toolbar_anchors.dart' show TextSelectionToolbarAnchors;
import 'package:flutter_test/flutter_test.dart';

import '../widgets/clipboard_utils.dart';
import '../widgets/text_selection_toolbar_utils.dart';
import 'editable_text_utils.dart';
import 'live_text_utils.dart';

void main() {
  final mockClipboard = MockClipboard();

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      mockClipboard.handleMethodCall,
    );
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  testWidgets(
    'Builds the right toolbar on each platform, including web, and shows buttonItems',
    (WidgetTester tester) async {
      const buttonText = 'Click me';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AdaptiveTextSelectionToolbar.buttonItems(
                anchors: const TextSelectionToolbarAnchors(primaryAnchor: Offset.zero),
                buttonItems: <ContextMenuButtonItem>[
                  ContextMenuButtonItem(label: buttonText, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          expect(find.byType(TextSelectionToolbar), findsOneWidget);
          expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
          expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
          expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
        case TargetPlatform.iOS:
          expect(find.byType(TextSelectionToolbar), findsNothing);
          expect(find.byType(CupertinoTextSelectionToolbar), findsOneWidget);
          expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
          expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
        case TargetPlatform.macOS:
          expect(find.byType(TextSelectionToolbar), findsNothing);
          expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
          expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
          expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsOneWidget);
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(find.byType(TextSelectionToolbar), findsNothing);
          expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
          expect(find.byType(DesktopTextSelectionToolbar), findsOneWidget);
          expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
      }
    },
    variant: TargetPlatformVariant.all(),
    skip: isBrowser, // [intended] see https://github.com/flutter/flutter/issues/108382
  );

  testWidgets('Can build children directly as well', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveTextSelectionToolbar(
              anchors: const TextSelectionToolbarAnchors(primaryAnchor: Offset.zero),
              children: <Widget>[Container(key: key)],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets(
    'Can build from EditableTextState',
    (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final controller = TextEditingController();
      final focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: EditableText(
                  controller: controller,
                  backgroundCursorColor: const Color(0xff00ffff),
                  focusNode: focusNode,
                  style: const TextStyle(),
                  cursorColor: const Color(0xff00ffff),
                  selectionControls: materialTextSelectionHandleControls,
                  contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                    return AdaptiveTextSelectionToolbar.editableText(
                      key: key,
                      editableTextState: editableTextState,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(); // Wait for autofocus to take effect.

      expect(find.byKey(key), findsNothing);

      // Long-press to bring up the context menu.
      final Finder textFinder = find.byType(EditableText);
      await tester.longPress(textFinder);
      tester.state<EditableTextState>(textFinder).showToolbar();
      await tester.pumpAndSettle();

      expect(find.byKey(key), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Cut'), findsNothing);
      expect(find.text('Select all'), findsNothing);
      expect(find.text('Paste'), findsOneWidget);

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          expect(find.byType(TextSelectionToolbarTextButton), findsOneWidget);
        case TargetPlatform.iOS:
          expect(find.byType(CupertinoTextSelectionToolbarButton), findsOneWidget);
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(find.byType(DesktopTextSelectionToolbarButton), findsOneWidget);
        case TargetPlatform.macOS:
          expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsOneWidget);
      }
      controller.dispose();
      focusNode.dispose();
    },
    skip: kIsWeb, // [intended] on web the browser handles the context menu.
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    'Can build for editable text from raw parameters',
    (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AdaptiveTextSelectionToolbar.editable(
                key: key,
                anchors: const TextSelectionToolbarAnchors(primaryAnchor: Offset.zero),
                clipboardStatus: ClipboardStatus.pasteable,
                onCopy: () {},
                onCut: () {},
                onPaste: () {},
                onSelectAll: () {},
                onLiveTextInput: () {},
                onLookUp: () {},
                onSearchWeb: () {},
                onShare: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          expect(find.byType(TextSelectionToolbarTextButton), findsNWidgets(6));
          expect(find.text('Cut'), findsOneWidget);
          expect(find.text('Copy'), findsOneWidget);
          expect(find.text('Paste'), findsOneWidget);
          expect(find.text('Share'), findsOneWidget);
          expect(find.text('Select all'), findsOneWidget);
          expect(find.text('Look Up'), findsOneWidget);
          expect(
            findMaterialOverflowNextButton(),
            findsOneWidget,
          ); // Material overflow buttons are not TextSelectionToolbarTextButton.

          await tapMaterialOverflowNextButton(tester);

          expect(find.byType(TextSelectionToolbarTextButton), findsNWidgets(2));
          expect(find.text('Search Web'), findsOneWidget);
          expect(findLiveTextButton(), findsOneWidget);
          expect(
            findMaterialOverflowBackButton(),
            findsOneWidget,
          ); // Material overflow buttons are not TextSelectionToolbarTextButton.

        case TargetPlatform.iOS:
          expect(find.byType(CupertinoTextSelectionToolbarButton), findsNWidgets(6));
          expect(find.text('Cut'), findsOneWidget);
          expect(find.text('Copy'), findsOneWidget);
          expect(find.text('Paste'), findsOneWidget);
          expect(find.text('Select All'), findsOneWidget);
          expect(find.text('Look Up'), findsOneWidget);
          expect(findCupertinoOverflowNextButton(), findsOneWidget);

          await tapCupertinoOverflowNextButton(tester);

          expect(find.byType(CupertinoTextSelectionToolbarButton), findsNWidgets(4));
          expect(findCupertinoOverflowBackButton(), findsOneWidget);
          expect(find.text('Search Web'), findsOneWidget);
          expect(find.text('Share...'), findsOneWidget);
          expect(findLiveTextButton(), findsOneWidget);

        case TargetPlatform.fuchsia:
          expect(find.byType(TextSelectionToolbarTextButton), findsNWidgets(8));
          expect(find.text('Cut'), findsOneWidget);
          expect(find.text('Copy'), findsOneWidget);
          expect(find.text('Paste'), findsOneWidget);
          expect(find.text('Select all'), findsOneWidget);
          expect(find.text('Look Up'), findsOneWidget);
          expect(find.text('Search Web'), findsOneWidget);
          expect(find.text('Share'), findsOneWidget);

        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(find.byType(DesktopTextSelectionToolbarButton), findsNWidgets(8));
          expect(find.text('Cut'), findsOneWidget);
          expect(find.text('Copy'), findsOneWidget);
          expect(find.text('Paste'), findsOneWidget);
          expect(find.text('Select all'), findsOneWidget);
          expect(find.text('Look Up'), findsOneWidget);
          expect(find.text('Search Web'), findsOneWidget);
          expect(find.text('Share'), findsOneWidget);
          expect(findLiveTextButton(), findsOneWidget);

        case TargetPlatform.macOS:
          expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNWidgets(8));
          expect(find.text('Cut'), findsOneWidget);
          expect(find.text('Copy'), findsOneWidget);
          expect(find.text('Paste'), findsOneWidget);
          expect(find.text('Select All'), findsOneWidget);
          expect(find.text('Look Up'), findsOneWidget);
          expect(find.text('Search Web'), findsOneWidget);
          expect(find.text('Share...'), findsOneWidget);
          expect(findLiveTextButton(), findsOneWidget);
      }
    },
    skip: kIsWeb, // [intended] on web the browser handles the context menu.
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    'Builds empty toolbar when children and buttonItems are null',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AdaptiveTextSelectionToolbar(
              anchors: TextSelectionToolbarAnchors(primaryAnchor: Offset.zero),
              children: null,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(AdaptiveTextSelectionToolbar)), Size.zero);
      expect(tester.takeException(), isNull);
    },
    skip: isBrowser, // [intended] on web the browser handles the context menu.
    variant: TargetPlatformVariant.all(),
  );

  group('buttonItems', () {
    testWidgets(
      'getEditableTextButtonItems builds the correct button items per-platform',
      (WidgetTester tester) async {
        // Fill the clipboard so that the Paste option is available in the text
        // selection menu.
        await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));

        var buttonTypes = <ContextMenuButtonType>{};
        final controller = TextEditingController();
        final focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: EditableText(
                  controller: controller,
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: const TextStyle(),
                  cursorColor: Colors.red,
                  selectionControls: materialTextSelectionHandleControls,
                  contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                    buttonTypes = editableTextState.contextMenuButtonItems
                        .map((ContextMenuButtonItem buttonItem) => buttonItem.type)
                        .toSet();
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

        // With no text in the field.
        await tester.tapAt(textOffsetToPosition(tester, 0));
        await tester.pump();
        expect(state.showToolbar(), true);
        await tester.pump();

        expect(buttonTypes, isNot(contains(ContextMenuButtonType.cut)));
        expect(buttonTypes, isNot(contains(ContextMenuButtonType.copy)));
        expect(buttonTypes, contains(ContextMenuButtonType.paste));
        expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));

        // With text but no selection.
        const text = 'lorem ipsum';
        controller.value = const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        await tester.pump();

        expect(buttonTypes, isNot(contains(ContextMenuButtonType.cut)));
        expect(buttonTypes, isNot(contains(ContextMenuButtonType.copy)));
        expect(buttonTypes, contains(ContextMenuButtonType.paste));

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.iOS:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            expect(buttonTypes, contains(ContextMenuButtonType.selectAll));
          case TargetPlatform.macOS:
            expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));
        }

        // With text and selection.
        controller.value = controller.value.copyWith(
          selection: const TextSelection(baseOffset: 0, extentOffset: 'lorem'.length),
        );
        await tester.pump();

        expect(buttonTypes, contains(ContextMenuButtonType.cut));
        expect(buttonTypes, contains(ContextMenuButtonType.copy));
        expect(buttonTypes, contains(ContextMenuButtonType.paste));

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            expect(buttonTypes, contains(ContextMenuButtonType.selectAll));
          case TargetPlatform.iOS:
          case TargetPlatform.macOS:
            expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));
        }

        focusNode.dispose();
        controller.dispose();
      },
      variant: TargetPlatformVariant.all(),
      skip: kIsWeb, // [intended]
    );

    testWidgets(
      'getAdaptiveButtons builds the correct button widgets per-platform',
      (WidgetTester tester) async {
        const buttonText = 'Click me';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (BuildContext context) {
                    final buttonItems = <ContextMenuButtonItem>[
                      ContextMenuButtonItem(label: buttonText, onPressed: () {}),
                    ];
                    return ListView(
                      children: AdaptiveTextSelectionToolbar.getAdaptiveButtons(
                        context,
                        buttonItems,
                      ).toList(),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text(buttonText), findsOneWidget);

        switch (defaultTargetPlatform) {
          case TargetPlatform.fuchsia:
          case TargetPlatform.android:
            expect(find.byType(TextSelectionToolbarTextButton), findsOneWidget);
            expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
            expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
            expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
          case TargetPlatform.iOS:
            expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
            expect(find.byType(CupertinoTextSelectionToolbarButton), findsOneWidget);
            expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
            expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
          case TargetPlatform.macOS:
            expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
            expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
            expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
            expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsOneWidget);
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
            expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
            expect(find.byType(DesktopTextSelectionToolbarButton), findsOneWidget);
            expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
        }
      },
      variant: TargetPlatformVariant.all(),
    );
  });
}
