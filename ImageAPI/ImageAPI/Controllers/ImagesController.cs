using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ImageAPI.Authentication;
using Microsoft.AspNetCore.Http;
using ImageAPI.Models.Database;
using System;
using ImageAPI.Models;

namespace ImageAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ImagesController : ControllerBase
{
    public ImagesController() { }

    [HttpPost("Upload")]
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
}