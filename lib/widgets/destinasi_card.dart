import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../models/format.dart';
import '../state/favorit_store.dart';
import '../state/lokasi_store.dart';
import '../state/store_scope.dart';
import 'gambar_kategori.dart';

/// Kartu ringkas satu destinasi: gambar kategori dengan status buka, nama, jarak dan lokasi,
/// rating, harga, dan tombol favorit. Mengetuk kartu membuka halaman detail.
class DestinasiCard extends StatelessWidget {
  const DestinasiCard({super.key, required this.destinasi});

  final Destinasi destinasi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final store = StoreScope.of<FavoritStore>(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final favorit = store.apakahFavorit(destinasi.id);
    final jarak = destinasi.jarakDari(lokasi.aktif);
    final status = destinasi.statusPada(WaktuScope.baca(context));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/detail', arguments: destinasi),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GambarKategori(
                      kategori: destinasi.kategori,
                      radius: BorderRadius.circular(12),
                    ),
                    if (status != null)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            status.singkat,
                            style: tema.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: status.terbuka ? skema.primary : skema.error,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      destinasi.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          jarak == null ? Icons.place_outlined : Icons.near_me_outlined,
                          size: 16,
                          color: skema.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            jarak == null ? destinasi.lokasi : '${formatJarak(jarak)} · ${destinasi.lokasi}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF9A825)),
                        const SizedBox(width: 2),
                        Text(
                          destinasi.rating.toStringAsFixed(1),
                          style: tema.textTheme.labelLarge,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            destinasi.hargaLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.labelLarge?.copyWith(color: skema.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: favorit ? 'Hapus dari favorit' : 'Tambah ke favorit',
                onPressed: () => store.toggle(destinasi.id),
                icon: Icon(
                  favorit ? Icons.favorite : Icons.favorite_border,
                  color: favorit ? Colors.redAccent : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
