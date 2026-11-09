import 'package:flutter/material.dart';

import '../data/destinasi_repository.dart';
import '../state/favorit_store.dart';
import '../widgets/destinasi_card.dart';

/// Halaman Favorit: daftar destinasi yang ditandai pengguna.
class FavoritPage extends StatelessWidget {
  const FavoritPage({super.key, required this.katalog});

  final KatalogDestinasi katalog;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final store = FavoritScope.of(context);
    final daftar = katalog.destinasi.where((d) => store.apakahFavorit(d.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorit')),
      body: daftar.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: tema.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('Belum ada favorit', style: tema.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk ikon hati pada destinasi untuk menyimpannya di sini.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: daftar.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => DestinasiCard(destinasi: daftar[i]),
            ),
    );
  }
}
