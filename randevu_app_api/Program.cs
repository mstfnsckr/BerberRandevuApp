using randevu_app_api.Data;
using randevu_app_api.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using aceta_app_api.Data;

var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ApplicationName = typeof(Program).Assembly.FullName,
    ContentRootPath = Directory.GetCurrentDirectory(),
    EnvironmentName = Environments.Development,
    WebRootPath = "wwwroot"
});

// Uygulamanın dinleyeceği URL'ler
builder.WebHost.UseUrls("http://localhost:5242", "https://localhost:7128");

// DbContext ayarları
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// CORS ayarları
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Controller'lar
builder.Services.AddControllers();

// Swagger ayarları
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Randevu App API",
        Version = "v1",
        Description = "Randevu App API dokümantasyonu"
    });
});

var app = builder.Build();

// Middleware'ler
app.UseRouting();
app.UseCors("AllowAll");

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Randevu App API v1");
    });
}

app.UseHttpsRedirection();
app.UseAuthorization();

app.UseEndpoints(endpoints =>
{
    endpoints.MapControllers();
});
// Diğer tüm middleware ve endpoint tanımlarından sonra gelmeli
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

    if (!context.Hizmetler.Any())
    {
        // Taşıma Sistemleri
        foreach (var ad in HizmetTurleri.Hizmetler)
        {
            var hizmet = new Hizmet { Ad = ad };
            context.Hizmetler.Add(hizmet);
        }
        context.SaveChanges();
    }
}
app.Run();
