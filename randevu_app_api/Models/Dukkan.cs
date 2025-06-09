using System.ComponentModel.DataAnnotations;

namespace randevu_app_api.Models
{
    public class Dukkan
    {
        public int Id { get; set; }

        public string DukkanAdi { get; set; }

        public string VergiKimlikNo { get; set; }

        public string Telefon { get; set; }

        public string EPosta { get; set; }

        public string Konum { get; set; }

        public string Sifre { get; set; }

        public bool Durum { get; set; } = false;
        public bool Onay { get; set; } = false;
        public ICollection<Calisan> Calisanlar { get; set; }


    }
}
