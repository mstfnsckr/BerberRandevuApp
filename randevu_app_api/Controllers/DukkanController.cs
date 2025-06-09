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
    public class DukkanController : ControllerBase
    {
        private readonly AppDbContext _context;
        private static readonly Dictionary<string, string> VerificationCodes = new Dictionary<string, string>();
        private static readonly HashSet<string> VerifiedEmails = new HashSet<string>();

        public DukkanController(AppDbContext context)
        {
            _context = context;
        }
        [HttpPost("kayit")]
        public async Task<IActionResult> DukkanKayitOl([FromBody] Dukkan model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // E-posta ve TC kimlik numarasının tekrarını kontrol et
            if (await _context.Dukkanlar.AnyAsync(x => x.VergiKimlikNo == model.VergiKimlikNo))
            {
                return BadRequest("Bu Vergi Kimlik Numarası zaten kayıtlı.");
            }


            // Şifreyi hashle
            model.Sifre = BCrypt.Net.BCrypt.HashPassword(model.Sifre);

            _context.Dukkanlar.Add(model);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Kayıt başarılı. Doğrulama e-postası gönderildi." });
        }
        [HttpPost("giris")]
        public async Task<IActionResult> DukkanGirisYap([FromBody] LoginModelDukkan model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var dukkan = await _context.Dukkanlar
                .FirstOrDefaultAsync(x => x.DukkanAdi == model.DukkanAdi);

            if (dukkan == null)
            {
                return Unauthorized("Dükkan bulunamadı.");
            }

            if (!BCrypt.Net.BCrypt.Verify(model.Sifre, dukkan.Sifre))
            {
                return Unauthorized("Yanlış Şifre.");
            }

            return Ok(new
            {
                success = true,
                message = "Giriş başarılı.",
                dukkanId = dukkan.Id // ID'yi yanıta ekleyin
            });
        }
        [HttpPost("kodgonderkayit")]
        public async Task<IActionResult> KodGonderKayit([FromBody] EmailModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
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
            var dukkan = await _context.Dukkanlar.FirstOrDefaultAsync(x => x.EPosta == model.EPosta);
            if (dukkan == null)
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
        public async Task<IActionResult> SifreyiYenileDukkan([FromBody] SifreYenilemeDukkan model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new
                {
                    success = false,
                    errors = ModelState.Values.SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                });
            }

            try
            {
                var dukkan = await _context.Dukkanlar
                    .FirstOrDefaultAsync(c =>
                        c.EPosta == model.EPosta &&
                        c.DukkanAdi.ToUpper() == model.DukkanAdi.ToUpper());

                if (dukkan == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "E-posta ve Dükkan Adı eşleşmiyor"
                    });
                }

                dukkan.Sifre = BCrypt.Net.BCrypt.HashPassword(model.YeniSifre);
                _context.Update(dukkan);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = "Şifre güncellendi"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Hata: " + ex.Message
                });
            }
        }
        [HttpGet("{id}")]
        public async Task<IActionResult> GetDukkan(int id)
        {
            var dukkan = await _context.Dukkanlar
                .Include(d => d.Calisanlar)
                    .ThenInclude(c => c.HizmetBedeller)
                        .ThenInclude(hb => hb.Hizmet)
                .FirstOrDefaultAsync(d => d.Id == id);

            if (dukkan == null)
                return NotFound();

            var result = new
            {
                dukkan.Id,
                dukkan.DukkanAdi,
                dukkan.VergiKimlikNo,
                dukkan.Telefon,
                dukkan.EPosta,
                Konum = new
                {
                    Latitude = double.Parse(dukkan.Konum.Split(',')[0]),
                    Longitude = double.Parse(dukkan.Konum.Split(',')[1])
                },
                dukkan.Durum,
                Calisanlar = dukkan.Calisanlar.Select(c => new
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
                })
            };

            return Ok(result);
        }

        [HttpPut("durum-guncelle")]
        public async Task<IActionResult> DurumGuncelle([FromBody] DurumGuncelleModel model)
        {
            var dukkan = await _context.Dukkanlar.FirstOrDefaultAsync(d => d.Id == model.DukkanId);

            if (dukkan == null)
                return NotFound();

            dukkan.Durum = model.YeniDurum;
            await _context.SaveChangesAsync();

            return Ok(new { success = true });
        }


        [HttpDelete("sil/{id}")]
        public async Task<IActionResult> DukkanSil(int id)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                var dukkan = await _context.Dukkanlar
                    .Include(d => d.Calisanlar)
                        .ThenInclude(c => c.HizmetBedeller)
                            .ThenInclude(hb => hb.Randevular)
                    .FirstOrDefaultAsync(d => d.Id == id);

                if (dukkan == null)
                {
                    return NotFound("Dükkan bulunamadı");
                }

                foreach (var calisan in dukkan.Calisanlar)
                {
                    foreach (var hizmetBedel in calisan.HizmetBedeller)
                    {
                        _context.Randevular.RemoveRange(hizmetBedel.Randevular);
                    }
                    _context.HizmetBedeller.RemoveRange(calisan.HizmetBedeller);
                }

                _context.Calisanlar.RemoveRange(dukkan.Calisanlar);
                _context.Dukkanlar.Remove(dukkan);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { success = true, message = "Dükkan ve ilişkili kayıtlar başarıyla silindi" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { success = false, message = "Silme işlemi sırasında hata oluştu: " + ex.Message });
            }
        }


        [HttpGet("aktif-dukkanlar")]
        public async Task<ActionResult<IEnumerable<object>>> GetAktifDukkanlar()
        {
            var bugun = DateTime.Today;
            var yarin = bugun.AddDays(1);

            var dukkanlar = await _context.Dukkanlar
                .Where(d => d.Durum && d.Onay) // Hem durum hem de onay true olanlar
                .Include(d => d.Calisanlar)
                    .ThenInclude(c => c.HizmetBedeller)
                        .ThenInclude(hb => hb.Hizmet)
                .Include(d => d.Calisanlar)
                    .ThenInclude(c => c.HizmetBedeller)
                        .ThenInclude(hb => hb.Randevular
                            .Where(r => r.Tarih >= bugun && r.Tarih < yarin))
                .ToListAsync();

            var result = dukkanlar.Select(d => new
            {
                d.Id,
                d.DukkanAdi,
                d.VergiKimlikNo,
                d.Telefon,
                d.EPosta,
                Konum = new
                {
                    Latitude = double.Parse(d.Konum.Split(',')[0]),
                    Longitude = double.Parse(d.Konum.Split(',')[1])
                },
                d.Durum,
                Calisanlar = d.Calisanlar.Select(c => new
                {
                    c.Id,
                    c.Ad,
                    c.Soyad,
                    c.TC,
                    c.DukkanId,
                    HizmetBedeller = c.HizmetBedeller.Select(hb => new
                    {
                        hb.Id,
                        Hizmet = new { hb.Hizmet.Id, hb.Hizmet.Ad },
                        hb.Fiyat,
                        RandevuSayisi = hb.Randevular.Count
                    })
                })
            });

            return Ok(result);
        }
        [HttpGet("onaysiz-dukkanlar")]
        public async Task<ActionResult<IEnumerable<object>>> GetOnaysizDukkanlar()
        {
            var dukkanlar = await _context.Dukkanlar
                .Where(d => !d.Onay)
                .Select(d => new
                {
                    id = d.Id,
                    dukkanAdi = d.DukkanAdi,
                    vergiKimlikNo = d.VergiKimlikNo,
                    telefon = d.Telefon,
                    ePosta = d.EPosta,
                    konum = d.Konum
                })
                .ToListAsync();

            return Ok(dukkanlar);
        }
        [HttpPut("onayla/{id}")]
        public async Task<IActionResult> OnaylaDukkan(int id)
        {
            var dukkan = await _context.Dukkanlar.FindAsync(id);
            if (dukkan == null)
            {
                return NotFound();
            }
            dukkan.Onay = true;
            await _context.SaveChangesAsync();

            return Ok(new { success = true });
        }

    }
    public class LoginModelDukkan
    {
        public required string DukkanAdi { get; set; }
        public required string Sifre { get; set; }
    }
    public class SifreYenilemeDukkan
    {
        public required string EPosta { get; set; }
        public required string YeniSifre { get; set; }
        public required string DukkanAdi { get; set; } 

    }
    
    public class DurumGuncelleModel
    {
        public int DukkanId { get; set; }
        public bool YeniDurum { get; set; }
    }
}
