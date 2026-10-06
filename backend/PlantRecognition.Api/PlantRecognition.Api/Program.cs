using PlantRecognition.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// AI Services
builder.Services.AddSingleton<
    IPlantRecognitionService,
    PlantRecognitionService
>();

builder.Services.AddSingleton<
    IModelManager,
    ModelManager
>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();