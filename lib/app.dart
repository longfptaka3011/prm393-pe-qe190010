import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core.dart';
import 'auth/screens.dart';
import 'recipes/list_screen.dart';
import 'recipes/repository.dart';

class RecipeBoxApp extends StatefulWidget {
  const RecipeBoxApp({super.key, this.configured = false, this.setupError});
  final bool configured;
  final String? setupError;
  @override
  State<RecipeBoxApp> createState() => _RecipeBoxAppState();
}

class _RecipeBoxAppState extends State<RecipeBoxApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _demo = false;
  void _registered() => _messenger.currentState?.showSnackBar(
    const SnackBar(content: Text(Messages.registrationSuccess)),
  );
  Widget _public() => AppFlow(
    key: const ValueKey('public'),
    child: HomeScreen(
      configured: widget.configured,
      setupError: widget.setupError,
      onRegistered: _registered,
      onDemo: () => setState(() => _demo = true),
    ),
  );
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RecipeBox',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    scaffoldMessengerKey: _messenger,
    home: _demo
        ? RecipeSession(
            key: const ValueKey('demo'),
            userId: 'demo',
            email: 'Demo collection',
            demo: true,
            logout: () async => setState(() => _demo = false),
          )
        : !widget.configured
        ? _public()
        : StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppLogo(size: 76, wordmark: false),
                        SizedBox(height: 24),
                        CircularProgressIndicator(),
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Scaffold(
                  body: Content(child: ErrorBanner(snapshot.error.toString())),
                );
              }
              final user = snapshot.data;
              return user == null
                  ? _public()
                  : RecipeSession(
                      key: ValueKey(user.uid),
                      userId: user.uid,
                      email: user.email ?? '',
                      logout: FirebaseAuth.instance.signOut,
                    );
            },
          ),
  );
}

class RecipeSession extends StatefulWidget {
  const RecipeSession({
    super.key,
    required this.userId,
    required this.email,
    required this.logout,
    this.demo = false,
  });
  final String userId, email;
  final Future<void> Function() logout;
  final bool demo;
  @override
  State<RecipeSession> createState() => _RecipeSessionState();
}

class _RecipeSessionState extends State<RecipeSession> {
  late final RecipeRepository repository = widget.demo
      ? DemoRecipeRepository()
      : FirestoreRecipeRepository(widget.userId);
  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFlow(
    child: RecipeListScreen(
      repository: repository,
      userId: widget.userId,
      email: widget.email,
      demo: widget.demo,
      logout: widget.logout,
    ),
  );
}

/// Gives Android Back to the active flow, while auth changes discard its stack.
class AppFlow extends StatefulWidget {
  const AppFlow({super.key, required this.child});
  final Widget child;
  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<Object?>(
    onPopWithResult: (result) => _navigator.currentState!.pop(result),
    child: Navigator(
      key: _navigator,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => widget.child),
    ),
  );
}
