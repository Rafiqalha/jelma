import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/destinasi_repository.dart';
import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/saran_cuaca.dart';
import '../state/cuaca_store.dart';
import '../state/lokasi_store.dart';
import '../state/pengaturan_store.dart';
import '../state/store_scope.dart';
import '../tema.dart';
import '../widgets/chip_saran.dart';
import '../widgets/destinasi_baris.dart';
import '../widgets/ikon_cuaca.dart';
import '../widgets/kartu_destinasi_mini.dart';
import '../widgets/logo_jelma.dart';
import '../widgets/panel_izin_lokasi.dart';

/// Halaman Beranda.
///
/// Titik fokusnya deret foto "Cocok untuk cuaca hari ini", karena kecocokan cuaca per lokasi
/// adalah hal yang membedakan JELMA. Bagian lain berganti bentuk (deret kategori, baris ringkas,
/// deret foto kecil) agar halaman tidak terasa seperti satu templat yang diulang.
class BerandaPage extends StatelessWidget {
  const BerandaPage({
    super.key,
    required this.katalog,
    required this.onKategori,
    required this.onCari,
    required this.onBukaCuaca,
  });

  final KatalogDestinasi katalog;

  /// Dipanggil saat kategori diketuk; menerima identitas kategori.
  final ValueChanged<String> onKategori;

  /// Dipanggil saat kolom pencarian diketuk.
  final VoidCallback onCari;

  /// Dipanggil saat kartu cuaca diketuk; membuka tab Cuaca.
  final VoidCallback onBukaCuaca;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final populer = katalog.populer;
    final peringkat = katalog.ratingTertinggi;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _Kepala(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _KolomCari(onTap: onCari),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _KartuCuacaRingkas(onTap: onBukaCuaca),
            ),
            ..._bagianCocok(context),
            const _JudulBagian('Kategori'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (final k in katalog.kategori)
                    Expanded(child: _KategoriTile(kategori: k, onTap: () => onKategori(k.id))),
                ],
              ),
            ),
            ..._bagianDekat(context),
            if (populer.isNotEmpty) ...[
              const _JudulBagian('Populer'),
              DeretMendatar(
                anak: [for (final d in populer) KartuDestinasiMini(destinasi: d, asalHero: 'populer')],
              ),
            ],
            const _JudulBagian('Rating tertinggi'),
            for (var i = 0; i < peringkat.length; i++)
              DestinasiBaris(
                destinasi: peringkat[i],
                asalHero: 'peringkat',
                awalan: SizedBox(
                  width: 20,
                  child: Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.titleLarge?.copyWith(color: WarnaJelma.hijau),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Rating, harga, dan jam buka adalah data contoh. Cuaca, koordinat, dan foto berasal dari '
                'sumber nyata; kredit foto ada di Pengaturan.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Destinasi yang cuaca hari ininya mendukung kunjungan, diurutkan dari yang terdekat atau berating tertinggi.
  List<Widget> _bagianCocok(BuildContext context) {
    final tema = Theme.of(context);
    final cuaca = StoreScope.of<CuacaStore>(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final kandidat = <({Destinasi destinasi, SaranCuaca saran})>[];
    for (final d in katalog.destinasi) {
      final hari = cuaca.untukDestinasi(d)?.hariIni;
      if (hari == null) continue;
      final saran = saranKunjungan(d, hari);
      if (saran.tingkat == TingkatSaran.baik) kandidat.add((destinasi: d, saran: saran));
    }
    const judul = 'Cocok untuk cuaca hari ini';
    if (kandidat.isEmpty) {
      final teks = !cuaca.adaData
          ? (cuaca.status == StatusCuaca.galat
              ? 'Saran cuaca belum tersedia karena cuaca gagal dimuat.'
              : 'Memuat saran cuaca untuk setiap destinasi...')
          : 'Belum ada destinasi yang cocok dengan cuaca hari ini. Buka tab Cuaca untuk rinciannya.';
      return [
        const _JudulBagian(judul),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(teks, style: tema.textTheme.bodyMedium),
        ),
      ];
    }
    final titik = lokasi.aktif;
    kandidat.sort((a, b) {
      if (titik != null) return a.destinasi.jarakDari(titik)!.compareTo(b.destinasi.jarakDari(titik)!);
      return b.destinasi.rating.compareTo(a.destinasi.rating);
    });
    return [
      const _JudulBagian(judul, keterangan: 'Dinilai dari prakiraan di lokasi masing-masing destinasi.'),
      DeretMendatar(
        anak: [
          for (final k in kandidat.take(6))
            KartuDestinasiMini(
              destinasi: k.destinasi,
              asalHero: 'cocok',
              lebar: 264,
              keterangan: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titik == null ? k.destinasi.lokasi : formatJarak(k.destinasi.jarakDari(titik)!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                  ),
                  const SizedBox(height: 6),
                  ChipSaran(saran: k.saran),
                ],
              ),
            ),
        ],
      ),
    ];
  }

  /// Tiga destinasi terdekat dalam radius pilihan pengguna, atau penjelasan bila lokasi belum diketahui.
  List<Widget> _bagianDekat(BuildContext context) {
    final tema = Theme.of(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final pengaturan = StoreScope.of<PengaturanStore>(context);
    final titik = lokasi.aktif;
    if (titik == null) {
      return const [
        _JudulBagian('Dekat Anda'),
        Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: PanelIzinLokasi()),
      ];
    }
    final radius = pengaturan.radiusKm;
    final dekat = katalog.destinasi.where((d) => d.jarakDari(titik)! <= radius).toList()
      ..sort((a, b) => a.jarakDari(titik)!.compareTo(b.jarakDari(titik)!));
    final judul = _JudulBagian(
      'Dekat Anda',
      keterangan: 'Dalam radius ${radius.round()} km dari ${lokasi.label}',
    );
    if (dekat.isEmpty) {
      return [
        judul,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tidak ada destinasi dalam radius ${radius.round()} km dari lokasi aktif. '
                'Perbesar radius atau pilih area lain di Pengaturan.',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/pengaturan'),
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      judul,
      for (final d in dekat.take(3)) DestinasiBaris(destinasi: d, asalHero: 'dekat'),
    ];
  }
}

