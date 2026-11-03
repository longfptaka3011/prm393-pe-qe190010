import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipe_box/main.dart' as app;
import 'package:recipe_box/core.dart';
import 'package:recipe_box/recipes/widgets.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('TEST_EMAIL');
  const password = String.fromEnvironment('TEST_PASSWORD');
  const secondEmail = String.fromEnvironment('SECOND_TEST_EMAIL');
  testWidgets('capture actual Firebase flows on the connected Android phone', (
    tester,
  ) async {
    expect(
      email,
      isNotEmpty,
      reason: 'Use the private dart-define-from-file configuration.',
    );
    expect(password, isNotEmpty);
    await app.main();
    expect(
      FirebaseAuth.instance.app.options.projectId,
      'recipebox-qe190010-20261103',
    );
    await FirebaseAuth.instance.signOut();
    Future<void> waitFor(Finder finder, {int seconds = 45}) async {
      final deadline = DateTime.now().add(Duration(seconds: seconds));
      while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(finder, findsWidgets);
    }

    Future<void> settle() async {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );
    }

    Finder field(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    Future<void> enter(String label, String value) async {
      await tester.ensureVisible(field(label));
      await tester.enterText(field(label), value);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder.first);
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> capture(String name, {Finder? show}) async {
      if (show != null) await tester.ensureVisible(show.first);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 600));
      const port = String.fromEnvironment('SCREENSHOT_PORT');
      const token = String.fromEnvironment('SCREENSHOT_TOKEN');
      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('http://127.0.0.1:$port/capture'),
        );
        request.headers.set('Authorization', 'Bearer $token');
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'name': name}));
        final response = await request.close();
        final message = await utf8.decoder.bind(response).join();
        expect(response.statusCode, 200, reason: message);
      } finally {
        client.close(force: true);
      }
    }

    Future<void> select(int index, String value) async {
      await tap(find.byType(DropdownButtonFormField<String>).at(index));
      await settle();
      await tap(find.text(value).last);
      await settle();
    }

    Future<void> register(String address) async {
      await enter('Email', address);
      await enter('Password', password);
      await enter('Confirm password', password);
      await tap(find.widgetWithText(FilledButton, 'Register'));
      await waitFor(find.text(Messages.registrationSuccess));
    }

    Future<void> logout() async {
      await tap(find.text('Logout'));
      await waitFor(find.text('Login'));
      await settle();
    }

    await waitFor(find.text('Login'));
    await settle();
    await capture('00_home');
    await tap(find.widgetWithText(FilledButton, 'Register'));
    await settle();
    await tap(find.widgetWithText(FilledButton, 'Register'));
    await settle();
    expect(find.text(Messages.emailRequired), findsOneWidget);
    await capture(
      '04_register_validation',
      show: find.text(Messages.emailRequired),
    );
    await capture(
      '04b_register_confirm_validation',
      show: find.text(Messages.confirmRequired),
    );
    await register(email);
    await capture('05_register_success');
    await waitFor(find.text('Recipes: 0'));
    await settle();
    await capture('16_empty_state', show: find.text(Messages.empty));
    final samples = [
      (
        'Avocado Toast',
        'Breakfast',
        'Easy',
        '10',
        'Top with a soft egg and a pinch of chili flakes.',
      ),
      (
        'Creamy Mushroom Pasta',
        'Dinner',
        'Easy',
        '25',
        'Finish with parmesan and freshly cracked pepper.',
      ),
      (
        'Lemon Herb Chicken',
        'Lunch',
        'Medium',
        '40',
        'Marinate with lemon, garlic and fresh herbs.',
      ),
      (
        'Sunday Apple Crumble',
        'Dessert',
        'Hard',
        '55',
        'Serve warm with vanilla ice cream.',
      ),
      (
        'Vegetable Fried Rice',
        'Dinner',
        'Easy',
        '20',
        'Day-old rice works best. Add basil before serving.',
      ),
    ];
    for (var index = 0; index < samples.length; index++) {
      final r = samples[index];
      await tap(find.widgetWithText(FilledButton, 'Add Recipe'));
      await settle();
      if (index == 0) {
        await tap(find.widgetWithText(FilledButton, 'Add Recipe'));
        await settle();
        await capture(
          '08_add_validation',
          show: find.text(Messages.nameRequired),
        );
        await capture(
          '08b_add_time_validation',
          show: find.text(Messages.timeRequired),
        );
      }
      await enter('Name', r.$1);
      await select(0, r.$2);
      await select(1, r.$3);
      await enter('Cook time', r.$4);
      await enter('Servings', '2');
      await enter('Notes', r.$5);
      await tap(find.widgetWithText(FilledButton, 'Add Recipe'));
      await waitFor(find.text(Messages.recipeAdded));
      if (index == 4) await capture('09_add_success', show: find.text(r.$1));
      await waitFor(find.text('Recipes: ${index + 1}'));
      await settle();
    }
    await logout();
    await tap(find.widgetWithText(OutlinedButton, 'Login'));
    await settle();
    await capture('06_login');
    await enter('Email', email);
    await enter('Password', password);
    await tap(find.widgetWithText(FilledButton, 'Login'));
    await waitFor(find.text(email));
    await waitFor(find.text('Recipes: 5'));
    await settle();
    await capture('07_list_after_login_header', show: find.text(email));
    await capture(
      '07b_list_after_login_recipes',
      show: find.text('Avocado Toast'),
    );
    await capture('15_favorite_before', show: find.text('Avocado Toast'));
    final card = find.ancestor(
      of: find.text('Avocado Toast'),
      matching: find.byType(RecipeCard),
    );
    await tap(find.descendant(of: card, matching: find.byType(FavoriteButton)));
    await waitFor(find.text('Favorites: 1'));
    await settle();
    await capture('15b_favorite_after', show: find.text('Avocado Toast'));
    await select(0, 'Dinner');
    await capture(
      '10_category_filter',
      show: find.byType(DropdownButtonFormField<String>).first,
    );
    expect(find.text('Recipes: 2'), findsOneWidget);
    await tap(find.text('Clear'));
    await select(1, 'Medium');
    expect(find.text('Recipes: 1'), findsOneWidget);
    await capture('10b_difficulty_filter');
    await tap(find.text('Clear'));
    await tap(find.byType(SwitchListTile));
    expect(find.text('Recipes: 1'), findsOneWidget);
    await capture('10c_favorites_filter');
    await tap(find.text('Clear'));
    final search = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Search recipes...',
    );
    await tester.ensureVisible(search);
    await tester.enterText(search, ' BASIL ');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle();
    expect(find.text('Recipes: 1'), findsOneWidget);
    await capture('10d_search_filter', show: search);
    await tap(find.text('Clear'));
    await capture('11_summary', show: find.text('At a glance'));
    await capture('11b_category_breakdown', show: find.text('By category'));
    await tap(find.text('Avocado Toast'));
    await settle();
    await capture('12_detail_view');
    await tap(find.widgetWithText(FilledButton, 'Edit'));
    await settle();
    await enter('Name', '');
    await enter('Cook time', '0');
    await tap(find.widgetWithText(FilledButton, 'Save'));
    await settle();
    await capture('13_edit_validation', show: find.text(Messages.nameRequired));
    await enter('Name', 'Avocado Brunch');
    await enter('Cook time', '12');
    await tap(find.widgetWithText(FilledButton, 'Save'));
    await waitFor(find.text('Recipe details'));
    await settle();
    await capture('14_detail_after_save');
    await tester.pageBack();
    await settle();
    expect(find.text('Avocado Brunch'), findsOneWidget);
    // Delete only a disposable recipe created by this evidence session.
    await tap(find.text('Sunday Apple Crumble'));
    await settle();
    await capture('15c_delete_before');
    await tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await settle();
    await capture('15d_delete_confirmation');
    await tap(find.widgetWithText(FilledButton, 'Delete'));
    await waitFor(find.text('Recipes: 4'));
    await settle();
    expect(find.text('Sunday Apple Crumble'), findsNothing);
    await capture('15e_delete_after', show: find.text('Recipes: 4'));
    final primaryUid = FirebaseAuth.instance.currentUser!.uid;
    final saved = await FirebaseFirestore.instance
        .collection('recipes')
        .where('userId', isEqualTo: primaryUid)
        .get();
    expect(saved.docs.length, 4);
    await logout();
    await tap(find.widgetWithText(FilledButton, 'Register'));
    await settle();
    await register(secondEmail);
    await waitFor(find.text('Recipes: 0'));
    await settle();
    await capture('16b_second_account_empty', show: find.text(Messages.empty));
    await logout();
    // Restore the grader's primary account without re-creating any documents.
    await tap(find.widgetWithText(OutlinedButton, 'Login'));
    await settle();
    await enter('Email', email);
    await enter('Password', password);
    await tap(find.widgetWithText(FilledButton, 'Login'));
    await waitFor(find.text('Recipes: 4'));
    await settle();
    await capture('17_final_collection', show: find.text('Avocado Brunch'));
    binding.reportData = {
      ...?binding.reportData,
      'projectId': FirebaseAuth.instance.app.options.projectId,
      'primaryUid': primaryUid,
      'primaryEmail': email,
      'recipesRemaining': saved.docs.length,
    };
  }, timeout: const Timeout(Duration(minutes: 15)));
}
