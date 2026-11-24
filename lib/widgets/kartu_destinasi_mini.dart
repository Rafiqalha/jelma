import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../navigasi.dart';
import '../tema.dart';
import 'destinasi_card.dart';
import 'gambar_destinasi.dart';

/// Kartu berfoto untuk deret mendatar di Beranda: foto bersudut lembut, lalu nama dan keterangan
/// langsung di atas latar halaman, tanpa bingkai kartu, agar foto menjadi pusat perhatian.
class KartuDestinasiMini extends StatelessWidget {
  const KartuDestinasiMini({
    super.key,
    required this.destinasi,
    required this.asalHero,
    this.lebar = 200,
    this.keterangan,
  });

  final Destinasi destinasi;

  /// Awalan tag Hero; setiap bagian Beranda memakai awalan sendiri.
  final String asalHero;
  final double lebar;

  /// Isi di bawah nama; bawaannya lokasi destinasi.
  final Widget? keterangan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tag = tagFoto(asalHero, destinasi);
    return SizedBox(
      width: lebar,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => bukaDetail(context, destinasi, heroTag: tag),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GambarDestinasi(destinasi: destinasi, heroTag: tag, radius: BorderRadius.circular(20)),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: NilaiRating(rating: destinasi.rating, kecil: true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                destinasi.nama,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 2),
              keterangan ??
                  Text(
                    destinasi.lokasi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deret mendatar yang tingginya mengikuti isi, sehingga teks besar tidak terpotong.
class DeretMendatar extends StatelessWidget {
  const DeretMendatar({super.key, required this.anak, this.jarak = 14});

  final List<Widget> anak;
  final double jarak;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < anak.length; i++) ...[
            if (i > 0) SizedBox(width: jarak),
            anak[i],
          ],
        ],
      ),
    );
  }
}
