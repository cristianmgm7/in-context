import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/data/models/context_model.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/failures/context_failure.dart';
import 'package:incontext/features/context/domain/repositories/context_repository.dart';

class FirebaseContextRepository implements ContextRepository {
  FirebaseContextRepository(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _contextsCollection(
          String projectId) =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(projectId)
          .collection('contexts');

  @override
  Future<Result<ContextEntity?>> getContextForProject(String projectId) async {
    try {
      final snapshot = await _contextsCollection(projectId)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const Success(null);
      }

      final context =
          ContextModel.fromFirestore(snapshot.docs.first).toEntity();
      return Success(context);
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to get context: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get context: $e'));
    }
  }

  @override
  Stream<ContextEntity?> watchContextForProject(String projectId) {
    return _contextsCollection(projectId)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return ContextModel.fromFirestore(snapshot.docs.first).toEntity();
    });
  }

  @override
  Future<Result<ContextEntity>> saveContext({
    required String projectId,
    required String content,
    required List<String> sourceThoughtIds,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _contextsCollection(projectId).doc();

      final context = ContextModel(
        id: docRef.id,
        projectId: projectId,
        content: content,
        sourceThoughtIds: sourceThoughtIds,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(context.toFirestore());
      return Success(context.toEntity());
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to save context: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to save context: $e'));
    }
  }

  @override
  Future<Result<ContextEntity>> updateContextContent({
    required String contextId,
    required String content,
  }) async {
    try {
      // We need to find which project this context belongs to
      final projectsSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .get();

      for (final projectDoc in projectsSnapshot.docs) {
        final contextDoc = await projectDoc.reference
            .collection('contexts')
            .doc(contextId)
            .get();

        if (contextDoc.exists) {
          await contextDoc.reference.update({
            'content': content,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

          // Fetch and return updated context
          final updatedDoc = await contextDoc.reference.get();
          return Success(ContextModel.fromFirestore(updatedDoc).toEntity());
        }
      }

      return Error(ContextFailure.contextNotFound());
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to update context: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to update context: $e'));
    }
  }
}
