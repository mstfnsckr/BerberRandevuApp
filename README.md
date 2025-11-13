# Randevu App 💈

---

### Proje Açıklaması

Bu proje, berber ve kuaför salonları için **tam yığın (full-stack)** bir randevu yönetim uygulamasıdır.

---

### ✨ Temel Özellikler

* **Randevu Yönetimi:** Yeni randevu oluşturma, mevcut randevuları görüntüleme, silme ve durumlarını güncelleme
* **Çalışan Takibi:** Belirlenen tarihlerdeki randevuları çalışan bazında listeleme
* **Kullanıcı Takibi:** Kullanıcının geçmiş ve gelecek randevularını görüntüleme
* **API Desteği:** **ASP.NET Core Web API** ile güçlü backend
* **API Dokümantasyonu:** **Swagger** dokümantasyon desteği

---

### 💻 Teknolojiler

| Bileşen | Teknoloji | Dil/Çerçeve |
| :--- | :--- | :--- |
| **Frontend / Mobil** | Flutter | Dart |
| **Backend / API** | ASP.NET Core | C# |
| **Veritabanı** | SQL Server | Entity Framework Core |

---

## 📋 KURULUM REHBERİ

Aşağıdaki butona tıklayarak tüm kurulum komutlarını tek seferde kopyalayabilirsiniz:

```bash
# 1. Projeyi klonlama
git clone https://github.com/mstfnsckr/BerberRandevuApp
cd BerberRandevuApp

# 2. Backend kurulumu
cd randevu_app_api
# - appsettings.json'daki connection string'i güncelleyin
# - Paketleri restore edin: dotnet restore
# - Migrations'ı çalıştırın: dotnet ef database update
# - API'yi başlatın: dotnet run

# 3. Frontend kurulumu  
cd ../randevu_app
# - Flutter paketlerini yükleyin: flutter pub get
# - Uygulamayı çalıştırın: flutter run

# API Base URL ayarı (lib/core/constants/api_constants.dart)
class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:5242'; // Android emülatör
  // static const String baseUrl = 'https://localhost:7128'; // iOS simülatör
}
