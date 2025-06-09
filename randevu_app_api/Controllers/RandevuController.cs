 using randevu_app_api.Data;
using randevu_app_api.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BCrypt.Net;
using System.Net;
using System.Net.Mail;
using System.ComponentModel.DataAnnotations;


namespace randevu_app_api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RandevuController : ControllerBase
    {
        private readonly AppDbContext _context;
        private static readonly Dictionary<string, string> VerificationCodes = new Dictionary<string, string>();
        private static readonly HashSet<string> VerifiedEmails = new HashSet<string>();

        public RandevuController(AppDbContext context)
        {
            _context = context;
        }
        [HttpPost]
        public async Task<IActionResult> CreateRandevu(RandevuCreateDto randevuDto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // Check if employee already has an appointment for the SAME SERVICE at this time
            var tarihSaat = randevuDto.Tarih.Date.Add(randevuDto.Saat);
            
            var existingAppointment = await _context.Randevular
                .Include(r => r.HizmetBedel)
                .AnyAsync(r => r.HizmetBedel.CalisanId == randevuDto.CalisanId &&
                            r.Tarih.Date == tarihSaat.Date &&
                            r.Saat == tarihSaat.TimeOfDay &&
                            r.HizmetBedel.HizmetId == _context.HizmetBedeller
                                .Where(hb => hb.Id == randevuDto.HizmetBedelId)
                                .Select(hb => hb.HizmetId)
                                .FirstOrDefault());

            if (existingAppointment)
            {
                return Conflict("Çalışanın bu saatte aynı hizmet için başka bir randevusu bulunmaktadır.");
            }

            var randevu = new Randevu
            {
                Tarih = tarihSaat.Date,
                Saat = tarihSaat.TimeOfDay,
                Durum = "Onay Bekliyor",
                KullaniciId = (int)randevuDto.KullaniciId,
                HizmetBedelId = randevuDto.HizmetBedelId
            };

            try
            {
                await _context.Randevular.AddAsync(randevu);
                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetRandevu), new { id = randevu.Id }, randevu);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetRandevu(int id)
        {
            var randevu = await _context.Randevular
                .Include(r => r.HizmetBedel)
                .ThenInclude(hb => hb.Hizmet)
                .FirstOrDefaultAsync(r => r.Id == id);

            return randevu == null ? NotFound() : Ok(randevu);
        }
        [HttpGet("CalisanRandevular")]
        public async Task<IActionResult> GetCalisanRandevularByDate(int calisanId, [FromQuery] string tarih)
        {
            try
            {
                if (!DateTime.TryParse(tarih, out var date))
                {
                    return BadRequest("Invalid date format");
                }

                var randevular = await _context.Randevular
                    .Include(r => r.HizmetBedel)
                    .ThenInclude(hb => hb.Calisan)
                    .Where(r => r.HizmetBedel != null && 
                            r.HizmetBedel.CalisanId == calisanId && 
                            r.Tarih.Date == date.Date)
                    .Select(r => new {
                        r.Id,
                        r.Tarih,
                        Saat = r.Saat.ToString(@"hh\:mm"),
                        HizmetAd = r.HizmetBedel.Hizmet.Ad,
                        Fiyat = r.HizmetBedel.Fiyat
                    })
                    .ToListAsync();

                return Ok(randevular);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
        [HttpGet("CalisanRandevularDetayli")]
        public async Task<ActionResult<IEnumerable<object>>> GetCalisanRandevularDetayli(int calisanId, string tarih)
        {
            var parsedDate = DateTime.Parse(tarih);

            var randevular = await _context.Randevular
                .Where(r => r.HizmetBedel.CalisanId == calisanId && 
                            r.Tarih.Date == parsedDate.Date)
                .Include(r => r.Kullanici)
                .Include(r => r.HizmetBedel)
                .ThenInclude(hb => hb.Hizmet)
                .OrderBy(r => r.Saat)
                .Select(r => new
                {
                    id = r.Id, // ID alanını ekledik
                    kullaniciAd = r.Kullanici.Ad,
                    kullaniciSoyad = r.Kullanici.Soyad,
                    saat = r.Saat,
                    hizmetAd = r.HizmetBedel.Hizmet.Ad,
                    fiyat = r.HizmetBedel.Fiyat,
                    durum = r.Durum
                })
                .ToListAsync();

            return Ok(randevular);
        }

        [HttpDelete("Sil/{id}")]
        public async Task<IActionResult> Sil(int id)
        {
            var randevu = await _context.Randevular.FindAsync(id);
            if (randevu == null)
            {
                return NotFound();
            }

            _context.Randevular.Remove(randevu);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpPut("DurumGuncelle/{id}")]
        public async Task<IActionResult> DurumGuncelle(int id, [FromBody] string yeniDurum)
        {
            var randevu = await _context.Randevular.FindAsync(id);
            if (randevu == null)
            {
                return NotFound();
            }

            randevu.Durum = yeniDurum;
            _context.Randevular.Update(randevu);
            await _context.SaveChangesAsync();

            return Ok(randevu);
        }
        // Kullanıcıya ait randevuları getir
        [HttpGet("KullaniciRandevular/{kullaniciId}")]
        public async Task<ActionResult<IEnumerable<RandevuDto>>> GetKullaniciRandevular(int kullaniciId)
        {
            var bugun = DateTime.Today;
            
            var randevular = await _context.Randevular
                .Where(r => r.KullaniciId == kullaniciId && r.Tarih >= bugun) // Sadece bugün ve sonrası
                .Include(r => r.HizmetBedel)
                .ThenInclude(hb => hb.Hizmet)
                .Include(r => r.HizmetBedel)
                .ThenInclude(hb => hb.Calisan)
                .ThenInclude(c => c.Dukkan)
                .OrderBy(r => r.Tarih)
                .ThenBy(r => r.Saat)
                .Select(r => new RandevuDto
                {
                    Id = r.Id,
                    Tarih = r.Tarih,
                    Saat = r.Saat,
                    Durum = r.Durum,
                    DukkanAdi = r.HizmetBedel.Calisan.Dukkan.DukkanAdi,
                    CalisanAdi = $"{r.HizmetBedel.Calisan.Ad} {r.HizmetBedel.Calisan.Soyad}",
                    HizmetAdi = r.HizmetBedel.Hizmet.Ad,
                    Fiyat = r.HizmetBedel.Fiyat
                })
                .ToListAsync();

            return Ok(randevular);
        }

    }

    public class RandevuCreateDto
    {
        public DateTime Tarih { get; set; }
        public TimeSpan Saat { get; set; }
        public int? KullaniciId { get; set; }
        public int HizmetBedelId { get; set; }
        public int CalisanId { get; set; } // Add this
    }
    public class CalisanRandevuDetayDto
    {
        public string KullaniciAd { get; set; }
        public string KullaniciSoyad { get; set; }
        public TimeSpan Saat { get; set; }
        public string HizmetAd { get; set; }
        public decimal Fiyat { get; set; }
        public string Durum { get; set; }
    }
    public class RandevuDto
    {
        public int Id { get; set; }
        public DateTime Tarih { get; set; }
        public TimeSpan Saat { get; set; }
        public string Durum { get; set; }
        public string DukkanAdi { get; set; }
        public string CalisanAdi { get; set; }
        public string HizmetAdi { get; set; }
        public int Fiyat { get; set; }
    }
}