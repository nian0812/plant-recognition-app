using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using PlantRecognition.Api.Models;
using PlantRecognition.Api.Models.AI;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace PlantRecognition.Api.Services;

public class PlantRecognitionService : IPlantRecognitionService
{
    private readonly IModelManager _modelManager;

    private static readonly float[] Mean =
    {
        0.485f,
        0.456f,
        0.406f
    };

    private static readonly float[] Std =
    {
        0.229f,
        0.224f,
        0.225f
    };

    public PlantRecognitionService(IModelManager modelManager)
    {
        _modelManager = modelManager;
    }

    public async Task<PredictionResult> PredictAsync(
        IFormFile image,
        string modelId)
    {
        if (image == null || image.Length == 0)
        {
            throw new ArgumentException(
                "Ảnh không hợp lệ."
            );
        }

        if (string.IsNullOrWhiteSpace(modelId))
        {
            throw new ArgumentException(
                "ModelId không được để trống."
            );
        }

        var modelInfo =
            _modelManager.GetModel(modelId);

        if (modelInfo == null)
        {
            throw new KeyNotFoundException(
                $"Không tìm thấy model '{modelId}'."
            );
        }

        Console.WriteLine(
            "========================================"
        );

        Console.WriteLine(
            $"PREDICTION MODEL: {modelInfo.Id}"
        );

        Console.WriteLine(
            $"MODEL NAME: {modelInfo.Name}"
        );

        Console.WriteLine(
            $"IMAGE SIZE: {modelInfo.ImageSize}"
        );

        Console.WriteLine(
            $"RESIZE SIZE: {modelInfo.ResizeSize}"
        );

        Console.WriteLine(
            $"CLASS COUNT: {modelInfo.ClassCount}"
        );

        Console.WriteLine(
            "========================================"
        );

        await using var stream =
            image.OpenReadStream();

        using var loadedImage =
            await Image.LoadAsync<Rgb24>(stream);

        // ========================================
        // PREPROCESS
        // ========================================

        using var processedImage =
            PreprocessImage(
                loadedImage,
                modelInfo.ResizeSize,
                modelInfo.ImageSize
            );

        // ========================================
        // CREATE TENSOR
        // ========================================

        var tensor =
            CreateTensor(
                processedImage,
                modelInfo.ImageSize
            );

        // ========================================
        // CREATE ONNX SESSION
        // ========================================

        using var session =
            new InferenceSession(
                modelInfo.OnnxPath
            );

        var inputName =
            session.InputMetadata.Keys.First();

        var inputs =
            new List<NamedOnnxValue>
            {
                NamedOnnxValue.CreateFromTensor(
                    inputName,
                    tensor
                )
            };

        // ========================================
        // INFERENCE
        // ========================================

        using var results =
            session.Run(inputs);

        var output =
            results.First();

        var logits =
            output
                .AsEnumerable<float>()
                .ToArray();

        if (logits.Length != modelInfo.ClassCount)
        {
            throw new InvalidOperationException(
                $"Model '{modelId}' trả về {logits.Length} outputs, " +
                $"nhưng mapping yêu cầu {modelInfo.ClassCount}."
            );
        }

        // ========================================
        // SOFTMAX
        // ========================================

        var probabilities =
            Softmax(logits);

        // ========================================
        // FIND BEST CLASS
        // ========================================

        int predictedIndex = 0;

        for (
            int i = 1;
            i < probabilities.Length;
            i++)
        {
            if (
                probabilities[i] >
                probabilities[predictedIndex]
            )
            {
                predictedIndex = i;
            }
        }

        float confidence =
            probabilities[predictedIndex];

        // ========================================
        // INDEX -> CLASS ID
        // ========================================

        if (
            !modelInfo.IndexToClass.TryGetValue(
                predictedIndex.ToString(),
                out var classId
            )
        )
        {
            throw new KeyNotFoundException(
                $"Không tìm thấy class cho index {predictedIndex}."
            );
        }

        // ========================================
        // CLASS ID -> PLANT INFORMATION
        // ========================================

        PlantClass? plantClass = null;

        if (
            modelInfo.PlantInformation.TryGetValue(
                classId,
                out var info
            )
        )
        {
            plantClass = info;
        }

        Console.WriteLine(
            $"Prediction: {classId}"
        );

        Console.WriteLine(
            $"Confidence: {confidence:P2}"
        );

        Console.WriteLine(
            "========================================"
        );

        // ========================================
        // RESULT
        // ========================================

        return new PredictionResult
        {
            Success = true,

            ClassId = classId,

            NameVi =
                plantClass?.NameVi
                ?? classId,

            ScientificName =
                plantClass?.ScientificName
                ?? classId,

            Confidence = confidence,

            ModelId = modelInfo.Id,

            ModelName = modelInfo.Name
        };
    }

