import 'dart:async';

import 'package:flutter/material.dart';

import '../core.dart';
import 'recipe.dart';
import 'repository.dart';
import 'recipe_form.dart';
import 'widgets.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.repository,
  });
  final Recipe recipe;
  final RecipeRepository repository;
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe = widget.recipe;
  bool _editing = false, _busy = false;
  String? _error;
  StreamSubscription<List<Recipe>>? _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = widget.repository.watch().listen(
      (recipes) {
        final matching = recipes.where((r) => r.id == _recipe.id);
        if (mounted && matching.isNotEmpty && !_busy) {
          setState(() => _recipe = matching.first);
        }
      },
      onError: (Object error) {
        if (mounted) setState(() => _error = error.toString());
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _favorite() async {
    final old = _recipe;
    setState(() {
      _busy = true;
      _recipe = old.withFavorite(!old.favorite);
      _error = null;
    });
    try {
      await widget.repository.favorite(old, !old.favorite);
    } catch (error) {
      if (mounted) {
        setState(() {
          _recipe = old;
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Palette.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.delete(_recipe);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Palette.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Palette.muted),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? 'Edit recipe' : 'Recipe details')),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Content(
          child: _editing
              ? RecipeForm(
                  key: ValueKey(_recipe.id),
                  repository: widget.repository,
                  userId: _recipe.userId,
                  recipe: _recipe,
                  onSaved: (recipe) => setState(() {
                    _recipe = recipe;
                    _editing = false;
                    _error = null;
                  }),
                  onCancel: () => setState(() => _editing = false),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _recipe.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                              ),
                              FavoriteButton(
                                value: _recipe.favorite,
                                onPressed: _busy ? null : _favorite,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          RecipeBadges(_recipe),
                          const SizedBox(height: 16),
                          const Divider(),
                          _row(
                            Icons.restaurant_menu_rounded,
                            'Category',
                            _recipe.category,
                          ),
                          _row(
                            Icons.speed_rounded,
                            'Difficulty',
                            _recipe.difficulty,
                          ),
                          _row(
                            Icons.schedule_rounded,
                            'Cook time',
                            '${_recipe.cookTime} min',
                          ),
                          _row(
                            Icons.groups_outlined,
                            'Servings',
                            _recipe.servings?.toString() ?? 'Not specified',
                          ),
                          _row(
                            Icons.notes_rounded,
                            'Notes',
                            _recipe.notes.isEmpty
                                ? 'Not specified'
                                : _recipe.notes,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SubmitButton(
                      label: 'Edit',
                      onPressed: _busy
                          ? null
                          : () => setState(() => _editing = true),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.error,
                      ),
                      onPressed: _busy ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                    ),
                    ErrorBanner(_error),
                  ],
                ),
        ),
      ),
    ),
  );
}
