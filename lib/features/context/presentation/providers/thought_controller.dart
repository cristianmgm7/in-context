import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:incontext/core/providers/core_providers.dart';
import 'package:incontext/core/services/audio_recorder_service.dart';
import 'package:incontext/core/services/transcription_service.dart';
import 'package:incontext/core/services/media_uploader.dart';
import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/thought_entity.dart';
import 'package:incontext/features/context/domain/repositories/thought_repository.dart';
import 'package:incontext/features/context/presentation/providers/context_providers.dart';

/// Provider for thought controller
final thoughtControllerProvider =
    StateNotifierProvider<ThoughtController, ThoughtState>((ref) {
  final repository = ref.watch(thoughtRepositoryProvider);
  final audioRecorder = ref.watch(audioRecorderServiceProvider);
  final mediaUploader = ref.watch(mediaUploaderProvider);
  final transcriptionService = ref.watch(transcriptionServiceProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return ThoughtController(
      repository, audioRecorder, mediaUploader, transcriptionService, firebaseAuth);
});

/// Controller for thought operations
class ThoughtController extends StateNotifier<ThoughtState> {
  ThoughtController(
    this._repository,
    this._audioRecorderService,
    this._mediaUploader,
    this._transcriptionService,
    this._firebaseAuth,
  ) : super(const ThoughtState());

  final ThoughtRepository _repository;
  final AudioRecorderService _audioRecorderService;
  final MediaUploader _mediaUploader;
  final TranscriptionService _transcriptionService;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  Future<void> createTextThought({
    required String projectId,
    required String text,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.createTextThought(
      projectId: projectId,
      text: text,
    );

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<void> startRecording() async {
    final result = await _audioRecorderService.startRecording();
    result.when(
      success: (_) {
        state = state.copyWith(isRecording: true);
      },
      error: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  Future<void> stopRecordingAndCreateThought(String projectId) async {
    state = state.copyWith(isUploading: true);

    // Stop recording
    final recordingResult = await _audioRecorderService.stopRecording();

    await recordingResult.when(
      success: (audioResult) async {
        // Upload to Firebase Storage
        final uploadPath = 'audio/$_userId/${DateTime.now().millisecondsSinceEpoch}.m4a';
        final uploadResult = await _mediaUploader.uploadFile(
          file: audioResult.file,
          storagePath: uploadPath,
          contentType: 'audio/mp4',
        );

        await uploadResult.when(
          success: (uploadData) async {
            // Create audio thought with storage URL
            final createResult = await _repository.createAudioThought(
              projectId: projectId,
              audioUrl: uploadData.remoteUrl,
            );

            createResult.when(
              success: (thought) {
                state = state.copyWith(
                  isRecording: false,
                  isUploading: false,
                );

                // Trigger transcription in background
                _transcribeThought(thought.id, uploadData.remoteUrl);
              },
              error: (failure) {
                state = state.copyWith(
                  isRecording: false,
                  isUploading: false,
                  error: failure.message,
                );
              },
            );
          },
          error: (failure) {
            state = state.copyWith(
              isRecording: false,
              isUploading: false,
              error: 'Upload failed: ${failure.message}',
            );
          },
        );
      },
      error: (failure) {
        state = state.copyWith(
          isRecording: false,
          isUploading: false,
          error: 'Recording failed: ${failure.message}',
        );
      },
    );
  }

  Future<void> cancelRecording() async {
    await _audioRecorderService.cancelRecording();
    state = state.copyWith(isRecording: false);
  }

  Future<void> _transcribeThought(String thoughtId, String audioUrl) async {
    // Update status to processing
    await _repository.updateTranscription(
      thoughtId: thoughtId,
      transcript: '',
      status: TranscriptionStatus.processing,
    );

    // Call transcription service
    final transcriptionResult = await _transcriptionService.transcribeAudio(
      audioUrl: audioUrl,
    );

    // Update with result
    await transcriptionResult.when(
      success: (result) async {
        await _repository.updateTranscription(
          thoughtId: thoughtId,
          transcript: result.text,
          status: TranscriptionStatus.completed,
        );
      },
      error: (failure) async {
        await _repository.updateTranscription(
          thoughtId: thoughtId,
          transcript: 'Transcription failed',
          status: TranscriptionStatus.failed,
        );
      },
    );
  }

  Future<void> deleteThought(String thoughtId) async {
    state = state.copyWith(isLoading: true);

    final result = await _repository.deleteThought(thoughtId);

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
      },
      error: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith();
  }
}

/// State for thought operations
class ThoughtState {
  const ThoughtState({
    this.isLoading = false,
    this.isRecording = false,
    this.isUploading = false,
    this.error,
  });

  final bool isLoading;
  final bool isRecording;
  final bool isUploading;
  final String? error;

  ThoughtState copyWith({
    bool? isLoading,
    bool? isRecording,
    bool? isUploading,
    String? error,
  }) {
    return ThoughtState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRecording: isRecording ?? this.isRecording,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}
