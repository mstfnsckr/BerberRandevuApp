using randevu_app_api.Models;
using Microsoft.EntityFrameworkCore;

namespace randevu_app_api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Kullanici> Kullanicilar { get; set; }
        public DbSet<Dukkan> Dukkanlar { get; set; }
        public DbSet<Calisan> Calisanlar { get; set; }
        public DbSet<Randevu> Randevular { get; set; }
        public DbSet<Hizmet> Hizmetler { get; set; }
        public DbSet<HizmetBedel> HizmetBedeller { get; set; }
        public DbSet<Admin> Adminler { get; set; }

    }
}