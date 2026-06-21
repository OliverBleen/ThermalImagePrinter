using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace ImageAPI.Models;

static class FileManager
{
    public static async Task CreateImage(string albumTitle, Guid imageId, IFormFile imageData)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, albumTitle);
        if(!Directory.Exists(albumDir))
            Directory.CreateDirectory(albumDir);

        var imageFilePath = Path.Combine(albumDir, imageId.ToString());

        using var outputStream = File.Create(imageFilePath);

        await imageData.CopyToAsync(outputStream);
    }
}