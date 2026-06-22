using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using ImageAPI.Models.Database;

public class ApiResponseAlbum
{
    public string Title { get; set; } = null!;

    public string TimestampCreated { get; set; } = null!;

    public string TimestampLastUpdate { get; set; } = null!;

    public virtual List<ApiResponseImage> Images { get; set; } = new List<ApiResponseImage>();

    public ApiResponseAlbum(Album album)
    {
        this.Title = album.Title;
        this.TimestampCreated = album.TimestampCreated;
        this.TimestampLastUpdate = album.TimestampLastUpdate;
        this.Images = [.. album.Images.OrderByDescending(i => i.TimestampCreated).Select(i => new ApiResponseImage(i))];
    }
}