import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '1.2.2.2.1_DukkanCalisanKayit_Sayfasi.dart';
import '1.2.2.2.2.1_CalisanRandevuListesi_Sayfasi.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

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

  String get tamAdi => '${ad ?? ''} ${soyad ?? ''}'.trim();
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
}

class Hizmet {
  final int id;
  final String ad;

  Hizmet({required this.id, required this.ad});
}

class DukkanCalisanListesi extends StatefulWidget {
  final int dukkanId;

  const DukkanCalisanListesi({super.key, required this.dukkanId});

  @override
  State<DukkanCalisanListesi> createState() => _DukkanCalisanListesiState();
}

class _DukkanCalisanListesiState extends State<DukkanCalisanListesi> {
  late Future<List<Calisan>> _futureCalisanlar;
  late Future<List<Hizmet>> _futureHizmetler;
  bool _isLoading = false;
  final _searchController = TextEditingController();
  List<Calisan> _filteredCalisanlar = [];

  @override
  void initState() {
    super.initState();
    _futureCalisanlar = _fetchCalisanlar();
    _futureHizmetler = _fetchHizmetler();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _futureCalisanlar.then((calisanlar) {
      if (_searchController.text.isEmpty) {
        setState(() => _filteredCalisanlar = calisanlar);
      } else {
        setState(() {
          _filteredCalisanlar = calisanlar.where((calisan) {
            final query = _searchController.text.toLowerCase();
            return calisan.tamAdi.toLowerCase().contains(query) ||
                (calisan.tc?.toLowerCase().contains(query) ?? false);
          }).toList();
        });
      }
    });
  }

