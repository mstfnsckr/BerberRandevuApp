using System.ComponentModel.DataAnnotations;

namespace randevu_app_api.Models
{
    public class Hizmet
    {
        public int Id { get; set; }
        public string Ad { get; set; }
        public ICollection<HizmetBedel> HizmetBedeller { get; set; }

    }
}
