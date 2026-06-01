using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using ImageAPI.Models.Database;

namespace ImageAPI.Authentication;

public class ApiKeyAuthFilter : Attribute, IAsyncAuthorizationFilter
{
    public string? _sectionName;
    /// <summary>
    /// Set an requirement that the request has to be authorized using an API Key
    /// </summary>
    /// <param name="sectionName">The provided API Key has to have access to a section with this name.<br/>
    /// When this is set to '*', any key will be provided access, but requests with no key will be denied</param>
    public ApiKeyAuthFilter(string? sectionName = null)
    {
        _sectionName = sectionName;
    }

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        if(!context.HttpContext.Request.Headers.TryGetValue(AuthConstants.ApiKeyHeaderName, out var extractedApiKey))
        {
            context.Result = new UnauthorizedObjectResult("Missing API Key");   
            return;
        }

        if(!Guid.TryParse(extractedApiKey, out Guid extractedGuid))
        {
            context.Result = new UnauthorizedObjectResult("Invalid API Key format");   
            return;
        }

        if(!await DatabaseHelper.ApiKeyExists(extractedGuid))
        {
            context.Result = new UnauthorizedObjectResult("Invalid API Key");   
            return;
        }

        if(_sectionName == null)
        {
            context.Result = new UnauthorizedObjectResult("PROTECTED SECTION NAME HAS NOT BEEN SET!");   
            return;
        }
        
        if(_sectionName != "*" && !await DatabaseHelper.ApiKeyHasAccess(extractedGuid, _sectionName))
        {
            context.Result = new UnauthorizedObjectResult($"API Key has no access to section '{_sectionName}'");
            return;
        }
    }
}