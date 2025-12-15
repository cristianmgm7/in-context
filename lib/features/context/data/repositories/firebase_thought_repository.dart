import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/data/models/thought_model.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/domain/failures/context_failure.dart';
import 'package:incontext/features/context/domain/repositories/thought_repository.dart';

class FirebaseThoughtRepository implements ThoughtRepository {
  FirebaseThoughtRepository(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _thoughtsCollection(
          String projectId) =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(projectId)
          .collection('thoughts');

  @override
  Stream<List<ThoughtEntity>> watchThoughts(String projectId) {
    return _thoughtsCollection(projectId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ThoughtModel.fromFirestore(doc).toEntity())
          .toList();
    });
  }

  @override
  Future<Result<ThoughtEntity>> createTextThought({
    required String projectId,
    required String text,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _thoughtsCollection(projectId).doc();

      final thought = ThoughtModel(
        id: docRef.id,
        projectId: projectId,
        type: ThoughtType.text,
        rawContent: text,
        createdAt: now,
      );

      await docRef.set(thought.toFirestore());
      return Success(thought.toEntity());
    } on FirebaseException catch (e) {
      return Error(ServerFailure(
          message: 'Failed to create text thought: ${e.message}'));
    } catch (e) {
      return Error(
          UnknownFailure(message: 'Failed to create text thought: $e'));
    }
  }

  @override
  Future<Result<ThoughtEntity>> createAudioThought({
    required String projectId,
    required String audioUrl,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _thoughtsCollection(projectId).doc();

      final thought = ThoughtModel(
        id: docRef.id,
        projectId: projectId,
        type: ThoughtType.audio,
        rawContent: audioUrl,
        transcriptionStatus: TranscriptionStatus.pending,
        createdAt: now,
      );

      await docRef.set(thought.toFirestore());
      return Success(thought.toEntity());
    } on FirebaseException catch (e) {
      return Error(ServerFailure(
          message: 'Failed to create audio thought: ${e.message}'));
    } catch (e) {
      return Error(
          UnknownFailure(message: 'Failed to create audio thought: $e'));
    }
  }

  @override
  Future<Result<void>> updateTranscription({
    required String thoughtId,
    required String transcript,
    required TranscriptionStatus status,
  }) async {
    try {
      // We need to find which project this thought belongs to
      // This is a limitation - we might need to store projectId in the thought document
      // For now, we'll search through all projects (not ideal for production)
      final projectsSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .get();

      for (final projectDoc in projectsSnapshot.docs) {
        final thoughtDoc = await projectDoc.reference
            .collection('thoughts')
            .doc(thoughtId)
            .get();

        if (thoughtDoc.exists) {
          await thoughtDoc.reference.update({
            'transcript': transcript,
            'transcriptionStatus': status.index,
          });
          return const Success(null);
        }
      }

      return Error(ContextFailure.thoughtNotFound());
    } on FirebaseException catch (e) {
      return Error(ServerFailure(
          message: 'Failed to update transcription: ${e.message}'));
    } catch (e) {
      return Error(
          UnknownFailure(message: 'Failed to update transcription: $e'));
    }
  }

  @override
  Future<Result<void>> deleteThought(String thoughtId) async {
    try {
      // Same limitation as updateTranscription
      final projectsSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .get();

      for (final projectDoc in projectsSnapshot.docs) {
        final thoughtDoc = await projectDoc.reference
            .collection('thoughts')
            .doc(thoughtId)
            .get();

        if (thoughtDoc.exists) {
          await thoughtDoc.reference.delete();
          return const Success(null);
        }
      }

      return Error(ContextFailure.thoughtNotFound());
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to delete thought: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to delete thought: $e'));
    }
  }
}
