import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/destinasi_repository.dart';
import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/gaya_kategori.dart';
import '../models/saran_cuaca.dart';
import '../state/cuaca_store.dart';
import '../state/lokasi_store.dart';
import '../state/pengaturan_store.dart';
import '../state/store_scope.dart';
import '../widgets/chip_saran.dart';
import '../widgets/destinasi_card.dart';
import '../widgets/ikon_cuaca.dart';
import '../widgets/kartu_destinasi_mini.dart';
import '../widgets/panel_izin_lokasi.dart';

/// Halaman Beranda: sambutan, ringkasan cuaca di lokasi pengguna, kategori, destinasi yang cocok
/// dengan cuaca hari ini, destinasi terdekat, populer, dan rating tertinggi.
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
    final skema = Theme.of(context).colorScheme;
    final atas = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Header berlatar gelap sehingga ikon status bar dibuat terang.
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Column(
        children: [
          // Blok berwarna sama dengan awal gradasi header agar isi daftar tidak tampak di bawah ikon sistem.
          Container(height: atas, color: skema.primary),
          Expanded(child: _isi(context)),
        ],
      ),
    );
  }

  Widget _isi(BuildContext context) {
    final populer = katalog.populer;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(onCari: onCari),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _KartuCuacaRingkas(onTap: onBukaCuaca),
        ),
        const _JudulBagian('Kategori'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final k in katalog.kategori)
                Expanded(child: _KategoriTile(kategori: k, onTap: () => onKategori(k.id))),
            ],
          ),
        ),
        ..._bagianCocok(context),
        ..._bagianDekat(context),
        const _JudulBagian('Populer'),
        SizedBox(
          height: tinggiDaftarMendatar(context, 200),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: populer.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => KartuDestinasiMini(destinasi: populer[i]),
          ),
        ),
        const _JudulBagian('Rating tertinggi'),
        for (final d in katalog.ratingTertinggi)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DestinasiCard(destinasi: d),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Text(
            'Rating, harga, dan jam buka adalah data contoh. Cuaca dan koordinat berasal dari sumber nyata (lihat Pengaturan).',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  /// Destinasi yang cuaca hari ininya mendukung kunjungan, diurutkan dari yang terdekat atau berating tertinggi.
  List<Widget> _bagianCocok(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(teks, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ];
    }
    final titik = lokasi.aktif;
    kandidat.sort((a, b) {
      if (titik != null) return a.destinasi.jarakDari(titik)!.compareTo(b.destinasi.jarakDari(titik)!);
      return b.destinasi.rating.compareTo(a.destinasi.rating);
    });
    final tampil = kandidat.take(6).toList();
    return [
      const _JudulBagian(judul, keterangan: 'Dinilai dari prakiraan di lokasi masing-masing destinasi.'),
      SizedBox(
        height: tinggiDaftarMendatar(context, 236),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: tampil.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final k = tampil[i];
            final jarak = k.destinasi.jarakDari(titik);
            return KartuDestinasiMini(
              destinasi: k.destinasi,
              keterangan: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChipSaran(saran: k.saran),
                  const SizedBox(height: 4),
                  Text(
                    jarak == null ? k.destinasi.lokasi : formatJarak(jarak),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
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
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: PanelIzinLokasi()),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
      for (final d in dekat.take(3))
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DestinasiCard(destinasi: d),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCari});

  final VoidCallback onCari;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skema.primary, Color.lerp(skema.primary, Colors.black, 0.32)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jelajah Malang',
                      style: tema.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Pengaturan',
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/pengaturan'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Temukan tempat wisata, budaya, kuliner, dan edukasi di Malang Raya.',
                      style: tema.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: onCari,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: skema.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Text(
                                'Cari destinasi...',
                                style: tema.textTheme.bodyLarge?.copyWith(color: skema.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ringkasan cuaca di lokasi aktif; mengetuknya membuka halaman Cuaca.
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

    final Widget isi;
    if (prakiraan == null) {
      final galat = cuaca.status == StatusCuaca.galat;
      isi = Row(
        children: [
          galat
              ? Icon(Icons.cloud_off, color: skema.error)
              : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              galat
                  ? 'Cuaca belum dapat dimuat. Ketuk untuk membuka halaman Cuaca dan mencoba lagi.'
                  : 'Memuat cuaca di ${lokasi.label}...',
              style: tema.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    } else {
      final kini = prakiraan.saatIni;
      isi = Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: skema.primaryContainer,
            child: IkonCuaca(kondisi: kini.kondisi, ukuran: 28, warna: skema.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatSuhu(kini.suhu)} ${kini.kondisi.label}',
                  style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  lokasi.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                ),
                if (hari != null)
                  Text('Peluang hujan hari ini ${hari.peluangHujan}%', style: tema.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: skema.onSurfaceVariant),
        ],
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: isi),
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
      padding: EdgeInsets.fromLTRB(16, 24, 16, keterangan == null ? 12 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(teks, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (keterangan != null) ...[
            const SizedBox(height: 2),
            Text(
              keterangan!,
              style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
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
    final warna = warnaKategori(kategori.id);
    return InkResponse(
      onTap: onTap,
      radius: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: warna.withValues(alpha: 0.14),
            child: Icon(kategori.ikonData, color: warna, size: 28),
          ),
          const SizedBox(height: 8),
          Text(kategori.nama, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
