/// Represents a category of organisms (flowers, trees, fruits, etc.)
class RecognitionCategory {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final List<String> availableModeIds;
  final bool isAvailable;
  final String? statusLabel; // 'SẴN SÀNG', 'SẮP CÓ', etc.
  final int? speciesRange; // e.g., '20-50' displayed as range
  final String? speciesRangeLabel;

  const RecognitionCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.availableModeIds,
    this.isAvailable = false,
    this.statusLabel,
    this.speciesRange,
    this.speciesRangeLabel,
  });
}
