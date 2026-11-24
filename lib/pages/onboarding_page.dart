import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/katalog_store.dart';
import '../state/lokasi_store.dart';
import '../state/store_scope.dart';
import '../tema.dart';
import '../widgets/logo_jelma.dart';

/// Isi satu halaman pengenalan. Foto dan kreditnya sama dengan entri katalog destinasi terkait.
class _Halaman {
  const _Halaman({required this.foto, required this.kredit, required this.judul});

  final String foto;
  final String kredit;
  final String judul;
}

const List<_Halaman> _daftarHalaman = [
  _Halaman(
    foto: 'assets/images/destinasi/04-kampung-warna-warni-jodipan.jpg',
    kredit: 'Foto Kampung Warna-Warni Jodipan: Dominic Nelson, CC BY-SA 4.0',
    judul: 'Kenali tempatnya sebelum berangkat',
  ),
  _Halaman(
    foto: 'assets/images/destinasi/01-coban-rondo.jpg',
    kredit: 'Foto Coban Rondo: Habitat salwa, CC BY-SA 4.0',
    judul: 'Cuaca dicek di titik destinasinya',
  ),
  _Halaman(
    foto: 'assets/images/destinasi/02-pantai-balekambang.jpg',
    kredit: 'Foto Pantai Balekambang: Maulana Yusuf, CC BY-SA 4.0',
    judul: 'Mulai dari lokasi Anda',
  ),
];

/// Pengenalan singkat pada pembukaan pertama: tiga halaman, bisa dilewati kapan saja.
///
/// Riset NN/g menunjukkan tutorial panjang jarang dibaca, jadi setiap halaman hanya memuat satu
/// hal yang perlu diketahui sebelum mulai. Izin lokasi diminta di halaman terakhir, setelah
/// alasannya dijelaskan, dan selalu ada pilihan "Nanti saja".
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onSelesai});

  /// Dipanggil saat pengenalan selesai atau dilewati.
  final VoidCallback onSelesai;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _halaman = PageController();
  int _indeks = 0;
  bool _memintaIzin = false;

  bool get _terakhir => _indeks == _daftarHalaman.length - 1;

  @override
  void dispose() {
    _halaman.dispose();
    super.dispose();
  }

  void _keHalaman(int indeks) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _halaman.jumpToPage(indeks);
    } else {
      _halaman.animateToPage(indeks, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _izinkanLokasi() async {
    setState(() => _memintaIzin = true);
    await StoreScope.baca<LokasiStore>(context).mintaIzinDulu();
    if (!mounted) return;
    setState(() => _memintaIzin = false);
    widget.onSelesai();
  }

  String _isi(int indeks, int? jumlah) => switch (indeks) {
        0 => 'Titik lokasi dan rute untuk ${jumlah == null ? '' : '$jumlah '}destinasi alam, budaya, kuliner, '
            'dan edukasi di Malang Raya, sebagian besar lengkap dengan foto asli.',
        1 => 'Prakiraan Open-Meteo diambil untuk lokasi setiap destinasi, lengkap dengan saran seperti '
            'cocok dikunjungi, bawa jas hujan, atau sebaiknya ditunda.',
        _ => 'Izinkan lokasi agar jarak dan cuaca dihitung dari posisi Anda. Tanpa izin, JELMA memakai area '
            'yang Anda pilih di Pengaturan atau pusat Kota Malang.',
      };

  @override
  Widget build(BuildContext context) {
    final jumlah = StoreScope.of<KatalogStore>(context).katalog?.destinasi.length;
    final ukuran = MediaQuery.sizeOf(context);
    final lebar = ukuran.width >= 600 && ukuran.width > ukuran.height;

    return PopScope(
      canPop: _indeks == 0,
      onPopInvokedWithResult: (sudah, _) {
        if (!sudah && _indeks > 0) _keHalaman(_indeks - 1);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _halaman,
                    itemCount: _daftarHalaman.length,
                    onPageChanged: (i) => setState(() => _indeks = i),
                    itemBuilder: (context, i) {
                      final foto = _FotoPengenalan(halaman: _daftarHalaman[i]);
                      final teks = _TeksPengenalan(
                        halaman: _daftarHalaman[i],
                        isi: _isi(i, jumlah),
                        pertama: i == 0,
                      );
                      return lebar
                          ? Row(
                              children: [
                                Expanded(child: foto),
                                Expanded(child: SingleChildScrollView(child: teks)),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(flex: 11, child: foto),
                                Expanded(flex: 9, child: SingleChildScrollView(child: teks)),
                              ],
                            );
                    },
                  ),
                ),
                _Kendali(
                  indeks: _indeks,
                  jumlah: _daftarHalaman.length,
                  terakhir: _terakhir,
                  memintaIzin: _memintaIzin,
                  onLanjut: () => _keHalaman(_indeks + 1),
                  onLewati: widget.onSelesai,
                  onIzinkan: _izinkanLokasi,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FotoPengenalan extends StatelessWidget {
  const _FotoPengenalan({required this.halaman});

  final _Halaman halaman;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          halaman.foto,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          excludeFromSemantics: true,
          errorBuilder: (context, galat, jejak) => const ColoredBox(color: WarnaJelma.hijauMuda),
        ),
      ),
    );
  }
}

class _TeksPengenalan extends StatelessWidget {
  const _TeksPengenalan({required this.halaman, required this.isi, required this.pertama});

  final _Halaman halaman;
  final String isi;
  final bool pertama;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pertama) ...[const MerekJelma(ukuran: 28), const SizedBox(height: 16)],
          Semantics(header: true, child: Text(halaman.judul, style: tema.textTheme.headlineMedium)),
          const SizedBox(height: 10),
          Text(isi, style: tema.textTheme.bodyLarge?.copyWith(color: WarnaJelma.tintaLembut)),
          const SizedBox(height: 12),
          Text(halaman.kredit, style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut)),
        ],
      ),
    );
  }
}

/// Penanda halaman, tombol Lewati, dan tombol utama. Di halaman terakhir tombol utama meminta izin lokasi.
class _Kendali extends StatelessWidget {
  const _Kendali({
    required this.indeks,
    required this.jumlah,
    required this.terakhir,
    required this.memintaIzin,
    required this.onLanjut,
    required this.onLewati,
    required this.onIzinkan,
  });

  final int indeks;
  final int jumlah;
  final bool terakhir;
  final bool memintaIzin;
  final VoidCallback onLanjut;
  final VoidCallback onLewati;
  final VoidCallback onIzinkan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final penanda = Semantics(
      label: 'Halaman ${indeks + 1} dari $jumlah',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < jumlah; i++)
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              width: i == indeks ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                // Penanda aktif memakai titik jingga yang sama dengan logo.
                color: i == indeks ? WarnaJelma.jingga : WarnaJelma.garisKontrol,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );

    if (terakhir) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: penanda),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: memintaIzin ? null : onIzinkan,
              icon: memintaIzin
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: Text(memintaIzin ? 'Menunggu izin...' : 'Izinkan lokasi'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 4),
            TextButton(onPressed: memintaIzin ? null : onLewati, child: const Text('Nanti saja')),
            Text(
              'Izin notifikasi baru diminta saat Anda menyimpan rencana kunjungan.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          penanda,
          const Spacer(),
          TextButton(onPressed: onLewati, child: const Text('Lewati')),
          const SizedBox(width: 8),
          FilledButton(onPressed: onLanjut, child: const Text('Lanjut')),
        ],
      ),
    );
  }
}
