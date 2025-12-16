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
  final List<String>
      sourceThoughtIds; // Which thoughts were used to generate this
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
