using System.ComponentModel.DataAnnotations;

namespace randevu_app_api.Models
{
    public class Admin
    {
        public int Id { get; set; }

        public string AdminNo { get; set; }

        public string Sifre { get; set; }
    }
}
