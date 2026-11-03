import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? setupError;
  bool configured = false;
  try {
    final config = jsonDecode(
      await rootBundle.loadString('assets/firebase_config.json'),
    ) as Map<String, dynamic>;
    if ((config['apiKey'] as String? ?? '').isNotEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey'] as String,
          appId: config['appId'] as String,
          messagingSenderId: config['messagingSenderId'] as String,
          projectId: config['projectId'] as String,
          storageBucket: config['storageBucket'] as String?,
        ),
      );
      const host = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
      if (host.isNotEmpty) {
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      }
      configured = true;
    }
  } catch (error) {
    setupError = error.toString();
  }
  runApp(RecipeBoxApp(configured: configured, setupError: setupError));
}
