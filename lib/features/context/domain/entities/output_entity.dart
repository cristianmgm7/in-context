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
  String toString() =>
      'OutputEntity(id: $id, promptId: $promptDefinitionId v$promptVersion)';
}