    // ============================================================
    // PREPROCESS
    // ============================================================

    private static Image<Rgb24> PreprocessImage(
        Image<Rgb24> image,
        int resizeSize,
        int imageSize)
    {
        var result =
            image.Clone();

        // --------------------------------------------
        // Resize theo cạnh ngắn
        // --------------------------------------------

        int originalWidth =
            result.Width;

        int originalHeight =
            result.Height;

        float scale =
            resizeSize /
            (float)Math.Min(
                originalWidth,
                originalHeight
            );

        int newWidth =
            Math.Max(
                imageSize,
                (int)Math.Round(
                    originalWidth * scale
                )
            );

        int newHeight =
            Math.Max(
                imageSize,
                (int)Math.Round(
                    originalHeight * scale
                )
            );

        result.Mutate(
            x =>
            {
                x.Resize(
                    newWidth,
                    newHeight
                );
            }
        );

        // --------------------------------------------
        // Center Crop
        // --------------------------------------------

        int cropX =
            Math.Max(
                0,
                (result.Width - imageSize) / 2
            );

        int cropY =
            Math.Max(
                0,
                (result.Height - imageSize) / 2
            );

        result.Mutate(
            x =>
            {
                x.Crop(
                    new Rectangle(
                        cropX,
                        cropY,
                        imageSize,
                        imageSize
                    )
                );
            }
        );

        return result;
    }

    // ============================================================
    // IMAGE -> TENSOR
    // ============================================================

    private static DenseTensor<float> CreateTensor(
        Image<Rgb24> image,
        int imageSize)
    {
        var tensor =
            new DenseTensor<float>(
                new[]
                {
                    1,
                    3,
                    imageSize,
                    imageSize
                }
            );

        for (
            int y = 0;
            y < imageSize;
            y++
        )
        {
            for (
                int x = 0;
                x < imageSize;
                x++
            )
            {
                var pixel =
                    image[x, y];

                float r =
                    pixel.R / 255f;

                float g =
                    pixel.G / 255f;

                float b =
                    pixel.B / 255f;

                tensor[
                    0,
                    0,
                    y,
                    x
                ] =
                    (r - Mean[0]) /
                    Std[0];

                tensor[
                    0,
                    1,
                    y,
                    x
                ] =
                    (g - Mean[1]) /
                    Std[1];

                tensor[
                    0,
                    2,
                    y,
                    x
                ] =
                    (b - Mean[2]) /
                    Std[2];
            }
        }

        return tensor;
    }

    // ============================================================
    // SOFTMAX
    // ============================================================

    private static float[] Softmax(
        float[] logits)
    {
        float max =
            logits.Max();

        var expValues =
            new float[logits.Length];

        double sum = 0;

        for (
            int i = 0;
            i < logits.Length;
            i++
        )
        {
            expValues[i] =
                MathF.Exp(
                    logits[i] - max
                );

            sum +=
                expValues[i];
        }

        for (
            int i = 0;
            i < expValues.Length;
            i++
        )
        {
            expValues[i] =
                (float)(
                    expValues[i] / sum
                );
        }

        return expValues;
    }
}