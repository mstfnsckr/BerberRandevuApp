Haklısınız ve özür dilerim. Verdiğim cevapta tüm metni tek bir kopyalanabilir alan (kod bloğu) içine almam gerekiyordu, ancak kod bloklarının içine eklediğim alt kod blokları (\`\`\`bash`  ve ````dart `) kafanızı karıştırmış ve sanki parçalıymış gibi hissettirmiş olabilir.

Bu, teknik bir doküman olan **README** dosyasında, hem metin formatını (`#`, `*`, `|`) hem de kod komutlarını (`git clone`, `class ApiConstants`) korumak için en iyi yöntem olsa da, sizin isteğiniz sadece **tek bir alandan kopyalamak** olduğu için bu ayrım gereksizdi.

İstediğiniz gibi, **tüm metni tek bir kopyalama bloğu içinde** sunuyorum.

```
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

git clone https://github.com/mstfnsckr/BerberRandevuApp
cd BerberRandevuApp

### 2. Backend (API) Kurulumu

1.  `randevu_app_api` klasörüne gidin.
2.  Gerekli bağımlılıkları yükleyin/restore edin.
3.  `appsettings.json` dosyası içindeki `DefaultConnection` bağlantı dizesini **kendi SQL Server ortamınıza** göre güncelleyin.
4.  Veritabanı migrasyonlarını uygulayın (EF Core CLI kurulu olmalıdır).
5.  Uygulamayı çalıştırın.

#### API Erişim Bilgileri (Geliştirme Ortamı)

* **HTTP:** http://localhost:5242
* **HTTPS:** https://localhost:7128
* **Swagger Dokümantasyonu:** http://localhost:5242/swagger

### 3. Frontend (Flutter) Kurulumu

1.  **Flutter SDK**'nın kurulu olduğundan emin olun.
2.  `randevu_app` klasörüne gidin.
3.  Uygulamayı çalıştırın.

#### Emülatör / Cihaz Ayarları

* **Android Emülatör:** http://10.0.2.2:5242
* **iOS Simülatör:** localhost

---

### 🔗 Flutter API Base URL Ayarı

Flutter uygulamasının API çağrıları için kullanacağı **`baseUrl`** ayarı:

class ApiConstants {
  // Geliştirme ortamı (Android emülatör IP'si)
  static const String baseUrl = 'http://10.0.2.2:5242'; 

  // Üretim ortamı
  // static const String baseUrl = 'https://api.sirketiniz.com';
}
```
