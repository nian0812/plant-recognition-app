using Microsoft.AspNetCore.Mvc;
using PlantRecognition.Api.Models.DTOs;
using PlantRecognition.Api.Services;

namespace PlantRecognition.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RecognitionController : ControllerBase
    {
        private readonly IPlantRecognitionService _recognitionService;

        public RecognitionController(
            IPlantRecognitionService recognitionService)
        {
            _recognitionService = recognitionService;
        }

        /// <summary>
        /// Nhận diện hoa bằng model được chọn.
        /// </summary>
        /// <param name="request">Ảnh hoa cần nhận diện.</param>
        /// <param name="modelId">v2 hoặc v4.</param>
        [HttpPost("predict")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Predict(
            [FromForm] RecognitionRequest request,
            [FromQuery] string modelId = "v4")
        {
            if (request.Image == null || request.Image.Length == 0)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Vui lòng chọn một ảnh."
                });
            }

            modelId = modelId.Trim().ToLowerInvariant();

            if (modelId != "v2" && modelId != "v4")
            {
                return BadRequest(new
                {
                    success = false,
                    message = "modelId không hợp lệ. Chỉ hỗ trợ v2 hoặc v4."
                });
            }

            var result = await _recognitionService
                .PredictAsync(request.Image, modelId);

            if (!result.Success)
            {
                return BadRequest(result);
            }

            return Ok(result);
        }
    }
}