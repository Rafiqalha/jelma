import 'package:flutter/material.dart';

import '../models/gaya_kategori.dart';
import '../tema.dart';

/// Gambar pengganti untuk destinasi yang belum punya foto atau fotonya gagal dimuat.
///
/// Sengaja tenang (rona tipis warna kategori dengan ikonnya) dan bila diminta diberi tulisan
/// "Foto belum tersedia", supaya tidak disangka foto sungguhan.
class GambarKategori extends StatelessWidget {
  const GambarKategori({
    super.key,
    required this.kategori,
    this.ukuranIkon = 40,
    this.radius,
    this.keterangan,
  });

  final String kategori;
  final double ukuranIkon;
  final BorderRadius? radius;

  /// Teks kecil di bawah ikon, misalnya "Foto belum tersedia".
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    final warna = warnaKategori(kategori);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: Color.alphaBlend(warna.withValues(alpha: 0.12), Colors.white),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikonKategori(kategori), size: ukuranIkon, color: warna),
            if (keterangan != null) ...[
              const SizedBox(height: 8),
              Text(
                keterangan!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: WarnaJelma.tintaLembut),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
