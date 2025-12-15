// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thought_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThoughtModel _$ThoughtModelFromJson(Map<String, dynamic> json) => ThoughtModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      type: $enumDecode(_$ThoughtTypeEnumMap, json['type']),
      rawContent: json['rawContent'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      transcript: json['transcript'] as String?,
      transcriptionStatus: $enumDecodeNullable(
              _$TranscriptionStatusEnumMap, json['transcriptionStatus']) ??
          TranscriptionStatus.completed,
    );

Map<String, dynamic> _$ThoughtModelToJson(ThoughtModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'type': _$ThoughtTypeEnumMap[instance.type]!,
      'rawContent': instance.rawContent,
      'transcript': instance.transcript,
      'transcriptionStatus':
          _$TranscriptionStatusEnumMap[instance.transcriptionStatus]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ThoughtTypeEnumMap = {
  ThoughtType.text: 'text',
  ThoughtType.audio: 'audio',
};

const _$TranscriptionStatusEnumMap = {
  TranscriptionStatus.pending: 'pending',
  TranscriptionStatus.processing: 'processing',
  TranscriptionStatus.completed: 'completed',
  TranscriptionStatus.failed: 'failed',
};
