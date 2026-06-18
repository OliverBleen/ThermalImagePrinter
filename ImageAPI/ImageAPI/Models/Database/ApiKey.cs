using System;
using System.Collections.Generic;

namespace ImageAPI.Models.Database;

public partial class ApiKey
{
    public Guid Key { get; set; }

    public string AccessTo { get; set; } = null!;

    public int Active { get; set; }

    public string Comment { get; set; } = null!;
}
