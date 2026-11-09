import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../state/favorit_store.dart';
import 'gambar_kategori.dart';

/// Kartu ringkas satu destinasi: gambar kategori, nama, lokasi, rating, harga,
/// dan tombol favorit. Mengetuk kartu membuka halaman detail.
class DestinasiCard extends StatelessWidget {
  const DestinasiCard({super.key, required this.destinasi});

  final Destinasi destinasi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final store = FavoritScope.of(context);
    final favorit = store.apakahFavorit(destinasi.id);

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
                child: GambarKategori(
                  kategori: destinasi.kategori,
                  radius: BorderRadius.circular(12),
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
                        Icon(Icons.place_outlined, size: 16, color: tema.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destinasi.lokasi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
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
                            style: tema.textTheme.labelLarge?.copyWith(color: tema.colorScheme.primary),
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
