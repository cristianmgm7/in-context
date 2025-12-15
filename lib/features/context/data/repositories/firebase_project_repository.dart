import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/data/models/project_model.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';
import 'package:incontext/features/context/domain/failures/context_failure.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';

class FirebaseProjectRepository implements ProjectRepository {
  FirebaseProjectRepository(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _projectsCollection =>
      _firestore.collection('users').doc(_userId).collection('projects');

  @override
  Stream<List<ProjectEntity>> watchProjects() {
    return _projectsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc).toEntity())
          .toList();
    });
  }

  @override
  Future<Result<ProjectEntity>> getProject(String id) async {
    try {
      final doc = await _projectsCollection.doc(id).get();
      if (!doc.exists) {
        return Error(ContextFailure.projectNotFound());
      }
      return Success(ProjectModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to get project: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get project: $e'));
    }
  }

  @override
  Future<Result<ProjectEntity>> createProject({
    required String title,
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _projectsCollection.doc();

      final project = ProjectModel(
        id: docRef.id,
        title: title,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(project.toFirestore());
      return Success(project.toEntity());
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to create project: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create project: $e'));
    }
  }

  @override
  Future<Result<ProjectEntity>> updateProject({
    required String id,
    String? title,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;

      await _projectsCollection.doc(id).update(updates);

      // Fetch and return updated project
      final result = await getProject(id);
      return result;
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to update project: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to update project: $e'));
    }
  }

  @override
  Future<Result<void>> deleteProject(String id) async {
    try {
      await _projectsCollection.doc(id).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Error(
          ServerFailure(message: 'Failed to delete project: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to delete project: $e'));
    }
  }
}
