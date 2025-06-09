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
    public class KullaniciController : ControllerBase
    {
        private readonly AppDbContext _context;
        private static readonly Dictionary<string, string> VerificationCodes = new Dictionary<string, string>();
        private static readonly HashSet<string> VerifiedEmails = new HashSet<string>();

        public KullaniciController(AppDbContext context)
        {
            _context = context;
        }

        // Kullanıcı kaydı
        [HttpPost("kayit")]
        public async Task<IActionResult> KayitOl([FromBody] Kullanici model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // E-posta ve TC kimlik numarasının tekrarını kontrol et
            if (await _context.Kullanicilar.AnyAsync(x => x.EPosta == model.EPosta))
            {
                return BadRequest("Bu e-posta adresi zaten kayıtl�.");
            }
            if (await _context.Kullanicilar.AnyAsync(x => x.TC == model.TC))
            {
                return BadRequest("Bu TC Kimlik No zaten kayıtl�.");
            }

            // Şifreyi hashle
            model.Sifre = BCrypt.Net.BCrypt.HashPassword(model.Sifre);
            model.KayitTarihi = DateTime.Now;

            _context.Kullanicilar.Add(model);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Kay�t ba�ar�l�. Do�rulama e-postas� g�nderildi." });
        }
        [HttpPost("giris")]
        public async Task<IActionResult> GirisYap([FromBody] LoginModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var kullanici = await _context.Kullanicilar
                .FirstOrDefaultAsync(x => x.EPosta == model.EPosta);

            if (kullanici == null)
            {
                return Unauthorized("E-posta adresi bulunamad�.");
            }

            if (!BCrypt.Net.BCrypt.Verify(model.Sifre, kullanici.Sifre))
            {
                return Unauthorized("Yanl�� �ifre.");
            }

            return Ok(new { success = true, message = "Giri� ba�ar�l�." });
        }
        [HttpPost("kodgonderkayit")]
        public async Task<IActionResult> KodGonderKayit([FromBody] EmailModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // E�er e-posta veritaban�nda zaten varsa hata d�nd�r
            var kullanici = await _context.Kullanicilar.FirstOrDefaultAsync(x => x.EPosta == model.EPosta);
            if (kullanici != null)
            {
                return BadRequest("Bu e-posta adresi zaten kay�tl�.");
            }

            // 6 haneli rastgele kod �retimi
            var random = new Random();
            var kod = string.Concat(Enumerable.Range(0, 6).Select(_ => random.Next(0, 10).ToString()));

            // Kodun e-posta adresine g�nderilmesi
            try
            {
                var fromAddress = new MailAddress("araccekicitamir@gmail.com", "Sistem");
                var toAddress = new MailAddress(model.EPosta);
                const string fromPassword = "wbfduhyfpfcdodcp"; // G�venli �ekilde y�netin
                const string subject = "Kay�t Do�rulama Kodu";
                string body = $"Kay�t i�leminiz i�in do�rulama kodunuz: {kod}";

                var smtp = new SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(fromAddress.Address, fromPassword)
                };

                using (var message = new MailMessage(fromAddress, toAddress)
                {
                    Subject = subject,
                    Body = body
                })
                {
                    await smtp.SendMailAsync(message);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, "E-posta g�nderilirken hata olu�tu: " + ex.Message);
            }

            // �retilen kodu ge�ici koleksiyonda sakla
            if (VerificationCodes.ContainsKey(model.EPosta))
            {
                VerificationCodes[model.EPosta] = kod;
            }
            else
            {
                VerificationCodes.Add(model.EPosta, kod);
            }

            return Ok(new { success = true, message = "Do�rulama kodu g�nderildi." });
        }
        [HttpPost("koddogrulakayit")]
        public async Task<IActionResult> KodDogrulaKayit([FromBody] KodDogrulamaModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // E�er e-posta zaten kay�tl�ysa, kay�t do�rulamas� yap�lamaz
            var kullanici = await _context.Kullanicilar.FirstOrDefaultAsync(x => x.EPosta == model.EPosta);
            if (kullanici != null)
            {
                return BadRequest("Bu e-posta adresi zaten kay�tl�.");
            }

            if (VerificationCodes.TryGetValue(model.EPosta, out var kod))
            {
                if (kod == model.Kod)
                {
                    // Do�rulama ba�ar�l�, e-posta kay�t i�in onayland�
                    VerifiedEmails.Add(model.EPosta);
                    VerificationCodes.Remove(model.EPosta);
                    return Ok(new { success = true, message = "Kod do�ruland�. Kay�t i�lemine devam edebilirsiniz." });
                }
            }

            return BadRequest("Do�rulama kodu hatal� veya s�resi dolmu� olabilir.");
        }
        [HttpPost("kodgondergiris")]
        public async Task<IActionResult> KodGonder([FromBody] EmailModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // Kullan�c�n�n varl���n� kontrol edelim
            var kullanici = await _context.Kullanicilar.FirstOrDefaultAsync(x => x.EPosta == model.EPosta);
            if (kullanici == null)
            {
                return NotFound("E-posta adresi bulunamad�.");
            }

            // 6 haneli rastgele kod �retimi
            var random = new Random();
            var kod = string.Concat(Enumerable.Range(0, 6).Select(_ => random.Next(0, 10).ToString()));

            // Kodun e-posta adresine g�nderilmesi
            try
            {
                var fromAddress = new MailAddress("araccekicitamir@gmail.com", "Sistem");
                var toAddress = new MailAddress(model.EPosta);
                const string fromPassword = "wbfduhyfpfcdodcp"; // Gmail hesab�n�z�n �ifresini buraya ekleyin (g�venlik a��s�ndan uygun bir �ekilde y�netin)
                const string subject = "�ifre Yenileme Do�rulama Kodu";
                string body = $"�ifre yenileme i�leminiz i�in do�rulama kodunuz: {kod}";

                var smtp = new SmtpClient
                {
                    Host = "smtp.gmail.com",
                    Port = 587,
                    EnableSsl = true,
                    DeliveryMethod = SmtpDeliveryMethod.Network,
                    UseDefaultCredentials = false,
                    Credentials = new NetworkCredential(fromAddress.Address, fromPassword)
                };

                using (var message = new MailMessage(fromAddress, toAddress)
                {
                    Subject = subject,
                    Body = body
                })
                {
                    await smtp.SendMailAsync(message);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, "E-posta g�nderilirken hata olu�tu: " + ex.Message);
            }

            // �retilen kodu ge�ici koleksiyonda saklayal�m
            if (VerificationCodes.ContainsKey(model.EPosta))
            {
                VerificationCodes[model.EPosta] = kod;
            }
            else
            {
                VerificationCodes.Add(model.EPosta, kod);
            }
            // Kod g�nderme i�lemi tamamland�
            return Ok(new { success = true, message = "Do�rulama kodu g�nderildi." });
        }

        [HttpPost("koddogrulagiris")]
        public IActionResult KodDogrula([FromBody] KodDogrulamaModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (VerificationCodes.TryGetValue(model.EPosta, out var kod))
            {
                if (kod == model.Kod)
                {
                    // Do�rulama ba�ar�l�, e-postay� do�rulanm�� listesine ekle
                    VerifiedEmails.Add(model.EPosta);
                    // Do�rulama kodunu iste�e ba�l� olarak koleksiyondan kald�rabilirsiniz.
                    VerificationCodes.Remove(model.EPosta);
                    return Ok(new { success = true, message = "Kod do�ruland�." });
                }
            }
            return BadRequest("Do�rulama kodu hatal�.");
        }
        [HttpPost("sifreyiYenile")]
        public async Task<IActionResult> SifreyiYenile([FromBody] SifreYenilemeModel model)
        {
            // �ncelikle, e-postan�n do�rulan�p do�rulanmad���n� kontrol edelim.
            if (!VerifiedEmails.Contains(model.EPosta))
            {
                return BadRequest("E-posta do�rulamas� yap�lmam��.");
            }

            var kullanici = await _context.Kullanicilar
                .FirstOrDefaultAsync(x => x.EPosta == model.EPosta);

            if (kullanici == null)
            {
                return NotFound("E-posta adresi bulunamad�.");
            }

            // Yeni �ifreyi hash'leyerek g�ncelle
            kullanici.Sifre = BCrypt.Net.BCrypt.HashPassword(model.YeniSifre);
            await _context.SaveChangesAsync();

            // ��lem sonras� do�rulanm�� e-posta listesinden silebiliriz
            VerifiedEmails.Remove(model.EPosta);

            return Ok(new { success = true, message = "�ifre ba�ar�yla g�ncellendi." });
        }
        [HttpGet("GetIdByEmail")]
        public async Task<ActionResult<dynamic>> GetUserInfoByEmail([FromQuery] string eposta)
        {
            var kullanici = await _context.Kullanicilar
                .Where(k => k.EPosta == eposta)
                .Select(k => new {
                    id = k.Id,
                    ad = k.Ad,
                    soyad = k.Soyad,
                })
                .FirstOrDefaultAsync();

            if (kullanici == null)
                return NotFound("Kullanıcı bulunamadı");

            return Ok(kullanici);
        }

    }
    public class EmailModel
    {
        [Required]
        [EmailAddress]
        public required string EPosta { get; set; }
    }

    public class KodDogrulamaModel
    {
        [Required]
        [EmailAddress]
        public required string EPosta { get; set; }

        [Required]
        public required string Kod { get; set; }
    }
    public class LoginModel
    {
        [Required]
        [EmailAddress]
        public required string EPosta { get; set; }

        [Required]
        public required string Sifre { get; set; }
    }
    public class SifreYenilemeModel
    {
        [Required]
        [EmailAddress]
        public required string EPosta { get; set; }

        [Required]
        public required string YeniSifre { get; set; }
    }
}
