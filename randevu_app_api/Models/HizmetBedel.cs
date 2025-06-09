using System.ComponentModel.DataAnnotations;

namespace randevu_app_api.Models
{
    public class HizmetBedel
    {
        public int Id { get; set; }
        public int Fiyat { get; set; }
        public int CalisanId { get; set; }
        public int HizmetId { get; set; }
        public Calisan Calisan { get; set; }
        public Hizmet Hizmet { get; set; }
        public ICollection<Randevu> Randevular { get; set; }

        
    }
}
