markdown
# Randevu App 💈

---

### Proje Açıklaması

Bu proje, berber ve kuaför salonları için **tam yığın (full-stack)** bir randevu yönetim uygulamasıdır. Uygulama, işletmelerin müşteri kayıtlarını, sundukları hizmetleri, çalışanlarını ve randevu süreçlerini etkin bir şekilde yönetmelerini sağlamak üzere geliştirilmiştir.

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

## 🚀 Kurulum ve Çalıştırma

### 1. Projeyi Klonlama
```bash
git clone https://github.com/mstfnsckr/BerberRandevuApp
cd BerberRandevuApp
2. Backend (API) Kurulumu

bash
cd randevu_app_api
# appsettings.json dosyasındaki connection string'i güncelleyin
# Paketleri restore edin: dotnet restore
# Veritabanını oluşturun: dotnet ef database update
# API'yi çalıştırın: dotnet run
3. Frontend (Flutter) Kurulumu

bash
cd ../randevu_app
# Bağımlılıkları yükleyin: flutter pub get
# Uygulamayı çalıştırın: flutter run
🔧 API Base URL Ayarı

Flutter uygulamasında lib/core/constants/api_constants.dart dosyasını aşağıdaki gibi düzenleyin:

dart
class ApiConstants {
  // Geliştirme ortamı (Android emülatör)
  static const String baseUrl = 'http://10.0.2.2:5242';

  // iOS simülatör için
  // static const String baseUrl = 'http://localhost:5242';
  
  // Üretim ortamı
  // static const String baseUrl = 'https://api.sirketiniz.com';
}
🌐 API Erişim Bilgileri

HTTP URL: http://localhost:5242
HTTPS URL: https://localhost:7128
Swagger UI: http://localhost:5242/swagger
📱 Ağ Yapılandırması

Android Emülatör: http://10.0.2.2:5242
iOS Simülatör: http://localhost:5242
Fiziksel Cihaz: Bilgisayarınızın IP adresi (ör: http://192.168.1.35:5242)
