import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/destinasi_repository.dart';
import 'pages/detail_page.dart';
import 'pages/pengaturan_page.dart';
import 'pages/rencana_detail_page.dart';
import 'pages/rencana_form_page.dart';
import 'pages/shell_page.dart';
import 'services/layanan_aplikasi.dart';
import 'state/cakupan_aplikasi.dart';
import 'state/cuaca_store.dart';
import 'state/favorit_store.dart';
import 'state/katalog_store.dart';
import 'state/lokasi_store.dart';
import 'state/notifikasi_store.dart';
import 'state/pengaturan_store.dart';
import 'state/rencana_store.dart';
import 'state/store_scope.dart';
import 'widgets/keadaan_halaman.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final layanan = await LayananAplikasi.bawaan();
  runApp(
    JelajahApp(
      repository: ApiDestinasiRepository(
        cadangan: LocalDestinasiRepository(),
        penyimpanan: layanan.penyimpanan,
      ),
      layanan: layanan,
    ),
  );
}

/// Aplikasi Jelajah Malang.
///
/// Sumber data diberikan melalui [repository] dan layanan luar (GPS, cuaca, notifikasi,
/// penyimpanan) melalui [layanan], sehingga keduanya dapat diganti tanpa mengubah halaman.
class JelajahApp extends StatefulWidget {
  const JelajahApp({super.key, required this.repository, required this.layanan});

  final DestinasiRepository repository;
  final LayananAplikasi layanan;

  @override
  State<JelajahApp> createState() => _JelajahAppState();
}

class _JelajahAppState extends State<JelajahApp> {
  late final KatalogStore _katalog;
  late final PengaturanStore _pengaturan;
  late final LokasiStore _lokasi;
  late final CuacaStore _cuaca;
  late final RencanaStore _rencana;
  late final FavoritStore _favorit;
  late final NotifikasiStore _notifikasi;

  @override
  void initState() {
    super.initState();
    final layanan = widget.layanan;
    _katalog = KatalogStore(widget.repository);
    _pengaturan = PengaturanStore(layanan.penyimpanan);
    _lokasi = LokasiStore(layanan: layanan.lokasi, pengaturan: _pengaturan, waktu: layanan.waktu);
    _cuaca = CuacaStore(layanan: layanan.cuaca, waktu: layanan.waktu);
    _rencana = RencanaStore(
      penyimpanan: layanan.penyimpanan,
      notifikasi: layanan.notifikasi,
      pengaturan: _pengaturan,
      waktu: layanan.waktu,
    );
    _favorit = FavoritStore(penyimpanan: layanan.penyimpanan);
    _notifikasi = NotifikasiStore(layanan.notifikasi);
    _katalog.muat();
  }

  @override
  void dispose() {
    _katalog.dispose();
    _pengaturan.dispose();
    _lokasi.dispose();
    _cuaca.dispose();
    _rencana.dispose();
    _favorit.dispose();
    _notifikasi.dispose();
    super.dispose();
  }

  ThemeData _tema() {
    final skema = ColorScheme.fromSeed(seedColor: const Color(0xFF00796B));
    return ThemeData(
      colorScheme: skema,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F8F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F8F7),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF14312E)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: skema.outlineVariant),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: skema.primary,
        unselectedItemColor: skema.onSurfaceVariant,
        showUnselectedLabels: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CakupanAplikasi(
      katalog: _katalog,
      pengaturan: _pengaturan,
      lokasi: _lokasi,
      cuaca: _cuaca,
      rencana: _rencana,
      favorit: _favorit,
      notifikasi: _notifikasi,
      waktu: widget.layanan.waktu,
      bukaTautan: widget.layanan.bukaTautan,
      child: MaterialApp(
        title: 'Jelajah Malang',
        debugShowCheckedModeBanner: false,
        theme: _tema(),
        // Bahasa Indonesia agar pemilih tanggal dan jam serta tooltip bawaan Material ikut berbahasa Indonesia.
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: '/',
        routes: {
          '/': (context) => const _MuatKatalog(),
          '/detail': (context) => const DetailPage(),
          '/pengaturan': (context) => const PengaturanPage(),
          '/rencana/form': (context) => const RencanaFormPage(),
          '/rencana/detail': (context) => const RencanaDetailPage(),
        },
      ),
    );
  }
}

/// Menunggu katalog dimuat, lalu menampilkan [ShellPage]. Katalog yang dimuat ulang tidak
/// mengganti halaman dengan layar memuat karena data lama tetap dipakai selama proses berjalan.
class _MuatKatalog extends StatelessWidget {
  const _MuatKatalog();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of<KatalogStore>(context);
    final katalog = store.katalog;
    if (katalog != null) return ShellPage(katalog: katalog);
    if (store.status == StatusKatalog.galat) {
      return Scaffold(
        body: KeadaanHalaman(
          ikon: Icons.cloud_off,
          judul: 'Data destinasi gagal dimuat',
          pesan: 'Periksa koneksi internet lalu coba lagi.',
          aksi: AksiHalaman(label: 'Coba lagi', ikon: Icons.refresh, onTekan: store.muat),
        ),
      );
    }
    return const Scaffold(body: KeadaanMemuat(pesan: 'Memuat katalog destinasi...'));
  }
}
