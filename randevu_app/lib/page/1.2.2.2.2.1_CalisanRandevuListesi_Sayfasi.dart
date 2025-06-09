import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CalisanRandevuListesi extends StatefulWidget {
  final int calisanId;
  
  const CalisanRandevuListesi({
    super.key,
    required this.calisanId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CalisanRandevuListesiState createState() => _CalisanRandevuListesiState();
}

class _CalisanRandevuListesiState extends State<CalisanRandevuListesi> {
  DateTime? _selectedDate;
  List<dynamic> _gunlukRandevular = [];
  bool _isLoading = false;
  final String _apiBaseUrl = "https://localhost:7128"; 

  // Renk Tanımları

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchGunlukRandevular(_selectedDate!);
  }

  Future<void> _fetchGunlukRandevular(DateTime date) async {
    setState(() => _isLoading = true);
    
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await http.get(
        Uri.parse(
          '$_apiBaseUrl/api/Randevu/CalisanRandevularDetayli?calisanId=${widget.calisanId}&tarih=$formattedDate'
        )
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _gunlukRandevular = data;
        });
      } else {
        throw 'Randevular getirilemedi: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.poppins()),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _randevuSil(int randevuId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/api/Randevu/Sil/$randevuId'),
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu başarıyla iptal edildi', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchGunlukRandevular(_selectedDate!);
      } else {
        throw 'Randevu iptal edilemedi: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _randevuOnayla(int randevuId) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/api/Randevu/DurumGuncelle/$randevuId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode('Onaylandı'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu onaylandı', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchGunlukRandevular(_selectedDate!);
      } else {
        throw 'Onaylama başarısız: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _changeDate(int days) {
    final newDate = _selectedDate!.add(Duration(days: days));
    final today = DateTime.now();
    final maxDate = today.add(Duration(days: 6));
    
    if (newDate.isAfter(maxDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Son 7 günü görüntüleyebilirsiniz', 
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }
    
    if (newDate.isBefore(today) && !_isSameDay(newDate, today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geçmiş tarihleri görüntüleyemezsiniz', 
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    setState(() {
      _selectedDate = newDate;
    });
    _fetchGunlukRandevular(newDate);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final today = DateTime.now();
    final maxDate = today.add(Duration(days: 7));

    return Scaffold(
      appBar: AppBar(
        title: Text('Çalışan Randevu Kontrol Sayfesı', style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, size: 30),
                  onPressed: () {
                    if (!_isSameDay(_selectedDate!, today)) {
                      _changeDate(-1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Geçmiş tarihleri görüntüleyemezsiniz', 
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange[700],
                        ),
                      );
                    }
                  },
                ),
                Text(
                  DateFormat('dd MMMM yyyy, EEEE').format(_selectedDate!),
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, size: 30),
                  onPressed: () {
                    if (!_isSameDay(_selectedDate!, maxDate)) {
                      _changeDate(1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('En fazla 7 gün sonrasını görüntüleyebilirsiniz', 
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.orange[700],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _gunlukRandevular.isEmpty
                    ? Center(
                        child: Text(
                          'Bu tarihe ait randevu bulunamadı',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _gunlukRandevular.length,
                        itemBuilder: (context, index) {
                          final randevu = _gunlukRandevular[index];
                          return _buildRandevuCard(randevu, isSmallScreen);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRandevuCard(Map<String, dynamic> randevu, bool isSmallScreen) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${randevu['kullaniciAd']} ${randevu['kullaniciSoyad']}',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(randevu['durum']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    randevu['durum'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'Saat: ${randevu['saat'].toString().substring(0, 5)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.cleaning_services, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'Hizmet: ${randevu['hizmetAd']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  'Ücret: ${randevu['fiyat'].toStringAsFixed(2)}₺',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (randevu['durum'] == 'Onay Bekliyor')
                  ElevatedButton(
                    onPressed: () => _randevuOnayla(randevu['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Onayla',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          randevu['durum'] == 'Onaylandı' ? 'Randevu İptali' : 'Randevu Silme',
                          style: GoogleFonts.poppins(),
                        ),
                        content: Text(
                          randevu['durum'] == 'Onaylandı' 
                            ? 'Bu randevuyu iptal etmek istediğinize emin misiniz?'
                            : 'Bu randevuyu silmek istediğinize emin misiniz?',
                          style: GoogleFonts.poppins(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Vazgeç', style: GoogleFonts.poppins()),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _randevuSil(randevu['id']);
                            },
                            child: Text(
                              randevu['durum'] == 'Onaylandı' ? 'İptal Et' : 'Sil',
                              style: GoogleFonts.poppins(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    randevu['durum'] == 'Onaylandı' ? 'İptal Et' : 'Sil',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String durum) {
    switch (durum.toLowerCase()) {
      case 'onaylandı':
        return Colors.green;
      case 'onay bekliyor':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}