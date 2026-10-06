import '../../domain/entities/plant_profile.dart';
import '../../domain/repositories/plant_profile_repository.dart';

class MockPlantProfileRepository implements PlantProfileRepository {
  final Map<int, PlantProfile> _profiles = {
    0: const PlantProfile(
      id: '0',
      nameVi: 'Hoa Hướng Dương',
      nameEn: 'Sunflower',
      scientificName: 'Helianthus annuus',
      family: 'Asteraceae',
      familyVi: 'Họ Cúc',
      genus: 'Helianthus',
      description:
          'Hoa hướng dương là loài thực vật thuộc họ Cúc, có nguồn gốc từ châu Mỹ. Đặc điểm nổi bật nhất là những bông hoa lớn, có màu vàng rực rỡ và luôn hướng về phía mặt trời.',
      characteristics: [
        'Thân cao từ 1-3 mét, lá to mọc so le.',
        'Bông hoa thực chất là một cụm hoa lớn bao gồm hàng ngàn bông hoa nhỏ.',
        'Có đặc tính hướng nhật quang (luôn quay theo hướng mặt trời khi còn non).',
      ],
      distribution:
          'Được trồng phổ biến trên toàn thế giới, thích hợp với khí hậu ấm áp và nhiều ánh sáng.',
      uses:
          'Trồng làm cảnh, lấy hạt để ăn hoặc ép dầu thực vật giàu dinh dưỡng.',
      notes:
          'Hạt hướng dương giàu vitamin E và chất chống oxy hóa tốt cho tim mạch.',
      imageUrl: 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651',
      categoryId: 'flowers',
    ),
    1: const PlantProfile(
      id: '1',
      nameVi: 'Hoa Hồng',
      nameEn: 'Rose',
      scientificName: 'Rosa',
      family: 'Rosaceae',
      familyVi: 'Họ Hoa hồng',
      genus: 'Rosa',
      description:
          'Hoa hồng là tên gọi chung cho các loài thực vật dạng cây bụi hoặc cây leo thuộc chi Rosa. Chúng nổi tiếng với vẻ đẹp và hương thơm quyến rũ.',
      characteristics: [
        'Thân cây thường có gai nhọn bảo vệ.',
        'Lá mọc kép hình lông chim, viền lá có răng cưa nhỏ.',
        'Hoa có nhiều lớp cánh mềm mại xếp xen kẽ, màu sắc phong phú.',
      ],
      distribution:
          'Phân bố rộng khắp từ vùng ôn đới đến cận nhiệt đới và nhiệt đới.',
      uses:
          'Trang trí cảnh quan, quà tặng ý nghĩa, chiết xuất tinh dầu nước hoa cao cấp và pha trà thảo mộc.',
      notes: 'Cần nhiều ánh sáng mặt trời và đất thoát nước tốt để hoa nở to, thơm.',
      imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23',
      categoryId: 'flowers',
    ),
    2: const PlantProfile(
      id: '2',
      nameVi: 'Hoa Lan',
      nameEn: 'Orchid',
      scientificName: 'Orchidaceae',
      family: 'Orchidaceae',
      familyVi: 'Họ Lan',
      genus: 'Dendrobium / Phalaenopsis',
      description:
          'Hoa lan là một trong những họ thực vật đa dạng và phong phú bậc nhất hành tinh với hàng chục ngàn loài và giống lai.',
      characteristics: [
        'Cấu tạo hoa đặc trưng với 3 cánh đài, 3 cánh hoa (1 cánh biến đổi thành cánh môi).',
        'Phần lớn là thực vật phụ sinh (sống bám trên cây khác nhưng không ký sinh).',
        'Rễ có màng xốp dày giúp hút nước và chất dinh dưỡng từ không khí.',
      ],
      distribution:
          'Có mặt ở hầu hết các châu lục, tập trung phong phú nhất tại các khu rừng nhiệt đới ẩm ướt.',
      uses: 'Cây cảnh cao cấp, biểu tượng của sự thanh cao, sang trọng và quý phái.',
      notes: 'Thích hợp nơi thoáng khí, ánh sáng tán xạ, độ ẩm cao nhưng tránh ứ đọng nước ở gốc.',
      imageUrl: 'https://images.unsplash.com/photo-1525310072745-f49212b5ac6d',
      categoryId: 'flowers',
    ),
    3: const PlantProfile(
      id: '3',
      nameVi: 'Hoa Cúc Vàng',
      nameEn: 'Chrysanthemum',
      scientificName: 'Chrysanthemum morifolium',
      family: 'Asteraceae',
      familyVi: 'Họ Cúc',
      genus: 'Chrysanthemum',
      description:
          'Hoa cúc là một chi thực vật có hoa trong họ Cúc, có lịch sử thuần hóa và trồng trọt hàng ngàn năm tại châu Á.',
      characteristics: [
        'Cây thân thảo, phân nhánh nhiều tạo thành bụi rậm.',
        'Cụm hoa dạng đầu gồm nhiều hoa hình lưỡi xếp xung quanh hoa hình ống.',
        'Lá xẻ thùy sâu, có mùi thơm thảo mộc đặc trưng khi vò nát.',
      ],
      distribution: 'Phổ biến khắp châu Á và châu Âu, được trồng quanh năm tại Việt Nam.',
      uses:
          'Trang trí ngày lễ Tết truyền thống, chế biến trà hoa cúc thanh nhiệt giải độc cơ thể.',
      notes: 'Trà cúc có tác dụng an thần nhẹ, hỗ trợ giấc ngủ và làm dịu mắt.',
      imageUrl: 'https://images.unsplash.com/photo-1606041008023-472dfb5e530f',
      categoryId: 'flowers',
    ),
    4: const PlantProfile(
      id: '4',
      nameVi: 'Hoa Sen',
      nameEn: 'Lotus',
      scientificName: 'Nelumbo nucifera',
      family: 'Nelumbonaceae',
      familyVi: 'Họ Sen',
      genus: 'Nelumbo',
      description:
          'Hoa sen là loài thực vật thủy sinh nổi tiếng, quốc hoa biểu trưng của Việt Nam thể hiện sự thuần khiết, thanh cao và bất khuất.',
      characteristics: [
        'Thân rễ (ngó sen) chìm dưới bùn đáy ao hồ.',
        'Lá tròn vươn cao khỏi mặt nước, bề mặt lá có hiệu ứng nano trượt nước kỳ diệu.',
        'Hoa to, hương thơm thanh khiết, màu hồng hoặc trắng thanh nhã.',
      ],
      distribution: 'Vùng nhiệt đới và cận nhiệt đới châu Á, châu Úc.',
      uses:
          'Mọi bộ phận đều hữu ích: hoa trang trí, hạt sen nấu chè, củ sen làm món ăn bổ dưỡng, lá sen gói xôi hoặc ướp trà.',
      notes: 'Tâm sen có vị đắng, có dược tính an thần và hạ huyết áp tốt.',
      imageUrl: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9',
      categoryId: 'flowers',
    ),
  };

  @override
  Future<PlantProfile?> getProfileByClassId(int classId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _profiles[classId] ?? _profiles[0]; // Fallback to 0 for demo
  }

  @override
  Future<PlantProfile?> getProfileByScientificName(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _profiles.values.firstWhere(
        (p) => p.scientificName?.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PlantProfile>> searchProfiles(String query) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final q = query.toLowerCase();
    return _profiles.values.where((p) {
      return p.nameVi.toLowerCase().contains(q) ||
          (p.scientificName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}
