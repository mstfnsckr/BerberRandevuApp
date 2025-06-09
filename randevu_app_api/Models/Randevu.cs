using System.ComponentModel.DataAnnotations;

namespace randevu_app_api.Models
{
    public class Randevu
    {
        public int Id { get; set; }
        public DateTime Tarih { get; set; }
        public TimeSpan Saat { get; set; }
        public string Durum { get; set; }
        public int KullaniciId { get; set; }
        public int HizmetBedelId { get; set; }
        public Kullanici Kullanici { get; set; }
        public HizmetBedel HizmetBedel { get; set; }
    }
}
