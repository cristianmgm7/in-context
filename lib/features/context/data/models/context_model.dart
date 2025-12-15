import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incontext/features/context/domain/entities/context_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'context_model.g.dart';

@JsonSerializable()
class ContextModel extends ContextEntity {
  const ContextModel({
    required super.id,
    required super.projectId,
    required super.content,
    required super.sourceThoughtIds,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ContextModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContextModel(
      id: doc.id,
      projectId: data['projectId'] as String,
      content: data['content'] as String,
      sourceThoughtIds: List<String>.from(data['sourceThoughtIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory ContextModel.fromJson(Map<String, dynamic> json) =>
      _$ContextModelFromJson(json);

  ContextEntity toEntity() {
    return ContextEntity(
      id: id,
      projectId: projectId,
      content: content,
      sourceThoughtIds: sourceThoughtIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'content': content,
      'sourceThoughtIds': sourceThoughtIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toJson() => _$ContextModelToJson(this);
}
