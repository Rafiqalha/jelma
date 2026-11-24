import 'package:flutter/material.dart';

import '../data/destinasi_repository.dart';
import '../state/favorit_store.dart';
import '../state/store_scope.dart';
import '../widgets/destinasi_card.dart';
import '../widgets/keadaan_halaman.dart';
import '../widgets/tombol_pengaturan.dart';

/// Halaman Favorit: daftar destinasi yang ditandai pengguna, tersimpan permanen.
class FavoritPage extends StatelessWidget {
  const FavoritPage({super.key, required this.katalog});

  final KatalogDestinasi katalog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of<FavoritStore>(context);
    final daftar = katalog.destinasi.where((d) => store.apakahFavorit(d.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorit'), actions: const [TombolPengaturan()]),
      body: daftar.isEmpty
          ? const KeadaanHalaman(
              ikon: Icons.favorite_border,
              judul: 'Belum ada favorit',
              pesan: 'Ketuk ikon hati pada destinasi untuk menyimpannya di sini.',
            )
          : DaftarKartuDestinasi(daftar: daftar, asalHero: 'favorit'),
    );
  }
}
