using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ImageAPI.Authentication;
using Microsoft.AspNetCore.Http;
using ImageAPI.Models.Database;
using System;
using ImageAPI.Models;
using Microsoft.AspNetCore.Http.HttpResults;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Extensions.Logging;

namespace ImageAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AlbumsController : ControllerBase
{
    private readonly ILogger<AlbumsController> _logger;
    public AlbumsController(ILogger<AlbumsController> logger) { _logger = logger; }

    [HttpGet("Get/{albumName}")]
    [ApiKeyAuthFilter("Get")]
    public async Task<ActionResult<ApiResponseAlbum>> GetAlbum(string albumName)
    {
        var album = await DatabaseHelper.GetAlbumAsync(albumName);

        if(album == null)
        {
            _logger.LogWarning($"Requested album '{albumName}' does not exist");
            return NotFound($"No album with name '{albumName}' exists");
        }
        
        _logger.LogInformation($"Serving album '{albumName}'");
        return album;
    }

    [HttpGet("GetAll")]
    [ApiKeyAuthFilter("Get")]
    public async Task<ActionResult<List<ApiResponseAlbumWithImageCount>>> GetAllAlbums()
    {
        var albums = await DatabaseHelper.GetAllAlbumsAsync();
        
        _logger.LogInformation($"Serving all albums");
        return albums.Select(a => new ApiResponseAlbumWithImageCount(a)).ToList();
    }
}