import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/data/models/output_model.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';
import 'package:incontext/features/context/domain/repositories/output_repository.dart';

class FirebaseOutputRepository implements OutputRepository {
  FirebaseOutputRepository(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  @override
  Stream<List<OutputEntity>> watchOutputs(String contextId) {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('outputs')
        .where('contextId', isEqualTo: contextId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OutputModel.fromFirestore(doc).toEntity())
          .toList();
    });
  }

  @override
  Future<Result<OutputEntity>> createOutput({
    required String contextId,
    required String promptDefinitionId,
    required String promptVersion,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('outputs')
          .doc();

      final output = OutputModel(
        id: docRef.id,
        contextId: contextId,
        promptDefinitionId: promptDefinitionId,
        promptVersion: promptVersion,
        content: content,
        createdAt: now,
      );

      await docRef.set(output.toFirestore());
      return Success(output.toEntity());
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to create output: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create output: $e'));
    }
  }

  @override
  Future<Result<void>> deleteOutput(String outputId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('outputs')
          .doc(outputId)
          .delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to delete output: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to delete output: $e'));
    }
  }
}
