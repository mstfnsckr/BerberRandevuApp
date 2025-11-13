# Randevu App 💈

---

### Proje Açıklaması

Bu proje, berber ve kuaför salonları için **tam yığın (full-stack)** bir randevu yönetim uygulamasıdır. Uygulama, işletmelerin müşteri kayıtlarını, sundukları hizmetleri, çalışanlarını ve randevu süreçlerini etkin bir şekilde yönetmelerini sağlamak üzere geliştirilmiştir.

---

### ✨ Temel Özellikler

* **Randevu Yönetimi:** Randevu oluşturma, görüntüleme, silme ve durum güncelleme.
* **Çalışan Takibi:** Belirli tarihli randevuları çalışan bazında listeleme.
* **Kullanıcı Takibi:** Kullanıcıya ait gelecek randevuları görme.
* **API Desteği:** ASP.NET Core Web API ile backend sağlanır.
* **API Dokümantasyonu:** Swagger desteği kullanılır.
* **CORS:** Geliştirme amaçlı tüm originlere izin verilmiştir.

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

* `randevu_app`: **Flutter** mobil uygulaması (kaynak: lib/).
* `randevu_app_api`: **ASP.NET Core Web API** (Controllers, Models, Data, Migrations).

---

### 🚀 Kurulum ve Çalıştırma

### 1. Klonlama İşlemleri

Projeyi yerel makinenize klonlayın:

```bash
git clone [https://github.com/mstfnsckr/BerberRandevuApp](https://github.com/mstfnsckr/BerberRandevuApp)
cd BerberRandevuApp
