import '../../domain/entities/recognition_mode.dart';
import '../../domain/repositories/mode_repository.dart';

class MockModeRepository implements ModeRepository {
  final List<RecognitionMode> _modes = const [
    RecognitionMode(
      id: 'single_image',
      name: 'Ảnh đơn (Single Image)',
      emoji: '📷',
      type: RecognitionModeType.singleImage,
      isAvailable: true,
      description: 'Chụp hoặc chọn 1 ảnh từ thư viện máy.',
      supportInfo: 'Hỗ trợ: V2 (50 loài), V4 (20 loài)',
    ),
    RecognitionMode(
      id: 'live_camera',
      name: 'Nhận dạng trực tiếp (Live)',
      emoji: '👁',
      type: RecognitionModeType.liveCamera,
      isAvailable: true,
      description: 'Quét liên tục qua camera không cần chụp.',
      supportInfo: 'On-Device Throttled • 30 FPS',
    ),
    RecognitionMode(
      id: 'object_detection',
      name: 'Quét đối tượng (Detection)',
      emoji: '⬡',
      type: RecognitionModeType.objectDetection,
      isAvailable: false,
      statusLabel: 'ĐANG HUẤN LUYỆN MODEL',
      description: 'Tìm và vẽ khung vị trí các hoa trong ảnh.',
    ),
    RecognitionMode(
      id: 'segmentation',
      name: 'Phân vùng (Segmentation)',
      emoji: '◉',
      type: RecognitionModeType.segmentation,
      isAvailable: false,
      statusLabel: 'GIAI ĐOẠN NGHIÊN CỨU',
      description: 'Tách chính xác từng viền cánh hoa và lá.',
    ),
  ];

  @override
  Future<List<RecognitionMode>> getModes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _modes;
  }

  @override
  Future<List<RecognitionMode>> getModesForCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (categoryId == 'flowers') {
      return _modes;
    }
    return [];
  }
}
