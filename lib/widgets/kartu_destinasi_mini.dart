import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import 'gambar_kategori.dart';

/// Tinggi daftar kartu mendatar; bertambah bila pengguna memperbesar ukuran teks agar isi tidak terpotong.
double tinggiDaftarMendatar(BuildContext context, double dasar) {
  final skala = MediaQuery.textScalerOf(context).scale(1);
  return dasar + (skala - 1).clamp(0.0, 1.0) * 96;
}

/// Kartu kecil destinasi untuk daftar mendatar: gambar kategori, lencana rating, nama, dan satu baris keterangan.
class KartuDestinasiMini extends StatelessWidget {
  const KartuDestinasiMini({super.key, required this.destinasi, this.keterangan});

  final Destinasi destinasi;

  /// Isi baris di bawah nama; bawaannya lokasi destinasi.
  final Widget? keterangan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/detail', arguments: destinasi),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GambarKategori(kategori: destinasi.kategori, ukuranIkon: 44),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF9A825)),
                            const SizedBox(width: 2),
                            Text(
                              destinasi.rating.toStringAsFixed(1),
                              style: tema.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destinasi.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    keterangan ??
                        Text(
                          destinasi.lokasi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
