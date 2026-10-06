enum ModelStatus { ready, downloading, unavailable, comingSoon }

/// AI model info, designed to be compatible with backend ModelInfoResponse
class AIModel {
  final String id; // maps to ModelId
  final String displayName;
  final String architecture;
  final String version;
  final int inputSize;
  final int classCount;
  final bool isDefault;
  final ModelStatus status;
  final List<String> categoryIds;

  const AIModel({
    required this.id,
    required this.displayName,
    required this.architecture,
    required this.version,
    required this.inputSize,
    required this.classCount,
    this.isDefault = false,
    this.status = ModelStatus.ready,
    this.categoryIds = const [],
  });

  String get inputSizeLabel => '$inputSize×$inputSize';
  String get summary => '$architecture • $classCount classes • $inputSizeLabel';
}
