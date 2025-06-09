import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:randevu_app/page/1.1.2.2.1.1_RandevuSayfas%C4%B1.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;

class Dukkan {
  final int id;
  final String dukkanAdi;
  final String vergiKimlikNo;
  final String telefon;
  final String eposta;
  final LatLng konum;
  final double mesafe;
  final bool durum;
  final List<Calisan> calisanlar;

  Dukkan({
    required this.id,
    required this.dukkanAdi,
    required this.vergiKimlikNo,
    required this.telefon,
    required this.eposta,
    required this.konum,
    required this.mesafe,
    required this.durum,
    required this.calisanlar,
  });

  factory Dukkan.fromJson(Map<String, dynamic> json) {
    return Dukkan(
      id: json['id'],
      dukkanAdi: json['dukkanAdi'] ?? 'İsimsiz Dükkan',
      vergiKimlikNo: json['vergiKimlikNo'] ?? '',
      telefon: json['telefon'] ?? '',
      eposta: json['ePosta'] ?? '',
      konum: LatLng(
        (json['konum']['latitude'] as num?)?.toDouble() ?? 0.0,
        (json['konum']['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      mesafe: 0.0,
      durum: json['durum'] ?? false,
      calisanlar: (json['calisanlar'] as List<dynamic>?)
          ?.map((c) => Calisan.fromJson(c))
          .toList() ?? [],
    );
  }
}

class Calisan {
  final int id;
  final String ad;
  final String soyad;
  final String tc;
  final int dukkanId;
  final List<HizmetBedel> hizmetBedeller;

  Calisan({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.tc,
    required this.dukkanId,
    required this.hizmetBedeller,
  });

  factory Calisan.fromJson(Map<String, dynamic> json) {
    return Calisan(
      id: json['id'],
      ad: json['ad'] ?? '',
      soyad: json['soyad'] ?? '',
      tc: json['tC'] ?? '',
      dukkanId: json['dukkanId'] ?? 0,
      hizmetBedeller: (json['hizmetBedeller'] as List<dynamic>?)
          ?.map((hb) => HizmetBedel.fromJson(hb))
          .toList() ?? [],
    );
  }

  String get tamAdi => '$ad $soyad';
}

class HizmetBedel {
  final int id;
  final Hizmet hizmet;
  final double fiyat;
  final int randevuSayisi;

  HizmetBedel({
    required this.id,
    required this.hizmet,
    required this.fiyat,
    required this.randevuSayisi,
  });

  factory HizmetBedel.fromJson(Map<String, dynamic> json) {
    return HizmetBedel(
      id: json['id'],
      hizmet: Hizmet.fromJson(json['hizmet']),
      fiyat: (json['fiyat'] as num).toDouble(),
      randevuSayisi: json['randevuSayisi'] ?? 0,
    );
  }
}

class Hizmet {
  final int id;
  final String ad;

  Hizmet({
    required this.id,
    required this.ad,
  });

  factory Hizmet.fromJson(Map<String, dynamic> json) {
    return Hizmet(
      id: json['id'],
      ad: json['ad'] ?? '',
    );
  }
}

class DukkanBulSayfasi extends StatefulWidget {
  final int? kullaniciId;
  const DukkanBulSayfasi({super.key, this.kullaniciId});

  @override
  State<DukkanBulSayfasi> createState() => _DukkanBulSayfasiState();
}

class _DukkanBulSayfasiState extends State<DukkanBulSayfasi> {
  Position? _currentPosition;
  List<Dukkan> _dukkanlar = [];
  bool _loading = true;
  final MapController _mapController = MapController();
  bool _showList = false;
  Dukkan? _selectedDukkan;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await _showLocationPermissionDialog();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = position);
      await _fetchDukkanlar();
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackbar('Konum bilgisi alınamadı: ${e.toString()}');
    }
  }

