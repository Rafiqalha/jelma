import 'package:flutter/material.dart';

import '../data/destinasi_repository.dart';
import '../models/cuaca.dart';
import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/saran_cuaca.dart';
import '../state/cuaca_store.dart';
import '../state/lokasi_store.dart';
import '../state/store_scope.dart';
import '../widgets/chip_saran.dart';
import '../widgets/gambar_kategori.dart';
import '../widgets/ikon_cuaca.dart';
import '../widgets/kartu_cuaca_utama.dart';
import '../widgets/keadaan_halaman.dart';
import '../widgets/panel_izin_lokasi.dart';
import '../widgets/tombol_pengaturan.dart';

enum _Saring { semua, cocok, dalamRuangan }

/// Halaman Cuaca: cuaca di lokasi pengguna, prakiraan tujuh hari, saran perlengkapan,
/// dan kecocokan setiap destinasi dengan cuaca hari ini.
class CuacaPage extends StatefulWidget {
  const CuacaPage({super.key, required this.katalog});

  final KatalogDestinasi katalog;

  @override
  State<CuacaPage> createState() => _CuacaPageState();
}

class _CuacaPageState extends State<CuacaPage> {
  _Saring _saring = _Saring.semua;

  Future<void> _muatUlang() async {
    final lokasi = StoreScope.baca<LokasiStore>(context);
    final cuaca = StoreScope.baca<CuacaStore>(context);
    await lokasi.perbarui();
    await cuaca.muat(lokasi: lokasi.untukCuaca, destinasi: widget.katalog.destinasi);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final cuaca = StoreScope.of<CuacaStore>(context);
    final prakiraan = cuaca.untukTitik(lokasi.untukCuaca);
    final baris = _susunBaris(lokasi, cuaca);
    final tampil = switch (_saring) {
      _Saring.semua => baris,
      _Saring.cocok => baris.where((b) => b.saran.tingkat == TingkatSaran.baik).toList(),
      _Saring.dalamRuangan => baris.where((b) => b.destinasi.ruang != Ruang.terbuka).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaca'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang cuaca',
            icon: const Icon(Icons.refresh),
            onPressed: _muatUlang,
          ),
          const TombolPengaturan(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _muatUlang,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const PanelIzinLokasi(),
            if (prakiraan != null)
              KartuCuacaUtama(lokasi: lokasi.label, sumber: lokasi.sumberLabel, prakiraan: prakiraan)
            else if (cuaca.status == StatusCuaca.galat)
              _KartuGalat(pesan: cuaca.pesanGalat ?? 'Cuaca belum dapat dimuat.', onUlang: _muatUlang)
            else
              const _KartuMemuat(),
            if (prakiraan != null && cuaca.status == StatusCuaca.galat)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _BarisGagalMemperbarui(
                  waktu: cuaca.diperbaruiPada,
                  pesan: cuaca.pesanGalat,
                  onUlang: _muatUlang,
                ),
              )
            else if (cuaca.diperbaruiPada != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Diperbarui pukul ${formatJamWaktu(cuaca.diperbaruiPada!)} WIB. Tarik layar ke bawah untuk memuat ulang.',
                  style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
              ),
            if (lokasi.jauhDariMalang)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Lokasi Anda jauh dari Malang Raya, jadi jarak ke destinasi ditampilkan dari posisi tersebut.',
                  style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
              ),
            if (prakiraan != null) ...[
              const _JudulBagian('Prakiraan 7 hari'),
              SizedBox(
                // Kartu hari berisi lima baris teks, jadi tingginya ikut bertambah saat ukuran teks diperbesar.
                height: 176 + (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.0) * 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: prakiraan.harian.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => _KartuHari(hari: prakiraan.harian[i], pertama: i == 0),
                ),
              ),
              const _JudulBagian('Saran perlengkapan'),
              _KartuPerlengkapan(
                kondisi: prakiraan.hariIni?.kondisi ?? prakiraan.saatIni.kondisi,
              ),
            ],
            const _JudulBagian('Destinasi hari ini'),
            Wrap(
              spacing: 8,
              children: [
                _chipSaring('Semua', _Saring.semua),
                _chipSaring('Cocok', _Saring.cocok),
                _chipSaring('Dalam ruangan', _Saring.dalamRuangan),
              ],
            ),
            const SizedBox(height: 12),
            if (baris.isEmpty)
              _KeteranganDestinasiKosong(status: cuaca.status)
            else if (tampil.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Tidak ada destinasi yang cocok dengan penyaring ini. Pilih "Semua" untuk melihat seluruh destinasi.',
                  style: tema.textTheme.bodyMedium,
                ),
              )
            else
              for (final b in tampil)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BarisDestinasiCuaca(data: b),
                ),
            const SizedBox(height: 8),
            Text(
              'Data cuaca: Open-Meteo.com (lisensi CC BY 4.0). Peluang hujan dan saran kunjungan adalah prakiraan, bukan jaminan.',
              style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipSaring(String label, _Saring nilai) => ChoiceChip(
        label: Text(label),
        selected: _saring == nilai,
        onSelected: (_) => setState(() => _saring = nilai),
      );

  /// Destinasi yang punya data cuaca, diurutkan dari yang paling cocok lalu yang paling dekat.
  List<_DataBaris> _susunBaris(LokasiStore lokasi, CuacaStore cuaca) {
    final hasil = <_DataBaris>[];
    for (final d in widget.katalog.destinasi) {
      final prakiraan = cuaca.untukDestinasi(d);
      final hari = prakiraan?.hariIni;
      if (prakiraan == null || hari == null) continue;
      hasil.add(_DataBaris(
        destinasi: d,
        hari: hari,
        saran: saranKunjungan(d, hari),
        jarakKm: d.jarakDari(lokasi.aktif),
      ));
    }
    hasil.sort((a, b) {
      final tingkat = a.saran.tingkat.index.compareTo(b.saran.tingkat.index);
      if (tingkat != 0) return tingkat;
      if (a.jarakKm != null && b.jarakKm != null) return a.jarakKm!.compareTo(b.jarakKm!);
      return b.destinasi.rating.compareTo(a.destinasi.rating);
    });
    return hasil;
  }
}

