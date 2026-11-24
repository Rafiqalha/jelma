import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/jam_buka.dart';
import '../navigasi.dart';
import '../state/lokasi_store.dart';
import '../state/store_scope.dart';
import '../tema.dart';
import 'gambar_destinasi.dart';
import 'tombol_favorit.dart';

/// Kartu destinasi berfoto besar untuk daftar Jelajah dan Favorit.
///
/// Foto berada di atas dan semua teks di bawahnya pada bidang putih, sehingga kontras teks tidak
/// bergantung pada isi foto. Di atas foto hanya ada label status buka dan tombol favorit, keduanya
/// berlatar putih padat.
class DestinasiCard extends StatelessWidget {
  const DestinasiCard({super.key, required this.destinasi, this.asalHero = 'daftar'});

  final Destinasi destinasi;

  /// Awalan tag Hero agar destinasi yang sama di tab lain tidak bertabrakan.
  final String asalHero;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final jarak = destinasi.jarakDari(lokasi.aktif);
    final status = destinasi.statusPada(WaktuScope.baca(context));
    final tag = tagFoto(asalHero, destinasi);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => bukaDetail(context, destinasi, heroTag: tag),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GambarDestinasi(destinasi: destinasi, heroTag: tag, ukuranIkon: 56, keteranganPengganti: true),
                  if (status != null) Positioned(left: 12, top: 12, child: LabelStatusBuka(status: status)),
                  Positioned(right: 6, top: 6, child: TombolFavorit(destinasi: destinasi, diAtasFoto: true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          destinasi.nama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NilaiRating(rating: destinasi.rating),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jarak == null ? destinasi.lokasi : '${formatJarak(jarak)} · ${destinasi.lokasi}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodyMedium?.copyWith(color: WarnaJelma.tintaLembut),
                  ),
                  const SizedBox(height: 8),
                  TeksHarga(destinasi: destinasi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daftar [DestinasiCard] yang dapat digulir sendiri; lihat [SliverKartuDestinasi].
class DaftarKartuDestinasi extends StatelessWidget {
  const DaftarKartuDestinasi({super.key, required this.daftar, required this.asalHero});

  final List<Destinasi> daftar;
  final String asalHero;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverKartuDestinasi(daftar: daftar, asalHero: asalHero),
        ),
      ],
    );
  }
}

/// Kartu destinasi dalam [CustomScrollView] yang menyesuaikan lebar layar: satu kolom di ponsel,
/// dua atau tiga kolom di layar lebar. Tinggi baris mengikuti isi kartu sehingga teks besar tidak terpotong.
class SliverKartuDestinasi extends StatelessWidget {
  const SliverKartuDestinasi({super.key, required this.daftar, required this.asalHero});

  final List<Destinasi> daftar;
  final String asalHero;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, batas) {
        final kolom = (batas.crossAxisExtent / 380).floor().clamp(1, 3);
        final baris = (daftar.length / kolom).ceil();
        return SliverList.separated(
          itemCount: baris,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, b) {
            if (kolom == 1) return DestinasiCard(destinasi: daftar[b], asalHero: asalHero);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var k = 0; k < kolom; k++) ...[
                  if (k > 0) const SizedBox(width: 16),
                  Expanded(
                    child: b * kolom + k < daftar.length
                        ? DestinasiCard(destinasi: daftar[b * kolom + k], asalHero: asalHero)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// Bintang dan angka rating. Bintang berwarna tinta agar kartu tidak bertambah warna.
class NilaiRating extends StatelessWidget {
  const NilaiRating({super.key, required this.rating, this.kecil = false});

  final double rating;
  final bool kecil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      label: 'Rating ${rating.toStringAsFixed(1)} dari 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: kecil ? 16 : 18, color: WarnaJelma.tinta),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: (kecil ? tema.textTheme.labelMedium : tema.textTheme.labelLarge)?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Harga tebal diikuti jenis harganya, misalnya "Rp 35.000 tiket masuk".
class TeksHarga extends StatelessWidget {
  const TeksHarga({super.key, required this.destinasi});

  final Destinasi destinasi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: destinasi.hargaLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (!destinasi.gratis)
            TextSpan(
              text: '  ${destinasi.judulHarga.toLowerCase()}',
              style: const TextStyle(color: WarnaJelma.tintaLembut, fontWeight: FontWeight.w500),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: tema.textTheme.bodyMedium,
    );
  }
}

/// Label "Buka" atau "Tutup" berlatar putih padat untuk diletakkan di atas foto.
class LabelStatusBuka extends StatelessWidget {
  const LabelStatusBuka({super.key, required this.status});

  final StatusBuka status;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final warna = status.terbuka ? WarnaJelma.hijau : tema.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.terbuka ? Icons.schedule : Icons.do_not_disturb_on_outlined, size: 14, color: warna),
          const SizedBox(width: 4),
          Text(status.singkat, style: tema.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: warna)),
        ],
      ),
    );
  }
}
