import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../state/favorit_store.dart';
import '../state/store_scope.dart';
import '../tema.dart';

/// Tombol simpan ke Favorit.
///
/// Di atas foto tombol berupa lingkaran putih padat, sehingga ikon gelapnya terbaca di foto apa pun.
/// Hati yang terisi memakai aksen jingga: favorit adalah pilihan pribadi pengguna, setara titik lokasi.
class TombolFavorit extends StatelessWidget {
  const TombolFavorit({super.key, required this.destinasi, this.diAtasFoto = false});

  final Destinasi destinasi;
  final bool diAtasFoto;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of<FavoritStore>(context);
    final favorit = store.apakahFavorit(destinasi.id);
    final ikon = Icon(
      favorit ? Icons.favorite : Icons.favorite_border,
      color: favorit ? WarnaJelma.jingga : WarnaJelma.tinta,
    );
    final tooltip = favorit ? 'Hapus dari favorit' : 'Tambah ke favorit';
    if (!diAtasFoto) {
      return IconButton(tooltip: tooltip, onPressed: () => store.toggle(destinasi.id), icon: ikon);
    }
    return TombolBulat(tooltip: tooltip, onPressed: () => store.toggle(destinasi.id), child: ikon);
  }
}

/// Tombol ikon bundar berlatar putih padat untuk diletakkan di atas foto.
class TombolBulat extends StatelessWidget {
  const TombolBulat({super.key, required this.tooltip, required this.onPressed, required this.child});

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: child,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: WarnaJelma.tinta,
        // Bayangan tipis memisahkan lingkaran putih dari bagian foto yang juga terang.
        elevation: 2,
        shadowColor: Colors.black54,
        minimumSize: const Size(44, 44),
      ),
    );
  }
}
