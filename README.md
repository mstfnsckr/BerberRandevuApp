# Randevu App 💈

---

### Proje Açıklaması

Bu proje, berber ve kuaför salonları için **tam yığın (full-stack)** bir randevu yönetim uygulamasıdır. Uygulama, işletmelerin müşteri kayıtlarını, sundukları hizmetleri, çalışanlarını ve randevu süreçlerini etkin bir şekilde yönetmelerini sağlamak üzere geliştirilmiştir.

---

### ✨ Temel Özellikler

* **Randevu Yönetimi:** Yeni randevu oluşturma, mevcut randevuları görüntüleme, silme ve durumlarını güncelleme yeteneği.
* **Çalışan Takibi:** Belirlenen tarihlerdeki randevuları çalışan bazında kolayca listeleme imkanı.
* **Kullanıcı Takibi:** Kullanıcının geçmiş ve gelecek randevularını görüntüleyebilmesi.
* **API Desteği:** Güçlü bir arka plan (backend) için **ASP.NET Core Web API** kullanılır.
* **API Dokümantasyonu:** API uç noktaları için **Swagger** dokümantasyon desteği mevcuttur.
* **CORS:** Geliştirme kolaylığı için tüm **origin**'lere izin verilmiştir.

---

### 💻 Teknolojiler

| Bileşen | Teknoloji | Dil/Çerçeve |
| :--- | :--- | :--- |
| **Frontend / Mobil** | Flutter | Dart |
| **Backend / API** | ASP.NET Core | C# |
| **Veritabanı** | SQL Server | Entity Framework Core (EF Core) |

---

### 📂 Proje Yapısı

Proje, iki ana klasörden oluşmaktadır:

* `randevu_app`: **Flutter** mobil uygulaması (Kaynak kodu `lib/` klasörü altındadır).
* `randevu_app_api`: **ASP.NET Core Web API** projesi (Controller'lar, Modeller, Veri Katmanı ve Migrasyonlar burada yer alır).

---

### 🚀 Kurulum ve Çalıştırma

### 1. Klonlama İşlemleri

Projeyi yerel makinenize klonlamak için aşağıdaki komutları kullanın:

```bash
git clone [https://github.com/mstfnsckr/BerberRandevuApp](https://github.com/mstfnsckr/BerberRandevuApp)
cd BerberRandevuApp
