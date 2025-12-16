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
