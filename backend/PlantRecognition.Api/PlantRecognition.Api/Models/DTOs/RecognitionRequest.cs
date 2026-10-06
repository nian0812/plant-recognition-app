using Microsoft.AspNetCore.Http;

namespace PlantRecognition.Api.Models.DTOs;

public class RecognitionRequest
{
    public IFormFile Image { get; set; } = null!;
}