// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContextModel _$ContextModelFromJson(Map<String, dynamic> json) => ContextModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      content: json['content'] as String,
      sourceThoughtIds: (json['sourceThoughtIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ContextModelToJson(ContextModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'content': instance.content,
      'sourceThoughtIds': instance.sourceThoughtIds,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
