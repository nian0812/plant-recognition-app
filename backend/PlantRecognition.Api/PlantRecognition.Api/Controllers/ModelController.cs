using Microsoft.AspNetCore.Mvc;
using PlantRecognition.Api.Models.AI;
using PlantRecognition.Api.Models.DTOs;
using PlantRecognition.Api.Services;

namespace PlantRecognition.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ModelController : ControllerBase
{
    private readonly IModelManager _modelManager;

    public ModelController(IModelManager modelManager)
    {
        _modelManager = modelManager;
    }

    // =========================================================
    // GET /api/Model
    // Lấy danh sách tất cả model
    // =========================================================
    [HttpGet]
    public ActionResult<IEnumerable<ModelInfoResponse>> GetModels()
    {
        var models = _modelManager
            .GetModels()
            .Select(model => new ModelInfoResponse
            {
                Id = model.Id,
                DisplayName = model.DisplayName,
                Architecture = model.Architecture,
                Version = model.Version,
                ImageSize = model.ImageSize,
                ClassCount = model.ClassCount,
                Status = model.Status
            })
            .ToList();

        return Ok(models);
    }

    // =========================================================
    // GET /api/Model/{modelId}
    // Ví dụ: /api/Model/v4
    // =========================================================
    [HttpGet("{modelId}")]
    public ActionResult<ModelInfoResponse> GetModel(string modelId)
    {
        if (!_modelManager.Exists(modelId))
        {
            return NotFound(new
            {
                success = false,
                message = $"Không tìm thấy model '{modelId}'."
            });
        }

        var model = _modelManager.GetModel(modelId);

        return Ok(new ModelInfoResponse
        {
            Id = model.Id,
            DisplayName = model.DisplayName,
            Architecture = model.Architecture,
            Version = model.Version,
            ImageSize = model.ImageSize,
            ClassCount = model.ClassCount,
            Status = model.Status
        });
    }

    // =========================================================
    // GET /api/Model/{modelId}/classes
    //
    // Ví dụ:
    // /api/Model/v2/classes
    // /api/Model/v4/classes
    // =========================================================
    [HttpGet("{modelId}/classes")]
    public ActionResult<IEnumerable<SupportedClassResponse>> GetClasses(
        string modelId)
    {
        if (!_modelManager.Exists(modelId))
        {
            return NotFound(new
            {
                success = false,
                message = $"Không tìm thấy model '{modelId}'."
            });
        }

        var classes = _modelManager.GetClasses(modelId);

        return Ok(classes);
    }
}