/// Logo, tombol Pengaturan, salam menurut jam WIB, dan pertanyaan pembuka.
class _Kepala extends StatelessWidget {
  const _Kepala();

  String _salam(DateTime waktu) => switch (waktu.hour) {
        < 11 => 'Selamat pagi',
        < 15 => 'Selamat siang',
        < 18 => 'Selamat sore',
        _ => 'Selamat malam',
      };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MerekJelma(),
              const Spacer(),
              IconButton(
                tooltip: 'Pengaturan',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.pushNamed(context, '/pengaturan'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _salam(WaktuScope.baca(context)),
            style: tema.textTheme.bodyLarge?.copyWith(color: WarnaJelma.tintaLembut),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('Mau ke mana hari ini?', style: tema.textTheme.headlineMedium),
          ),
        ],
      ),
    );
  }
}

/// Tombol berbentuk kolom pencarian; membuka tab Jelajah tempat pencarian sebenarnya.
class _KolomCari extends StatelessWidget {
  const _KolomCari({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Cari destinasi',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: WarnaJelma.garisKontrol),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                const Icon(Icons.search, color: WarnaJelma.tinta),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cari destinasi, kuliner, atau lokasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodyLarge?.copyWith(color: WarnaJelma.tintaLembut),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lokasi aktif dan cuaca di sana; mengetuknya membuka halaman Cuaca.
///
/// Titik jingga di depan nama lokasi adalah motif yang sama dengan titik pada logo.
class _KartuCuacaRingkas extends StatelessWidget {
  const _KartuCuacaRingkas({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final lokasi = StoreScope.of<LokasiStore>(context);
    final cuaca = StoreScope.of<CuacaStore>(context);
    final prakiraan = cuaca.untukTitik(lokasi.untukCuaca);
    final hari = prakiraan?.hariIni;

    final baris = Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: WarnaJelma.jingga, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lokasi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.labelLarge,
          ),
        ),
      ],
    );

    final Widget isi;
    if (prakiraan == null) {
      final galat = cuaca.status == StatusCuaca.galat;
      isi = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                baris,
                const SizedBox(height: 4),
                Text(
                  galat
                      ? 'Cuaca belum dapat dimuat. Ketuk untuk membuka halaman Cuaca dan mencoba lagi.'
                      : 'Memuat cuaca di ${lokasi.label}...',
                  style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          galat
              ? Icon(Icons.cloud_off, color: skema.error)
              : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
        ],
      );
    } else {
      final kini = prakiraan.saatIni;
      isi = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                baris,
                const SizedBox(height: 4),
                Text(
                  hari == null ? kini.kondisi.label : '${kini.kondisi.label}, peluang hujan hari ini ${hari.peluangHujan}%',
                  style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IkonCuaca(kondisi: kini.kondisi, ukuran: 30, warna: WarnaJelma.hijau),
          const SizedBox(width: 6),
          Text(formatSuhu(kini.suhu), style: tema.textTheme.titleLarge),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right, color: WarnaJelma.tintaLembut),
        ],
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 10, 14), child: isi),
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian(this.teks, {this.keterangan});

  final String teks;
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 28, 20, keterangan == null ? 12 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(teks, style: tema.textTheme.titleLarge?.copyWith(fontSize: 20)),
          if (keterangan != null) ...[
            const SizedBox(height: 2),
            Text(keterangan!, style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut)),
          ],
        ],
      ),
    );
  }
}

class _KategoriTile extends StatelessWidget {
  const _KategoriTile({required this.kategori, required this.onTap});

  final Kategori kategori;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: WarnaJelma.garis),
              ),
              child: Icon(kategori.ikonData, color: WarnaJelma.hijau, size: 28),
            ),
            const SizedBox(height: 8),
            Text(kategori.nama, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
