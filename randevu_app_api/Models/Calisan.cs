using System.ComponentModel.DataAnnotations;

namespace randevu_app_api.Models
{
    public class Calisan
    {
        public int Id { get; set; }

        public string Ad { get; set; }

        public string Soyad { get; set; }

        public string TC { get; set; }

        public int DukkanId { get; set; }

        public Dukkan Dukkan { get; set; }

        public ICollection<HizmetBedel> HizmetBedeller { get; set; }

    }
}
