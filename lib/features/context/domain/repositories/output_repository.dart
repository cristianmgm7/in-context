import 'package:incontext/core/utils/result.dart';
import 'package:incontext/features/context/domain/entities/output_entity.dart';

abstract class OutputRepository {
  /// Stream of all outputs for a context
  Stream<List<OutputEntity>> watchOutputs(String contextId);

  /// Create a new output
  Future<Result<OutputEntity>> createOutput({
    required String contextId,
    required String promptDefinitionId,
    required String promptVersion,
    required String content,
  });

  /// Delete an output
  Future<Result<void>> deleteOutput(String outputId);
}
