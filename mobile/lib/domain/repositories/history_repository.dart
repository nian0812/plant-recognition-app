import '../entities/recognition_history_item.dart';
import '../entities/recognition_result.dart';

abstract class HistoryRepository {
  Future<List<RecognitionHistoryItem>> getHistory();
  Future<void> addToHistory(RecognitionResult result);
  Future<void> clearHistory();
  Future<void> deleteHistoryItem(String id);
}
