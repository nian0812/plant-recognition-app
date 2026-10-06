namespace PlantRecognition.Api.Models;

public class PredictionResult
{
    public bool Success { get; set; }

    public string ClassId { get; set; } = string.Empty;

    public string NameVi { get; set; } = string.Empty;

    public string ScientificName { get; set; } = string.Empty;

    public float Confidence { get; set; }

    public string ModelId { get; set; } = string.Empty;

    public string ModelName { get; set; } = string.Empty;
}