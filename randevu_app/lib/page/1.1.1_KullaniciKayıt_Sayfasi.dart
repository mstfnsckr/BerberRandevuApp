import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import '1.1.2_KullaniciGiris_Sayfasi.dart';

class KayitPage extends StatefulWidget {
  const KayitPage({super.key});

  @override
  _KayitPageState createState() => _KayitPageState();
}

class _KayitPageState extends State<KayitPage> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _ePostaController = TextEditingController();
  final _sifreController = TextEditingController();
  final _dogumTarihiController = TextEditingController();
  final _kodController = TextEditingController();
  final _tcController = TextEditingController();

  bool _sifreGizle = true;
  bool _sozlesmeKabul = false;
  bool _emailVerified = false;
  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _ePostaController.dispose();
    _sifreController.dispose();
    _dogumTarihiController.dispose();
    _kodController.dispose();
    _tcController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.deepPurple,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dogumTarihiController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _sendCode() async {
    if (!EmailValidator.validate(_ePostaController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen geçerli bir e‑posta girin', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://localhost:7128/api/Kullanici/kodgonderkayit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ePosta': _ePostaController.text}),
      );
      if (res.statusCode == 200) {
        setState(() {
          _codeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doğrulama kodu gönderildi.', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        final msg = json.decode(res.body)['message'] ?? 'Hata oluştu';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sunucu hatası', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_kodController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('6 haneli kod girin', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://localhost:7128/api/Kullanici/koddogrulakayit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ePosta': _ePostaController.text,
          'kod': _kodController.text,
        }),
      );
      if (res.statusCode == 200) {
        setState(() {
          _emailVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E‑posta doğrulandı ✅', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        final msg = json.decode(res.body)['message'] ?? 'Kod hatalı';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sunucu hatası', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _kayitOl() async {
    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Önce e‑posta doğrulaması yapın', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_sozlesmeKabul) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sözleşmeyi kabul edin', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://localhost:7128/api/Kullanici/kayit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ad': _adController.text,
          'soyad': _soyadController.text,
          'telefon': _telefonController.text,
          'ePosta': _ePostaController.text,
          'sifre': _sifreController.text,
          'dogumTarihi': _dogumTarihiController.text,
          'tc': _tcController.text,
          'randevular' : [],
        }),
      );
      if (res.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GirisPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt başarılı!', style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        final msg = json.decode(res.body)['message'] ?? 'Kayıt hatası';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sunucu hatası', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSozlesme() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kullanıcı Sözleşmesi',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[800],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSozlesmeItem(
                        title: '1. Gizlilik Politikası',
                        content: 'Kişisel verileriniz KVKK kapsamında korunur.',
                      ),
                      _buildSozlesmeItem(
                        title: '2. Kullanım Koşulları',
                        content: 'Yasalara aykırı içerik paylaşmayınız.',
                      ),
                      _buildSozlesmeItem(
                        title: '3. Sorumluluklar',
                        content: 'Şifrenizi güvenli tutmak sizin sorumluluğunuzdadır.',
                      ),
                      _buildSozlesmeItem(
                        title: '4. Hizmet Şartları',
                        content: 'Yöneticiler hizmeti sonlandırabilir.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Kapat',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSozlesmeItem({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
        onTap: onTap,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.deepPurple[400]),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Hesap Oluştur', style: GoogleFonts.poppins()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ve Başlık
              Column(
                children: [
                  Image.asset(
                    'assets/Randevu_Logo.jpg',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hesap Oluştur',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[800],
                    ),
                  ),
                  Text(
                    'Bilgilerinizi girin ve kayıt olun',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Kayıt Formu
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Ad ve Soyad
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _adController,
                            label: 'Ad',
                            icon: Icons.person,
                            validator: (v) => v!.isEmpty ? 'Ad girin' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            controller: _soyadController,
                            label: 'Soyad',
                            icon: Icons.person_outline,
                            validator: (v) => v!.isEmpty ? 'Soyad girin' : null,
                          ),
                        ),
                      ],
                    ),

                    // Doğum Tarihi
                    _buildInputField(
                      controller: _dogumTarihiController,
                      label: 'Doğum Tarihi',
                      icon: Icons.calendar_today,
                      validator: (v) => v!.isEmpty ? 'Tarih seçin' : null,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_month, color: Colors.deepPurple[400]),
                        onPressed: () => _selectDate(context),
                      ),
                      onTap: () => _selectDate(context),
                    ),

                    // Telefon
                    _buildInputField(
                      controller: _telefonController,
                      label: 'Telefon',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Telefon girin';
                        if (v.length < 10) return 'Geçerli numara';
                        return null;
                      },
                    ),

                    // TC Kimlik No
                    _buildInputField(
                      controller: _tcController,
                      label: 'TC Kimlik No',
                      icon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length != 11) {
                          return 'Geçerli bir TC Kimlik No girin';
                        }
                        return null;
                      },
                    ),

                    // E-posta ve Kod Gönder
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildInputField(
                            controller: _ePostaController,
                            label: 'E-posta',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_emailVerified,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'E‑posta girin';
                              if (!EmailValidator.validate(v)) return 'Geçerli e‑posta';
                              return null;
                            },
                            suffixIcon: _emailVerified
                                ? Icon(Icons.check_circle, color: Colors.green[400])
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: (_codeSent || _emailVerified || _isLoading) 
                                  ? null 
                                  : _sendCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Kod Gönder',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Kod Doğrulama
                    if (_codeSent && !_emailVerified) ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildInputField(
                              controller: _kodController,
                              label: 'Doğrulama Kodu',
                              icon: Icons.lock_outline,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _verifyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Doğrula',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Şifre
                    _buildInputField(
                      controller: _sifreController,
                      label: 'Şifre',
                      icon: Icons.lock,
                      obscureText: _sifreGizle,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Şifre girin';
                        if (v.length < 6) return 'En az 6 karakter';
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sifreGizle ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[500],
                        ),
                        onPressed: () => setState(() => _sifreGizle = !_sifreGizle),
                      ),
                    ),

                    // Sözleşme Onayı
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _sozlesmeKabul,
                              onChanged: (v) => setState(() => _sozlesmeKabul = v!),
                              activeColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showSozlesme,
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[800],
                                      fontSize: 13,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Kullanıcı sözleşmesini '),
                                      TextSpan(
                                        text: 'okudum',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          color: Colors.deepPurple[600],
                                        ),
                                      ),
                                      const TextSpan(text: ' ve '),
                                      TextSpan(
                                        text: 'kabul ediyorum',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          color: Colors.deepPurple[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Kayıt Ol Butonu
                    Container(
                      height: 56,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple[700]!,
                            Colors.deepPurple[500]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _kayitOl,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'KAYIT OL',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Zaten hesabınız var mı?
              Container(
                margin: const EdgeInsets.only(top: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Zaten hesabınız var mı?',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const GirisPage()),
                      ),
                      child: Text(
                        'Giriş Yap',
                        style: GoogleFonts.poppins(
                          color: Colors.deepPurple[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}