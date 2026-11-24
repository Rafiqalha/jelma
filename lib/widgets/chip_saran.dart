import 'package:flutter/material.dart';

import '../models/saran_cuaca.dart';

/// Warna dan ikon untuk satu tingkat saran.
///
/// Tingkat selalu ditulis sebagai teks dan ikon, tidak hanya warna. Pasangan warna kuning
/// diperiksa kontrasnya (lebih dari 7:1); dua tingkat lain memakai warna dari skema tema.
class GayaSaran {
  const GayaSaran({required this.latar, required this.teks, required this.ikon});

  final Color latar;
  final Color teks;
  final IconData ikon;
}

GayaSaran gayaSaran(ColorScheme skema, TingkatSaran tingkat) => switch (tingkat) {
      TingkatSaran.baik => GayaSaran(
          latar: skema.primaryContainer,
          teks: skema.onPrimaryContainer,
          ikon: Icons.check_circle_outline,
        ),
      TingkatSaran.waspada => const GayaSaran(
          latar: Color(0xFFFFF0C2),
          teks: Color(0xFF5C4200),
          ikon: Icons.warning_amber,
        ),
      TingkatSaran.hindari => GayaSaran(
          latar: skema.errorContainer,
          teks: skema.onErrorContainer,
          ikon: Icons.block,
        ),
    };

/// Label cuaca untuk satu rencana, misalnya "Tunda · Hujan 90%".
class ChipPenilaian extends StatelessWidget {
  const ChipPenilaian({super.key, required this.penilaian});

  final PenilaianRencana penilaian;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gaya = gayaSaran(tema.colorScheme, penilaian.tingkat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: gaya.latar, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(penilaian.kondisi.ikon, size: 14, color: gaya.teks),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${penilaian.tingkat.label} · ${penilaian.kondisi.label} ${penilaian.peluangHujan}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.labelSmall?.copyWith(color: gaya.teks, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label status kecocokan cuaca, misalnya "Bawa jas hujan".
class ChipSaran extends StatelessWidget {
  const ChipSaran({super.key, required this.saran});

  final SaranCuaca saran;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gaya = gayaSaran(tema.colorScheme, saran.tingkat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: gaya.latar, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(gaya.ikon, size: 14, color: gaya.teks),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              saran.judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.labelSmall?.copyWith(color: gaya.teks, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
