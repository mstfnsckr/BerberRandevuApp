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
    public class CalisanController : ControllerBase
    {
        private readonly AppDbContext _context;
        private static readonly Dictionary<string, string> VerificationCodes = new Dictionary<string, string>();
        private static readonly HashSet<string> VerifiedEmails = new HashSet<string>();

        public CalisanController(AppDbContext context)
        {
            _context = context;
        }
        
        [HttpPost("eklecalisan")]
        public async Task<IActionResult> EkleCalisan([FromBody] CalisanEkleModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var calisan = await _context.Calisanlar.FirstOrDefaultAsync(x => x.TC == model.TC);
            if (calisan != null)
            {
                return BadRequest("Bu TC zaten kayitli.");
            }
            var dukkan = await _context.Dukkanlar.FindAsync(model.DukkanId);
            if (dukkan == null)
                return NotFound("Dükkan bulunamadı.");

            var yeniCalisan = new Calisan
            {
                Ad = model.Ad,
                Soyad = model.Soyad,
                TC = model.TC,
                DukkanId = model.DukkanId
            };

            _context.Calisanlar.Add(yeniCalisan);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Çalışan başarıyla eklendi." });
        }
        // Add these to your CalisanController.cs

        [HttpGet("calisanlar/{dukkanId}")]
        public async Task<IActionResult> GetCalisanlarByDukkan(int dukkanId)
        {
            var calisanlar = await _context.Calisanlar
                .Where(c => c.DukkanId == dukkanId)
                .Include(c => c.HizmetBedeller)
                    .ThenInclude(hb => hb.Hizmet)
                .ToListAsync();

            var result = calisanlar.Select(c => new
            {
                c.Id,
                c.Ad,
                c.Soyad,
                c.TC,
                c.DukkanId,
                HizmetBedeller = c.HizmetBedeller.Select(hb => new
                {
                    hb.Id,
                    HizmetAd = hb.Hizmet.Ad,
                    hb.Fiyat
                })
            });

            return Ok(result);
        }

        [HttpDelete("sil/{id}")]
        public async Task<IActionResult> SilCalisan(int id)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                var calisan = await _context.Calisanlar
                    .Include(c => c.HizmetBedeller)
                        .ThenInclude(hb => hb.Randevular)
                    .FirstOrDefaultAsync(c => c.Id == id);

                if (calisan == null)
                {
                    return NotFound("Çalışan bulunamadı");
                }

                foreach (var hizmetBedel in calisan.HizmetBedeller)
                {
                    _context.Randevular.RemoveRange(hizmetBedel.Randevular);
                }
                _context.HizmetBedeller.RemoveRange(calisan.HizmetBedeller);
                _context.Calisanlar.Remove(calisan);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { success = true, message = "Çalışan ve ilişkili kayıtlar başarıyla silindi" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { success = false, message = "Silme işlemi sırasında hata oluştu: " + ex.Message });
            }
        }
    }
    
    public class CalisanEkleModel
    {
        [Required]
        public string Ad { get; set; }

        [Required]
        public string Soyad { get; set; }

        [Required]
        [StringLength(11, MinimumLength = 11)]
        public string TC { get; set; }

        public int DukkanId { get; set; } // Flutter'dan gelecek
    }
    
}
