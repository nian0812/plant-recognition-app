using Microsoft.AspNetCore.Mvc;

namespace PlantRecognition.Api.Models.DTOs
{
    public class PredictRequest : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
