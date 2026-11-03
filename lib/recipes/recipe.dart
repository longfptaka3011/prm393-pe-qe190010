import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core.dart';

String recipeId(String userId, String name) =>
    '${userId}_${utf8.encode(name.trim().toLowerCase()).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

class Recipe {
  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    this.servings,
    this.favorite = false,
    this.notes = '',
    required this.createdAt,
  });
  final String id, userId, name, category, difficulty, notes;
  final int cookTime;
  final int? servings;
  final bool favorite;
  final DateTime createdAt;
  factory Recipe.fromMap(Map<String, dynamic> data) => Recipe(
    id: data['id'] as String,
    userId: data['userId'] as String,
    name: data['name'] as String,
    category: data['category'] as String,
    difficulty: data['difficulty'] as String,
    cookTime: data['cookTime'] as int,
    servings: data['servings'] as int?,
    favorite: data['favorite'] as bool,
    notes: data['notes'] as String? ?? '',
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'category': category,
    'difficulty': difficulty,
    'cookTime': cookTime,
    if (servings != null) 'servings': servings,
    'favorite': favorite,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };
  Recipe withFavorite(bool value) => Recipe(
    id: id,
    userId: userId,
    name: name,
    category: category,
    difficulty: difficulty,
    cookTime: cookTime,
    servings: servings,
    favorite: value,
    notes: notes,
    createdAt: createdAt,
  );
}

class RecipeFilter {
  String category = 'All', difficulty = 'All', search = '';
  bool favoritesOnly = false;
  void clear() {
    category = difficulty = 'All';
    search = '';
    favoritesOnly = false;
  }

  List<Recipe> apply(List<Recipe> recipes) {
    final query = search.trim().toLowerCase();
    final result = recipes
        .where(
          (r) =>
              (category == 'All' || r.category == category) &&
              (difficulty == 'All' || r.difficulty == difficulty) &&
              (!favoritesOnly || r.favorite) &&
              (r.name.toLowerCase().contains(query) ||
                  r.notes.toLowerCase().contains(query)),
        )
        .toList();
    result.sort((a, b) {
      final time = a.cookTime.compareTo(b.cookTime);
      return time != 0
          ? time
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }
}

class RecipeSummary {
  RecipeSummary(List<Recipe> recipes)
    : count = recipes.length,
      favorites = recipes.where((r) => r.favorite).length,
      totalTime = recipes.fold(0, (total, r) => total + r.cookTime) {
    for (final r in recipes) {
      breakdown[r.category] = (breakdown[r.category] ?? 0) + 1;
    }
  }
  final int count, favorites, totalTime;
  final Map<String, int> breakdown = {};
  List<MapEntry<String, int>> get orderedCategories =>
      breakdown.entries.toList()..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count != 0
            ? count
            : categories.indexOf(a.key).compareTo(categories.indexOf(b.key));
      });
}
