import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:randevu_app/page/1.1.2.2.1_Dukkan_Bul.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnaSayfa extends StatefulWidget {
  final String? ePosta;
  const AnaSayfa({super.key, this.ePosta});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<dynamic> randevular = [];
  int? kullaniciId;
  String? kullaniciAd;
  String? kullaniciSoyad;
  bool isLoading = false;
  bool isRandevuLoading = false;
  String errorMessage = '';
  bool showAllAppointments = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.ePosta != null) {
      await _fetchUserInfo(widget.ePosta!);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      showAllAppointments = false;
    });
    if (widget.ePosta != null && kullaniciId != null) {
      await _fetchRandevular(kullaniciId!);
    }
  }

  Future<void> _fetchUserInfo(String eposta) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse('https://localhost:7128/api/Kullanici/GetIdByEmail?eposta=$eposta');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          kullaniciId = data['id'];
          kullaniciAd = data['ad'];
          kullaniciSoyad = data['soyad'];
          isLoading = false;
        });
        await _fetchRandevular(data['id']);
      } else if (response.statusCode == 404) {
        setState(() {
          isLoading = false;
          errorMessage = 'Kullanıcı bulunamadı';
        });
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Kullanıcı bilgileri alınırken hata oluştu: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchRandevular(int kullaniciId) async {
    setState(() {
      isRandevuLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse('https://localhost:7128/api/Randevu/KullaniciRandevular/$kullaniciId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          randevular = data;
          isRandevuLoading = false;
        });
      } else {
        throw Exception('Randevular alınırken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isRandevuLoading = false;
        errorMessage = 'Randevular alınırken hata oluştu: ${e.toString()}';
      });
    }
  }

  String _formatTarih(DateTime tarih) {
    final days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
    final dayName = days[tarih.weekday - 1];
    return '$dayName, ${tarih.day}.${tarih.month}.${tarih.year}';
  }

  String _formatSaat(String saat) {
    return saat.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final visibleAppointments = showAllAppointments ? randevular : (randevular.length > 2 ? randevular.sublist(0, 2) : randevular);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Ana Sayfa', style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.deepPurple,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kullanıcı Hoş Geldiniz Bölümü
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade50, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 28,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoş Geldiniz',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kullaniciAd != null && kullaniciSoyad != null 
                                    ? '$kullaniciAd $kullaniciSoyad'
                                    : widget.ePosta ?? 'Misafir Kullanıcı',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurple.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        if (!isSmallScreen)
                          Icon(
                            Icons.waving_hand,
                            color: Colors.amber.shade600,
                            size: 28,
                          ),
                      ],
                    ),
                    if (widget.ePosta != null) ...[
                      const SizedBox(height: 12),
                      if (isLoading)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                        )
                      else if (errorMessage.isNotEmpty)
                        Text(
                          errorMessage,
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Randevu Listesi Başlığı - DÜZELTİLMİŞ KISIM
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Yaklaşan Randevular',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (randevular.isNotEmpty)
                          Flexible(
                            child: Text(
                              'Toplam ${randevular.length} randevu',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Randevu Listesi
              if (isRandevuLoading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    errorMessage,
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                )
              else if (randevular.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Henüz randevunuz bulunmamaktadır.',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ...visibleAppointments.map((randevu) => _buildRandevuCard(randevu, isSmallScreen)),
                    if (randevular.length > 2 && !showAllAppointments)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showAllAppointments = true;
                          });
                        },
                        child: Text(
                          'Tüm randevuları göster (${randevular.length - 2} tane daha)',
                          style: GoogleFonts.poppins(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DukkanBulSayfasi(
                kullaniciId: kullaniciId, 
              ),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.map, color: Colors.white),
        tooltip: 'Dükkan Bul',
      ),
    );
  }

  Widget _buildRandevuCard(Map<String, dynamic> randevu, bool isSmallScreen) {
    final statusColor = _getStatusColor(randevu['durum']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  randevu['dukkanAdi'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  randevu['durum'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Tarih ve Saat
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTarih(DateTime.parse(randevu['tarih'])),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _formatSaat(randevu['saat']),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Çalışan ve Hizmet
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  randevu['calisanAdi'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.work,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  randevu['hizmetAdi'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Onaylandı':
        return Colors.green.shade700;
      case 'Onay Bekliyor':
        return Colors.orange.shade700;
      case 'İptal Edildi':
        return Colors.red.shade700;
      case 'Tamamlandı':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}