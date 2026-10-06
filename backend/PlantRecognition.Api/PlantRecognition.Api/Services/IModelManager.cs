using PlantRecognition.Api.Models.AI;
using PlantRecognition.Api.Models.DTOs;

namespace PlantRecognition.Api.Services;

public interface IModelManager
{
    IReadOnlyList<ModelDefinition> GetModels();

    ModelDefinition GetModel(string modelId);

    bool Exists(string modelId);

    IReadOnlyList<SupportedClassResponse> GetClasses(string modelId);
}