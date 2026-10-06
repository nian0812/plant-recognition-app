using System.Text.Json;
using PlantRecognition.Api.Models.AI;
using PlantRecognition.Api.Models.DTOs;

namespace PlantRecognition.Api.Services;

public class ModelManager : IModelManager
{
    private readonly List<ModelDefinition> _models;
    private readonly IWebHostEnvironment _environment;

    public ModelManager(IWebHostEnvironment environment)
    {
        _environment = environment;

        var registryPath = Path.Combine(
            environment.ContentRootPath,
            "Data",
            "model_registry.json"
        );

        if (!File.Exists(registryPath))
        {
            throw new FileNotFoundException(
                "Không tìm thấy model_registry.json.",
                registryPath
            );
        }

        var json = File.ReadAllText(registryPath);

        var registry =
            JsonSerializer.Deserialize<ModelRegistry>(
                json,
                new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                }
            );

        _models = registry?.Models ?? new List<ModelDefinition>();

        if (_models.Count == 0)
        {
            throw new InvalidOperationException(
                "model_registry.json không có model nào."
            );
        }

        // =========================================================
        // LOAD CLASS MAPPING CHO TỪNG MODEL
        // =========================================================

        foreach (var model in _models)
        {
            LoadModelMapping(model);
        }

        Console.WriteLine(
            $"Loaded {_models.Count} AI models."
        );

