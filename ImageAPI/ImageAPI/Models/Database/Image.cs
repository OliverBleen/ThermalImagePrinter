using System;
using System.Collections.Generic;

namespace ImageAPI.Models.Database;

public partial class Image
{
    public string Id { get; set; } = null!;

    public string AlbumTitle { get; set; } = null!;

    public string TimestampCreated { get; set; } = null!;

    public string ContentType { get; set; } = null!;

    public virtual Album AlbumTitleNavigation { get; set; } = null!;
}
