using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ImageAPI.Authentication;
using Microsoft.AspNetCore.Http;
using ImageAPI.Models.Database;
using System;
using ImageAPI.Models;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.Extensions.Logging;
using ImageMagick;
using System.IO;

namespace ImageAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ImagesController : ControllerBase
{
    private readonly ILogger<ImagesController> _logger;
    public ImagesController(ILogger<ImagesController> logger) { _logger = logger; }

    [HttpPost("Upload/{albumTitle}/{uuid}")]
    [ApiKeyAuthFilter("Upload")]
    public async Task<ActionResult> UploadImage(string albumTitle, string uuid, IFormFile imageData)
    {
        await DatabaseHelper.CreateOrUpdateAlbum(albumTitle);

        if(!Guid.TryParse(uuid, out var imageUuid))
        {
            _logger.LogWarning($"Upload image with malformed UUID: '{uuid}', AlbumTitle: '{albumTitle}'");
            return BadRequest($"Given Image UUID does not have a valid format: '{uuid}'");
        }

        await DatabaseHelper.CreateImage(imageUuid, albumTitle, imageData.ContentType);

        await FileManager.CreateImage(albumTitle, imageUuid, imageData);

        _logger.LogInformation($"Uploaded image '{uuid}', Album: '{albumTitle}'");
        return Ok();
    }

    [HttpGet("Get/{uuid}")]
    public async Task<ActionResult> GetImage(string uuid)
    {
        if(!Guid.TryParse(uuid, out var imageUuid))
        {
            _logger.LogWarning($"Get image with malformed UUID: '{uuid}'");
            return BadRequest($"Given Image UUID does not have a valid format: '{uuid}'");
        }

        var img = await DatabaseHelper.GetImageAsync(imageUuid);

        if(img == null)
        {
            _logger.LogWarning($"Get image not found: '{uuid}'");
            return NotFound($"No image with UUID '{uuid}' exists");
        }

        var imgStream = await FileManager.GetImage(img);

        if(imgStream == null)
        {
            _logger.LogError($"Image in database but not on disk: '{uuid}', Album: '{img.AlbumTitle}'");
            return StatusCode(550, "The requested image exists in the Database, but not on disk");
        }

        _logger.LogInformation($"Serving image '{uuid}'");
        return imgStream;
    }

    [HttpGet("GetPreview/{uuid}")]
    public async Task<ActionResult> GetPreviewImage(string uuid)
    {
        if(!Guid.TryParse(uuid, out var imageUuid))
        {
            _logger.LogWarning($"Get image with malformed UUID: '{uuid}'");
            return BadRequest($"Given Image UUID does not have a valid format: '{uuid}'");
        }

        var img = await DatabaseHelper.GetImageAsync(imageUuid);

        if(img == null)
        {
            _logger.LogWarning($"Get image not found: '{uuid}'");
            return NotFound($"No image with UUID '{uuid}' exists");
        }

        var imgStream = await FileManager.GetImage(img);

        if(imgStream == null)
        {
            _logger.LogError($"Image in database but not on disk: '{uuid}', Album: '{img.AlbumTitle}'");
            return StatusCode(550, "The requested image exists in the Database, but not on disk");
        }

        using var image = new MagickImage(imgStream.FileStream);

        image.Resize(750, 750);
        image.Quality = 60; // Very aggressive, but I don't have that much upload bandwith :'3
        
        var memStream = new MemoryStream();
        await image.WriteAsync(memStream, MagickFormat.Jpeg);
        memStream.Position = 0;

        _logger.LogInformation($"Serving image preview '{uuid}'");
        return new FileStreamResult(memStream, "image/jpeg");
    }

    [HttpGet("GetMetadata/{uuid}")]
    [ApiKeyAuthFilter("Get")]
    public async Task<ActionResult<ApiResponseImage>> GetImageMetadata(string uuid)
    {
        if(!Guid.TryParse(uuid, out var imageUuid))
        {
            _logger.LogWarning($"Get image metadata with malformed UUID: '{uuid}'");
            return BadRequest($"Given Image UUID does not have a valid format: '{uuid}'");
        }

        var img = await DatabaseHelper.GetImageAsync(imageUuid);

        if(img == null)
        {
            _logger.LogWarning($"Get image metadata not found: '{uuid}'");
            return NotFound($"No image with UUID '{uuid}' exists");
        }

        _logger.LogInformation($"Serving image metadata '{uuid}'");
        return new ApiResponseImage(img);
    }


    [HttpDelete("Delete/{uuid}")]
    [ApiKeyAuthFilter("Delete")]
    public async Task<ActionResult> DeleteImage(string uuid)
    {
        if(!Guid.TryParse(uuid, out var imageUuid))
        {
            _logger.LogWarning($"Delete image with malformed UUID: '{uuid}'");
            return BadRequest($"Given Image UUID does not have a valid format: '{uuid}'");
        }

        var img = await DatabaseHelper.GetImageAsync(imageUuid);

        if(img == null)
        {
            _logger.LogWarning($"Delete image not found: '{uuid}'");
            return NotFound($"No image with UUID '{uuid}' exists");
        }

        await FileManager.DeleteImage(img);

        await DatabaseHelper.DeleteImageAsync(imageUuid);

        _logger.LogInformation($"Deleting image '{uuid}'");
        return Ok();
    }
}