        foreach (var model in _models)
        {
            Console.WriteLine(
                $"Model: {model.Id} | " +
                $"{model.DisplayName} | " +
                $"{model.ClassCount} classes"
            );
        }
    }

    // =========================================================
    // LOAD MODEL MAPPING
    // =========================================================

    private void LoadModelMapping(ModelDefinition model)
    {
        var mappingPath = Path.IsPathRooted(model.MappingPath)
            ? model.MappingPath
            : Path.Combine(
                _environment.ContentRootPath,
                model.MappingPath
            );

        if (!File.Exists(mappingPath))
        {
            throw new FileNotFoundException(
                $"Không tìm thấy class mapping của model '{model.Id}'.",
                mappingPath
            );
        }

        var json = File.ReadAllText(mappingPath);

        using var document = JsonDocument.Parse(json);

        var root = document.RootElement;

        // Xóa mapping cũ nếu có
        model.IndexToClass.Clear();
        model.PlantInformation.Clear();

        // =========================================================
        // FORMAT 1
        //
        // {
        //   "class_to_idx": {
        //      "Anemone_coronaria": 0,
        //      "Antirrhinum_majus": 1
        //   },
        //   "idx_to_class": {
        //      "0": "Anemone_coronaria",
        //      "1": "Antirrhinum_majus"
        //   }
        // }
        // =========================================================

        if (root.TryGetProperty(
            "idx_to_class",
            out var idxToClass))
        {
            foreach (var item in idxToClass.EnumerateObject())
            {
                var classId = item.Value.GetString();

                if (string.IsNullOrWhiteSpace(classId))
                {
                    continue;
                }

                model.IndexToClass[item.Name] = classId;
            }
        }

        // =========================================================
        // FORMAT 2
        //
        // {
        //   "class_to_idx": {
        //      "Anemone_coronaria": 0,
        //      "Antirrhinum_majus": 1
        //   }
        // }
        //
        // Dùng khi không có idx_to_class
        // =========================================================

        else if (root.TryGetProperty(
            "class_to_idx",
            out var classToIdx))
        {
            foreach (var item in classToIdx.EnumerateObject())
            {
                if (!item.Value.TryGetInt32(
                    out var index))
                {
                    continue;
                }

                model.IndexToClass[index.ToString()] =
                    item.Name;
            }
        }

        // =========================================================
        // FORMAT 3
        //
        // {
        //   "Anemone_coronaria": 0,
        //   "Antirrhinum_majus": 1
        // }
        // =========================================================

        else
        {
            foreach (var item in root.EnumerateObject())
            {
                if (!item.Value.TryGetInt32(
                    out var index))
                {
                    continue;
                }

                model.IndexToClass[index.ToString()] =
                    item.Name;
            }
        }

        // =========================================================
        // LOAD PLANT INFORMATION
        // =========================================================

        foreach (
            var classId in
            model.IndexToClass.Values.Distinct())
        {
            model.PlantInformation[classId] =
                new PlantClass
                {
                    ClassId = classId,
                    NameVi = GetVietnameseName(classId),
                    ScientificName =
                        GetScientificName(classId)
                };
        }

        // =========================================================
        // VALIDATE MAPPING
        // =========================================================

        if (model.IndexToClass.Count != model.ClassCount)
        {
            throw new InvalidOperationException(
                $"Model '{model.Id}' khai báo " +
                $"{model.ClassCount} classes, " +
                $"nhưng mapping chỉ có " +
                $"{model.IndexToClass.Count} classes."
            );
        }

        Console.WriteLine(
            $"Loaded mapping for {model.Id}: " +
            $"{model.IndexToClass.Count} classes."
        );

        // =========================================================
        // TEST INDEX 11
        // =========================================================

        if (model.IndexToClass.TryGetValue(
            "11",
            out var classAt11))
        {
            Console.WriteLine(
                $"Mapping test: index 11 -> {classAt11}"
            );
        }
    }

    // =========================================================
    // GET ALL MODELS
    // =========================================================

    public IReadOnlyList<ModelDefinition> GetModels()
    {
        return _models;
    }

    // =========================================================
    // GET MODEL
    // =========================================================

    public ModelDefinition GetModel(string modelId)
    {
        var model = _models.FirstOrDefault(
            x => x.Id.Equals(
                modelId,
                StringComparison.OrdinalIgnoreCase
            )
        );

        if (model == null)
        {
            throw new KeyNotFoundException(
                $"Không tìm thấy model '{modelId}'."
            );
        }

        return model;
    }

    // =========================================================
    // CHECK MODEL
    // =========================================================

    public bool Exists(string modelId)
    {
        return _models.Any(
            x => x.Id.Equals(
                modelId,
                StringComparison.OrdinalIgnoreCase
            )
        );
    }

    // =========================================================
    // GET CLASSES
    // =========================================================

    public IReadOnlyList<SupportedClassResponse> GetClasses(
        string modelId)
    {
        var model = GetModel(modelId);

        var result =
            model.IndexToClass
                .Select(pair =>
                {
                    var index =
                        int.Parse(pair.Key);

                    var classId =
                        pair.Value;

                    return new SupportedClassResponse
                    {
                        Index = index,
                        ClassId = classId,
                        NameVi =
                            GetVietnameseName(classId),
                        ScientificName =
                            GetScientificName(classId)
                    };
                })
                .OrderBy(x => x.Index)
                .ToList();

        return result;
    }

    // =========================================================
    // VIETNAMESE NAMES
    // =========================================================

    private static string GetVietnameseName(
        string classId)
    {
        var names =
            new Dictionary<string, string>(
                StringComparer.OrdinalIgnoreCase)
            {
                ["Agapanthus_praecox"] =
                    "Hoa huệ châu Phi",

                ["Anemone_coronaria"] =
                    "Hoa hải quỳ",

                ["Antirrhinum_majus"] =
                    "Hoa mõm sói",

                ["Bellis_perennis"] =
                    "Hoa cúc Anh",

                ["Calendula_officinalis"] =
                    "Hoa calendula",

                ["Canna_indica"] =
                    "Hoa dong riềng",

                ["Catharanthus_roseus"] =
                    "Hoa dừa cạn",

                ["Celosia_argentea"] =
                    "Hoa mào gà",

                ["Chrysanthemum_zawadzkii"] =
                    "Hoa cúc",

                ["Cosmos_bipinnatus"] =
                    "Hoa sao nhái",

                ["Crocus_vernus"] =
                    "Hoa Crocus",

                ["Dahlia_coccinea"] =
                    "Hoa thược dược",

                ["Dianthus_chinensis"] =
                    "Hoa cẩm chướng",

                ["Echinacea_purpurea"] =
                    "Hoa Echinacea",

                ["Fuchsia_magellanica"] =
                    "Hoa Fuchsia",

                ["Gardenia_jasminoides"] =
                    "Hoa dành dành",

                ["Gladiolus_italicus"] =
                    "Hoa lay ơn",

                ["Helianthus_annuus"] =
                    "Hoa hướng dương",

                ["Hibiscus_syriacus"] =
                    "Hoa dâm bụt",

                ["Hyacinthus_orientalis"] =
                    "Hoa dạ lan hương",

                ["Hydrangea_macrophylla"] =
                    "Hoa cẩm tú cầu",

                ["Impatiens_walleriana"] =
                    "Hoa ngọc thảo",

                ["Ipomoea_purpurea"] =
                    "Hoa bìm bìm",

                ["Iris_sibirica"] =
                    "Hoa diên vĩ",

                ["Ixora_coccinea"] =
                    "Hoa trang",

                ["Lantana_camara"] =
                    "Hoa ngũ sắc",

                ["Lavandula_stoechas"] =
                    "Hoa oải hương",

                ["Leucanthemum_vulgare"] =
                    "Hoa cúc trắng",

                ["Lilium_lancifolium"] =
                    "Hoa lily hổ",

                ["Magnolia_grandiflora"] =
                    "Hoa mộc lan",

                ["Narcissus_pseudonarcissus"] =
                    "Hoa thủy tiên",

                ["Nelumbo_nucifera"] =
                    "Hoa sen",

                ["Nerium_oleander"] =
                    "Hoa trúc đào",

                ["Paeonia_anomala"] =
                    "Hoa mẫu đơn",

                ["Papaver_rhoeas"] =
                    "Hoa anh túc",

                ["Passiflora_edulis"] =
                    "Hoa chanh dây",

                ["Plumeria_rubra"] =
                    "Hoa sứ",

                ["Portulaca_grandiflora"] =
                    "Hoa mười giờ",

                ["Protea_cynaroides"] =
                    "Hoa Protea",

                ["Rhododendron_maximum"] =
                    "Hoa đỗ quyên",

                ["Rosa_rugosa"] =
                    "Hoa hồng",

                ["Rudbeckia_hirta"] =
                    "Hoa Rudbeckia",

                ["Salvia_coccinea"] =
                    "Hoa xác pháo",

                ["Strelitzia_nicolai"] =
                    "Hoa thiên điểu",

                ["Syringa_vulgaris"] =
                    "Hoa tử đinh hương",

                ["Tagetes_minuta"] =
                    "Hoa vạn thọ",

                ["Tulipa_sylvestris"] =
                    "Hoa tulip",

                ["Wisteria_sinensis"] =
                    "Hoa tử đằng",

                ["Zantedeschia_aethiopica"] =
                    "Hoa rum",

                ["Zinnia_elegans"] =
                    "Hoa zinnia"
            };

        if (names.TryGetValue(
            classId,
            out var name))
        {
            return name;
        }

        return classId.Replace(
            "_",
            " "
        );
    }

    // =========================================================
    // SCIENTIFIC NAME
    // =========================================================

    private static string GetScientificName(
        string classId)
    {
        return classId.Replace(
            "_",
            " "
        );
    }

    // =========================================================
    // REGISTRY
    // =========================================================

    private class ModelRegistry
    {
        public List<ModelDefinition> Models { get; set; }
            = new();
    }
}