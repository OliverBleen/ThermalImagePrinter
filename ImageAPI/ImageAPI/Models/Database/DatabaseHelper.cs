using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SQLitePCL;

namespace ImageAPI.Models.Database;

class DatabaseHelper
{
    #region ApiKey
    public static async Task<bool> ApiKeyExists(Guid apiKey)
    {
        using var _context = new DatabaseContext();
        return await _context.ApiKeys.AnyAsync(k => k.Key == apiKey && k.Active != 0);
    }
    public static async Task<bool> ApiKeyHasAccess(Guid apiKey, string section)
    {
        using var _context = new DatabaseContext();
        var key = await _context.ApiKeys.FirstAsync(k => k.Key == apiKey && k.Active != 0);

        if(key.AccessTo == "*") //Special case for master / testing key
            return true;

        var accessTo = key.AccessTo.Split(";");
        return accessTo.Contains(section);
    }
    #endregion

    #region Album

    public static async Task CreateOrUpdateAlbum(string albumTitle)
    {
        using var _context = new DatabaseContext();

        var existingAlbum = await _context.Albums.FirstOrDefaultAsync(a => a.Title == albumTitle);
        
        if(existingAlbum != null)
        {
            existingAlbum.TimestampLastUpdate = DateTime.UtcNow.ToString("s", System.Globalization.CultureInfo.InvariantCulture);
        }
        else
        {
            await _context.Albums.AddAsync(new Album()
            {
                Title = albumTitle,
                TimestampCreated = DateTime.UtcNow.ToString("s", System.Globalization.CultureInfo.InvariantCulture),
                TimestampLastUpdate = DateTime.UtcNow.ToString("s", System.Globalization.CultureInfo.InvariantCulture),
            });
        }
        await _context.SaveChangesAsync();
    }

    #endregion

    #region Image

    public static async Task CreateImage(Guid imageId, string albumTitle, string contentType)
    {
        using var _context = new DatabaseContext();
        
        if(await _context.Images.AnyAsync(i => i.Id == imageId.ToString()))
            throw new Exception($"Image with ID '{imageId}' already exsists");

        if(!await _context.Albums.AnyAsync(a => a.Title == albumTitle))
            throw new Exception($"No album with title '{albumTitle}' exists");

        await _context.Images.AddAsync(new Image()
        {
            Id = imageId.ToString(),
            AlbumTitle = albumTitle,
            TimestampCreated = DateTime.UtcNow.ToString("s", System.Globalization.CultureInfo.InvariantCulture),
            ContentType = contentType,
        });
        await _context.SaveChangesAsync();
    }

    public static async Task<Image?> GetImageAsync(Guid imageId)
    {
        using var _context = new DatabaseContext();

        return await _context.Images.FirstOrDefaultAsync(i => i.Id == imageId.ToString());
    }

    #endregion
}