import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class DukkanKayitSayfasi extends StatefulWidget {
  const DukkanKayitSayfasi({super.key});

  @override
  _DukkanKayitSayfasiState createState() => _DukkanKayitSayfasiState();
}

class _DukkanKayitSayfasiState extends State<DukkanKayitSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _dukkanAdiController = TextEditingController();
  final _vergiKimlikNoController = TextEditingController();
  final _telefonController = TextEditingController();
  final _ePostaController = TextEditingController();
  final _sifreController = TextEditingController();
  final _konumController = TextEditingController();
  final _kodController = TextEditingController();

  bool _sifreGizle = true;
  bool _sozlesmeKabul = false;
  bool _emailVerified = false;
  bool _codeSent = false;
  bool _isLoading = false;
  
  LatLng? _selectedLocation;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      _showError('Konum alınamadı. Lütfen tekrar deneyin');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Konum servisleri kapalı');
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      _showError('Konum izinleri kalıcı olarak reddedildi');
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _openMapPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: _currentPosition != null 
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : const LatLng(41.0082, 28.9784),
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
      _konumController.text = '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
    }
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

  Future<void> _sendCode() async {
    if (!EmailValidator.validate(_ePostaController.text)) {
      _showError('Lütfen geçerli bir e‑posta girin');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://localhost:7128/api/Dukkan/kodgonderkayit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ePosta': _ePostaController.text}),
      );
      if (res.statusCode == 200) {
        setState(() => _codeSent = true);
        _showSuccess('Doğrulama kodu gönderildi.');
      } else {
        final msg = json.decode(res.body)['message'] ?? 'Hata oluştu';
        _showError(msg);
      }
    } catch (e) {
      _showError('Sunucu hatası');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_kodController.text.length != 6) {
      _showError('6 haneli kod girin');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://localhost:7128/api/Dukkan/koddogrulakayit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ePosta': _ePostaController.text,
          'kod': _kodController.text,
        }),
      );
      if (res.statusCode == 200) {
        setState(() => _emailVerified = true);
        _showSuccess('E‑posta doğrulandı ✅');
      } else {
        final msg = json.decode(res.body)['message'] ?? 'Kod hatalı';
        _showError(msg);
      }
    } catch (e) {
      _showError('Doğrulama işlemi başarısız');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _kayitOl() async {
    if (!_emailVerified) {
      _showError('Önce e‑posta doğrulaması yapın');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_sozlesmeKabul) {
      _showError('Sözleşmeyi kabul edin');
      return;
    }
    if (_selectedLocation == null) {
      _showError('Lütfen konum seçin');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://localhost:7128/api/Dukkan/kayit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dukkanAdi': _dukkanAdiController.text,
          'vergiKimlikNo': _vergiKimlikNoController.text,
          'telefon': _telefonController.text,
          'ePosta': _ePostaController.text,
          'konum': _konumController.text,
          'sifre': _sifreController.text,
          'durum': true,
          'calisanlar': [],
        }),
      );
      if (res.statusCode == 200) {
        Navigator.pop(context);
        _showSuccess('Dükkan kaydı başarılı!');
      } else {
        final msg = json.decode(res.body)['message'] ?? 'Kayıt hatası';
        _showError(msg);
      }
    } catch (e) {
      _showError('Sunucu hatası');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Dükkan Kayıt', style: GoogleFonts.poppins()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dükkan Bilgileri
              Text(
                'Dükkan Bilgileri',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[800],
                ),
              ),
              const SizedBox(height: 20),
              
              _buildInputField(
                controller: _dukkanAdiController,
                label: 'Dükkan Adı',
                icon: Icons.store,
                validator: (v) => v!.isEmpty ? 'Dükkan adı girin' : null,
              ),
              
              _buildInputField(
                controller: _vergiKimlikNoController,
                label: 'Vergi Kimlik No',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vergi no girin';
                  if (v.length != 10) return '10 haneli olmalı';
                  return null;
                },
              ),
              
              _buildInputField(
                controller: _telefonController,
                label: 'Telefon',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Telefon girin';
                  if (v.length < 10) return 'Geçerli numara girin';
                  return null;
                },
              ),
              
              // Konum
              _buildInputField(
                controller: _konumController,
                label: 'Konum',
                icon: Icons.location_on,
                validator: (v) => _selectedLocation == null ? 'Konum seçin' : null,
                onTap: _openMapPicker,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: _openMapPicker,
                ),
              ),

              // E-posta Doğrulama
              const SizedBox(height: 20),
              Text(
                'E-posta Doğrulama',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[800],
                ),
              ),
              const SizedBox(height: 20),
              
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
                const SizedBox(height: 16),
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
              const SizedBox(height: 20),
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
                margin: const EdgeInsets.only(top: 16, bottom: 24),
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
                          onTap: () {
                            // Sözleşme göster
                          },
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
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _searchResults = data.map<Map<String, dynamic>>((item) => ({
            'displayName': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          })).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arama hatası: ${e.toString()}', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _moveToLocation(LatLng location) {
    _mapController.move(location, 15.0);
    setState(() => _selectedLocation = location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Konum Seçin',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.deepPurple[800]),
            onPressed: () => Navigator.pop(context, _selectedLocation),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
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
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Adres ara...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.deepPurple[400]),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.deepPurple[400]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                onSubmitted: (query) => _searchLocation(query),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: widget.initialLocation,
                    zoom: 14.0,
                    onTap: (tapPosition, point) {
                      setState(() => _selectedLocation = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: _selectedLocation != null
                          ? [
                              Marker(
                                point: _selectedLocation!,
                                width: 40.0,
                                height: 40.0,
                                builder: (context) => Icon(
                                  Icons.location_pin,
                                  color: Colors.deepPurple,
                                  size: 40,
                                ),
                              )
                            ]
                          : [],
                    ),
                  ],
                ),
                if (_isSearching)
                  Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurple,
                      strokeWidth: 3,
                    ),
                  ),
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            title: Text(
                              result['displayName'],
                              style: GoogleFonts.poppins(),
                            ),
                            dense: true,
                            onTap: () {
                              final location = LatLng(
                                result['lat'],
                                result['lon'],
                              );
                              _moveToLocation(location);
                              setState(() => _searchResults = []);
                              _searchController.clear();
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}