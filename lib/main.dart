import 'package:flutter/material.dart';

import 'data/destinasi_repository.dart';
import 'pages/detail_page.dart';
import 'pages/shell_page.dart';
import 'state/favorit_store.dart';

void main() {
  runApp(JelajahApp(repository: LocalDestinasiRepository()));
}

/// Aplikasi Jelajah Malang.
///
/// Sumber data diberikan melalui [repository] sehingga dapat diganti dengan
/// implementasi API tanpa mengubah halaman.
class JelajahApp extends StatefulWidget {
  const JelajahApp({super.key, required this.repository});

  final DestinasiRepository repository;

  @override
  State<JelajahApp> createState() => _JelajahAppState();
}

class _JelajahAppState extends State<JelajahApp> {
  final FavoritStore _favorit = FavoritStore();
  late Future<KatalogDestinasi> _katalog = widget.repository.muat();

  @override
  void dispose() {
    _favorit.dispose();
    super.dispose();
  }

  void _muatUlang() => setState(() => _katalog = widget.repository.muat());

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
    return FavoritScope(
      store: _favorit,
      child: MaterialApp(
        title: 'Jelajah Malang',
        debugShowCheckedModeBanner: false,
        theme: _tema(),
        initialRoute: '/',
        routes: {
          '/': (context) => _MuatKatalog(katalog: _katalog, onUlang: _muatUlang),
          '/detail': (context) => const DetailPage(),
        },
      ),
    );
  }
}

/// Menunggu data katalog dimuat, lalu menampilkan [ShellPage].
class _MuatKatalog extends StatelessWidget {
  const _MuatKatalog({required this.katalog, required this.onUlang});

  final Future<KatalogDestinasi> katalog;
  final VoidCallback onUlang;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<KatalogDestinasi>(
      future: katalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Data destinasi gagal dimuat'),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: onUlang, child: const Text('Coba lagi')),
                ],
              ),
            ),
          );
        }
        return ShellPage(katalog: snapshot.data!);
      },
    );
  }
}
