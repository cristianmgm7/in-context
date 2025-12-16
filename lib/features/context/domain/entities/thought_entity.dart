import 'package:equatable/equatable.dart';

enum ThoughtType { text, audio }

enum TranscriptionStatus { pending, processing, completed, failed }

class ThoughtEntity extends Equatable {
  const ThoughtEntity({
    required this.id,
    required this.projectId,
    required this.type,
    required this.rawContent,
    required this.createdAt,
    this.transcript,
    this.transcriptionStatus = TranscriptionStatus.completed,
  });

  final String id;
  final String projectId;
  final ThoughtType type;
  final String
      rawContent; // For text: the text itself. For audio: Firebase Storage URL
  final String? transcript; // Only for audio thoughts
  final TranscriptionStatus transcriptionStatus;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        projectId,
        type,
        rawContent,
        transcript,
        transcriptionStatus,
        createdAt,
      ];

  @override
  String toString() =>
      'ThoughtEntity(id: $id, type: $type, createdAt: $createdAt)';
}
