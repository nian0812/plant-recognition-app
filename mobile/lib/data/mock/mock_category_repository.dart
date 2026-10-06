import '../../domain/entities/recognition_category.dart';
import '../../domain/repositories/category_repository.dart';

class MockCategoryRepository implements CategoryRepository {
  static const _categories = [
    RecognitionCategory(
      id: 'flowers',
      name: 'Hoa',
      description: '20 - 50 loài',
      emoji: '🌸',
      availableModeIds: [
        'single_image',
        'live_camera',
        'object_detection',
        'segmentation',
      ],
      isAvailable: true,
      statusLabel: 'SẴN SÀNG',
      speciesRangeLabel: '20 - 50 loài',
    ),
    RecognitionCategory(
      id: 'woody_trees',
      name: 'Cây thân gỗ',
      description: 'Cây bóng mát, rừng',
      emoji: '🌳',
      availableModeIds: [],
      isAvailable: false,
      statusLabel: 'SẮP CÓ',
    ),
    RecognitionCategory(
      id: 'fruit_trees',
      name: 'Cây ăn quả',
      description: 'Xoài, cam, bưởi',
      emoji: '🍎',
      availableModeIds: [],
      isAvailable: false,
      statusLabel: 'SẮP CÓ',
    ),
    RecognitionCategory(
      id: 'industrial_plants',
      name: 'Cây công nghiệp',
      description: 'Cà phê, cao su, tiêu',
      emoji: '🌿',
      availableModeIds: [],
      isAvailable: false,
      statusLabel: 'SẮP CÓ',
    ),
    RecognitionCategory(
      id: 'ornamental_plants',
      name: 'Cây cảnh',
      description: 'Cây trang trí nội ngoại thất',
      emoji: '🌵',
      availableModeIds: [],
      isAvailable: false,
      statusLabel: 'SẮP CÓ',
    ),
    RecognitionCategory(
      id: 'medicinal_plants',
      name: 'Cây thuốc / thảo dược',
      description: 'Dược liệu truyền thống',
      emoji: '🌾',
      availableModeIds: [],
      isAvailable: false,
      statusLabel: 'SẮP CÓ',
    ),
    RecognitionCategory(
      id: 'fungi',
      name: 'Nấm tự nhiên',
      description: 'Giới Nấm (Fungi)',
      emoji: '🍄',
      availableModeIds: [],
      isAvailable: false,
      statusLabel: 'SẮP CÓ',
    ),
  ];

  @override
  Future<List<RecognitionCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _categories;
  }

  @override
  Future<RecognitionCategory?> getCategoryById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
