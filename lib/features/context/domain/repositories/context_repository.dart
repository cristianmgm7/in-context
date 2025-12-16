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
