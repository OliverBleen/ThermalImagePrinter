using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using ImageAPI.Authentication;
using System;

namespace ImageAPI.Controllers
{
    [Route("api/")]
    [ApiController]
    public class API : ControllerBase
    {

        public API()
        {
        }


        // GET: version
        [HttpGet("version")]
        [ApiKeyAuthFilter("*")]
        public string GetAPIVersion()
        {
            return Program.API_VERSION;
        }

        // GET: datetimeUTC
        [HttpGet("datetimeUTC")]
        [ApiKeyAuthFilter("*")]
        public string GetDatetimeUTC()
        {
            return DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture);
        }

        // GET: datetimeLocal
        [HttpGet("datetimeLocal")]
        [ApiKeyAuthFilter("*")]
        public string GetDatetimeLocal()
        {
            return DateTime.Now.ToString("o", CultureInfo.InvariantCulture);
        }
    }
}
