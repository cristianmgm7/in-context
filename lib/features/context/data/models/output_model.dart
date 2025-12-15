import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'output_model.g.dart';

@JsonSerializable()
class OutputModel extends OutputEntity {
  const OutputModel({
    required super.id,
    required super.contextId,
    required super.promptDefinitionId,
    required super.promptVersion,
    required super.content,
    required super.createdAt,
  });

  factory OutputModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OutputModel(
      id: doc.id,
      contextId: data['contextId'] as String,
      promptDefinitionId: data['promptDefinitionId'] as String,
      promptVersion: data['promptVersion'] as String,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  factory OutputModel.fromJson(Map<String, dynamic> json) =>
      _$OutputModelFromJson(json);

  OutputEntity toEntity() {
    return OutputEntity(
      id: id,
      contextId: contextId,
      promptDefinitionId: promptDefinitionId,
      promptVersion: promptVersion,
      content: content,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contextId': contextId,
      'promptDefinitionId': promptDefinitionId,
      'promptVersion': promptVersion,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toJson() => _$OutputModelToJson(this);
}
