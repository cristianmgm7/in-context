import 'package:firebase_core/firebase_core.dart';
import 'package:incontext/core/config/firebase_options_dev.dart' as dev;
import 'package:incontext/core/providers/core_providers.dart';

class FirebaseConfig {
  Future<void> initialize() async {
    try {
      logger.i('🔥 Initializing Firebase');

      // Always use Firebase options from code for consistency
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
