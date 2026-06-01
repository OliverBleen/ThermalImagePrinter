using System;
using System.Collections.Generic;

namespace ImageAPI.Models.Database;

public partial class ApiKey
{
    public string Key { get; set; } = null!;

    public string AccessTo { get; set; } = null!;

    public int Active { get; set; }

    public string Comment { get; set; } = null!;
}
