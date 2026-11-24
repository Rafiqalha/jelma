import 'package:flutter/material.dart';

import '../data/destinasi_repository.dart';
import '../state/cuaca_store.dart';
import '../state/favorit_store.dart';
import '../state/lokasi_store.dart';
import '../state/rencana_store.dart';
import '../state/store_scope.dart';
import '../tema.dart';
import 'beranda_page.dart';
import 'cuaca_page.dart';
import 'favorit_page.dart';
import 'jelajah_page.dart';
import 'rencana_page.dart';

/// Kerangka utama aplikasi: lima tab (Beranda, Jelajah, Cuaca, Rencana, Favorit) yang dipindahkan
/// dengan [NavigationBar] Material 3. Halaman lain dibuka terpisah dengan `Navigator`.
///
/// Kerangka ini juga menghubungkan lokasi, cuaca, dan rencana: cuaca dimuat ulang saat lokasi
/// berubah, dan notifikasi rencana disesuaikan setiap kali cuaca berhasil dimuat.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.katalog});

  final KatalogDestinasi katalog;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _tab = 0;
  String _kategori = 'semua';

  /// Jumlah ketukan kolom cari Beranda; perubahan nilainya membuat kolom cari Jelajah aktif.
  int _mintaCari = 0;

  late final LokasiStore _lokasi;
  late final CuacaStore _cuaca;
  late final RencanaStore _rencana;
  String? _kunciCuaca;
  DateTime? _sinkronTerakhir;

  @override
  void initState() {
    super.initState();
    _lokasi = StoreScope.baca<LokasiStore>(context);
    _cuaca = StoreScope.baca<CuacaStore>(context);
    _rencana = StoreScope.baca<RencanaStore>(context);
    _lokasi.addListener(_muatCuaca);
    _cuaca.addListener(_sinkronkanNotifikasi);
    // Dijalankan setelah frame pertama karena store memberi tahu pendengarnya secara langsung.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _lokasi.mulai();
    });
  }

  @override
  void didUpdateWidget(ShellPage lama) {
    super.didUpdateWidget(lama);
    if (!identical(lama.katalog, widget.katalog)) {
      _kunciCuaca = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _muatCuaca();
      });
    }
  }

  @override
  void dispose() {
    _lokasi.removeListener(_muatCuaca);
    _cuaca.removeListener(_sinkronkanNotifikasi);
    super.dispose();
  }

  /// Memuat cuaca setelah lokasi diketahui, dan lagi hanya bila titiknya berubah.
  void _muatCuaca() {
    final status = _lokasi.status;
    if (status == StatusLokasi.memuat || status == StatusLokasi.belumDicek) return;
    final titik = _lokasi.untukCuaca;
    if (titik.kunci == _kunciCuaca) return;
    _kunciCuaca = titik.kunci;
    _cuaca.muat(lokasi: titik, destinasi: widget.katalog.destinasi);
  }

  void _sinkronkanNotifikasi() {
    final waktu = _cuaca.diperbaruiPada;
    if (_cuaca.status != StatusCuaca.siap || waktu == null || waktu == _sinkronTerakhir) return;
    _sinkronTerakhir = waktu;
    _rencana.sinkronkan(katalog: widget.katalog, cuaca: _cuaca);
  }

  void _pilihTab(int indeks) {
    // Keyboard kolom cari tidak ikut terbawa ke tab lain.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = indeks);
  }

  /// Membuka tab Jelajah dengan kategori yang dipilih dari Beranda.
  void _bukaKategori(String id) => setState(() {
        _kategori = id;
        _tab = 1;
      });

  @override
  Widget build(BuildContext context) {
    final jumlahFavorit = StoreScope.of<FavoritStore>(context).jumlah;
    final adaRencana = StoreScope.of<RencanaStore>(context).daftar.isNotEmpty;
    return Scaffold(
      // Tombol ini dipasang di sini, bukan di Scaffold halaman Rencana, karena SnackBar selalu tampil
      // di Scaffold terluar dan hanya memberi ruang untuk tombol di Scaffold yang sama. Di Scaffold
      // halaman Rencana, pesan "Rencana disimpan" menutupi tombolnya.
      floatingActionButton: _tab == 3 && adaRencana
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/rencana/form'),
              icon: const Icon(Icons.add),
              label: const Text('Buat rencana'),
            )
          : null,
      body: IndexedStack(
        index: _tab,
        children: [
          BerandaPage(
            katalog: widget.katalog,
            onKategori: _bukaKategori,
            onCari: () {
              _mintaCari++;
              _bukaKategori('semua');
            },
            onBukaCuaca: () => _pilihTab(2),
          ),
          JelajahPage(
            katalog: widget.katalog,
            kategoriTerpilih: _kategori,
            onKategoriBerubah: (id) => setState(() => _kategori = id),
            permintaanCari: _mintaCari,
          ),
          CuacaPage(katalog: widget.katalog),
          RencanaPage(katalog: widget.katalog),
          FavoritPage(katalog: widget.katalog),
        ],
      ),
      // Garis tipis memisahkan bilah navigasi putih dari isi halaman yang bergulir di atasnya.
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: WarnaJelma.garis))),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _pilihTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Jelajah',
            ),
            const NavigationDestination(
              icon: Icon(Icons.wb_cloudy_outlined),
              selectedIcon: Icon(Icons.wb_cloudy),
              label: 'Cuaca',
            ),
            const NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Rencana',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: jumlahFavorit > 0,
                label: Text('$jumlahFavorit'),
                child: const Icon(Icons.favorite_border),
              ),
              selectedIcon: Badge(
                isLabelVisible: jumlahFavorit > 0,
                label: Text('$jumlahFavorit'),
                child: const Icon(Icons.favorite),
              ),
              label: 'Favorit',
            ),
          ],
        ),
      ),
    );
  }
}
