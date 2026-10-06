using Microsoft.AspNetCore.Http;
using PlantRecognition.Api.Models;

namespace PlantRecognition.Api.Services;

public interface IPlantRecognitionService
{
    Task<PredictionResult> PredictAsync(
        IFormFile image,
        string modelId
    );
}