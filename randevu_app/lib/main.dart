import 'package:flutter/material.dart';
import 'package:randevu_app/page/1.1_Kay%C4%B1tGiris_Sayfasi.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Randevu Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const KullaniciKGPage(), // Doğrudan giriş sayfasını kullanıyoruz
    );
  }
}