class _DataBaris {
  const _DataBaris({required this.destinasi, required this.hari, required this.saran, required this.jarakKm});

  final Destinasi destinasi;
  final CuacaHarian hari;
  final SaranCuaca saran;
  final double? jarakKm;
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Text(teks, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

class _KartuMemuat extends StatelessWidget {
  const _KartuMemuat();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(height: 180, child: KeadaanMemuat(pesan: 'Memuat cuaca dari Open-Meteo...')),
    );
  }
}

class _KartuGalat extends StatelessWidget {
  const _KartuGalat({required this.pesan, required this.onUlang});

  final String pesan;
  final VoidCallback onUlang;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: KeadaanHalaman(
        ikon: Icons.cloud_off,
        judul: 'Cuaca belum dapat dimuat',
        pesan: pesan,
        aksi: AksiHalaman(label: 'Coba lagi', ikon: Icons.refresh, onTekan: onUlang),
      ),
    );
  }
}

class _BarisGagalMemperbarui extends StatelessWidget {
  const _BarisGagalMemperbarui({required this.waktu, required this.pesan, required this.onUlang});

  final DateTime? waktu;
  final String? pesan;
  final VoidCallback onUlang;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tanpaWaktu = waktu == null ? '' : ' Menampilkan data pukul ${formatJamWaktu(waktu!)} WIB.';
    return Row(
      children: [
        Icon(Icons.sync_problem, color: tema.colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${pesan ?? 'Gagal memperbarui cuaca.'}$tanpaWaktu',
            style: tema.textTheme.bodySmall,
          ),
        ),
        TextButton(onPressed: onUlang, child: const Text('Coba lagi')),
      ],
    );
  }
}

class _KartuHari extends StatelessWidget {
  const _KartuHari({required this.hari, required this.pertama});

  final CuacaHarian hari;
  final bool pertama;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    return SizedBox(
      width: 84,
      child: Card(
        color: pertama ? skema.primaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pertama ? 'Hari ini' : namaHariSingkat(hari.tanggal),
                style: tema.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(formatTanggalSingkat(hari.tanggal), style: tema.textTheme.labelSmall),
              IkonCuaca(kondisi: hari.kondisi, ukuran: 28, warna: skema.primary),
              Text(hari.kondisi.label, textAlign: TextAlign.center, style: tema.textTheme.labelSmall),
              Text(
                '${hari.suhuMaks.round()}° / ${hari.suhuMin.round()}°',
                style: tema.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text('Hujan ${hari.peluangHujan}%', style: tema.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuPerlengkapan extends StatelessWidget {
  const _KartuPerlengkapan({required this.kondisi});

  final KondisiCuaca kondisi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.luggage, color: tema.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Untuk cuaca ${kondisi.label.toLowerCase()}',
                    style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final saran in perlengkapanUntuk(kondisi))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check, size: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(saran, style: tema.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeteranganDestinasiKosong extends StatelessWidget {
  const _KeteranganDestinasiKosong({required this.status});

  final StatusCuaca status;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final teks = switch (status) {
      StatusCuaca.galat => 'Cuaca destinasi belum tersedia karena pemuatan gagal. Coba muat ulang.',
      _ => 'Memuat cuaca untuk setiap destinasi...',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(teks, style: tema.textTheme.bodyMedium),
    );
  }
}

class _BarisDestinasiCuaca extends StatelessWidget {
  const _BarisDestinasiCuaca({required this.data});

  final _DataBaris data;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final d = data.destinasi;
    final jarak = data.jarakKm;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/detail', arguments: d),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: GambarKategori(kategori: d.kategori, ukuranIkon: 26, radius: BorderRadius.circular(12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      jarak == null ? d.lokasi : '${formatJarak(jarak)} · ${d.lokasi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    ChipSaran(saran: data.saran),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IkonCuaca(kondisi: data.hari.kondisi, ukuran: 28, warna: tema.colorScheme.primary),
                  Text(
                    '${data.hari.suhuMaks.round()}°',
                    style: tema.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('${data.hari.peluangHujan}%', style: tema.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
