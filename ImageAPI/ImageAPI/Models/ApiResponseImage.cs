using ImageAPI.Models.Database;

public partial class ApiResponseImage
{
    public string Id { get; set; } = null!;

    public string AlbumTitle { get; set; } = null!;

    public string TimestampCreated { get; set; } = null!;

    public string ContentType { get; set; } = null!;

    public ApiResponseImage(Image image)
    {
        this.Id = image.Id;
        this.AlbumTitle = image.AlbumTitle;
        this.TimestampCreated = image.TimestampCreated;
        this.ContentType = image.ContentType;
    }
}
