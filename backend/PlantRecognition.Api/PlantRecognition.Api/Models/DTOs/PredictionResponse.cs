using Microsoft.AspNetCore.Mvc;

namespace PlantRecognition.Api.Models.DTOs
{
    public class PredictionResponse : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
