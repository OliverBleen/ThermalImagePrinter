using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ImageAPI.Authentication;
using Microsoft.AspNetCore.Http;
using ImageAPI.Models.Database;
using System;
using ImageAPI.Models;
using Microsoft.AspNetCore.Http.HttpResults;

namespace ImageAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ImagesController : ControllerBase
{
    public ImagesController() { }

    [HttpPost("Upload/{albumTitle}/{uuid}")]
    [ApiKeyAuthFilter("Upload")]
    public async Task<ActionResult> UploadImage(string albumTitle, string uuid, IFormFile imageData)
    {
        await DatabaseHelper.CreateOrUpdateAlbum(albumTitle);

        if(!Guid.TryParse(uuid, out var imageUuid))
            return BadRequest($"Given Image UUID does not have a valid format: '{uuid}'");

        await DatabaseHelper.CreateImage(imageUuid, albumTitle, imageData.ContentType);

        await FileManager.CreateImage(albumTitle, imageUuid, imageData);

        return Ok();
    }

    [HttpGet("Get/{uuid}")]
    public async Task<ActionResult> GetImage(string uuid)
    {
        if(!Guid.TryParse(uuid, out var imageUuid))
            return BadRequest($"Given Image UUID does not have a valid format: '{uuid}'");

        var img = await DatabaseHelper.GetImageAsync(imageUuid);

        if(img == null)
            return NotFound($"No image with UUID '{uuid}' exists");

        var imgStream = await FileManager.GetImage(img);

        if(imgStream == null)
            return StatusCode(550, "The requested image exists in the Database, but not on disk");

        return imgStream;
    }

    [HttpGet("GetMetadata/{uuid}")]
    [ApiKeyAuthFilter("Get")]
    public async Task<ActionResult<ApiResponseImage>> GetImageMetadata(string uuid)
    {
        if(!Guid.TryParse(uuid, out var imageUuid))
            return BadRequest($"Given Image UUID does not have a valid format: '{uuid}'");

        var img = await DatabaseHelper.GetImageAsync(imageUuid);

        if(img == null)
            return NotFound($"No image with UUID '{uuid}' exists");

        return new ApiResponseImage(img);
    }
}