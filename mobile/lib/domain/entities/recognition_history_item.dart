/// A history entry for a past recognition.
class RecognitionHistoryItem {
  final String id;
  final String nameVi;
  final String? scientificName;
  final double confidence;
  final String modelName;
  final String categoryId;
  final DateTime timestamp;
  final String? thumbnailPath;

  const RecognitionHistoryItem({
    required this.id,
    required this.nameVi,
    this.scientificName,
    required this.confidence,
    required this.modelName,
    required this.categoryId,
    required this.timestamp,
    this.thumbnailPath,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(2)}%';
}
