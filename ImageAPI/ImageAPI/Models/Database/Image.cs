using System;
using System.Collections.Generic;

namespace ImageAPI.Models.Database;

public partial class Image
{
    public string Id { get; set; } = null!;

    public string AlbumTitle { get; set; } = null!;

    public string TimestampCreated { get; set; } = null!;

    public string ContentType { get; set; } = null!;

    public int Views { get; set; }

    public int PreviewLargeViews { get; set; }

    public int PreviewSmallViews { get; set; }

    public virtual Album AlbumTitleNavigation { get; set; } = null!;
}
