import 'package:flutter/material.dart';

import '../models/cuaca.dart';
import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/gaya_kategori.dart';
import '../models/saran_cuaca.dart';
import '../state/cuaca_store.dart';
import '../state/favorit_store.dart';
import '../state/lokasi_store.dart';
import '../state/store_scope.dart';
import '../widgets/chip_saran.dart';
import '../widgets/gambar_kategori.dart';
import '../widgets/ikon_cuaca.dart';
import 'rencana_form_page.dart';

/// Halaman Detail: informasi lengkap satu destinasi, termasuk status buka, jarak dari lokasi
/// pengguna, cuaca di lokasi destinasi, dan pintasan untuk merencanakan kunjungan atau membuka rute.
///
/// Objek [Destinasi] diterima melalui `arguments` pada `Navigator.pushNamed`.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  Future<void> _bukaRute(BuildContext context, Destinasi d) async {
    final buka = TautanScope.baca(context);
    final pesan = ScaffoldMessenger.of(context);
    final tautan = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${d.koordinat.lintang},${d.koordinat.bujur}',
    });
    var berhasil = false;
    try {
      berhasil = await buka(tautan);
    } catch (_) {
      berhasil = false;
    }
    if (!berhasil) {
      pesan.showSnackBar(const SnackBar(content: Text('Tidak dapat membuka aplikasi peta atau peramban.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final argumen = ModalRoute.of(context)?.settings.arguments;
    if (argumen is! Destinasi) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Data destinasi tidak tersedia')),
      );
    }
    final d = argumen;
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final warna = warnaKategori(d.kategori);
    final store = StoreScope.of<FavoritStore>(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final favorit = store.apakahFavorit(d.id);
    final jarak = d.jarakDari(lokasi.aktif);
    final status = d.statusPada(WaktuScope.baca(context));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: warna,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            title: Text(d.nama),
            flexibleSpace: FlexibleSpaceBar(
              background: GambarKategori(kategori: d.kategori, ukuranIkon: 88),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        avatar: Icon(ikonKategori(d.kategori), size: 18, color: warna),
                        label: Text(namaKategori(d.kategori)),
                        side: BorderSide(color: warna.withValues(alpha: 0.4)),
                        backgroundColor: warna.withValues(alpha: 0.08),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: Color(0xFFF9A825)),
                      const SizedBox(width: 4),
                      Text(d.rating.toStringAsFixed(1), style: tema.textTheme.titleMedium),
                      Text(' / 5', style: tema.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(d.nama, style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        _BarisInfo(
                          ikon: Icons.place_outlined,
                          judul: 'Lokasi',
                          nilai: d.lokasi,
                          keterangan: d.koordinatPerkiraan
                              ? 'Titik perkiraan di pusat kota karena hidangan ini tersebar di banyak tempat.'
                              : null,
                        ),
                        if (jarak != null) ...[
                          const Divider(height: 1),
                          _BarisInfo(
                            ikon: Icons.near_me_outlined,
                            judul: 'Jarak dari lokasi Anda',
                            nilai: '${formatJarak(jarak)} (garis lurus)',
                            keterangan: lokasi.label,
                          ),
                        ],
                        const Divider(height: 1),
                        _BarisInfo(
                          ikon: Icons.schedule,
                          judul: 'Jam buka',
                          nilai: d.jamBuka,
                          keterangan: status?.label,
                          warnaKeterangan: status == null ? null : (status.terbuka ? skema.primary : skema.error),
                        ),
                        const Divider(height: 1),
                        _BarisInfo(
                          ikon: Icons.confirmation_number_outlined,
                          judul: d.judulHarga,
                          nilai: d.hargaLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Rating, harga, dan jam buka adalah data contoh.',
                      style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Cuaca di lokasi ini', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _KartuCuacaDestinasi(destinasi: d),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/rencana/form',
                          arguments: FormRencanaArgumen(destinasiAwal: d),
                        ),
                        icon: const Icon(Icons.event_available),
                        label: const Text('Rencanakan kunjungan'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _bukaRute(context, d),
                        icon: const Icon(Icons.directions),
                        label: const Text('Buka rute di Google Maps'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Tentang', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(d.deskripsi, style: tema.textTheme.bodyLarge?.copyWith(height: 1.5)),
                  const SizedBox(height: 20),
                  Text('Fasilitas', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final f in d.fasilitas) Chip(label: Text(f))],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => store.toggle(d.id),
            icon: Icon(favorit ? Icons.favorite : Icons.favorite_border),
            label: Text(favorit ? 'Hapus dari Favorit' : 'Tambah ke Favorit'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ),
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({
    required this.ikon,
    required this.judul,
    required this.nilai,
    this.keterangan,
    this.warnaKeterangan,
  });

  final IconData ikon;
  final String judul;
  final String nilai;

  /// Baris kecil di bawah nilai, misalnya status buka atau asal lokasi.
  final String? keterangan;
  final Color? warnaKeterangan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(ikon, color: tema.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: tema.textTheme.labelMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(nilai, style: tema.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (keterangan != null)
                  Text(
                    keterangan!,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: warnaKeterangan ?? tema.colorScheme.onSurfaceVariant,
                      fontWeight: warnaKeterangan == null ? null : FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuaca saat ini di titik destinasi, saran kunjungan hari ini, dan prakiraan beberapa hari ke depan.
class _KartuCuacaDestinasi extends StatelessWidget {
  const _KartuCuacaDestinasi({required this.destinasi});

  final Destinasi destinasi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final cuaca = StoreScope.of<CuacaStore>(context);
    final prakiraan = cuaca.untukDestinasi(destinasi);
    final hari = prakiraan?.hariIni;

    if (prakiraan == null || hari == null) {
      final galat = cuaca.status == StatusCuaca.galat;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              galat
                  ? Icon(Icons.cloud_off, color: skema.error)
                  : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  galat
                      ? 'Cuaca belum dapat dimuat. Buka tab Cuaca lalu muat ulang.'
                      : 'Memuat cuaca di lokasi destinasi...',
                  style: tema.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final kini = prakiraan.saatIni;
    final saran = saranKunjungan(destinasi, hari);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IkonCuaca(kondisi: kini.kondisi, ukuran: 40, warna: skema.primary),
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
                        'Terasa ${formatSuhu(kini.suhuTerasa)}, kelembapan ${kini.kelembapan}%, angin ${kini.angin.round()} km/jam',
                        style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ChipSaran(saran: saran),
            const SizedBox(height: 6),
            Text(saran.penjelasan, style: tema.textTheme.bodyMedium),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < prakiraan.harian.length && i < 4; i++)
                  Expanded(child: _HariMini(hari: prakiraan.harian[i], pertama: i == 0)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HariMini extends StatelessWidget {
  const _HariMini({required this.hari, required this.pertama});

  final CuacaHarian hari;
  final bool pertama;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Text(
          pertama ? 'Hari ini' : namaHariSingkat(hari.tanggal),
          style: tema.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        IkonCuaca(kondisi: hari.kondisi, ukuran: 24, warna: tema.colorScheme.primary),
        const SizedBox(height: 4),
        Text('${hari.suhuMaks.round()}° / ${hari.suhuMin.round()}°', style: tema.textTheme.labelSmall),
        Text('Hujan ${hari.peluangHujan}%', style: tema.textTheme.labelSmall),
      ],
    );
  }
}
