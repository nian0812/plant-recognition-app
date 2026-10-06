import 'package:uuid/uuid.dart';
import '../../domain/entities/recognition_history_item.dart';
import '../../domain/entities/recognition_result.dart';
import '../../domain/repositories/history_repository.dart';

class MockHistoryRepository implements HistoryRepository {
  final List<RecognitionHistoryItem> _items = [
    RecognitionHistoryItem(
      id: '1',
      nameVi: 'Hoa Hướng Dương',
      scientificName: 'Helianthus annuus',
      confidence: 0.9421,
      modelName: 'Flower Recognition V4',
      categoryId: 'flowers',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      thumbnailPath: null,
    ),
    RecognitionHistoryItem(
      id: '2',
      nameVi: 'Hoa Hồng',
      scientificName: 'Rosa',
      confidence: 0.8950,
      modelName: 'Flower Recognition V4',
      categoryId: 'flowers',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      thumbnailPath: null,
    ),
    RecognitionHistoryItem(
      id: '3',
      nameVi: 'Hoa Sen',
      scientificName: 'Nelumbo nucifera',
      confidence: 0.9610,
      modelName: 'Flower Recognition V2',
      categoryId: 'flowers',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      thumbnailPath: null,
    ),
  ];

  @override
  Future<List<RecognitionHistoryItem>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> addToHistory(RecognitionResult result) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _items.insert(
      0,
      RecognitionHistoryItem(
        id: const Uuid().v4(),
        nameVi: result.nameVi,
        scientificName: result.scientificName,
        confidence: result.confidence,
        modelName: result.modelName,
        categoryId: 'flowers',
        timestamp: result.timestamp,
        thumbnailPath: result.imagePath,
      ),
    );
  }

  @override
  Future<void> deleteHistoryItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clearHistory() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _items.clear();
  }
}
