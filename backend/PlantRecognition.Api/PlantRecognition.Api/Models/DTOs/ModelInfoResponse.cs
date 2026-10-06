namespace PlantRecognition.Api.Models.DTOs;

public class ModelInfoResponse
{
    public string Id { get; set; } = "";

    public string DisplayName { get; set; } = "";

    public string Architecture { get; set; } = "";

    public string Version { get; set; } = "";

    public int ImageSize { get; set; }

    public int ClassCount { get; set; }

    public string Status { get; set; } = "";
}