title: "Randevu App 💈"

description: |
  Bu proje, berber ve kuaför randevu yönetimi için geliştirilmiş
  tam yığın (full‑stack) bir uygulamadır.
  Uygulama, berber dükkanları için müşteri kayıt, hizmet, çalışan
  ve randevu yönetimini sağlar.

features: |
  - Randevu Yönetimi: Randevu oluşturma, görüntüleme, silme ve durum güncelleme
  - Çalışan Takibi: Belirli tarihli randevuları çalışan bazında listeleme
  - Kullanıcı Takibi: Kullanıcıya ait gelecek randevuları görme
  - API Desteği: ASP.NET Core Web API ile backend sağlanır
  - Swagger Desteği: API dokümantasyonu için Swagger kullanılır
  - CORS: Geliştirme amaçlı tüm originlere izin verilmiştir

technologies: |
  - Frontend / Mobil: Flutter, Dart
  - Backend / API: ASP.NET Core, C#
  - Veritabanı: SQL Server (EF Core)

project_structure: |
  randevu_app         # Flutter mobil uygulaması (kaynak: lib/)
  randevu_app_api     # ASP.NET Core Web API (Controllers, Models, Data, Migrations)

setup: |
  Backend (API):
    1. randevu_app_api klasörüne gidin
    2. Bağımlılıkları yükleyin / restore edin
    3. appsettings.json içindeki DefaultConnection bağlantı dizesini kendi SQL Server ortamınıza göre güncelleyin
    4. Veritabanı migrasyonlarını uygulayın (EF Core CLI yüklü ise)
    5. Uygulamayı çalıştırın

    API, geliştirme ortamında şu URL’lerde dinler:
      - HTTP: http://localhost:5242
      - HTTPS: https://localhost:7128

    Swagger dokümantasyonu: http://localhost:5242/swagger

  Frontend (Flutter):
    1. Flutter SDK kurulu olduğundan emin olun
    2. randevu_app klasörüne gidin
    3. Uygulamayı çalıştırın

    Emülatör / cihaz ayarları:
      - Android emülatör: http://10.0.2.2:5242
      - iOS simülatör: localhost çalışır

flutter_api_base_url: |
  Flutter uygulamasındaki API çağrıları için baseUrl ayarı:
  Örnek constants.dart dosyası:

  ```dart
  class ApiConstants {
    // Geliştirme ortamı
    static const String baseUrl = 'http://10.0.2.2:5242';

    // Üretim ortamı
    // static const String baseUrl = 'https://api.sirketiniz.com';
  }

### Klonlama
Projeyi yerel makinenize klonlayın:

```bash
git clone [https://github.com/mstfnsckr/BerberRandevuApp](https://github.com/mstfnsckr/BerberRandevuApp)
cd BerberRandevuApp
