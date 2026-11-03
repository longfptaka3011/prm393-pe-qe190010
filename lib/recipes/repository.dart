import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'recipe.dart';

abstract class RecipeRepository {
  Stream<List<Recipe>> watch();
  Future<void> save(Recipe recipe, {String? previousId});
  Future<void> favorite(Recipe recipe, bool value);
  Future<void> delete(Recipe recipe);
  void dispose() {}
}

class FirestoreRecipeRepository extends RecipeRepository {
  FirestoreRecipeRepository(this.userId);
  final String userId;
  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('recipes');
  @override
  Stream<List<Recipe>> watch() => collection
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList(),
      );
  @override
  Future<void> save(Recipe recipe, {String? previousId}) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final target = collection.doc(recipe.id);
      final current = await transaction.get(target);
      DocumentSnapshot<Map<String, dynamic>>? previous;
      if (previousId != null && previousId != recipe.id) {
        previous = await transaction.get(collection.doc(previousId));
      }
      if (current.exists && previousId != recipe.id) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'A recipe with this name already exists.',
        );
      }
      if ((previousId != null && previousId == recipe.id && !current.exists) ||
          (previousId != null &&
              previousId != recipe.id &&
              previous?.exists != true)) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'This recipe no longer exists.',
        );
      }
      transaction.set(target, recipe.toMap());
      if (previous != null) transaction.delete(previous.reference);
    });
  }

  @override
  Future<void> favorite(Recipe recipe, bool value) =>
      collection.doc(recipe.id).update({'favorite': value});
  @override
  Future<void> delete(Recipe recipe) => collection.doc(recipe.id).delete();
}

/// Explicit, nonpersistent preview. Never used for Firebase authentication.
class DemoRecipeRepository extends RecipeRepository {
  DemoRecipeRepository() {
    final examples = [
      (
        'Creamy Mushroom Pasta',
        'Dinner',
        'Easy',
        25,
        true,
        'Finish with parmesan and freshly cracked pepper.',
      ),
      (
        'Avocado Toast',
        'Breakfast',
        'Easy',
        10,
        true,
        'Top with a soft egg and a pinch of chili flakes.',
      ),
      (
        'Lemon Herb Chicken',
        'Lunch',
        'Medium',
        40,
        false,
        'Marinate with lemon, garlic and fresh herbs.',
      ),
      (
        'Sunday Apple Crumble',
        'Dessert',
        'Medium',
        55,
        false,
        'Serve warm with a scoop of vanilla ice cream.',
      ),
      (
        'Vegetable Fried Rice',
        'Dinner',
        'Easy',
        20,
        false,
        'Day-old rice works best.',
      ),
    ];
    _recipes = examples
        .map(
          (e) => Recipe(
            id: recipeId('demo', e.$1),
            userId: 'demo',
            name: e.$1,
            category: e.$2,
            difficulty: e.$3,
            cookTime: e.$4,
            favorite: e.$5,
            notes: e.$6,
            servings: 2,
            createdAt: DateTime.now(),
          ),
        )
        .toList();
  }
  late List<Recipe> _recipes;
  final _changes = StreamController<List<Recipe>>.broadcast();
  @override
  Stream<List<Recipe>> watch() async* {
    yield List.of(_recipes);
    yield* _changes.stream;
  }

  void _emit() => _changes.add(List.of(_recipes));
  @override
  Future<void> save(Recipe recipe, {String? previousId}) async {
    if (_recipes.any((r) => r.id == recipe.id && r.id != previousId)) {
      throw StateError('A recipe with this name already exists.');
    }
    _recipes.removeWhere((r) => r.id == previousId);
    _recipes.add(recipe);
    _emit();
  }

  @override
  Future<void> favorite(Recipe recipe, bool value) async {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index >= 0) _recipes[index] = recipe.withFavorite(value);
    _emit();
  }

  @override
  Future<void> delete(Recipe recipe) async {
    _recipes.removeWhere((r) => r.id == recipe.id);
    _emit();
  }

  @override
  void dispose() {
    _changes.close();
  }
}
