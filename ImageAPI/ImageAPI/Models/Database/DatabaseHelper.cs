using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace ImageAPI.Models.Database;

class DatabaseHelper
{
    #region ApiKey
    public static async Task<bool> ApiKeyExists(Guid apiKey)
    {
        using var _context = new DatabaseContext();
        return await _context.ApiKeys.AnyAsync(k => k.Key == apiKey && k.Active != 0);
    }
    public static async Task<bool> ApiKeyHasAccess(Guid apiKey, string section)
    {
        using var _context = new DatabaseContext();
        var key = await _context.ApiKeys.FirstAsync(k => k.Key == apiKey && k.Active != 0);

        if(key.AccessTo == "*") //Special case for master / testing key
            return true;

        var accessTo = key.AccessTo.Split(";");
        return accessTo.Contains(section);
    }
    #endregion
}