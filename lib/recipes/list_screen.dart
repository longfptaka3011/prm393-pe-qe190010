import 'dart:async';

import 'package:flutter/material.dart';

import '../core.dart';
import 'recipe.dart';
import 'repository.dart';
import 'recipe_form.dart';
import 'widgets.dart';
import 'detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({
    super.key,
    required this.repository,
    required this.userId,
    required this.email,
    required this.logout,
    this.demo = false,
  });
  final RecipeRepository repository;
  final String userId, email;
  final Future<void> Function() logout;
  final bool demo;
  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final _filter = RecipeFilter();
  final _search = TextEditingController();
  final Map<String, bool> _pendingFavorites = {};
  List<Recipe> _recipes = [];
  StreamSubscription<List<Recipe>>? _subscription;
  bool _loading = true, _loggingOut = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _subscription = widget.repository.watch().listen(
      (recipes) {
        if (mounted) {
          setState(() {
            _recipes = recipes;
            _loading = false;
            _error = null;
          });
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
            _loading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _favorite(Recipe recipe) async {
    setState(() => _pendingFavorites[recipe.id] = !recipe.favorite);
    try {
      await widget.repository.favorite(recipe, !recipe.favorite);
    } catch (error) {
      if (mounted) feedback(context, error.toString());
    } finally {
      if (mounted) setState(() => _pendingFavorites.remove(recipe.id));
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await widget.logout();
    } catch (error) {
      if (mounted) feedback(context, error.toString());
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filter.apply(
      _recipes
          .map(
            (r) => _pendingFavorites.containsKey(r.id)
                ? r.withFavorite(_pendingFavorites[r.id]!)
                : r,
          )
          .toList(),
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AppLogo(size: 36),
        actions: [
          TextButton(
            onPressed: _loggingOut ? null : _logout,
            child: const Text('Logout'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Content(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.email,
                  style: const TextStyle(color: Palette.muted),
                ),
                if (widget.demo)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3DD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Demo · sample data · changes are not saved after exit',
                      style: TextStyle(color: Color(0xFFA66316)),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Your recipe collection',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Good food starts with a little inspiration.',
                  style: TextStyle(color: Palette.muted),
                ),
                const SizedBox(height: 20),
                SubmitButton(
                  label: 'Add Recipe',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddRecipeScreen(
                        repository: widget.repository,
                        userId: widget.userId,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _filter.search = v),
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () => setState(() {
                              _search.clear();
                              _filter.search = '';
                            }),
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Surface(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: Palette.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Filters',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _filter.clear();
                              _search.clear();
                            }),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        key: ValueKey('category-${_filter.category}'),
                        initialValue: _filter.category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        isExpanded: true,
                        items: ['All', ...categories]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _filter.category = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('difficulty-${_filter.difficulty}'),
                        initialValue: _filter.difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                        ),
                        isExpanded: true,
                        items: ['All', ...difficulties]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _filter.difficulty = v!),
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Favorites only',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: _filter.favoritesOnly,
                        onChanged: (v) =>
                            setState(() => _filter.favoritesOnly = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (_error != null) ...[
                    ErrorBanner(_error),
                    TextButton(
                      onPressed: () {
                        setState(() => _loading = true);
                        _listen();
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                  SummaryPanel(visible),
                  const SizedBox(height: 24),
                  Text(
                    'Recipes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    const Surface(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: Palette.primary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                Messages.empty,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add a recipe or adjust your filters.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Palette.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  for (final recipe in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RecipeCard(
                        recipe: recipe,
                        onFavorite: _pendingFavorites.containsKey(recipe.id)
                            ? null
                            : () => _favorite(recipe),
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(
                              recipe: recipe,
                              repository: widget.repository,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
