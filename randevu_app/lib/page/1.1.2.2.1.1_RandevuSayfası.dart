import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:randevu_app/page/1.1.2.2.1_Dukkan_Bul.dart';

class RandevuSayfasi extends StatefulWidget {
  final int calisanId;
  final int dukkanId;
  final int? kullaniciId;
  final List<HizmetBedel> hizmetBedeller;

  const RandevuSayfasi({
    Key? key,
    required this.calisanId,
    required this.dukkanId,
    required this.hizmetBedeller,
    required this.kullaniciId,
  }) : super(key: key);

  @override
  State<RandevuSayfasi> createState() => _RandevuSayfasiState();
}

class _RandevuSayfasiState extends State<RandevuSayfasi> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  HizmetBedel? _selectedHizmet;
  bool _isLoading = false;
  List<dynamic> _gunlukRandevular = [];

  // Renk Tanımları
  final Color _primaryColor = Colors.deepPurple;
  final Color _primaryColorLight = Color(0xFF7B1FA2);
  final Color _secondaryColor = Colors.teal;
  final Color _accentColor = Colors.amber[600]!;

  Future<void> _createAppointment() async {
    if (_selectedDate == null || _selectedTime == null || _selectedHizmet == null) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime = '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
          '${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      final randevuData = {
        "tarih": formattedDate,
        "saat": formattedTime,
        "kullaniciId": widget.kullaniciId,
        "hizmetBedelId": _selectedHizmet!.id,
        "calisanId": widget.calisanId,
      };

      final response = await http.post(
        Uri.parse('https://localhost:7128/api/Randevu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(randevuData),
      );

      if (response.statusCode == 201) {
        _showSuccess('Randevu başarıyla oluşturuldu');
        Navigator.pop(context, true);
      } else if (response.statusCode == 409) {
        _showError('Çalışanın bu saatte aynı hizmet için başka bir randevusu bulunmaktadır');
      } else {
        throw 'Hata: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGunlukRandevular(DateTime date) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final response = await http.get(
        Uri.parse(
          'https://localhost:7128/api/Randevu/CalisanRandevularDetayli?calisanId=${widget.calisanId}&tarih=$formattedDate'),
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
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectTime() async {
    final bookedTimesForSelectedService = _gunlukRandevular
        .where((r) => r['hizmetAd'] == _selectedHizmet?.hizmet.ad)
        .map((r) {
          final timeStr = r['saat'].toString();
          return TimeOfDay(
            hour: int.parse(timeStr.split(':')[0]),
            minute: int.parse(timeStr.split(':')[1]),
          );
        }).toList();

    final pickedTime = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<int> availableHours = List.generate(11, (index) => 9 + index);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Saat Seçin',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Expanded(
                child: ListView.builder(
                  itemCount: availableHours.length,
                  itemBuilder: (context, index) {
                    final hour = availableHours[index];
                    final time = TimeOfDay(hour: hour, minute: 0);
                    final isBookedForThisService = bookedTimesForSelectedService.any((t) => 
                      t.hour == time.hour && t.minute == time.minute);
                    
                    return ListTile(
                      title: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: GoogleFonts.poppins(
                          color: isBookedForThisService ? Colors.grey : null,
                        ),
                      ),
                      onTap: isBookedForThisService ? null : () {
                        Navigator.pop(context, time);
                      },
                      enabled: !isBookedForThisService,
                      trailing: isBookedForThisService 
                        ? const Icon(Icons.lock, color: Colors.grey)
                        : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Onaylandı':
        return Icons.check_circle;
      case 'Tamamlandı':
        return Icons.done_all;
      default: // 'Onay Bekliyor'
        return Icons.access_time;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Onaylandı':
        return Colors.green;
      case 'Tamamlandı':
        return Colors.blue;
      default: // 'Onay Bekliyor'
        return Colors.orange;
    }
  }

  @override
  
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Randevu Sayfası', style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih Seçim Bölümü
            Text(
              'Tarih Seçin',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDate != null && _selectedDate!.day == date.day;
                  final isToday = date.day == DateTime.now().day;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 80,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        setState(() => _selectedDate = date);
                        _fetchGunlukRandevular(date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [_primaryColor, _primaryColorLight])
                              : null,
                          color: isSelected
                              ? null
                              : isToday
                                  ? _accentColor.withOpacity(0.2)
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isToday ? _accentColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(date),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : _primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Hizmet Seçim Kartı
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonFormField<HizmetBedel>(
                  value: _selectedHizmet,
                  items: widget.hizmetBedeller.map((HizmetBedel hizmet) {
                    return DropdownMenuItem<HizmetBedel>(
                      value: hizmet,
                      child: Text(
                        '${hizmet.hizmet.ad} - ${hizmet.fiyat.toStringAsFixed(2)}₺',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHizmet = value;
                      _selectedTime = null; // Hizmet değişince saati sıfırla
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Hizmet Seçin',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                    ),
                    border: InputBorder.none,
                    icon: Icon(Icons.cleaning_services, color: _primaryColor),
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade800,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                  validator: (value) => value == null ? 'Zorunlu alan' : null,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Saat Seçim Kartı
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: ListTile(
                title: Text(
                  _selectedTime == null ? 'Saat Seçin' : _selectedTime!.format(context),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _selectedTime == null 
                        ? Colors.grey.shade600 
                        : Colors.grey.shade800,
                  ),
                ),
                leading: Icon(Icons.access_time, color: _primaryColor),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade500),
                onTap: _selectedHizmet == null 
                    ? () => _showError('Önce bir hizmet seçin')
                    : _selectTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mevcut Randevular Listesi
            if (_gunlukRandevular.isNotEmpty) ...[
              Text(
                'Mevcut Randevular:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _gunlukRandevular.length,
                itemBuilder: (context, index) {
                  final randevu = _gunlukRandevular[index];
                  final statusColor = _getStatusColor(randevu['durum']);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(randevu['durum']),
                          color: statusColor,
                        ),
                      ),
                      title: Text(
                        '${randevu['kullaniciAd']} ${randevu['kullaniciSoyad']}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saat: ${randevu['saat'].toString().substring(0,5)}',
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            'Hizmet: ${randevu['hizmetAd']}',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      trailing: Text(
                        randevu['durum'],
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Onay Butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, 
                  backgroundColor: _secondaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _createAppointment,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Randevuyu Onayla',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
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
}