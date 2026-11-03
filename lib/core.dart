import 'package:flutter/material.dart';

const categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
const difficulties = ['Easy', 'Medium', 'Hard'];

abstract final class Palette {
  static const primary = Color(0xFF2F6B4F);
  static const canvas = Color(0xFFFAF8F3);
  static const ink = Color(0xFF203127);
  static const muted = Color(0xFF647267);
  static const light = Color(0xFFE8F2EA);
  static const border = Color(0xFFDCE5DC);
  static const accent = Color(0xFFF6B65B);
  static const error = Color(0xFFB42318);
}

abstract final class Messages {
  static const emailRequired = 'Email is required';
  static const emailInvalid = 'Please enter a valid email address';
  static const passwordRequired = 'Password is required';
  static const passwordShort = 'Password must be at least 6 characters';
  static const confirmRequired = 'Confirm password is required';
  static const passwordMismatch = 'Passwords do not match';
  static const nameRequired = 'Name is required';
  static const nameLong = 'Name must be at most 80 characters';
  static const categoryRequired = 'Please choose a category';
  static const difficultyRequired = 'Please choose a difficulty';
  static const timeRequired = 'Cook time is required';
  static const timeInvalid = 'Cook time must be a whole number from 1 to 600';
  static const servingsInvalid = 'Servings must be a whole number from 1 to 20';
  static const notesLong = 'Notes must be at most 300 characters';
  static const registrationSuccess = 'Registration successful';
  static const recipeAdded = 'Recipe added';
  static const empty = 'No recipes found';
}

abstract final class Validate {
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return Messages.emailRequired;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
        ? null
        : Messages.emailInvalid;
  }

  static String? name(String? value) {
    final text = value ?? '';
    if (text.trim().isEmpty) return Messages.nameRequired;
    return text.length > 80 ? Messages.nameLong : null;
  }

  static String? integer(String? value, int max, {bool optional = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return optional ? null : Messages.timeRequired;
    final number = RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) : null;
    return number != null && number >= 1 && number <= max
        ? null
        : (optional ? Messages.servingsInvalid : Messages.timeInvalid);
  }
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.primary,
    primary: Palette.primary,
    surface: Colors.white,
    error: Palette.error,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Palette.border),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.canvas,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.canvas,
      foregroundColor: Palette.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: -.8,
        color: Palette.ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
        color: Palette.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Palette.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Palette.ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: Palette.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Palette.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: Palette.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.light,
      contentTextStyle: const TextStyle(color: Palette.ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.wordmark = true});
  final double size;
  final bool wordmark;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        label: 'RecipeBox logo',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Palette.primary,
            borderRadius: BorderRadius.circular(size * .29),
          ),
          child: CustomPaint(painter: _LogoPainter()),
        ),
      ),
      if (wordmark) ...[
        const SizedBox(width: 10),
        const Text(
          'RecipeBox',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
            color: Palette.ink,
          ),
        ),
      ],
    ],
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 11, 24, 28),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    final line = Paint()
      ..color = Palette.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(18, 24), const Offset(29, 24), line);
    canvas.drawLine(const Offset(18, 30), const Offset(27, 30), line);
    canvas.save();
    canvas.translate(32, 13);
    canvas.rotate(-.6);
    canvas.drawOval(
      const Rect.fromLTWH(-5, -3, 10, 6),
      Paint()..color = Palette.accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Content extends StatelessWidget {
  const Content({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F203127),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Palette.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message!,
                    style: const TextStyle(color: Palette.error),
                  ),
                ),
              ],
            ),
          ),
        );
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    ),
  );
}

void feedback(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
