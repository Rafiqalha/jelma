import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../models/format.dart';
import '../navigasi.dart';
import '../state/lokasi_store.dart';
import '../state/store_scope.dart';
import '../tema.dart';
import 'destinasi_card.dart';
import 'gambar_destinasi.dart';
import 'tombol_favorit.dart';

/// Baris destinasi ringkas: foto persegi kecil, nama, jarak atau lokasi, rating, dan harga.
/// Dipakai untuk daftar pendek seperti "Dekat Anda" dan "Rating tertinggi".
class DestinasiBaris extends StatelessWidget {
  const DestinasiBaris({super.key, required this.destinasi, required this.asalHero, this.awalan});

  final Destinasi destinasi;
  final String asalHero;

  /// Widget di depan foto, misalnya nomor peringkat.
  final Widget? awalan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final jarak = destinasi.jarakDari(StoreScope.of<LokasiStore>(context).aktif);
    final tag = tagFoto(asalHero, destinasi);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => bukaDetail(context, destinasi, heroTag: tag),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            if (awalan != null) ...[awalan!, const SizedBox(width: 12)],
            SizedBox.square(
              dimension: 76,
              child: GambarDestinasi(destinasi: destinasi, heroTag: tag, radius: BorderRadius.circular(16), ukuranIkon: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destinasi.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jarak == null ? destinasi.lokasi : '${formatJarak(jarak)} · ${destinasi.lokasi}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [NilaiRating(rating: destinasi.rating, kecil: true), TeksHarga(destinasi: destinasi)],
                  ),
                ],
              ),
            ),
            TombolFavorit(destinasi: destinasi),
          ],
        ),
      ),
    );
  }
}
