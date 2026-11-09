import 'package:flutter/material.dart';

import '../models/gaya_kategori.dart';

/// Pengganti foto destinasi: latar gradasi warna kategori dengan ikon di tengah.
///
/// Aplikasi sengaja tidak memuat gambar dari internet sehingga tampilan tetap
/// konsisten, ringan, dan tidak bergantung pada hak cipta foto pihak lain.
class GambarKategori extends StatelessWidget {
  const GambarKategori({
    super.key,
    required this.kategori,
    this.ukuranIkon = 40,
    this.radius,
  });

  final String kategori;
  final double ukuranIkon;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final warna = warnaKategori(kategori);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [warna, Color.lerp(warna, Colors.black, 0.28)!],
        ),
      ),
      child: Center(
        child: Icon(
          ikonKategori(kategori),
          size: ukuranIkon,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
