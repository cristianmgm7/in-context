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
  final String
      description; // e.g., "Converts context into a professional email"
  final String version; // e.g., "1.0.0"
  final String promptTemplate; // The actual prompt text with placeholders

  @override
  List<Object?> get props => [id, name, description, version, promptTemplate];

  @override
  String toString() => 'PromptDefinitionEntity(id: $id, name: $name v$version)';
}
