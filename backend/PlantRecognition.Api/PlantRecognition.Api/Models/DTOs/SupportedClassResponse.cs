namespace PlantRecognition.Api.Models.DTOs;

public class SupportedClassResponse
{
    public int Index { get; set; }

    public string ClassId { get; set; } = "";

    public string NameVi { get; set; } = "";

    public string ScientificName { get; set; } = "";
}