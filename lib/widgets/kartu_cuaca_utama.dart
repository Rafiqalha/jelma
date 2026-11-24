import 'package:flutter/material.dart';

import '../models/cuaca.dart';
import 'ikon_cuaca.dart';

/// Kartu utama halaman Cuaca: kondisi sekarang di satu lokasi, dengan gradasi yang sama dengan header Beranda.
///
/// Gradasi dan teks putih dipilih sebagai titik fokus halaman; kontras putih pada ujung terang
/// gradasi (#00796B) adalah 5,3:1 dan pada ujung gelap lebih tinggi.
class KartuCuacaUtama extends StatelessWidget {
  const KartuCuacaUtama({
    super.key,
    required this.lokasi,
    required this.sumber,
    required this.prakiraan,
  });

  final String lokasi;

  /// Asal lokasi: `GPS`, `Area pilihan`, atau `Bawaan`.
  final String sumber;
  final PrakiraanCuaca prakiraan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final kini = prakiraan.saatIni;
    final kondisi = kini.kondisi;
    final peluang = prakiraan.hariIni?.peluangHujan;
    const putih = TextStyle(color: Colors.white);

    return Semantics(
      container: true,
      label: 'Cuaca di $lokasi: ${kondisi.label}, ${kini.suhu.round()} derajat Celsius',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [skema.primary, Color.lerp(skema.primary, Colors.black, 0.32)!],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lokasi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleSmall?.merge(putih).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(sumber, style: tema.textTheme.labelMedium?.merge(putih)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IkonCuaca(kondisi: kondisi, ukuran: 64, warna: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${kini.suhu.round()}°',
                        style: tema.textTheme.displayMedium?.merge(putih).copyWith(fontWeight: FontWeight.w800, height: 1.05),
                      ),
                      Text(kondisi.label, style: tema.textTheme.titleMedium?.merge(putih)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Metrik(judul: 'Terasa seperti', nilai: '${kini.suhuTerasa.round()}°'),
                if (peluang != null) _Metrik(judul: 'Peluang hujan', nilai: '$peluang%'),
                _Metrik(judul: 'Kelembapan', nilai: '${kini.kelembapan}%'),
                _Metrik(judul: 'Angin', nilai: '${kini.angin.round()} km/jam'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metrik extends StatelessWidget {
  const _Metrik({required this.judul, required this.nilai});

  final String judul;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(judul, style: tema.textTheme.labelMedium?.copyWith(color: Colors.white)),
        Text(nilai, style: tema.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
