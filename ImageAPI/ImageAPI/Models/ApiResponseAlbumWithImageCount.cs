using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using ImageAPI.Models.Database;

public class ApiResponseAlbumWithImageCount
{
    public string Title { get; set; } = null!;

    public string TimestampCreated { get; set; } = null!;

    public string TimestampLastUpdate { get; set; } = null!;

    public int ImageCount { get; set; }
    public List<string> AlbumPreviewImages { get; set; } = new();
    public int Views { get; set; }

    public ApiResponseAlbumWithImageCount(Album album)
    {
        this.Title = album.Title;
        this.TimestampCreated = album.TimestampCreated;
        this.TimestampLastUpdate = album.TimestampLastUpdate;
        this.ImageCount = album.Images.Count;
        this.AlbumPreviewImages.AddRange(album.Images.GetRandomSubset(5).Select(i => i.Id));
        this.Views = album.Views;
    }
}