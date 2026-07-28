using System;
using System.Collections.Generic;

namespace ImageAPI.Models.Database;

public partial class Album
{
    public string Title { get; set; } = null!;

    public string TimestampCreated { get; set; } = null!;

    public string TimestampLastUpdate { get; set; } = null!;

    public int Views { get; set; }

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();
}
