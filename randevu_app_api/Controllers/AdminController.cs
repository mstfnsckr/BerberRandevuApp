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
    public class AdminController : ControllerBase
    {
        private readonly AppDbContext _context;
        private static readonly Dictionary<string, string> VerificationCodes = new Dictionary<string, string>();
        private static readonly HashSet<string> VerifiedEmails = new HashSet<string>();

        public AdminController(AppDbContext context)
        {
            _context = context;
        }
        [HttpPost("giris")]
        public async Task<IActionResult> AdminGiris([FromBody] Admin model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var admin = await _context.Adminler
                .FirstOrDefaultAsync(x => x.AdminNo == model.AdminNo);

            if (admin == null)
            {
                return Unauthorized("Admin bulunamadı.");
            }

            if (admin.Sifre != model.Sifre) // Note: In production, use password hashing
            {
                return Unauthorized("Yanlış şifre.");
            }

            return Ok(new { success = true, message = "Giriş başarılı." });
        }
    }
    
}
