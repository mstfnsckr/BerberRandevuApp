import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DukkanCalisanKayit extends StatefulWidget {
  final int dukkanId;

  const DukkanCalisanKayit({super.key, required this.dukkanId});

  @override
  State<DukkanCalisanKayit> createState() => _DukkanCalisanKayitState();
}

class _DukkanCalisanKayitState extends State<DukkanCalisanKayit> {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _tcController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _calisanKaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://localhost:7128/api/Calisan/eklecalisan'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ad': _adController.text.trim(),
          'soyad': _soyadController.text.trim(),
          'tc': _tcController.text.trim(),
          'dukkanId': widget.dukkanId,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(responseData['message'] ?? 'Çalışan başarıyla kaydedildi!', Colors.green);
        _clearForm();
      } else if (response.statusCode == 400) {
        _showSnackBar(responseData['message'] ?? 'Geçersiz veri gönderildi', Colors.orange);
      } else if (response.statusCode == 404) {
        _showSnackBar(responseData['message'] ?? 'Dükkan bulunamadı', Colors.red);
      } else {
        _showSnackBar('Beklenmeyen bir hata oluştu: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('İstek sırasında hata oluştu: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: renk,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan zorunludur';
    }
    return null;
  }

  String? _tcValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'TC Kimlik No zorunludur';
    }
    if (value.length != 11) {
      return 'TC Kimlik No 11 haneli olmalıdır';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Sadece rakam giriniz';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Çalışan Kayıt Sayfası', style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Yeni Çalışan Kaydı',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      _adController,
                      'Ad',
                      icon: Icons.person,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      _soyadController,
                      'Soyad',
                      icon: Icons.person_outline,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      _tcController,
                      'TC Kimlik No',
                      icon: Icons.badge,
                      keyboardType: TextInputType.number,
                      validator: _tcValidator,
                      inputFormatters: [LengthLimitingTextInputFormatter(11)],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _calisanKaydet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'Kaydediliyor...' : 'Kaydet',
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String labelText, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
      inputFormatters: inputFormatters,
    );
  }
}