  Future<List<Calisan>> _fetchCalisanlar() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://localhost:7128/api/Calisan/calisanlar/${widget.dukkanId}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        final calisanlar = jsonData.map((e) => Calisan(
          id: e['id'] ?? 0,
          ad: e['ad'],
          soyad: e['soyad'],
          tc: e['tC'],
          dukkanId: e['dukkanId'] ?? 0,
          hizmetBedeller: (e['hizmetBedeller'] as List).map((hb) => HizmetBedel(
            id: hb['id'] ?? 0,
            hizmetAd: hb['hizmetAd'],
            fiyat: (hb['fiyat'] as num?)?.toDouble() ?? 0.0,
          )).toList(),
        )).toList();

        _filteredCalisanlar = calisanlar;
        return calisanlar;
      } else {
        throw Exception('Çalışanlar alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Çalışanlar alınırken hata oluştu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Hizmet>> _fetchHizmetler() async {
    try {
      final response = await http.get(
        Uri.parse('https://localhost:7128/api/HizmetBedel/hizmetler'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        return jsonData.map((e) => Hizmet(id: e['id'] ?? 0, ad: e['ad'])).toList();
      } else {
        throw Exception('Hizmetler alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hizmetler alınırken hata oluştu: $e');
    }
  }

  Future<void> _silCalisan(int calisanId) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => ConfirmationBottomSheet(
        title: 'Çalışanı Sil',
        message: 'Bu çalışanı ve tüm hizmetlerini silmek istediğinize emin misiniz?',
        confirmText: 'Sil',
        confirmColor: Colors.red,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('https://localhost:7128/api/Calisan/sil/$calisanId'),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Çalışan başarıyla silindi');
        setState(() {
          _futureCalisanlar = _fetchCalisanlar();
        });
      } else {
        _showErrorSnackBar('Silme işlemi başarısız: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Hata: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _silHizmet(int hizmetBedelId) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => ConfirmationBottomSheet(
        title: 'Hizmeti Sil',
        message: 'Bu hizmeti silmek istediğinize emin misiniz?',
        confirmText: 'Sil',
        confirmColor: Colors.red,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('https://localhost:7128/api/HizmetBedel/sil/$hizmetBedelId'),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Hizmet başarıyla silindi');
        setState(() {
          _futureCalisanlar = _fetchCalisanlar();
        });
      } else {
        _showErrorSnackBar('Silme işlemi başarısız: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Hata: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hizmetEkle(int calisanId) async {
    final hizmetler = await _futureHizmetler;
    final formKey = GlobalKey<FormState>();
    final fiyatController = TextEditingController();
    Hizmet? secilenHizmet;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Yeni Hizmet Ekle',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<Hizmet>(
                    decoration: InputDecoration(
                      labelText: 'Hizmet',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Iconsax.activity),
                    ),
                    items: hizmetler.map((hizmet) {
                      return DropdownMenuItem<Hizmet>(
                        value: hizmet,
                        child: Text(hizmet.ad),
                      );
                    }).toList(),
                    onChanged: (Hizmet? value) {
                      setState(() => secilenHizmet = value);
                    },
                    validator: (value) => value == null ? 'Hizmet seçiniz' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: fiyatController,
                    decoration: InputDecoration(
                      labelText: 'Fiyat',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Iconsax.money),
                      suffixText: '₺',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Fiyat giriniz';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Geçerli bir sayı giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate() && secilenHizmet != null) {
                              setState(() => _isLoading = true);
                              try {
                                final response = await http.post(
                                  Uri.parse('https://localhost:7128/api/HizmetBedel/ekle'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: json.encode({
                                    'calisanId': calisanId,
                                    'hizmetId': secilenHizmet!.id,
                                    'fiyat': int.parse(fiyatController.text),
                                  }),
                                );

                                if (response.statusCode == 200) {
                                  _showSuccessSnackBar('Hizmet başarıyla eklendi');
                                  Navigator.pop(context);
                                  setState(() {
                                    _futureCalisanlar = _fetchCalisanlar();
                                  });
                                } else {
                                  final error = json.decode(response.body)['message'] ?? 'Hizmet eklenemedi';
                                  _showErrorSnackBar(error);
                                }
                              } catch (e) {
                                _showErrorSnackBar('Hata: ${e.toString()}');
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildHizmetChip(HizmetBedel hizmet) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${hizmet.hizmetAd} - ${hizmet.fiyat.toStringAsFixed(2)}₺',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _silHizmet(hizmet.id),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalisanCard(Calisan calisan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      calisan.tamAdi,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.calendar),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CalisanRandevuListesi(
                                calisanId: calisan.id,
                              ),
                            ),
                          );
                        },
                        tooltip: 'Randevularım',
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.trash),
                        onPressed: () => _silCalisan(calisan.id),
                        tooltip: 'Çalışanı Sil',
                      ),
                    ],
                  ),
                ],
              ),
              if (calisan.tc != null) ...[
                const SizedBox(height: 4),
                Text(
                  'TC: ${calisan.tc}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Hizmetler',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (calisan.hizmetBedeller.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Henüz hizmet eklenmemiş',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                )
              else
                Wrap(
                  children: calisan.hizmetBedeller.map(_buildHizmetChip).toList(),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Iconsax.add, size: 20),
                  label: const Text('Hizmet Ekle'),
                  onPressed: () => _hizmetEkle(calisan.id),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(
          duration: 300.ms,
          begin: 0.1,
          curve: Curves.easeOutQuad,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DukkanCalisanKayit(
                dukkanId: widget.dukkanId,
              ),
            ),
          ).then((_) => _futureCalisanlar = _fetchCalisanlar());
        },
        child: const Icon(Iconsax.user_add),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Çalışanlar Sayfası'),
              floating: true,
              snap: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Çalışan ara...',
                      prefixIcon: const Icon(Iconsax.search_normal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _futureCalisanlar = _fetchCalisanlar();
            });
          },
          child: FutureBuilder<List<Calisan>>(
            future: _futureCalisanlar,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.warning_2,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hata oluştu',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _futureCalisanlar = _fetchCalisanlar();
                          });
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || _filteredCalisanlar.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.user_octagon,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz çalışan eklenmemiş',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yeni çalışan eklemek için alttaki + butonuna basın',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filteredCalisanlar.length,
                itemBuilder: (context, index) {
                  return _buildCalisanCard(_filteredCalisanlar[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;

  const ConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('İptal')),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(confirmText)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}