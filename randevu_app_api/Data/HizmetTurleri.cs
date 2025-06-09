using randevu_app_api.Models;
using randevu_app_api.Data;
using Microsoft.EntityFrameworkCore;

namespace aceta_app_api.Data
{
    public static class HizmetTurleri
    {
        public static readonly List<string> Hizmetler = new()
        {
            "Saç", "Sakal", "Kaş"
        };
    }
}