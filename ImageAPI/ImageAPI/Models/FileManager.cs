using System;
using System.IO;
using System.Threading.Tasks;
using ImageAPI.Models.Database;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace ImageAPI.Models;

static class FileManager
{
    const string preview_postscript = "_prev";
    const string preview_small_postscript = "_prev_sml";

    public static async Task CreateImage(string albumTitle, Guid imageId, IFormFile imageData)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, albumTitle);
        if(!Directory.Exists(albumDir))
            Directory.CreateDirectory(albumDir);

        var imageFilePath = Path.Combine(albumDir, imageId.ToString());

        using var outputStream = File.Create(imageFilePath);

        await imageData.CopyToAsync(outputStream);
    }
    public static async Task CreateImagePreview(string albumTitle, Guid imageId, Stream imageData)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, albumTitle);
        if(!Directory.Exists(albumDir))
            Directory.CreateDirectory(albumDir);

        var imageFilePath = Path.Combine(albumDir, imageId.ToString() + preview_postscript);

        using var outputStream = File.Create(imageFilePath);

        await imageData.CopyToAsync(outputStream);
        imageData.Position = 0;
    }
    public static async Task CreateImagePreviewSmall(string albumTitle, Guid imageId, Stream imageData)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, albumTitle);
        if(!Directory.Exists(albumDir))
            Directory.CreateDirectory(albumDir);

        var imageFilePath = Path.Combine(albumDir, imageId.ToString() + preview_small_postscript);

        using var outputStream = File.Create(imageFilePath);

        await imageData.CopyToAsync(outputStream);
        imageData.Position = 0;
    }

    public static async Task<FileStreamResult?> GetImage(Image img)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, img.AlbumTitle);
        
        if(!Directory.Exists(albumDir))
            return null;

        var imageFilePath = Path.Combine(albumDir, img.Id.ToString());
        
        if(!File.Exists(imageFilePath))
            return null;
        
        return new FileStreamResult(new FileStream(imageFilePath, FileMode.Open), img.ContentType);
    }

    public static async Task<FileStreamResult?> GetImagePreview(Image img)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, img.AlbumTitle);
        
        if(!Directory.Exists(albumDir))
            return null;

        var imageFilePath = Path.Combine(albumDir, img.Id.ToString() + preview_postscript);
        
        if(!File.Exists(imageFilePath))
            return null;
        
        return new FileStreamResult(new FileStream(imageFilePath, FileMode.Open), img.ContentType);
    }
    public static async Task<FileStreamResult?> GetImagePreviewSmall(Image img)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, img.AlbumTitle);
        
        if(!Directory.Exists(albumDir))
            return null;

        var imageFilePath = Path.Combine(albumDir, img.Id.ToString() + preview_small_postscript);
        
        if(!File.Exists(imageFilePath))
            return null;
        
        return new FileStreamResult(new FileStream(imageFilePath, FileMode.Open), img.ContentType);
    }

    public static async Task DeleteImage(Image img)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, img.AlbumTitle);
        
        if(!Directory.Exists(albumDir))
            return;

        var imageFilePath = Path.Combine(albumDir, img.Id.ToString());
        
        if(!File.Exists(imageFilePath))
            return;
        
        File.Delete(imageFilePath);
    }

    public static async Task DeleteAlbum(string albumTitle)
    {
        var albumDir = Path.Combine(Program.BASE_DIR, albumTitle);
        if(!Directory.Exists(albumDir))
            return;

        Directory.Delete(albumDir, true);
    }
}