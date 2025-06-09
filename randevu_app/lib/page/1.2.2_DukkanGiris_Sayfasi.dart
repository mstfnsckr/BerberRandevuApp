import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '1.2.1_DukkanKayit_Sayfasi.dart';
import '1.2.2.1_Dukkan_SifreYenileme.dart';
import '1.2.2.2_DukkanAna_Sayfasi.dart';

class DukkanGirisSayfasi extends StatefulWidget {
  
  const DukkanGirisSayfasi({super.key});

  @override
  _DukkanGirisSayfasiState createState() => _DukkanGirisSayfasiState();
}

class _DukkanGirisSayfasiState extends State<DukkanGirisSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _dukkanAdiController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _sifreGizle = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _dukkanAdiController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final res = await http.post(
        Uri.parse('https://localhost:7128/api/Dukkan/giris'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dukkanAdi': _dukkanAdiController.text,
          'sifre': _sifreController.text,
        }),
      );

      final response = json.decode(res.body);
      
      if (res.statusCode == 200) {
        final int dukkanId = response['dukkanId'];
        _showSnackBar('Giriş başarılı!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DukkanSayfasi(dukkanId: dukkanId),
          ),
        );
      } else {
        _showSnackBar(response['message'] ?? 'Dükkan adı veya şifre hatalı!', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Sunucuya bağlanılamadı: ${e.toString()}', Colors.orange);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Dükkan Girişi', style: GoogleFonts.poppins()),
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
                  Icon(Icons.storefront_outlined, 
                    size: 120,
                    color: Colors.deepPurple[700],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dükkan Girişi',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[800],
                    ),
                  ),
                  Text(
                    'Mağaza yönetim paneline erişim',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Giriş Formu
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Dükkan Adı
                    Container(
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
                        controller: _dukkanAdiController,
                        decoration: InputDecoration(
                          labelText: 'Dükkan Adı',
                          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.store_mall_directory, 
                            color: Colors.deepPurple[400],
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, 
                            horizontal: 20,
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Dükkan adı giriniz' : null,
                        style: GoogleFonts.poppins(),
                      ),
                    ),

                    // Şifre
                    Container(
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
                        controller: _sifreController,
                        obscureText: _sifreGizle,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.lock_outline,
                            color: Colors.deepPurple[400],
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _sifreGizle ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[500],
                            ),
                            onPressed: () => setState(() => _sifreGizle = !_sifreGizle),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, 
                            horizontal: 20,
                          ),
                        ),
                        validator: (v) => v!.length < 6 ? 'Şifre en az 6 karakter olmalı' : null,
                        style: GoogleFonts.poppins(),
                      ),
                    ),

                    // Şifremi Unuttum
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DukkanSifreYenilemeSayfasi(),
                          ),
                        ),
                        child: Text(
                          'Şifremi unuttum?',
                          style: GoogleFonts.poppins(
                            color: Colors.deepPurple[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Giriş Yap Butonu
                    Container(
                      height: 56,
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
                        onPressed: _isLoading ? null : _girisYap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                'DÜKKANA GİRİŞ YAP',
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
              const SizedBox(height: 30),

              // Kayıt Ol Linki
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Dükkanınız yok mu?',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DukkanKayitSayfasi(),
                      ),
                    ),
                    child: Text(
                      'Hemen Kayıt Ol',
                      style: GoogleFonts.poppins(
                        color: Colors.deepPurple[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}