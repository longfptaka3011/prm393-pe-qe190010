import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core.dart';
import 'recipe.dart';
import 'repository.dart';

class RecipeForm extends StatefulWidget {
  const RecipeForm({
    super.key,
    required this.repository,
    required this.userId,
    required this.onSaved,
    required this.onCancel,
    this.recipe,
  });
  final RecipeRepository repository;
  final String userId;
  final Recipe? recipe;
  final ValueChanged<Recipe> onSaved;
  final VoidCallback onCancel;
  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.recipe?.name ?? '');
  late final _time = TextEditingController(
    text: widget.recipe?.cookTime.toString() ?? '',
  );
  late final _servings = TextEditingController(
    text: widget.recipe?.servings?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.recipe?.notes ?? '');
  late String? _category = widget.recipe?.category,
      _difficulty = widget.recipe?.difficulty;
  bool _submitted = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _time.dispose();
    _servings.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final recipe = Recipe(
      id: recipeId(widget.userId, _name.text),
      userId: widget.userId,
      name: _name.text.trim(),
      category: _category!,
      difficulty: _difficulty!,
      cookTime: int.parse(_time.text.trim()),
      servings: _servings.text.trim().isEmpty
          ? null
          : int.parse(_servings.text.trim()),
      notes: _notes.text,
      favorite: widget.recipe?.favorite ?? false,
      createdAt: widget.recipe?.createdAt ?? DateTime.now(),
    );
    try {
      await widget.repository.save(recipe, previousId: widget.recipe?.id);
      if (mounted) widget.onSaved(recipe);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FirebaseException
              ? error.message ?? error.code
              : error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Form(
      key: _form,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            validator: Validate.name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter recipe name',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category'),
            hint: const Text('Choose category'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Choose category'),
              ),
              ...categories.map(
                (c) => DropdownMenuItem(value: c, child: Text(c)),
              ),
            ],
            onChanged: _busy ? null : (v) => setState(() => _category = v),
            validator: (v) => v == null ? Messages.categoryRequired : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _difficulty,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Difficulty'),
            hint: const Text('Choose difficulty'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Choose difficulty'),
              ),
              ...difficulties.map(
                (d) => DropdownMenuItem(value: d, child: Text(d)),
              ),
            ],
            onChanged: _busy ? null : (v) => setState(() => _difficulty = v),
            validator: (v) => v == null ? Messages.difficultyRequired : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _time,
            keyboardType: TextInputType.number,
            validator: (v) => Validate.integer(v, 600),
            decoration: const InputDecoration(
              labelText: 'Cook time',
              hintText: 'Minutes',
              suffixText: 'min',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _servings,
            keyboardType: TextInputType.number,
            validator: (v) => Validate.integer(v, 20, optional: true),
            decoration: const InputDecoration(
              labelText: 'Servings',
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notes,
            minLines: 4,
            maxLines: 6,
            maxLength: 300,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            validator: (v) =>
                (v?.length ?? 0) > 300 ? Messages.notesLong : null,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Add a note (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          SubmitButton(
            label: widget.recipe == null ? 'Add Recipe' : 'Save',
            onPressed: _save,
            busy: _busy,
          ),
          ErrorBanner(_error),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

class AddRecipeScreen extends StatelessWidget {
  const AddRecipeScreen({
    super.key,
    required this.repository,
    required this.userId,
  });
  final RecipeRepository repository;
  final String userId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Recipe')),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Content(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Something worth keeping.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Save the details that make it yours.',
                style: TextStyle(color: Palette.muted),
              ),
              const SizedBox(height: 24),
              RecipeForm(
                repository: repository,
                userId: userId,
                onSaved: (_) {
                  Navigator.of(context).pop();
                  feedback(context, Messages.recipeAdded);
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
