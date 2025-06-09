import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:randevu_app/page/1.2.2.2.2_DukkanCalisanListesi_Sayfasi.dart';
import 'dart:convert';
import '1.2.2.2.1_DukkanCalisanKayit_Sayfasi.dart';

class Dukkan {
  final int id;
  final String? dukkanAdi;
  final String? vergiKimlikNo;
  final String? telefon;
  final String? ePosta;
  final Konum? konum;
  final bool durum;
  final List<Calisan> calisanlar;

  Dukkan({
    required this.id,
    this.dukkanAdi,
    this.vergiKimlikNo,
    this.telefon,
    this.ePosta,
    this.konum,
    required this.durum,
    required this.calisanlar,
  });

  factory Dukkan.fromJson(Map<String, dynamic> json) {
    var calisanlarList = json['calisanlar'] as List? ?? [];
    List<Calisan> calisanlar = calisanlarList.map((i) => Calisan.fromJson(i)).toList();

    return Dukkan(
      id: json['id'] ?? 0,
      dukkanAdi: json['dukkanAdi'],
      vergiKimlikNo: json['vergiKimlikNo'],
      telefon: json['telefon'],
      ePosta: json['ePosta'],
      konum: json['konum'] != null ? Konum.fromJson(json['konum']) : null,
      durum: json['durum'] ?? false,
      calisanlar: calisanlar,
    );
  }
}

class Konum {
  final double? latitude;
  final double? longitude;

  Konum({this.latitude, this.longitude});

  factory Konum.fromJson(Map<String, dynamic> json) {
    return Konum(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  @override
  String toString() {
    return '${latitude?.toStringAsFixed(6) ?? "N/A"}, ${longitude?.toStringAsFixed(6) ?? "N/A"}';
  }
}

class Calisan {
  final int id;
  final String? ad;
  final String? soyad;
  final String? tc;
  final int dukkanId;
  final List<HizmetBedel> hizmetBedeller;

  Calisan({
    required this.id,
    this.ad,
    this.soyad,
    this.tc,
    required this.dukkanId,
    required this.hizmetBedeller,
  });

  factory Calisan.fromJson(Map<String, dynamic> json) {
    var hizmetBedellerList = json['hizmetBedeller'] as List? ?? [];
    List<HizmetBedel> hizmetBedeller = hizmetBedellerList.map((i) => HizmetBedel.fromJson(i)).toList();

    return Calisan(
      id: json['id'] ?? 0,
      ad: json['ad'],
      soyad: json['soyad'],
      tc: json['tC'],
      dukkanId: json['dukkanId'] ?? 0,
      hizmetBedeller: hizmetBedeller,
    );
  }
}

class HizmetBedel {
  final int id;
  final String? hizmetAd;
  final double fiyat;

  HizmetBedel({
    required this.id,
    this.hizmetAd,
    required this.fiyat,
  });

  factory HizmetBedel.fromJson(Map<String, dynamic> json) {
    return HizmetBedel(
      id: json['id'] ?? 0,
      hizmetAd: json['hizmetAd'],
      fiyat: (json['fiyat'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DukkanSayfasi extends StatefulWidget {
  final int dukkanId;

  const DukkanSayfasi({super.key, required this.dukkanId});

  @override
  State<DukkanSayfasi> createState() => _DukkanSayfasiState();
}

class _DukkanSayfasiState extends State<DukkanSayfasi> {
  late Future<Dukkan> _futureDukkan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _futureDukkan = _fetchDukkan();
  }

  Future<Dukkan> _fetchDukkan() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://localhost:7128/api/Dukkan/${widget.dukkanId}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Dukkan.fromJson(jsonData);
      } else {
        throw Exception('Dükkan bilgileri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Dükkan bilgileri alınırken hata oluştu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hizmetDurumuGuncelle(bool yeniDurum) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('https://localhost:7128/api/Dukkan/durum-guncelle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dukkanId': widget.dukkanId,
          'yeniDurum': yeniDurum,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final yeniDukkan = await _fetchDukkan();
          setState(() {
            _futureDukkan = Future.value(yeniDukkan);
          });
          _showSnackBar(
            yeniDurum ? 'Hizmet başlatıldı 🚀' : 'Hizmet durduruldu ⛔',
            yeniDurum ? Colors.green : Colors.orange,
          );
        } else {
          _showSnackBar('Güncelleme başarısız: ${responseData['message']}', Colors.red);
        }
      } else {
        _showSnackBar('Sunucu hatası: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Hata: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dukkanSil() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dükkanı Sil'),
        content: const Text('Bu dükkanı ve tüm çalışanlarını, randevularını silmek istediğinize emin misiniz? Bu işlem geri alınamaz!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('https://localhost:7128/api/Dukkan/sil/${widget.dukkanId}'),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Dükkan başarıyla silindi', Colors.green);
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar('Silme işlemi başarısız: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Hata: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _bilgiSatiri(IconData icon, String baslik, String? deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baslik,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deger ?? 'Belirtilmemiş',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: renk,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 24),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(isActive ? 1.0 : 0.6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: isActive ? onPressed : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dükkan Sayfası', style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<Dukkan>(
            future: _futureDukkan,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.red),
                      const SizedBox(height: 20),
                      Text('Hata: ${snapshot.error}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _futureDukkan = _fetchDukkan();
                          });
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('Dükkan bilgileri bulunamadı'));
              }

              final dukkan = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: const Icon(Icons.store, color: Colors.deepPurple),
                                  radius: 30,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              dukkan.dukkanAdi ?? 'İsimsiz Dükkan',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: _dukkanSil,
                                            tooltip: 'Dükkanı Sil',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              dukkan.durum ? 'Aktif' : 'Pasif',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            backgroundColor: dukkan.durum
                                                ? Colors.green
                                                : Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: Icon(
                                              dukkan.durum 
                                                ? Icons.toggle_on 
                                                : Icons.toggle_off,
                                              color: dukkan.durum ? Colors.green : Colors.red,
                                              size: 40,
                                            ),
                                            onPressed: () => _hizmetDurumuGuncelle(!dukkan.durum),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            _bilgiSatiri(Icons.assignment_ind, 'Vergi No', dukkan.vergiKimlikNo),
                            _bilgiSatiri(Icons.phone, 'Telefon', dukkan.telefon),
                            _bilgiSatiri(Icons.email, 'E-Posta', dukkan.ePosta),
                            _bilgiSatiri(Icons.location_on, 'Konum', dukkan.konum?.toString()),
                            const SizedBox(height: 10),
                            Text(
                              'Çalışan Sayısı: ${dukkan.calisanlar.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.person_add,
                          text: 'Çalışan Ekle',
                          color: Colors.deepPurple,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DukkanCalisanKayit(
                                  dukkanId: widget.dukkanId,
                                ),
                              ),
                            ).then((_) {
                              setState(() {
                                _futureDukkan = _fetchDukkan();
                              });
                            });
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.people,
                          text: 'Çalışan Listesi',
                          color: Colors.blue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DukkanCalisanListesi(
                                  dukkanId: widget.dukkanId,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}