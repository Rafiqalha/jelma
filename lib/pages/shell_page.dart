import 'package:flutter/material.dart';

import '../data/destinasi_repository.dart';
import '../state/favorit_store.dart';
import 'beranda_page.dart';
import 'favorit_page.dart';
import 'jelajah_page.dart';

/// Kerangka utama aplikasi: tiga tab (Beranda, Jelajah, Favorit) yang dipindahkan
/// dengan [BottomNavigationBar]. Halaman Detail dibuka terpisah dengan `Navigator`.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.katalog});

  final KatalogDestinasi katalog;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _tab = 0;
  String _kategori = 'semua';

  void _pilihTab(int indeks) => setState(() => _tab = indeks);

  /// Membuka tab Jelajah dengan kategori yang dipilih dari Beranda.
  void _bukaKategori(String id) => setState(() {
        _kategori = id;
        _tab = 1;
      });

  @override
  Widget build(BuildContext context) {
    final jumlahFavorit = FavoritScope.of(context).jumlah;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          BerandaPage(
            katalog: widget.katalog,
            onKategori: _bukaKategori,
            onCari: () => _bukaKategori('semua'),
          ),
          JelajahPage(
            katalog: widget.katalog,
            kategoriTerpilih: _kategori,
            onKategoriBerubah: (id) => setState(() => _kategori = id),
          ),
          FavoritPage(katalog: widget.katalog),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: _pilihTab,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Jelajah',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: jumlahFavorit > 0,
              label: Text('$jumlahFavorit'),
              child: const Icon(Icons.favorite_border),
            ),
            activeIcon: Badge(
              isLabelVisible: jumlahFavorit > 0,
              label: Text('$jumlahFavorit'),
              child: const Icon(Icons.favorite),
            ),
            label: 'Favorit',
          ),
        ],
      ),
    );
  }
}
