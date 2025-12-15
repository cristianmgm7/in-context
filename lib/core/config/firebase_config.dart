import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:incontext/core/config/firebase_options_dev.dart' as dev;
import 'package:incontext/core/providers/core_providers.dart';

class FirebaseConfig {
  Future<void> initialize() async {
    try {
      logger.i('🔥 Initializing Firebase');

      // Use native platform configuration files on mobile to avoid crashes
      // when Dart options are placeholders or not configured.
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android)) {
        await Firebase.initializeApp();
        logger.i('✅ Firebase initialized successfully (plist/json)');
        return;
      }

      // Use dev options for development
      await Firebase.initializeApp(
        options: dev.DefaultFirebaseOptions.currentPlatform,
      );

      logger.i('✅ Firebase initialized successfully');
    } on FirebaseException catch (e) {
      logger.i('❌ Firebase initialization failed: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      logger.i('❌ Firebase initialization failed: $e');
      logger.i('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
