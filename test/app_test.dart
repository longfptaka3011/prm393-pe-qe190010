import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_box/app.dart';
import 'package:recipe_box/core.dart';
import 'package:recipe_box/recipes/recipe_form.dart';
import 'package:recipe_box/recipes/repository.dart';

void main() {
  testWidgets(
    'demo supports favorite filters, detail editing, delete and logout',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        final fonts = FontLoader('Roboto');
        for (final weight in ['regular', 'medium', 'bold', 'black']) {
          fonts.addFont(rootBundle.load('assets/fonts/roboto-$weight.ttf'));
        }
        await fonts.load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      }
      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('CAPTURE_UI')) return;
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('artifacts/ui').create(recursive: true);
          await File('artifacts/ui/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: const RecipeBoxApp()),
      );
      await tester.pumpAndSettle();
      await capture('home');
      await tester.ensureVisible(find.text('Explore demo'));
      await tester.tap(find.text('Explore demo'));
      await tester.pumpAndSettle();
      expect(find.text('Recipes: 5'), findsOneWidget);
      await capture('list');
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Recipes: 2'), findsOneWidget);
      final star = find.byTooltip('Remove from favorites').first;
      await tester.ensureVisible(star);
      await tester.tap(star);
      await tester.pumpAndSettle();
      expect(find.text('Recipes: 1'), findsOneWidget);
      await tester.ensureVisible(find.text('Clear'));
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Recipes: 5'), findsOneWidget);
      await tester.ensureVisible(find.text('Avocado Toast'));
      await tester.tap(find.text('Avocado Toast'));
      await tester.pumpAndSettle();
      expect(find.text('Recipe details'), findsOneWidget);
      await capture('detail');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Edit'));
      await tester.tap(find.widgetWithText(FilledButton, 'Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Avocado Brunch',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Avocado Brunch'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete recipe?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Recipes: 4'), findsOneWidget);
      expect(find.text('Avocado Brunch'), findsNothing);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Recipes: 4'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('home and register validation fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const RecipeBoxApp());
    expect(find.text('Save your recipes'), findsOneWidget);
    await tester.tap(find.text('Register').first);
    await tester.pumpAndSettle();
    expect(find.text(Messages.emailRequired), findsNothing);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Register'));
    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text(Messages.emailRequired), findsOneWidget);
    expect(find.text(Messages.passwordRequired), findsOneWidget);
    expect(find.text(Messages.confirmRequired), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'valid@example.com',
    );
    await tester.pumpAndSettle();
    expect(find.text(Messages.emailRequired), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'recipe form validates only after submit and clears field errors',
    (tester) async {
      final repository = DemoRecipeRepository();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RecipeForm(
                repository: repository,
                userId: 'demo',
                onSaved: (_) {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text(Messages.nameRequired), findsNothing);
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Add Recipe'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add Recipe'));
      await tester.pumpAndSettle();
      for (final error in [
        Messages.nameRequired,
        Messages.categoryRequired,
        Messages.difficultyRequired,
        Messages.timeRequired,
      ]) {
        expect(find.text(error), findsOneWidget);
      }
      await tester.enterText(find.byType(TextFormField).first, 'Soup');
      await tester.pumpAndSettle();
      expect(find.text(Messages.nameRequired), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
