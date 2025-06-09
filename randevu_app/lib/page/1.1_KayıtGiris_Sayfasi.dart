import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '1.1.1_KullaniciKayıt_Sayfasi.dart';
import '1.1.2_KullaniciGiris_Sayfasi.dart';
import '1.2.1_DukkanKayit_Sayfasi.dart';
import '1.2.2_DukkanGiris_Sayfasi.dart';
import '1.3_AdminGiris_Sayfasi.dart';

class KullaniciKGPage extends StatelessWidget {
  const KullaniciKGPage({super.key});

  void _showAccountTypeDialog(BuildContext context, bool isRegister) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRegister ? 'Kayıt Türü Seçin' : 'Giriş Türü Seçin',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAccountTypeButton(
              context,
              'Kullanıcı',
              Icons.person,
              isRegister ? const KayitPage() : const GirisPage(),
            ),
            const SizedBox(height: 16),
            _buildAccountTypeButton(
              context,
              'Dükkan',
              Icons.store,
              isRegister ? const DukkanKayitSayfasi() : const DukkanGirisSayfasi(),
            ),
            if (!isRegister) ...[
              const SizedBox(height: 16),
              _buildAccountTypeButton(
                context,
                'Admin',
                Icons.admin_panel_settings,
                const AdminGirisSayfasi(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeButton(
      BuildContext context, String label, IconData icon, Widget page) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple[50],
        foregroundColor: Colors.deepPurple[800],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/Randevu_Logo.jpg',
                  height: 140,
                ),
                const SizedBox(height: 30),

                // Uygulama İsmi
                Text(
                  'Randevu App',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Çevrendeki kuaförleri hızlıca bul randevu al.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Giriş Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showAccountTypeDialog(context, false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepPurple[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Giriş Yap',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kayıt Ol Butonu
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showAccountTypeDialog(context, true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.deepPurple[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Kayıt Ol',
                      style: GoogleFonts.poppins(
                        color: Colors.deepPurple[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}