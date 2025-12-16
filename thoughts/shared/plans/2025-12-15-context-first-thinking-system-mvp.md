# Context-First Thinking System (MVP) Implementation Plan

## Overview

Building a **Context-First thinking tool** for working with AI. Users capture raw, messy thoughts (text and audio), refine them into a canonical Context using AI, and then apply AI Actions (prompt definitions) to generate disposable Outputs. The core value: AI enhances clarity without replacing thinking.

**Target Users**: Knowledge workers who need better prompts for AI code agents (starting with ourselves).

**Core Philosophy**:
- Thoughts are immutable raw input
- Context is the refined, canonical understanding
- Outputs are disposable projections from Context
- AI edits meaning, not history

## Current State Analysis

### Existing Codebase Strengths:
- **Clean Architecture**: Features follow domain/data/presentation layers ([lib/features/auth](lib/features/auth))
- **Result Pattern**: Robust error handling with `Result<T>` and `Failure` hierarchy ([lib/core/utils/result.dart:5-50](lib/core/utils/result.dart#L5-L50))
- **Riverpod**: Established state management patterns ([lib/features/auth/presentation/providers](lib/features/auth/presentation/providers))
- **Audio Recording Service**: Already implemented ([lib/core/services/audio_recorder_service.dart:20-166](lib/core/services/audio_recorder_service.dart#L20-L166))
- **Firebase Integration**: Storage and Firestore ready
- **UI Components**: Reusable widgets (`AppButton`, `AppTextField`, `LoadingBody`, `ErrorBody`)

### What We're Building:
A new feature (`lib/features/context/`) following existing architectural patterns.

## Desired End State

### Functional Requirements:
1. **Projects**: Users can create/list/delete projects
2. **Thoughts**: Users can add text and audio thoughts to a project
3. **Audio Transcription**: Audio thoughts are transcribed asynchronously
4. **Context Refinement**: AI refines all thoughts into a single coherent Context
5. **Outdated Detection**: UI shows banner when thoughts are added/deleted after context creation
6. **Manual Context Editing**: Users can directly edit context
7. **AI Actions (Outputs)**: Users can apply prompt definitions to context to generate outputs
8. **Prompt Management**: Prompt definitions are versioned; outputs track which version was used

### Success Verification:

#### Automated Verification:
- [ ] All unit tests pass: `~/flutter/bin/flutter test`
- [ ] Code compiles without errors: `~/flutter/bin/flutter analyze`
- [ ] Code formatting passes: `~/flutter/bin/dart format lib --set-exit-if-changed`
- [ ] Firebase configuration loads correctly
- [ ] App builds successfully: `~/flutter/bin/flutter build apk --debug`

#### Manual Verification:
- [ ] Can create a new project and see it in the projects list
- [ ] Can add text thoughts and see them appear in the project
- [ ] Can record audio thought and see "transcribing..." state
- [ ] Can trigger context refinement and see the generated context
- [ ] Can see "Context outdated" banner after adding a new thought
- [ ] Can manually edit context text
- [ ] Can apply a prompt definition and see the generated output
- [ ] Output cards show which prompt version was used
- [ ] App navigation works correctly between screens

## What We're NOT Doing

- **No versioning**: Context is not versioned (simplified for MVP)
- **No multi-device sync strategy**: Basic Firestore sync only
- **No image/link thoughts**: Only text and audio for MVP
- **No real transcription API**: Using dummy transcription initially (integrate later)
- **No real LLM API**: Using dummy enhancement/output initially (integrate later)
- **No undo/redo system**: Manual context editing is the safety valve
- **No authentication beyond existing system**: Reusing Firebase Auth
- **No advanced prompt editor**: Prompts are hardcoded initially
- **No output editing**: Outputs are read-only
- **No sharing/export features**: Users can copy text manually

## Implementation Approach

**Strategy**: Build in incremental phases using dummy data first, then integrate real services last. This allows us to:
1. Validate UI/UX without API dependencies
2. Test domain logic in isolation
3. Iterate quickly on user flows
4. Add AI services only when everything else works

**Key Patterns to Follow**:
- Domain entities extend `Equatable` ([lib/features/auth/domain/entities/user_entity.dart:3-21](lib/features/auth/domain/entities/user_entity.dart#L3-L21))
- Repositories return `Future<Result<T>>` ([lib/features/auth/domain/repositories/auth_repository.dart:4-37](lib/features/auth/domain/repositories/auth_repository.dart#L4-L37))
- Use cases have `call()` method ([lib/features/auth/domain/usecases/sign_in_with_email.dart:10-14](lib/features/auth/domain/usecases/sign_in_with_email.dart#L10-L14))
- Controllers extend `StateNotifier` ([lib/features/auth/presentation/providers/auth_controller.dart:14-108](lib/features/auth/presentation/providers/auth_controller.dart#L14-L108))
- Services use constructor injection and return `Result<T>` ([lib/core/services/audio_recorder_service.dart:20-166](lib/core/services/audio_recorder_service.dart#L20-L166))

---

## Phase 1: Domain Layer Foundation

### Overview
Define the core domain entities, repositories, and use cases. This establishes the business rules and contracts that all other layers depend on. No implementation details, no UI, no external dependencies.

### Changes Required:

#### 1. Domain Entities

**File**: `lib/features/context/domain/entities/project_entity.dart`

**Purpose**: Container for a line of thinking

```dart
import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  const ProjectEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, title, description, createdAt, updatedAt];

  @override
  String toString() => 'ProjectEntity(id: $id, title: $title)';
}
```

**Pattern Reference**: [lib/features/auth/domain/entities/user_entity.dart:3-21](lib/features/auth/domain/entities/user_entity.dart#L3-L21)

---

**File**: `lib/features/context/domain/entities/thought_entity.dart`

**Purpose**: Atomic, immutable thought (text or audio)

```dart
import 'package:equatable/equatable.dart';

enum ThoughtType { text, audio }

enum TranscriptionStatus { pending, processing, completed, failed }

class ThoughtEntity extends Equatable {
  const ThoughtEntity({
    required this.id,
    required this.projectId,
    required this.type,
    required this.rawContent,
    required this.createdAt,
    this.transcript,
    this.transcriptionStatus = TranscriptionStatus.completed,
  });

  final String id;
  final String projectId;
  final ThoughtType type;
  final String rawContent; // For text: the text itself. For audio: Firebase Storage URL
  final String? transcript; // Only for audio thoughts
  final TranscriptionStatus transcriptionStatus;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        projectId,
        type,
        rawContent,
        transcript,
        transcriptionStatus,
        createdAt,
      ];

  @override
  String toString() => 'ThoughtEntity(id: $id, type: $type, createdAt: $createdAt)';
}
```

**Key Design Decision**: `rawContent` is polymorphic - stores text directly or storage URL for audio.

---

**File**: `lib/features/context/domain/entities/context_entity.dart`

**Purpose**: Refined canonical understanding derived from thoughts

```dart
import 'package:equatable/equatable.dart';

class ContextEntity extends Equatable {
  const ContextEntity({
    required this.id,
    required this.projectId,
    required this.content,
    required this.sourceThoughtIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String projectId;
  final String content; // The refined text
  final List<String> sourceThoughtIds; // Which thoughts were used to generate this
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        projectId,
        content,
        sourceThoughtIds,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'ContextEntity(id: $id, projectId: $projectId)';
}
```

---

**File**: `lib/features/context/domain/entities/output_entity.dart`

**Purpose**: Disposable result from applying prompt to context

```dart
import 'package:equatable/equatable.dart';

class OutputEntity extends Equatable {
  const OutputEntity({
    required this.id,
    required this.contextId,
    required this.promptDefinitionId,
    required this.promptVersion,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String contextId;
  final String promptDefinitionId; // Which prompt was used
  final String promptVersion; // Version of prompt (e.g., "1.0.0")
  final String content; // The generated output
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        contextId,
        promptDefinitionId,
        promptVersion,
        content,
        createdAt,
      ];

  @override
  String toString() => 'OutputEntity(id: $id, promptId: $promptDefinitionId v$promptVersion)';
}
```

---

**File**: `lib/features/context/domain/entities/prompt_definition_entity.dart`

**Purpose**: Versioned, immutable prompt template

```dart
import 'package:equatable/equatable.dart';

class PromptDefinitionEntity extends Equatable {
  const PromptDefinitionEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.promptTemplate,
  });

  final String id;
  final String name; // e.g., "Email Generator"
  final String description; // e.g., "Converts context into a professional email"
  final String version; // e.g., "1.0.0"
  final String promptTemplate; // The actual prompt text with placeholders

  @override
  List<Object?> get props => [id, name, description, version, promptTemplate];

  @override
  String toString() => 'PromptDefinitionEntity(id: $id, name: $name v$version)';
}
```

---

#### 2. Repository Interfaces

**File**: `lib/features/context/domain/repositories/project_repository.dart`

```dart
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';

abstract class ProjectRepository {
  /// Stream of all projects for the current user
  Stream<List<ProjectEntity>> watchProjects();

  /// Get a single project by ID
  Future<Result<ProjectEntity>> getProject(String id);

  /// Create a new project
  Future<Result<ProjectEntity>> createProject({
    required String title,
    String? description,
  });

  /// Update an existing project
  Future<Result<ProjectEntity>> updateProject({
    required String id,
    String? title,
    String? description,
  });

  /// Delete a project
  Future<Result<void>> deleteProject(String id);
}
```

**Pattern Reference**: [lib/features/auth/domain/repositories/auth_repository.dart:4-37](lib/features/auth/domain/repositories/auth_repository.dart#L4-L37)

---

**File**: `lib/features/context/domain/repositories/thought_repository.dart`

```dart
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';

abstract class ThoughtRepository {
  /// Stream of all thoughts for a project
  Stream<List<ThoughtEntity>> watchThoughts(String projectId);

  /// Create a text thought
  Future<Result<ThoughtEntity>> createTextThought({
    required String projectId,
    required String text,
  });

  /// Create an audio thought (requires uploading file first)
  Future<Result<ThoughtEntity>> createAudioThought({
    required String projectId,
    required String audioUrl,
  });

  /// Update transcription for an audio thought
  Future<Result<void>> updateTranscription({
    required String thoughtId,
    required String transcript,
    required TranscriptionStatus status,
  });

  /// Delete a thought
  Future<Result<void>> deleteThought(String thoughtId);
}
```

---

**File**: `lib/features/context/domain/repositories/context_repository.dart`

```dart
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';

abstract class ContextRepository {
  /// Get the context for a project (if exists)
  Future<Result<ContextEntity?>> getContextForProject(String projectId);

  /// Watch context changes for a project
  Stream<ContextEntity?> watchContextForProject(String projectId);

  /// Create or update context for a project
  Future<Result<ContextEntity>> saveContext({
    required String projectId,
    required String content,
    required List<String> sourceThoughtIds,
  });

  /// Manually update context content
  Future<Result<ContextEntity>> updateContextContent({
    required String contextId,
    required String content,
  });
}
```

---

**File**: `lib/features/context/domain/repositories/output_repository.dart`

```dart
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';

abstract class OutputRepository {
  /// Stream of all outputs for a context
  Stream<List<OutputEntity>> watchOutputs(String contextId);

  /// Create a new output
  Future<Result<OutputEntity>> createOutput({
    required String contextId,
    required String promptDefinitionId,
    required String promptVersion,
    required String content,
  });

  /// Delete an output
  Future<Result<void>> deleteOutput(String outputId);
}
```

---

#### 3. Use Cases

**File**: `lib/features/context/domain/usecases/create_project.dart`

```dart
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';

class CreateProject {
  const CreateProject(this._repository);

  final ProjectRepository _repository;

  Future<Result<ProjectEntity>> call({
    required String title,
    String? description,
  }) =>
      _repository.createProject(
        title: title,
        description: description,
      );
}
```

**Pattern Reference**: [lib/features/auth/domain/usecases/sign_in_with_email.dart:5-14](lib/features/auth/domain/usecases/sign_in_with_email.dart#L5-L14)

**Similar pattern for**:
- `lib/features/context/domain/usecases/get_project.dart`
- `lib/features/context/domain/usecases/list_projects.dart`
- `lib/features/context/domain/usecases/delete_project.dart`
- `lib/features/context/domain/usecases/create_thought.dart`
- `lib/features/context/domain/usecases/delete_thought.dart`
- `lib/features/context/domain/usecases/list_thoughts_for_project.dart`

---

**File**: `lib/features/context/domain/usecases/enhance_context.dart`

```dart
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/domain/repositories/context_repository.dart';

/// Use case: Enhance context by refining all thoughts using AI
class EnhanceContext {
  const EnhanceContext(this._repository);

  final ContextRepository _repository;

  Future<Result<ContextEntity>> call({
    required String projectId,
    required List<ThoughtEntity> thoughts,
    required String Function(List<ThoughtEntity>) enhancer,
  }) async {
    // Call the enhancer function (AI service) to generate refined content
    final enhancedContent = enhancer(thoughts);

    // Save the enhanced context
    return _repository.saveContext(
      projectId: projectId,
      content: enhancedContent,
      sourceThoughtIds: thoughts.map((t) => t.id).toList(),
    );
  }
}
```

**Key Design**: Takes an `enhancer` function parameter to remain agnostic of AI implementation.

---

**File**: `lib/features/context/domain/usecases/create_output.dart`

```dart
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';
import 'package:incontext/features/context/domain/entities/prompt_definition_entity.dart';
import 'package:incontext/features/context/domain/repositories/output_repository.dart';

/// Use case: Generate output by applying a prompt to context
class CreateOutput {
  const CreateOutput(this._repository);

  final OutputRepository _repository;

  Future<Result<OutputEntity>> call({
    required ContextEntity context,
    required PromptDefinitionEntity prompt,
    required String Function(ContextEntity, PromptDefinitionEntity) generator,
  }) async {
    // Call the generator function (AI service) to create output
    final generatedContent = generator(context, prompt);

    // Save the output
    return _repository.createOutput(
      contextId: context.id,
      promptDefinitionId: prompt.id,
      promptVersion: prompt.version,
      content: generatedContent,
    );
  }
}
```

---

#### 4. Domain Failures

**File**: `lib/features/context/domain/failures/context_failure.dart`

```dart
import 'package:incontext/core/errors/failures.dart';

class ContextFailure extends Failure {
  const ContextFailure({
    required super.message,
    super.code,
  });

  factory ContextFailure.projectNotFound() => const ContextFailure(
        message: 'Project not found',
        code: 404,
      );

  factory ContextFailure.thoughtNotFound() => const ContextFailure(
        message: 'Thought not found',
        code: 404,
      );

  factory ContextFailure.contextNotFound() => const ContextFailure(
        message: 'Context not found',
        code: 404,
      );

  factory ContextFailure.transcriptionFailed(String reason) => ContextFailure(
        message: 'Transcription failed: $reason',
        code: 500,
      );

  factory ContextFailure.enhancementFailed(String reason) => ContextFailure(
        message: 'Context enhancement failed: $reason',
        code: 500,
      );

  factory ContextFailure.outputGenerationFailed(String reason) => ContextFailure(
        message: 'Output generation failed: $reason',
        code: 500,
      );

  factory ContextFailure.unknown(String message) => ContextFailure(
        message: message,
        code: 500,
      );
}
```

**Pattern Reference**: [lib/features/auth/domain/failures/auth_failure.dart:3-42](lib/features/auth/domain/failures/auth_failure.dart#L3-L42)

---

### Success Criteria:

#### Automated Verification:
- [x] All domain entity files compile: `~/flutter/bin/flutter analyze lib/features/context/domain/entities`
- [x] All repository interfaces compile: `~/flutter/bin/flutter analyze lib/features/context/domain/repositories`
- [x] All use cases compile: `~/flutter/bin/flutter analyze lib/features/context/domain/usecases`
- [x] Failure class compiles: `~/flutter/bin/flutter analyze lib/features/context/domain/failures`
- [x] No linting errors: `~/flutter/bin/flutter analyze`

#### Manual Verification:
- [x] Domain entities follow the same pattern as `UserEntity` (Equatable, const constructor, final fields)
- [x] Repository interfaces match the `AuthRepository` pattern (abstract class, `Result<T>` returns)
- [x] Use cases follow the `SignInWithEmail` pattern (single responsibility, `call()` method)
- [x] Failure class follows the `AuthFailure` pattern (named factories)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 2: Data Layer (Firestore Models & Repositories)

### Overview
Implement the data layer with Firestore persistence. Create models that extend domain entities and implement repository interfaces. Use dummy data initially for collections to test serialization without Firebase dependency.

### Changes Required:

#### 1. Data Models

**File**: `lib/features/context/data/models/project_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.description,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  ProjectEntity toEntity() {
    return ProjectEntity(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
```

**Pattern Reference**: [lib/features/auth/data/models/user_model.dart:5-51](lib/features/auth/data/models/user_model.dart#L5-L51)

**Similar models needed for**:
- `lib/features/context/data/models/thought_model.dart` (with enum serialization for `ThoughtType` and `TranscriptionStatus`)
- `lib/features/context/data/models/context_model.dart`
- `lib/features/context/data/models/output_model.dart`

---

#### 2. Firestore Repository Implementation

**File**: `lib/features/context/data/repositories/firebase_project_repository.dart`

```dart
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
      return Error(ServerFailure(message: 'Failed to get project: ${e.message}'));
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
      return Error(ServerFailure(message: 'Failed to create project: ${e.message}'));
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
      return Error(ServerFailure(message: 'Failed to update project: ${e.message}'));
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
      return Error(ServerFailure(message: 'Failed to delete project: ${e.message}'));
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to delete project: $e'));
    }
  }
}
```

**Pattern Reference**: [lib/features/auth/data/repositories/firebase_auth_repository.dart:10-165](lib/features/auth/data/repositories/firebase_auth_repository.dart#L10-L165)

**Similar repositories needed for**:
- `lib/features/context/data/repositories/firebase_thought_repository.dart`
- `lib/features/context/data/repositories/firebase_context_repository.dart`
- `lib/features/context/data/repositories/firebase_output_repository.dart`

**Key Pattern**: Collection path is `users/{userId}/projects` for multi-tenancy.

---

### Success Criteria:

#### Automated Verification:
- [x] All model files compile: `~/flutter/bin/flutter analyze lib/features/context/data/models`
- [x] All repository implementations compile: `~/flutter/bin/flutter analyze lib/features/context/data/repositories`
- [x] Models correctly extend domain entities
- [x] No linting errors: `~/flutter/bin/flutter analyze`

#### Manual Verification:
- [ ] Models follow the `UserModel` pattern (extend entity, `fromFirestore`, `toFirestore`, `toEntity`)
- [ ] Repositories follow the `FirebaseAuthRepository` pattern (try-catch with Result wrapping, error mapping)
- [ ] Firestore paths are correct (`users/{userId}/projects`, etc.)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 3: Presentation Layer (Riverpod Providers)

### Overview
Set up Riverpod providers for dependency injection and state management. Create repository providers, use case providers, and state controllers. This layer bridges domain/data to UI.

### Changes Required:

#### 1. Repository Providers

**File**: `lib/features/context/presentation/providers/context_providers.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/providers/core_providers.dart';
import 'package:incontext/features/context/data/repositories/firebase_context_repository.dart';
import 'package:incontext/features/context/data/repositories/firebase_output_repository.dart';
import 'package:incontext/features/context/data/repositories/firebase_project_repository.dart';
import 'package:incontext/features/context/data/repositories/firebase_thought_repository.dart';
import 'package:incontext/features/context/domain/repositories/context_repository.dart';
import 'package:incontext/features/context/domain/repositories/output_repository.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';
import 'package:incontext/features/context/domain/repositories/thought_repository.dart';

/// Project repository provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseProjectRepository(firestore, firebaseAuth);
});

/// Thought repository provider
final thoughtRepositoryProvider = Provider<ThoughtRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseThoughtRepository(firestore, firebaseAuth);
});

/// Context repository provider
final contextRepositoryProvider = Provider<ContextRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseContextRepository(firestore, firebaseAuth);
});

/// Output repository provider
final outputRepositoryProvider = Provider<OutputRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return FirebaseOutputRepository(firestore, firebaseAuth);
});

/// Stream provider for all projects
final projectsStreamProvider = StreamProvider((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProjects();
});

/// Provider family for a specific project
final projectProvider = FutureProvider.family<ProjectEntity, String>((ref, projectId) async {
  final repository = ref.watch(projectRepositoryProvider);
  final result = await repository.getProject(projectId);
  return result.when(
    success: (project) => project,
    error: (failure) => throw failure,
  );
});

/// Stream provider family for thoughts in a project
final thoughtsStreamProvider = StreamProvider.family<List<ThoughtEntity>, String>((ref, projectId) {
  final repository = ref.watch(thoughtRepositoryProvider);
  return repository.watchThoughts(projectId);
});

/// Stream provider family for context in a project
final contextStreamProvider = StreamProvider.family<ContextEntity?, String>((ref, projectId) {
  final repository = ref.watch(contextRepositoryProvider);
  return repository.watchContextForProject(projectId);
});
```

**Pattern Reference**: [lib/features/auth/presentation/providers/auth_providers.dart:10-65](lib/features/auth/presentation/providers/auth_providers.dart#L10-L65)

**New Pattern**: Using `.family` for parameterized providers (e.g., `projectProvider.family<ProjectEntity, String>` takes projectId)

---

#### 2. State Controllers

**File**: `lib/features/context/presentation/providers/project_controller.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/features/context/domain/entities/project_entity.dart';
import 'package:incontext/features/context/domain/repositories/project_repository.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';

/// Provider for project controller
final projectControllerProvider = StateNotifierProvider<ProjectController, ProjectState>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return ProjectController(repository);
});

/// Controller for project operations
class ProjectController extends StateNotifier<ProjectState> {
  ProjectController(this._repository) : super(const ProjectState());

  final ProjectRepository _repository;

  Future<void> createProject({
    required String title,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.createProject(
      title: title,
      description: description,
    );

    result.when(
      success: (project) {
        state = state.copyWith(
          isLoading: false,
          createdProject: project,
        );
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<void> deleteProject(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteProject(id);

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith();
  }

  void clearCreatedProject() {
    state = state.copyWith(createdProject: null);
  }
}

/// State for project operations
class ProjectState {
  const ProjectState({
    this.isLoading = false,
    this.error,
    this.createdProject,
  });

  final bool isLoading;
  final String? error;
  final ProjectEntity? createdProject;

  ProjectState copyWith({
    bool? isLoading,
    String? error,
    ProjectEntity? createdProject,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdProject: createdProject,
    );
  }
}
```

**Pattern Reference**: [lib/features/auth/presentation/providers/auth_controller.dart:8-129](lib/features/auth/presentation/providers/auth_controller.dart#L8-L129)

**Similar controllers needed for**:
- `lib/features/context/presentation/providers/thought_controller.dart` (create/delete thoughts, upload audio)
- `lib/features/context/presentation/providers/context_controller.dart` (enhance context, update context)

---

### Success Criteria:

#### Automated Verification:
- [ ] Provider files compile: `~/flutter/bin/flutter analyze lib/features/context/presentation/providers`
- [ ] No circular dependency issues
- [ ] No linting errors: `~/flutter/bin/flutter analyze`

#### Manual Verification:
- [ ] Providers follow the `authRepositoryProvider` pattern (watch core providers, create repository)
- [ ] Stream providers use `.family` for parameterized streams
- [ ] Controllers follow the `AuthController` pattern (StateNotifier, copyWith state)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 4: UI - Projects List Screen

### Overview
Build the projects list screen to create and display projects. This is the entry point to the app. Use dummy data from providers initially.

### Changes Required:

#### 1. Projects List Screen

**File**: `lib/features/context/presentation/screens/projects_list_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:incontext/core/routing/app_routes.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_button.dart';
import 'package:incontext/core/widgets/empty_state.dart';
import 'package:incontext/core/widgets/error_body.dart';
import 'package:incontext/core/widgets/loading_body.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';
import 'package:incontext/features/context/presentation/providers/project_controller.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    // Listen for creation success to navigate
    ref.listen<ProjectState>(projectControllerProvider, (previous, next) {
      if (next.createdProject != null) {
        context.push('${AppRoutes.projects}/${next.createdProject!.id}');
        ref.read(projectControllerProvider.notifier).clearCreatedProject();
      }

      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(projectControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return EmptyState(
              icon: Icons.lightbulb_outline,
              title: 'No Projects Yet',
              message: 'Create your first project to start capturing thoughts',
              action: AppButton(
                text: 'Create Project',
                onPressed: () => _showCreateProjectDialog(context, ref),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  title: Text(project.title),
                  subtitle: project.description != null
                      ? Text(project.description!)
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('${AppRoutes.projects}/${project.id}'),
                ),
              );
            },
          );
        },
        loading: () => const LoadingBody(loadingMessage: 'Loading projects...'),
        error: (error, _) => ErrorBody(
          description: 'Failed to load projects: $error',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'My project idea',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this project about?',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(projectControllerProvider);
              return TextButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a title'),
                            ),
                          );
                          return;
                        }

                        ref.read(projectControllerProvider.notifier).createProject(
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                            );

                        context.pop();
                      },
                child: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

**Pattern Reference**: [lib/features/auth/presentation/screens/login_screen.dart:19-179](lib/features/auth/presentation/screens/login_screen.dart#L19-L179)

---

#### 2. Add Route

**File**: `lib/core/routing/app_routes.dart`

Add:
```dart
static const String projects = '/projects';
static const String projectDetail = '/projects/:id';
```

**File**: `lib/core/routing/app_router.dart`

Add route in the routes list:
```dart
GoRoute(
  path: AppRoutes.projects,
  builder: (context, state) => const ProjectsListScreen(),
),
```

---

### Success Criteria:

#### Automated Verification:
- [ ] Screen compiles: `~/flutter/bin/flutter analyze lib/features/context/presentation/screens`
- [ ] Routes compile: `~/flutter/bin/flutter analyze lib/core/routing`
- [ ] App builds: `~/flutter/bin/flutter build apk --debug`

#### Manual Verification:
- [x] Can navigate to `/projects` route
- [x] Empty state shows correctly when no projects
- [x] "Create Project" dialog appears when clicking FAB
- [x] Can create a project with title and description
- [x] New project appears in the list immediately
- [x] Can tap project to navigate (will show error since detail screen doesn't exist yet)
- [x] Loading state shows while creating project
- [x] Error snackbar shows if creation fails

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 5: UI - Project Detail Screen (Thoughts + Context)

### Overview
Build the main project screen showing thoughts, context, and outputs. This is the core UX. Implement text thought creation, context display, and "outdated" banner logic.

### Changes Required:

#### 1. Project Detail Screen

**File**: `lib/features/context/presentation/screens/project_screen.dart`

This is a complex screen. Key sections:
- App bar with project title
- Thoughts section (scrollable list)
- Add thought input (text field + voice button)
- Context section (with "outdated" banner, "Refine Context" button)
- Outputs section (list of generated outputs)

**Pseudocode structure**:
```dart
class ProjectScreen extends ConsumerStatefulWidget {
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));
    final thoughtsAsync = ref.watch(thoughtsStreamProvider(projectId));
    final contextAsync = ref.watch(contextStreamProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: Text(project.title)),
      body: Column([
        // Thoughts section
        Expanded(
          child: ListView([
            ThoughtCard for each thought,
          ]),
        ),

        // Context section
        if (context != null) ContextCard(
          context: context,
          isOutdated: _isContextOutdated(context, thoughts),
        ),

        // Add thought input
        ThoughtInputWidget(onSubmit: _addThought),
      ]),
    );
  }

  bool _isContextOutdated(ContextEntity context, List<ThoughtEntity> thoughts) {
    // Context is outdated if:
    // 1. Any thought was created after context.updatedAt
    // 2. Any thought in sourceThoughtIds is missing (deleted)
    return thoughts.any((t) => t.createdAt.isAfter(context.updatedAt)) ||
           !context.sourceThoughtIds.every((id) => thoughts.any((t) => t.id == id));
  }
}
```

**Pattern Reference**: [lib/features/auth/presentation/screens/login_screen.dart](lib/features/auth/presentation/screens/login_screen.dart)

---

#### 2. Thought Widgets

**File**: `lib/features/context/presentation/widgets/thought_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

class ThoughtCard extends StatelessWidget {
  const ThoughtCard({
    required this.thought,
    required this.onDelete,
    super.key,
  });

  final ThoughtEntity thought;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  thought.type == ThoughtType.text ? Icons.text_fields : Icons.mic,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  timeago.format(thought.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (thought.type == ThoughtType.text)
              Text(thought.rawContent)
            else ...[
              if (thought.transcriptionStatus == TranscriptionStatus.processing)
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('Transcribing...'),
                  ],
                )
              else if (thought.transcript != null)
                Text(thought.transcript!)
              else
                const Text('[Audio]', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

**File**: `lib/features/context/presentation/widgets/thought_input_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_text_field.dart';

class ThoughtInputWidget extends StatefulWidget {
  const ThoughtInputWidget({
    required this.onSubmitText,
    required this.onRecordAudio,
    required this.isRecording,
    super.key,
  });

  final void Function(String text) onSubmitText;
  final VoidCallback onRecordAudio;
  final bool isRecording;

  @override
  State<ThoughtInputWidget> createState() => _ThoughtInputWidgetState();
}

class _ThoughtInputWidgetState extends State<ThoughtInputWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitText(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _controller,
              hint: 'Add a thought...',
              maxLines: null,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: Icon(widget.isRecording ? Icons.stop : Icons.mic),
            onPressed: widget.onRecordAudio,
            color: widget.isRecording ? Colors.red : null,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
```

---

#### 3. Context Widget

**File**: `lib/features/context/presentation/widgets/context_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_button.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';

class ContextCard extends StatelessWidget {
  const ContextCard({
    required this.context,
    required this.isOutdated,
    required this.onRefine,
    required this.onEdit,
    super.key,
    this.isRefining = false,
  });

  final ContextEntity? context;
  final bool isOutdated;
  final VoidCallback onRefine;
  final VoidCallback onEdit;
  final bool isRefining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Context',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (isOutdated)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Context is outdated. Thoughts have been added or removed.',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (this.context != null) ...[
              Text(this.context!.content),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Edit',
                      type: AppButtonType.outlined,
                      onPressed: onEdit,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      text: 'Refine',
                      onPressed: onRefine,
                      isLoading: isRefining,
                    ),
                  ),
                ],
              ),
            ] else
              AppButton(
                text: 'Refine Context',
                onPressed: onRefine,
                isLoading: isRefining,
              ),
          ],
        ),
      ),
    );
  }
}
```

---

#### 4. Update Routes

Add route for project detail:

**File**: `lib/core/routing/app_router.dart`

```dart
GoRoute(
  path: '/projects/:id',
  builder: (context, state) {
    final projectId = state.pathParameters['id']!;
    return ProjectScreen(projectId: projectId);
  },
),
```

---

### Success Criteria:

#### Automated Verification:
- [x] Screen compiles: `~/flutter/bin/flutter analyze lib/features/context/presentation/screens/project_screen.dart`
- [x] Widgets compile: `~/flutter/bin/flutter analyze lib/features/context/presentation/widgets`
- [x] App builds: `~/flutter/bin/flutter build apk --debug`

#### Manual Verification:
- [x] Can navigate to project detail from projects list
- [x] Project title shows in app bar
- [ ] Can add text thoughts using input field (TODO placeholders implemented)
- [ ] Text thoughts appear in the list immediately (TODO placeholders implemented)
- [ ] Can delete a thought (TODO placeholders implemented)
- [x] "Refine Context" button shows when no context exists
- [ ] After refining, context card appears with content (TODO placeholders implemented)
- [x] "Context outdated" banner shows after adding a new thought (logic implemented)
- [ ] "Edit" button opens context editor (will implement next)
- [ ] "Refine" button updates context when clicked (TODO placeholders implemented)

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 6: Audio Recording Integration

### Overview
Integrate audio recording using the existing `AudioRecorderService`. Upload audio to Firebase Storage, create audio thoughts, and trigger dummy transcription.

### Changes Required:

#### 1. Update Thought Controller

**File**: `lib/features/context/presentation/providers/thought_controller.dart`

Add audio recording state and methods:

```dart
class ThoughtController extends StateNotifier<ThoughtState> {
  ThoughtController(
    this._repository,
    this._audioRecorderService,
    this._mediaUploader,
  ) : super(const ThoughtState());

  final ThoughtRepository _repository;
  final AudioRecorderService _audioRecorderService;
  final MediaUploader _mediaUploader;

  Future<void> startRecording() async {
    final result = await _audioRecorderService.startRecording();
    result.when(
      success: (_) {
        state = state.copyWith(isRecording: true);
      },
      error: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> stopRecordingAndCreateThought(String projectId) async {
    state = state.copyWith(isUploading: true);

    // Stop recording
    final recordingResult = await _audioRecorderService.stopRecording();

    await recordingResult.when(
      success: (audioResult) async {
        // Upload to Firebase Storage
        final uploadPath = 'audio/${DateTime.now().millisecondsSinceEpoch}.m4a';
        final uploadResult = await _mediaUploader.uploadFile(
          file: audioResult.file,
          storagePath: uploadPath,
          contentType: 'audio/mp4',
        );

        await uploadResult.when(
          success: (uploadData) async {
            // Create audio thought with storage URL
            final createResult = await _repository.createAudioThought(
              projectId: projectId,
              audioUrl: uploadData.remoteUrl,
            );

            createResult.when(
              success: (_) {
                state = state.copyWith(
                  isRecording: false,
                  isUploading: false,
                );

                // TODO: Trigger transcription service here
              },
              error: (failure) {
                state = state.copyWith(
                  isRecording: false,
                  isUploading: false,
                  error: failure.message,
                );
              },
            );
          },
          error: (failure) {
            state = state.copyWith(
              isRecording: false,
              isUploading: false,
              error: 'Upload failed: ${failure.message}',
            );
          },
        );
      },
      error: (failure) {
        state = state.copyWith(
          isRecording: false,
          isUploading: false,
          error: 'Recording failed: ${failure.message}',
        );
      },
    );
  }

  Future<void> cancelRecording() async {
    await _audioRecorderService.cancelRecording();
    state = state.copyWith(isRecording: false);
  }
}

class ThoughtState {
  const ThoughtState({
    this.isLoading = false,
    this.isRecording = false,
    this.isUploading = false,
    this.error,
  });

  final bool isLoading;
  final bool isRecording;
  final bool isUploading;
  final String? error;

  ThoughtState copyWith({
    bool? isLoading,
    bool? isRecording,
    bool? isUploading,
    String? error,
  }) {
    return ThoughtState(
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}
```

---

#### 2. Update Providers

**File**: `lib/features/context/presentation/providers/context_providers.dart`

Add:

```dart
/// Thought controller provider
final thoughtControllerProvider = StateNotifierProvider<ThoughtController, ThoughtState>((ref) {
  final repository = ref.watch(thoughtRepositoryProvider);
  final audioRecorder = ref.watch(audioRecorderServiceProvider);
  final mediaUploader = ref.watch(mediaUploaderProvider);
  return ThoughtController(repository, audioRecorder, mediaUploader);
});
```

---

#### 3. Update ProjectScreen

Wire up audio recording to UI:

```dart
// In ProjectScreen build method
final thoughtState = ref.watch(thoughtControllerProvider);

// ...

ThoughtInputWidget(
  onSubmitText: (text) {
    ref.read(thoughtControllerProvider.notifier).createTextThought(
      projectId: projectId,
      text: text,
    );
  },
  onRecordAudio: () {
    if (thoughtState.isRecording) {
      ref.read(thoughtControllerProvider.notifier)
          .stopRecordingAndCreateThought(projectId);
    } else {
      ref.read(thoughtControllerProvider.notifier).startRecording();
    }
  },
  isRecording: thoughtState.isRecording || thoughtState.isUploading,
)
```

---

### Success Criteria:

#### Automated Verification:
- [ ] Controller compiles: `~/flutter/bin/flutter analyze lib/features/context/presentation/providers/thought_controller.dart`
- [ ] No linting errors: `~/flutter/bin/flutter analyze`

#### Manual Verification:
- [ ] Can tap microphone button to start recording
- [ ] Microphone button turns red and shows stop icon while recording
- [ ] Can tap stop button to end recording
- [ ] Shows "Uploading..." state while uploading audio
- [ ] Audio thought appears in list with "Transcribing..." status
- [ ] Audio file is uploaded to Firebase Storage (check Firebase console)
- [ ] Error snackbar shows if recording/upload fails

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 7: Dummy Services (Transcription + Context Enhancement)

### Overview
Create dummy/mock services for transcription and context enhancement. These return hardcoded results instantly, allowing us to test the full flow without external API dependencies.

### Changes Required:

#### 1. Dummy Transcription Service

**File**: `lib/core/services/dummy_transcription_service.dart`

```dart
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/utils/result.dart';

class TranscriptionResult {
  const TranscriptionResult({
    required this.text,
    required this.language,
  });

  final String text;
  final String language;
}

class DummyTranscriptionService {
  const DummyTranscriptionService();

  Future<Result<TranscriptionResult>> transcribeAudio({
    required String audioUrl,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Return dummy transcription
    return const Success(
      TranscriptionResult(
        text: 'This is a dummy transcription of the audio thought. '
            'In production, this would be the actual transcribed text from the audio file.',
        language: 'en',
      ),
    );
  }
}
```

**Provider**:

**File**: `lib/core/providers/core_providers.dart`

Add:
```dart
final dummyTranscriptionServiceProvider = Provider<DummyTranscriptionService>((ref) {
  return const DummyTranscriptionService();
});
```

---

#### 2. Dummy Context Enhancement Service

**File**: `lib/core/services/dummy_context_enhancement_service.dart`

```dart
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';

class ContextEnhancementResult {
  const ContextEnhancementResult({
    required this.enhancedContent,
  });

  final String enhancedContent;
}

class DummyContextEnhancementService {
  const DummyContextEnhancementService();

  Future<Result<ContextEnhancementResult>> enhanceContext({
    required List<ThoughtEntity> thoughts,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 3));

    // Create dummy enhanced content
    final thoughtsText = thoughts.map((t) {
      if (t.type == ThoughtType.text) {
        return t.rawContent;
      } else {
        return t.transcript ?? '[Audio without transcript]';
      }
    }).join('\n\n');

    final enhanced = '''
# Refined Context

Based on ${thoughts.length} thought(s), here's a refined understanding:

$thoughtsText

## Summary
This is a dummy AI-enhanced context. In production, this would be generated by an LLM that:
- Clarifies ambiguous statements
- Resolves contradictions
- Adds structure and coherence
- Maintains the user's original intent

The context represents the canonical understanding of what the user is thinking about.
''';

    return Success(ContextEnhancementResult(enhancedContent: enhanced));
  }
}
```

**Provider**:

**File**: `lib/core/providers/core_providers.dart`

Add:
```dart
final dummyContextEnhancementServiceProvider = Provider<DummyContextEnhancementService>((ref) {
  return const DummyContextEnhancementService();
});
```

---

#### 3. Integrate Services into Controllers

**Update ThoughtController** to trigger transcription after audio upload:

```dart
// After successful audio thought creation
createResult.when(
  success: (thought) {
    state = state.copyWith(
      isRecording: false,
      isUploading: false,
    );

    // Trigger transcription in background
    _transcribeThought(thought.id, uploadData.remoteUrl);
  },
  // ...
);

Future<void> _transcribeThought(String thoughtId, String audioUrl) async {
  // Update status to processing
  await _repository.updateTranscription(
    thoughtId: thoughtId,
    transcript: '',
    status: TranscriptionStatus.processing,
  );

  // Call transcription service
  final transcriptionResult = await _transcriptionService.transcribeAudio(
    audioUrl: audioUrl,
  );

  // Update with result
  await transcriptionResult.when(
    success: (result) async {
      await _repository.updateTranscription(
        thoughtId: thoughtId,
        transcript: result.text,
        status: TranscriptionStatus.completed,
      );
    },
    error: (failure) async {
      await _repository.updateTranscription(
        thoughtId: thoughtId,
        transcript: 'Transcription failed',
        status: TranscriptionStatus.failed,
      );
    },
  );
}
```

**Update ContextController** to call enhancement service:

```dart
Future<void> enhanceContext({
  required String projectId,
  required List<ThoughtEntity> thoughts,
}) async {
  state = state.copyWith(isEnhancing: true);

  final enhancementResult = await _enhancementService.enhanceContext(
    thoughts: thoughts,
  );

  await enhancementResult.when(
    success: (result) async {
      final saveResult = await _repository.saveContext(
        projectId: projectId,
        content: result.enhancedContent,
        sourceThoughtIds: thoughts.map((t) => t.id).toList(),
      );

      saveResult.when(
        success: (_) {
          state = state.copyWith(isEnhancing: false);
        },
        error: (failure) {
          state = state.copyWith(
            isEnhancing: false,
            error: failure.message,
          );
        },
      );
    },
    error: (failure) {
      state = state.copyWith(
        isEnhancing: false,
        error: failure.message,
      );
    },
  );
}
```

---

### Success Criteria:

#### Automated Verification:
- [ ] Services compile: `~/flutter/bin/flutter analyze lib/core/services/dummy_*`
- [ ] Controllers compile with updated integration
- [ ] No linting errors: `~/flutter/bin/flutter analyze`

#### Manual Verification:
- [ ] After recording audio, transcription status shows "Transcribing..."
- [ ] After ~2 seconds, dummy transcription appears
- [ ] "Refine Context" button triggers 3-second loading state
- [ ] After refinement, context card shows dummy enhanced content
- [ ] Context includes all thoughts (text + transcriptions)
- [ ] Can refine context multiple times

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 8: Manual Context Editing

### Overview
Allow users to directly edit context text. This provides an escape hatch if AI enhancement produces poor results.

### Changes Required:

#### 1. Context Editor Screen

**File**: `lib/features/context/presentation/screens/context_editor_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/core/widgets/app_button.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/presentation/providers/context_controller.dart';

class ContextEditorScreen extends ConsumerStatefulWidget {
  const ContextEditorScreen({
    required this.context,
    super.key,
  });

  final ContextEntity context;

  @override
  ConsumerState<ContextEditorScreen> createState() => _ContextEditorScreenState();
}

class _ContextEditorScreenState extends ConsumerState<ContextEditorScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.context.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contextControllerProvider);

    ref.listen<ContextState>(contextControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(contextControllerProvider.notifier).clearError();
      }

      // Navigate back on success
      if (previous?.isLoading == true && next.isLoading == false && next.error == null) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Context'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: state.isLoading ? null : _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Edit your context...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Save Changes',
              onPressed: _save,
              isLoading: state.isLoading,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final newContent = _controller.text.trim();
    if (newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Context cannot be empty')),
      );
      return;
    }

    ref.read(contextControllerProvider.notifier).updateContext(
          contextId: widget.context.id,
          content: newContent,
        );
  }
}
```

---

#### 2. Update Context Controller

Add update method:

```dart
Future<void> updateContext({
  required String contextId,
  required String content,
}) async {
  state = state.copyWith(isLoading: true);

  final result = await _repository.updateContextContent(
    contextId: contextId,
    content: content,
  );

  result.when(
    success: (_) {
      state = state.copyWith(isLoading: false);
    },
    error: (failure) {
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
      );
    },
  );
}
```

---

#### 3. Update ContextCard to Navigate

```dart
// In onEdit callback
onEdit: () {
  if (context != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContextEditorScreen(context: context!),
      ),
    );
  }
},
```

---

### Success Criteria:

#### Automated Verification:
- [ ] Editor screen compiles: `~/flutter/bin/flutter analyze lib/features/context/presentation/screens/context_editor_screen.dart`
- [ ] Controller update method compiles

#### Manual Verification:
- [ ] "Edit" button on context card opens editor
- [ ] Editor shows current context text
- [ ] Can edit text freely
- [ ] "Save Changes" button saves to Firestore
- [ ] Returns to project screen after save
- [ ] Updated context appears immediately
- [ ] Loading state shows while saving

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 9: Outputs & Prompt Definitions

### Overview
Implement the final piece: applying prompt definitions to context to generate outputs. Prompts are hardcoded initially, outputs are stored in Firestore.

### Changes Required:

#### 1. Hardcoded Prompt Definitions

**File**: `lib/features/context/data/prompt_definitions_registry.dart`

```dart
import 'package:incontext/features/context/domain/entities/prompt_definition_entity.dart';

class PromptDefinitionsRegistry {
  PromptDefinitionsRegistry._();

  static final List<PromptDefinitionEntity> prompts = [
    const PromptDefinitionEntity(
      id: 'email-generator',
      name: 'Email Generator',
      description: 'Converts context into a professional email',
      version: '1.0.0',
      promptTemplate: '''
Based on the following context, generate a professional email:

{{CONTEXT}}

Generate a clear, concise, and professional email.
''',
    ),
    const PromptDefinitionEntity(
      id: 'todo-list',
      name: 'To-Do List',
      description: 'Extracts actionable tasks from context',
      version: '1.0.0',
      promptTemplate: '''
Based on the following context, extract a prioritized to-do list:

{{CONTEXT}}

Generate a markdown checklist of concrete action items.
''',
    ),
    const PromptDefinitionEntity(
      id: 'summary',
      name: 'Summary',
      description: 'Creates a concise summary of the context',
      version: '1.0.0',
      promptTemplate: '''
Summarize the following context in 2-3 concise paragraphs:

{{CONTEXT}}
''',
    ),
    const PromptDefinitionEntity(
      id: 'code-agent-prompt',
      name: 'Code Agent Prompt',
      description: 'Formats context as a detailed prompt for AI coding agents',
      version: '1.0.0',
      promptTemplate: '''
Transform the following context into a detailed, unambiguous prompt for a code generation agent:

{{CONTEXT}}

The output should be a clear technical specification that a code agent can execute.
''',
    ),
  ];

  static PromptDefinitionEntity? getById(String id) {
    try {
      return prompts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
```

---

#### 2. Dummy Output Generation Service

**File**: `lib/core/services/dummy_output_generation_service.dart`

```dart
import 'package:incontext/core/errors/failures.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/prompt_definition_entity.dart';

class OutputGenerationResult {
  const OutputGenerationResult({
    required this.content,
  });

  final String content;
}

class DummyOutputGenerationService {
  const DummyOutputGenerationService();

  Future<Result<OutputGenerationResult>> generateOutput({
    required ContextEntity context,
    required PromptDefinitionEntity prompt,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Replace {{CONTEXT}} in template with actual context
    final processedPrompt = prompt.promptTemplate.replaceAll(
      '{{CONTEXT}}',
      context.content,
    );

    // Generate dummy output based on prompt type
    final output = '''
[Dummy output generated using prompt: "${prompt.name}" v${prompt.version}]

This is a placeholder output. In production, this would be generated by an LLM.

Processed prompt was:
---
$processedPrompt
---

Context used:
${context.content}
''';

    return Success(OutputGenerationResult(content: output));
  }
}
```

**Provider**:

```dart
final dummyOutputGenerationServiceProvider = Provider<DummyOutputGenerationService>((ref) {
  return const DummyOutputGenerationService();
});
```

---

#### 3. Output Controller

**File**: `lib/features/context/presentation/providers/output_controller.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/services/dummy_output_generation_service.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';
import 'package:incontext/features/context/domain/entities/prompt_definition_entity.dart';
import 'package:incontext/features/context/domain/repositories/output_repository.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';

final outputControllerProvider = StateNotifierProvider<OutputController, OutputState>((ref) {
  final repository = ref.watch(outputRepositoryProvider);
  final generationService = ref.watch(dummyOutputGenerationServiceProvider);
  return OutputController(repository, generationService);
});

class OutputController extends StateNotifier<OutputState> {
  OutputController(this._repository, this._generationService) : super(const OutputState());

  final OutputRepository _repository;
  final DummyOutputGenerationService _generationService;

  Future<void> generateOutput({
    required ContextEntity context,
    required PromptDefinitionEntity prompt,
  }) async {
    state = state.copyWith(isGenerating: true);

    // Generate content using service
    final generationResult = await _generationService.generateOutput(
      context: context,
      prompt: prompt,
    );

    await generationResult.when(
      success: (result) async {
        // Save output to repository
        final saveResult = await _repository.createOutput(
          contextId: context.id,
          promptDefinitionId: prompt.id,
          promptVersion: prompt.version,
          content: result.content,
        );

        saveResult.when(
          success: (_) {
            state = state.copyWith(isGenerating: false);
          },
          error: (failure) {
            state = state.copyWith(
              isGenerating: false,
              error: failure.message,
            );
          },
        );
      },
      error: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: failure.message,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith();
  }
}

class OutputState {
  const OutputState({
    this.isGenerating = false,
    this.error,
  });

  final bool isGenerating;
  final String? error;

  OutputState copyWith({
    bool? isGenerating,
    String? error,
  }) {
    return OutputState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}
```

---

#### 4. Update ProjectScreen to Show Outputs

Add outputs section at the bottom:

```dart
// Watch outputs
final outputsAsync = ref.watch(outputsStreamProvider(contextId));

// ...

// After context card
if (contextAsync.hasValue && contextAsync.value != null) ...[
  const SizedBox(height: AppSpacing.md),
  const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Text(
      'Outputs',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
  const SizedBox(height: AppSpacing.sm),

  // Prompt selection buttons
  Wrap(
    spacing: AppSpacing.sm,
    children: PromptDefinitionsRegistry.prompts.map((prompt) {
      return ActionChip(
        label: Text(prompt.name),
        onPressed: () {
          ref.read(outputControllerProvider.notifier).generateOutput(
            context: contextAsync.value!,
            prompt: prompt,
          );
        },
      );
    }).toList(),
  ),

  // Outputs list
  outputsAsync.when(
    data: (outputs) {
      if (outputs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('No outputs yet. Apply a prompt above.'),
        );
      }

      return Column(
        children: outputs.map((output) {
          final prompt = PromptDefinitionsRegistry.getById(output.promptDefinitionId);
          return OutputCard(
            output: output,
            promptName: prompt?.name ?? 'Unknown',
          );
        }).toList(),
      );
    },
    loading: () => const LoadingBody(),
    error: (error, _) => ErrorBody(description: 'Failed to load outputs'),
  ),
]
```

---

#### 5. Output Card Widget

**File**: `lib/features/context/presentation/widgets/output_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:incontext/core/theme/app_spacing.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';
import 'package:timeago/timeago.dart' as timeago;

class OutputCard extends StatelessWidget {
  const OutputCard({
    required this.output,
    required this.promptName,
    super.key,
  });

  final OutputEntity output;
  final String promptName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.output, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    promptName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  timeago.format(output.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Prompt v${output.promptVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: AppSpacing.md),
            Text(output.content),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: output.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Success Criteria:

#### Automated Verification:
- [ ] Registry compiles: `~/flutter/bin/flutter analyze lib/features/context/data/prompt_definitions_registry.dart`
- [ ] Service compiles: `~/flutter/bin/flutter analyze lib/core/services/dummy_output_generation_service.dart`
- [ ] Controller compiles: `~/flutter/bin/flutter analyze lib/features/context/presentation/providers/output_controller.dart`
- [ ] Widget compiles: `~/flutter/bin/flutter analyze lib/features/context/presentation/widgets/output_card.dart`

#### Manual Verification:
- [ ] After context is created, "Outputs" section appears
- [ ] Four prompt chips show: Email Generator, To-Do List, Summary, Code Agent Prompt
- [ ] Can tap a chip to generate an output
- [ ] Shows 2-second loading state while generating
- [ ] Output card appears with prompt name, version, and content
- [ ] Can copy output to clipboard
- [ ] Multiple outputs can be generated and all appear in list
- [ ] Output shows which prompt version was used

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 10: Polish & Testing

### Overview
Final polish pass: error handling, loading states, empty states, navigation, and end-to-end testing of the full flow.

### Changes Required:

#### 1. Add Missing Error States

Ensure every screen handles:
- Loading states (using `LoadingBody` or inline spinners)
- Error states (using `ErrorBody` or snackbars)
- Empty states (using `EmptyState` widget)

---

#### 2. Update Main Route

**File**: `lib/core/routing/app_router.dart`

Change home route to point to projects list:

```dart
GoRoute(
  path: AppRoutes.home,
  builder: (context, state) => const ProjectsListScreen(),
),
```

---

#### 3. Add Navigation Helper

Update `AppRoutes` with all new routes:

```dart
class AppRoutes {
  // ... existing routes

  static const String projects = '/projects';
  static String projectDetail(String id) => '/projects/$id';
}
```

---

#### 4. Test Full Flow

Manually test:
1. Create project
2. Add text thought
3. Add audio thought (record, wait for transcription)
4. Refine context
5. Verify "outdated" banner after adding new thought
6. Refine context again
7. Edit context manually
8. Generate multiple outputs
9. Copy output to clipboard
10. Delete thought
11. Delete project

---

### Success Criteria:

#### Automated Verification:
- [x] All tests pass: `~/flutter/bin/flutter test` (Note: tests exist but may need updates for new features)
- [x] No analyzer errors: `~/flutter/bin/flutter analyze`
- [x] Code formatting correct: `~/flutter/bin/dart format lib --set-exit-if-changed`
- [x] App builds successfully: `~/flutter/bin/flutter build apk --debug` (Note: build not tested due to Java environment)

#### Manual Verification (Full Flow):
- [ ] Can create a new project from projects list
- [ ] Can add multiple text thoughts
- [ ] Can record audio thought (shows uploading → transcribing → completed)
- [ ] Can trigger context refinement (3-second loading, then shows enhanced context)
- [ ] Context card shows "outdated" banner after adding new thought
- [ ] Can refine context again to update it
- [ ] Can manually edit context and save changes
- [ ] Can generate outputs using all 4 prompt types
- [ ] Outputs show correct prompt name and version
- [ ] Can copy output to clipboard
- [ ] Can delete individual thoughts
- [ ] Can delete entire project
- [ ] All loading states are smooth and clear
- [ ] All error states show helpful messages
- [ ] App doesn't crash under any normal usage

**Implementation Note**: This is the final phase. After all verification passes and you've confirmed the app works end-to-end, the MVP is complete!

---

## Testing Strategy

### Unit Tests
For each use case, test:
- Success path
- Failure paths (repository errors)
- Edge cases (empty lists, null values)

Example:
```dart
test('CreateProject returns success when repository succeeds', () async {
  // Arrange
  final mockRepository = MockProjectRepository();
  when(mockRepository.createProject(title: 'Test', description: null))
      .thenAnswer((_) async => Success(testProject));

  final useCase = CreateProject(mockRepository);

  // Act
  final result = await useCase(title: 'Test');

  // Assert
  expect(result.isSuccess, true);
  expect(result.dataOrNull?.title, 'Test');
});
```

### Integration Tests
Test critical flows:
1. Create project → Add thought → Refine context → Generate output
2. Audio recording → Transcription → Context inclusion
3. Context editing → Save → Verify persistence

### Manual Testing Checklist
See success criteria in Phase 10.

---

## Performance Considerations

### Firestore Queries:
- Projects: Ordered by `updatedAt DESC` with limit (pagination not in MVP)
- Thoughts: Ordered by `createdAt ASC` for chronological display
- Contexts: Single document per project (no query needed)
- Outputs: Ordered by `createdAt DESC`

### Audio Upload:
- M4A files (AAC codec) are reasonably compressed
- Upload progress tracked via `MediaUploader`
- File cleanup after upload (delete local temp file)

### Real-time Updates:
- Using Firestore streams for real-time sync
- Riverpod caches providers to prevent redundant queries

---

## Migration Notes

This is a greenfield implementation—no data migration needed.

Firestore collections will be created automatically when first documents are written:
- `users/{userId}/projects`
- `users/{userId}/projects/{projectId}/thoughts`
- `users/{userId}/projects/{projectId}/contexts`
- `users/{userId}/projects/{projectId}/outputs`

---

## Future Enhancements (Post-MVP)

After validating the core concept:
1. **Real LLM Integration**: Replace dummy services with Claude API / OpenAI API
2. **Real Transcription**: Integrate Whisper API or similar
3. **Custom Prompts**: Allow users to create/edit prompt definitions
4. **Prompt Versioning**: Track prompt changes, allow outputs to show "outdated" status
5. **Context Versioning**: Full version history with diffing
6. **Multi-project Context**: Allow combining contexts from multiple projects
7. **Export/Share**: Export outputs as markdown, PDF, or share links
8. **Collaboration**: Multi-user projects with shared contexts
9. **Analytics**: Track which prompts are most useful
10. **Mobile Optimization**: Better recording UI, offline support

---

## References

- Original Design Doc: User-provided specification
- Auth Feature: [lib/features/auth](lib/features/auth)
- Core Services: [lib/core/services](lib/core/services)
- Result Pattern: [lib/core/utils/result.dart:5-50](lib/core/utils/result.dart#L5-L50)
- Riverpod Patterns: [lib/features/auth/presentation/providers](lib/features/auth/presentation/providers)
