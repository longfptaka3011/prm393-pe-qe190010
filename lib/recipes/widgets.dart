import 'package:flutter/material.dart';

import '../core.dart';
import 'recipe.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.value,
    required this.onPressed,
  });
  final bool value;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    child: IconButton(
      tooltip: value ? 'Remove from favorites' : 'Add to favorites',
      onPressed: onPressed,
      icon: Icon(
        value ? Icons.star_rounded : Icons.star_border_rounded,
        color: value ? Palette.accent : Palette.muted,
      ),
    ),
  );
}

class RecipeBadges extends StatelessWidget {
  const RecipeBadges(this.recipe, {super.key});
  final Recipe recipe;
  Widget _badge(String text, Color background, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
    ),
  );
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _badge(recipe.category, Palette.light, Palette.primary),
      _badge(
        recipe.difficulty,
        recipe.difficulty == 'Easy'
            ? Palette.light
            : recipe.difficulty == 'Medium'
            ? const Color(0xFFFFF3DD)
            : const Color(0xFFFFEDEA),
        recipe.difficulty == 'Easy'
            ? Palette.primary
            : recipe.difficulty == 'Medium'
            ? const Color(0xFFA66316)
            : Palette.error,
      ),
    ],
  );
}

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onOpen,
    required this.onFavorite,
  });
  final Recipe recipe;
  final VoidCallback onOpen;
  final VoidCallback? onFavorite;
  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.zero,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FavoriteButton(value: recipe.favorite, onPressed: onFavorite),
                ],
              ),
              const SizedBox(height: 4),
              RecipeBadges(recipe),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: Palette.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${recipe.cookTime} min',
                    style: const TextStyle(
                      color: Palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Details',
                    style: TextStyle(color: Palette.primary),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Palette.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SummaryPanel extends StatelessWidget {
  const SummaryPanel(this.recipes, {super.key});
  final List<Recipe> recipes;
  @override
  Widget build(BuildContext context) {
    final summary = RecipeSummary(recipes);
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('At a glance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final stat in [
            (Icons.menu_book_outlined, 'Recipes: ${summary.count}'),
            (Icons.star_border_rounded, 'Favorites: ${summary.favorites}'),
            (Icons.schedule_rounded, 'Total time: ${summary.totalTime} min'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(stat.$1, size: 20, color: Palette.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stat.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          if (summary.breakdown.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'By category',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final entry in summary.orderedCategories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(color: Palette.muted),
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
