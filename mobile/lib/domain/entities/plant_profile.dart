/// Biological profile of a plant species.
class PlantProfile {
  final String id;
  final String nameVi;
  final String? nameEn;
  final String? scientificName;
  final String? family;
  final String? familyVi;
  final String? genus;
  final String? description;
  final List<String>? characteristics;
  final String? distribution;
  final String? uses;
  final String? notes;
  final String? imageUrl;
  final String? categoryId;

  const PlantProfile({
    required this.id,
    required this.nameVi,
    this.nameEn,
    this.scientificName,
    this.family,
    this.familyVi,
    this.genus,
    this.description,
    this.characteristics,
    this.distribution,
    this.uses,
    this.notes,
    this.imageUrl,
    this.categoryId,
  });
}
