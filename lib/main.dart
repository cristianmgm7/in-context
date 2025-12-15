import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/app/app.dart';
import 'package:incontext/core/config/firebase_options_dev.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase with environment-based options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.ios, // Use iOS options for now
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
