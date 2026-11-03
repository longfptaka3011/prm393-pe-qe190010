import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.configured,
    this.setupError,
    required this.onRegistered,
    required this.onDemo,
  });
  final bool configured;
  final String? setupError;
  final VoidCallback onRegistered, onDemo;
  void _open(BuildContext context, bool register) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AuthScreen(
        register: register,
        configured: configured,
        onRegistered: onRegistered,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Content(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _open(context, false),
                    child: const Text('Login'),
                  ),
                  FilledButton(
                    onPressed: () => _open(context, true),
                    child: const Text('Register'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Palette.light,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'A little order. A lot of flavor.',
                  style: TextStyle(
                    color: Palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'RecipeBox',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your recipes, beautifully organized.',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.35,
                  color: Palette.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Keep the dishes you love in one personal place. Find your next meal, save a family favorite, and make room for something new.',
                style: TextStyle(color: Palette.muted, height: 1.6),
              ),
              const SizedBox(height: 24),
              SubmitButton(
                label: 'Create your recipe box',
                onPressed: () => _open(context, true),
              ),
              const SizedBox(height: 32),
              for (final feature in [
                (
                  Icons.menu_book_rounded,
                  'Save your recipes',
                  'Your everyday meals and treasured family recipes, together.',
                ),
                (
                  Icons.schedule_rounded,
                  'Sort by cooking time',
                  'Find something delicious that fits the time you have.',
                ),
                (
                  Icons.star_rounded,
                  'Mark your favorites',
                  'Keep your tried-and-loved dishes just a tap away.',
                ),
              ]) ...[
                Surface(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Palette.light,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(feature.$1, color: Palette.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.$2,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              feature.$3,
                              style: const TextStyle(color: Palette.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!configured) ...[
                const SizedBox(height: 12),
                const Text(
                  'Preview the experience',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explore a sample collection. Demo changes last only for this session.',
                  style: TextStyle(color: Palette.muted),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onDemo,
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Explore demo'),
                ),
              ],
              ErrorBanner(setupError),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.register,
    required this.configured,
    required this.onRegistered,
  });
  final bool register, configured;
  final VoidCallback onRegistered;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _submitted = false,
      _busy = false,
      _hidePassword = true,
      _hideConfirm = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    if (!widget.configured) {
      setState(
        () => _error = 'Firebase is not configured yet. Add your client configuration to connect your account.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.register) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        widget.onRegistered();
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool hide,
    VoidCallback toggle,
    String? Function(String?) validator,
  ) => TextFormField(
    controller: controller,
    obscureText: hide,
    enableSuggestions: false,
    autocorrect: false,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: hide ? 'Show password' : 'Hide password',
        onPressed: toggle,
        icon: Icon(
          hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.register ? 'Register' : 'Login')),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Content(
          child: Form(
            key: _form,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const AppLogo(size: 68, wordmark: false),
                const SizedBox(height: 24),
                Text(
                  widget.register
                      ? 'A fresh start for your recipes.'
                      : 'Welcome back.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.register
                      ? 'Create your personal collection, one good meal at a time.'
                      : 'Your next favorite meal is waiting for you.',
                  style: const TextStyle(color: Palette.muted),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: Validate.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 16),
                _passwordField(
                  _password,
                  'Password',
                  _hidePassword,
                  () => setState(() => _hidePassword = !_hidePassword),
                  (v) => v == null || v.isEmpty
                      ? Messages.passwordRequired
                      : widget.register && v.length < 6
                      ? Messages.passwordShort
                      : null,
                ),
                if (widget.register) ...[
                  const SizedBox(height: 16),
                  _passwordField(
                    _confirm,
                    'Confirm password',
                    _hideConfirm,
                    () => setState(() => _hideConfirm = !_hideConfirm),
                    (v) => v == null || v.isEmpty
                        ? Messages.confirmRequired
                        : v != _password.text
                        ? Messages.passwordMismatch
                        : null,
                  ),
                ],
                const SizedBox(height: 24),
                SubmitButton(
                  label: widget.register ? 'Register' : 'Login',
                  onPressed: _submit,
                  busy: _busy,
                ),
                ErrorBanner(_error),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => AuthScreen(
                                register: !widget.register,
                                configured: widget.configured,
                                onRegistered: widget.onRegistered,
                              ),
                            ),
                          ),
                    child: Text(
                      widget.register
                          ? 'Already have an account? Login'
                          : 'New here? Register',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
