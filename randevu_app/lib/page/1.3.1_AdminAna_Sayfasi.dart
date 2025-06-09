import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminSayfasi extends StatefulWidget {
  const AdminSayfasi({super.key});

  @override
  State<AdminSayfasi> createState() => _AdminSayfasiState();
}

class _AdminSayfasiState extends State<AdminSayfasi> {
  List<dynamic> _onaysizDukkanlar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOnaysizDukkanlar();
  }

  Future<void> _fetchOnaysizDukkanlar() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://localhost:7128/api/Dukkan/onaysiz-dukkanlar'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _onaysizDukkanlar = jsonDecode(response.body);
        });
      }
    } catch (e) {
      _showSnackBar('Veriler alınırken hata oluştu', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dukkanOnayla(int dukkanId) async {
    try {
      final response = await http.put(
        Uri.parse('https://localhost:7128/api/Dukkan/onayla/$dukkanId'),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Dükkan başarıyla onaylandı', Colors.green);
        _fetchOnaysizDukkanlar();
      } else {
        _showSnackBar('Onaylama işlemi başarısız', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Sunucu hatası: $e', Colors.orange);
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

  Widget _buildDukkanCard(Map<String, dynamic> dukkan) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.deepPurple[400], size: 24),
                const SizedBox(width: 8),
                Text(
                  dukkan['dukkanAdi'],
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.confirmation_number, 'Vergi No: ${dukkan['vergiKimlikNo']}'),
            _buildInfoRow(Icons.phone, 'Telefon: ${dukkan['telefon']}'),
            _buildInfoRow(Icons.email, 'Email: ${dukkan['ePosta']}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _dukkanOnayla(dukkan['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Onayla',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontSize: 14,
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
      appBar: AppBar(
        title: Text('Admin Paneli', style: GoogleFonts.poppins()),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.deepPurple[800]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurple,
                ),
              )
            : _onaysizDukkanlar.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Onay bekleyen dükkan bulunmamaktadır',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchOnaysizDukkanlar,
                    color: Colors.deepPurple,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _onaysizDukkanlar.length,
                      itemBuilder: (context, index) {
                        final dukkan = _onaysizDukkanlar[index];
                        return _buildDukkanCard(dukkan);
                      },
                    ),
                  ),
      ),
    );
  }
}