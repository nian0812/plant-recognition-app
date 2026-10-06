using PlantRecognition.Api.Models.AI;

namespace PlantRecognition.Api.Services;

public class ModelDefinition
{
    // =========================================================
    // MODEL INFORMATION
    // =========================================================

    public string Id { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string DisplayName { get; set; } = string.Empty;

    public string Architecture { get; set; } = string.Empty;

    public string Version { get; set; } = string.Empty;

    public int ImageSize { get; set; }

    public int ResizeSize { get; set; }

    public int ClassCount { get; set; }

    public string OnnxPath { get; set; } = string.Empty;

    public string MappingPath { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;


    // =========================================================
    // INDEX -> CLASS
    // =========================================================
    // Ví dụ:
    // "0" -> "Anemone_coronaria"
    // "1" -> "Antirrhinum_majus"
    //
    // Dùng để lấy tên class từ output index của ONNX.
    // =========================================================

    public Dictionary<string, string> IndexToClass { get; set; }
        = new();


    // =========================================================
    // CLASS INFORMATION
    // =========================================================
    // Ví dụ:
    // "Anemone_coronaria" ->
    // {
    //     ClassId,
    //     NameVi,
    //     ScientificName
    // }
    // =========================================================

    public Dictionary<string, PlantClass> PlantInformation { get; set; }
        = new();
}