import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/app/app.dart';
import 'package:incontext/core/config/firebase_config.dart';
import 'package:incontext/core/config/flavor_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AppConfig first (also loads .env file)
  await AppConfig.initialize();

  // Initialize Firebase
  final firebaseConfig = FirebaseConfig();
  await firebaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