  Future<void> _showLocationServiceDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum Servisleri Kapalı'),
        content: const Text('Uygulamanın düzgün çalışması için konum servislerini açmanız gerekiyor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'refresh'),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.pop(context, 'refresh');
            },
            child: const Text('Ayarlar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationPermissionDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konum İzni Gerekli'),
        content: const Text('Bu uygulamanın konum bilgisine erişmesine izin vermeniz gerekiyor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'refresh'),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context, 'refresh');
            },
            child: const Text('Ayarlar'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  double _calculateDistance(LatLng konum) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      konum.latitude,
      konum.longitude,
    ) / 1000;
  }

  Future<void> _fetchDukkanlar() async {
    try {
      setState(() => _loading = true);
      final response = await http.get(
        Uri.parse('https://localhost:7128/api/Dukkan/aktif-dukkanlar'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _dukkanlar = data.map((dukkan) {
            final dukkanObj = Dukkan.fromJson(dukkan);
            return Dukkan(
              id: dukkanObj.id,
              dukkanAdi: dukkanObj.dukkanAdi,
              vergiKimlikNo: dukkanObj.vergiKimlikNo,
              telefon: dukkanObj.telefon,
              eposta: dukkanObj.eposta,
              konum: dukkanObj.konum,
              mesafe: _calculateDistance(dukkanObj.konum),
              durum: dukkanObj.durum,
              calisanlar: dukkanObj.calisanlar,
            );
          }).where((dukkan) => dukkan.durum).toList(); // Burada zaten durum=true olanlar filtreleniyor

          _dukkanlar.sort((a, b) => a.mesafe.compareTo(b.mesafe));
          _loading = false;
        });
      } else {
        throw 'Sunucu hatası: ${response.statusCode}';
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackbar('Dükkanlar yüklenirken hata: $e');
    }
  }

  void _zoomToDukkan(Dukkan dukkan) {
    _mapController.move(dukkan.konum, 14.0);
    setState(() {
      _selectedDukkan = dukkan;
      _showList = false;
    });
  }

  List<Dukkan> get _filteredDukkanar {
    if (_searchQuery.isEmpty) return _dukkanlar;
    return _dukkanlar.where((dukkan) =>
        dukkan.dukkanAdi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        dukkan.telefon.contains(_searchQuery) ||
        dukkan.eposta.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        dukkan.calisanlar.any((calisan) =>
            calisan.tamAdi.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  Future<void> _openNavigationApp() async {
    if (_selectedDukkan == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum bilgisi bulunamadı')),
      );
      return;
    }

    final String mapsUrl = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&destination=${_selectedDukkan!.konum.latitude},${_selectedDukkan!.konum.longitude}'
        '&travelmode=driving';

    if (kIsWeb) {
      html.window.open(mapsUrl, '_blank');
      return;
    }

    final Uri url = Uri.parse(mapsUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Harita uygulaması açılamadı';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _navigateToRandevuPage(int calisanId, int dukkanId, List<HizmetBedel> hizmetBedeller) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RandevuSayfasi(
          calisanId: calisanId,
          dukkanId: dukkanId,
          hizmetBedeller: hizmetBedeller,
          kullaniciId: widget.kullaniciId, 
        ),
      ),
    );

    // Eğer randevu oluşturulduysa (result true ise) verileri yenile
    if (result == true) {
      await _fetchDukkanlar();
    }
  }

  Widget _buildDukkanDetay(Dukkan dukkan) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dukkan.dukkanAdi,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedDukkan = null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, dukkan.telefon),
            _buildInfoRow(Icons.email, dukkan.eposta),
            _buildInfoRow(Icons.location_on, '${dukkan.mesafe.toStringAsFixed(1)} km uzakta'),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            const Text(
              'Çalışanlar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            
            ...dukkan.calisanlar.map((calisan) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          calisan.tamAdi,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _navigateToRandevuPage(
                          calisan.id, 
                          dukkan.id,
                          calisan.hizmetBedeller,
                        ),
                        child: const Text(
                          'Randevu Al',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (calisan.hizmetBedeller.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hizmetler:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          ...calisan.hizmetBedeller.map((hb) => Text(
                            '• ${hb.hizmet.ad} - ${hb.fiyat.toStringAsFixed(2)}₺ (${hb.randevuSayisi} randevu)',
                            style: const TextStyle(fontSize: 12),
                          )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )),
            
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _openNavigationApp,
                child: const Text(
                  'YOL TARİFİ AL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Dükkan veya çalışan ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildDukkanList() {
    final filteredDukkanlar = _filteredDukkanar;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.list, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      'Yakındaki Dükkanlar (${filteredDukkanlar.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showList = false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filteredDukkanlar.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Sonuç bulunamadı',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.separated(
                padding: const EdgeInsets.all(0),
                itemCount: filteredDukkanlar.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final dukkan = filteredDukkanlar[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.store,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(
                      dukkan.dukkanAdi,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${dukkan.mesafe.toStringAsFixed(1)} km • ${dukkan.calisanlar.length} çalışan',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _zoomToDukkan(dukkan),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dükkan Bul Sayfası', style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Konum bilgisi alınamadı',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 12.0,
                        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 50,
                              height: 50,
                              builder: (ctx) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            ),
                            ..._dukkanlar.map((dukkan) => Marker(
                                  point: dukkan.konum,
                                  width: 50,
                                  height: 50,
                                  builder: (ctx) => GestureDetector(
                                    onTap: () => _zoomToDukkan(dukkan),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: _selectedDukkan?.id == dukkan.id
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.green.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.store,
                                        color: _selectedDukkan?.id == dukkan.id
                                            ? Colors.red
                                            : Colors.green,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ],
                    ),
                    
                    if (_showList && _selectedDukkan == null) _buildDukkanList(),
                    
                    if (!_showList && _selectedDukkan == null) _buildSearchBar(),
                    
                    if (_selectedDukkan != null)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: _buildDukkanDetay(_selectedDukkan!),
                      ),
                    
                    if (_selectedDukkan == null) ...[
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: FloatingActionButton(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                          onPressed: () {
                            _mapController.move(
                              LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              12.0,
                            );
                            setState(() => _selectedDukkan = null);
                          },
                        ),
                      ),
                      
                      Positioned(
                        bottom: 80,
                        right: 20,
                        child: FloatingActionButton(
                          backgroundColor: Colors.white,
                          child: Icon(
                            _showList ? Icons.map : Icons.list,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () => setState(() => _showList = !_showList),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}