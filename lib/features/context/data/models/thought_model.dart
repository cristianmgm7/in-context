import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'thought_model.g.dart';

@JsonSerializable()
class ThoughtModel extends ThoughtEntity {
  const ThoughtModel({
    required super.id,
    required super.projectId,
    required super.type,
    required super.rawContent,
    required super.createdAt,
    super.transcript,
    super.transcriptionStatus,
  });

  factory ThoughtModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ThoughtModel(
      id: doc.id,
      projectId: data['projectId'] as String,
      type: ThoughtType.values[data['type'] as int],
      rawContent: data['rawContent'] as String,
      transcript: data['transcript'] as String?,
      transcriptionStatus: TranscriptionStatus.values[
          data['transcriptionStatus'] as int? ?? 2], // Default to completed
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  factory ThoughtModel.fromJson(Map<String, dynamic> json) =>
      _$ThoughtModelFromJson(json);

  ThoughtEntity toEntity() {
    return ThoughtEntity(
      id: id,
      projectId: projectId,
      type: type,
      rawContent: rawContent,
      transcript: transcript,
      transcriptionStatus: transcriptionStatus,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'type': type.index,
      'rawContent': rawContent,
      'transcript': transcript,
      'transcriptionStatus': transcriptionStatus.index,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toJson() => _$ThoughtModelToJson(this);
}
