enum RecognitionModeType {
  singleImage,
  liveCamera,
  objectDetection,
  segmentation,
}

/// Recognition mode (single image, live, detection, segmentation)
class RecognitionMode {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final RecognitionModeType type;
  final bool isAvailable;
  final String? statusLabel;
  final String? supportInfo; // e.g., 'Hỗ trợ: V2 (50 loài), V4 (20 loài)'

  const RecognitionMode({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.type,
    this.isAvailable = true,
    this.statusLabel,
    this.supportInfo,
  });
}
