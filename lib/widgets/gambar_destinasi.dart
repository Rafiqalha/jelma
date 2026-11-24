import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../models/gaya_kategori.dart';
import 'gambar_kategori.dart';

/// Foto asli destinasi yang memenuhi kotaknya, dengan keadaan memuat dan gambar pengganti.
///
/// Destinasi tanpa foto, atau foto yang gagal dimuat, memakai [GambarKategori], sehingga kotak
/// foto tidak pernah kosong. Foto didekode seukuran tampilannya agar hemat memori.
class GambarDestinasi extends StatelessWidget {
  const GambarDestinasi({
    super.key,
    required this.destinasi,
    this.radius,
    this.heroTag,
    this.ukuranIkon = 40,
    this.keteranganPengganti = false,
    this.semantik = false,
  });

  final Destinasi destinasi;
  final BorderRadius? radius;

  /// Tag Hero untuk transisi foto ke halaman Detail; harus unik dalam satu halaman.
  final Object? heroTag;
  final double ukuranIkon;

  /// Menulis "Foto belum tersedia" pada gambar pengganti.
  final bool keteranganPengganti;

  /// Memberi label aksesibilitas pada foto. Dimatikan pada kartu karena nama destinasi sudah dibacakan.
  final bool semantik;

  @override
  Widget build(BuildContext context) {
    final foto = destinasi.foto;
    final pengganti = GambarKategori(
      kategori: destinasi.kategori,
      ukuranIkon: ukuranIkon,
      keterangan: keteranganPengganti ? 'Foto belum tersedia' : null,
    );

    Widget isi;
    if (foto == null) {
      isi = pengganti;
    } else {
      isi = LayoutBuilder(
        builder: (context, batas) {
          // Foto katalog berasio 4:3 sampai 16:9; lebar dekode dihitung agar tetap tajam saat dipotong.
          final rasioPiksel = MediaQuery.devicePixelRatioOf(context);
          final lebarPerlu = math.max(
            batas.maxWidth.isFinite ? batas.maxWidth : 0.0,
            batas.maxHeight.isFinite ? batas.maxHeight * 16 / 9 : 0.0,
          );
          final ImageProvider sumber = foto.dariJaringan ? NetworkImage(foto.berkas) : AssetImage(foto.berkas);
          return Image(
            image: ResizeImage.resizeIfNeeded(lebarPerlu > 0 ? (lebarPerlu * rasioPiksel).round() : null, null, sumber),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            semanticLabel: semantik ? 'Foto ${destinasi.nama}' : null,
            excludeFromSemantics: !semantik,
            frameBuilder: (context, child, frame, sinkron) {
              if (sinkron || frame != null) return child;
              // Keadaan memuat: rona kategori yang sama dengan gambar pengganti, tanpa animasi berulang.
              return ColoredBox(color: Color.alphaBlend(warnaKategori(destinasi.kategori).withValues(alpha: 0.12), Colors.white));
            },
            errorBuilder: (context, galat, jejak) => pengganti,
          );
        },
      );
    }
    if (radius != null) isi = ClipRRect(borderRadius: radius!, child: isi);
    if (heroTag != null) isi = Hero(tag: heroTag!, child: isi);
    return isi;
  }
}
