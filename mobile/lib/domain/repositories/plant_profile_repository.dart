import '../entities/plant_profile.dart';

abstract class PlantProfileRepository {
  Future<PlantProfile?> getProfileByClassId(int classId);
  Future<PlantProfile?> getProfileByScientificName(String name);
  Future<List<PlantProfile>> searchProfiles(String query);
}
