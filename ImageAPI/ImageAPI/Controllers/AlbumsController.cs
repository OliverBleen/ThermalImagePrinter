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

namespace ImageAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AlbumsController : ControllerBase
{
    public AlbumsController() { }

    [HttpGet("Get/{albumName}")]
    [ApiKeyAuthFilter("Get")]
    public async Task<ActionResult<ApiResponseAlbum>> GetAlbum(string albumName)
    {
        var album = await DatabaseHelper.GetAlbumAsync(albumName);

        if(album == null)
            return NotFound($"No album with name '{albumName}' exists");

        return album;
    }

    [HttpGet("GetAll")]
    [ApiKeyAuthFilter("Get")]
    public async Task<ActionResult<List<ApiResponseAlbumWithImageCount>>> GetAllAlbums()
    {
        var albums = await DatabaseHelper.GetAllAlbumsAsync();

        return albums.Select(a => new ApiResponseAlbumWithImageCount(a)).ToList();
    }
}