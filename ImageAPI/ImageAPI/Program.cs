using System;
using System.Linq;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.OpenApi.Models;
using ImageAPI.Authentication;
using System.Collections.Generic;
using Microsoft.Extensions.Logging;

namespace ImageAPI;

public class Program
{
    public static readonly string API_VERSION = "v1.6.3";
    // => optionsBuilder.UseSqlite($"Filename={Path.Combine(Program.BASE_DIR, "Database.sqlite3")}");
    public static string BASE_DIR = "./bin/Debug/";

    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add services to the container.
        // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
        builder.Services.AddControllers();
        // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen(s =>
        {
            s.SwaggerDoc("v1", new OpenApiInfo
            {
                Title = "PrivAPI",
                Version = API_VERSION,
            });
            s.AddSecurityDefinition("ApiKey", new OpenApiSecurityScheme
            {
                Description = "The Api Key to Authenticate",
                Type = SecuritySchemeType.ApiKey,
                Name = AuthConstants.ApiKeyHeaderName,
                In = ParameterLocation.Header,
                Scheme = "ApiKeyScheme"
            });
            var scheme = new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "ApiKey"
                },
                In = ParameterLocation.Header
            };
            var requirement = new OpenApiSecurityRequirement
            {
                { scheme, new List<string>() }
            };
            s.AddSecurityRequirement(requirement);
        });


        builder.Logging.ClearProviders();
        builder.Logging.AddConsole();

        builder.Services.AddScoped<ApiKeyAuthFilter>();

        var app = builder.Build();

        // Configure the HTTP request pipeline.
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }
        if(app.Environment.IsProduction())
        {
            BASE_DIR = "/data/";
        }

        app.UseHttpsRedirection();

        app.UseAuthorization();

        app.MapControllers();

        app.Logger.LogInformation($"ImageAPI {API_VERSION}");
        app.Logger.LogInformation($"BASE_DIR: '{BASE_DIR}'");
        ApiKeyAuthFilter.Logger = app.Logger;
        app.Run();
    }
    record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
    {
        public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
    }
}