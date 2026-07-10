using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using ImageAPI.Authentication;
using System;
using Microsoft.Extensions.Logging;

namespace ImageAPI.Controllers
{
    [Route("api/")]
    [ApiController]
    public class API : ControllerBase
    {
        private readonly ILogger<API> _logger;
        public API(ILogger<API> logger)
        {
            _logger = logger;
        }


        // GET: version 
        [HttpGet("version")]
        [ApiKeyAuthFilter("*")]
        public string GetAPIVersion()
        {
            // Warning because this is usually not called in production code
            _logger.LogWarning("Serving API Version");
            return Program.API_VERSION;
        }
    }
}
