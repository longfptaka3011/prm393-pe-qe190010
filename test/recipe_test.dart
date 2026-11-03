import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_box/core.dart';
import 'package:recipe_box/recipes/recipe.dart';
import 'package:recipe_box/recipes/repository.dart';

Recipe recipe(
  String name,
  String category,
  int time, {
  String difficulty = 'Easy',
  bool favorite = false,
  String notes = '',
}) => Recipe(
  id: recipeId('user', name),
  userId: 'user',
  name: name,
  category: category,
  difficulty: difficulty,
  cookTime: time,
  favorite: favorite,
  notes: notes,
  createdAt: DateTime(2026),
);

void main() {
  test(
    'validation rejects blanks, decimal/exponent and out-of-range integers',
    () {
      expect(Validate.name('   '), Messages.nameRequired);
      expect(Validate.name('a' * 81), Messages.nameLong);
      expect(Validate.integer('', 600), Messages.timeRequired);
      for (final value in ['0', '601', '1.0', '1e2', '-2', '+1', 'abc']) {
        expect(Validate.integer(value, 600), Messages.timeInvalid);
      }
      for (final value in ['1', '600', ' 25 ']) {
        expect(Validate.integer(value, 600), isNull);
      }
      expect(Validate.integer('', 20, optional: true), isNull);
      expect(
        Validate.integer('21', 20, optional: true),
        Messages.servingsInvalid,
      );
      expect(Validate.email(' a@b.com '), isNull);
      expect(Validate.email('a@@b.com'), Messages.emailInvalid);
    },
  );
  test('canonical ID has owner scope, case-insensitive names and safe Unicode/slashes', () {
    expect(recipeId('a', ' Pho Bo '), recipeId('a', 'pho bo'));
    expect(recipeId('a', 'pho bo'), isNot(recipeId('b', 'pho bo')));
    expect(recipeId('a', 'Phở / bò'), matches(RegExp(r'^a_[0-9a-f]+$')));
    expect(recipeId('a', 'Pho'), isNot(recipeId('a', 'Pho!')));
  });
  final data = [
    recipe('Zucchini', 'Dinner', 20, favorite: true, notes: 'Fresh BASIL'),
    recipe('apple', 'Breakfast', 20, favorite: true),
    recipe('Banana', 'Lunch', 10),
    recipe('Cake', 'Dessert', 30, difficulty: 'Medium'),
  ];
  test('sort by time then name ignoring case', () {
    expect(RecipeFilter().apply(data).map((r) => r.name), [
      'Banana',
      'apple',
      'Zucchini',
      'Cake',
    ]);
  });
  test('all filters combine, search matches notes, clear resets all four', () {
    final filter = RecipeFilter()
      ..category = 'Dinner'
      ..difficulty = 'Easy'
      ..favoritesOnly = true
      ..search = ' BASIL ';
    final visible = filter.apply(data);
    expect(visible.single.name, 'Zucchini');
    final summary = RecipeSummary(visible);
    expect((summary.count, summary.favorites, summary.totalTime), (1, 1, 20));
    expect(filter.apply([data.first.withFavorite(false)]), isEmpty);
    filter.clear();
    expect(filter.apply(data), hasLength(4));
    expect(
      (filter.category, filter.difficulty, filter.favoritesOnly, filter.search),
      ('All', 'All', false, ''),
    );
  });
  test('category summary uses counts descending and meal-order ties', () {
    final summary = RecipeSummary([...data, recipe('Soup', 'Dinner', 5)]);
    expect(summary.orderedCategories.map((e) => e.key), [
      'Dinner',
      'Breakfast',
      'Lunch',
      'Dessert',
    ]);
    expect((summary.count, summary.favorites, summary.totalTime), (5, 2, 85));
  });
  test(
    'demo repository rejects duplicates and supports rename/delete',
    () async {
      final repository = DemoRecipeRepository();
      addTearDown(repository.dispose);
      final existing = (await repository.watch().first).first;
      await expectLater(repository.save(existing), throwsStateError);
      final renamed = recipe('New name', 'Dinner', 5);
      await repository.save(renamed, previousId: existing.id);
      expect(
        (await repository.watch().first).any((r) => r.id == existing.id),
        isFalse,
      );
      await repository.delete(renamed);
      expect(
        (await repository.watch().first).any((r) => r.id == renamed.id),
        isFalse,
      );
    },
  );
}
