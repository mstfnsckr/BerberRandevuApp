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
    public class HizmetBedelController : ControllerBase
    {
        private readonly AppDbContext _context;
        private static readonly Dictionary<string, string> VerificationCodes = new Dictionary<string, string>();
        private static readonly HashSet<string> VerifiedEmails = new HashSet<string>();

        public HizmetBedelController(AppDbContext context)
        {
            _context = context;
        }
        // Add these to your HizmetBedelController.cs

        [HttpGet("hizmetler")]
        public async Task<IActionResult> GetHizmetler()
        {
            var hizmetler = await _context.Hizmetler.ToListAsync();
            return Ok(hizmetler);
        }

        [HttpPost("ekle")]
        public async Task<IActionResult> EkleHizmetBedel([FromBody] HizmetBedelEkleModel model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var calisan = await _context.Calisanlar.FindAsync(model.CalisanId);
            if (calisan == null)
                return NotFound("Çalışan bulunamadı");

            var hizmet = await _context.Hizmetler.FindAsync(model.HizmetId);
            if (hizmet == null)
                return NotFound("Hizmet bulunamadı");

            var existingBedel = await _context.HizmetBedeller
                .FirstOrDefaultAsync(hb => hb.CalisanId == model.CalisanId && hb.HizmetId == model.HizmetId);
            
            if (existingBedel != null)
                return BadRequest("Bu hizmet zaten bu çalışana eklenmiş");

            var hizmetBedel = new HizmetBedel
            {
                CalisanId = model.CalisanId,
                HizmetId = model.HizmetId,
                Fiyat = model.Fiyat
            };

            _context.HizmetBedeller.Add(hizmetBedel);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Hizmet bedeli başarıyla eklendi" });
        }
        [HttpDelete("sil/{id}")]
        public async Task<IActionResult> SilHizmetBedel(int id)
        {
            var hizmetBedel = await _context.HizmetBedeller
                .Include(hb => hb.Randevular)
                .FirstOrDefaultAsync(hb => hb.Id == id);

            if (hizmetBedel == null)
                return NotFound("Hizmet bedeli bulunamadı");

            // Randevuları sil
            _context.Randevular.RemoveRange(hizmetBedel.Randevular);
            _context.HizmetBedeller.Remove(hizmetBedel);
            
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Hizmet bedeli başarıyla silindi" });
        }

    }
    public class HizmetBedelEkleModel
    {
        [Required]
        public int CalisanId { get; set; }
        
        [Required]
        public int HizmetId { get; set; }
        
        [Required]
        [Range(0, int.MaxValue)]
        public int Fiyat { get; set; }
    }
}
