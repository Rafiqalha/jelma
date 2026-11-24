import 'package:flutter/material.dart';

import '../data/destinasi_repository.dart';
import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/rencana.dart';
import '../models/saran_cuaca.dart';
import '../state/cuaca_store.dart';
import '../state/lokasi_store.dart';
import '../state/rencana_store.dart';
import '../state/store_scope.dart';
import '../widgets/chip_saran.dart';
import '../widgets/gambar_destinasi.dart';
import '../widgets/keadaan_halaman.dart';
import '../widgets/tombol_pengaturan.dart';

/// Halaman Rencana: daftar rencana kunjungan beserta prakiraan cuaca pada hari kunjungan.
class RencanaPage extends StatelessWidget {
  const RencanaPage({super.key, required this.katalog});

  final KatalogDestinasi katalog;

  void _buat(BuildContext context) => Navigator.pushNamed(context, '/rencana/form');

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final store = StoreScope.of<RencanaStore>(context);
    final mendatang = store.mendatang;
    final selesai = store.selesai;

    return Scaffold(
      appBar: AppBar(title: const Text('Rencana'), actions: const [TombolPengaturan()]),
      // Tombol Buat rencana untuk daftar yang sudah berisi dipasang di ShellPage.
      body: store.daftar.isEmpty
          ? KeadaanHalaman(
              ikon: Icons.event_note,
              judul: 'Belum ada rencana kunjungan',
              pesan: 'Pilih destinasi dan tanggal. Aplikasi memeriksa cuacanya pada hari itu '
                  'dan mengingatkan Anda sebelum berangkat.',
              aksi: AksiHalaman(label: 'Buat rencana', ikon: Icons.add, onTekan: () => _buat(context)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const _JudulBagian('Mendatang'),
                if (mendatang.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Tidak ada rencana mendatang. Ketuk Buat rencana untuk menambahkan.',
                      style: tema.textTheme.bodyMedium,
                    ),
                  ),
                for (final r in mendatang)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _KartuRencana(rencana: r, katalog: katalog),
                  ),
                if (selesai.isNotEmpty) ...[
                  const _JudulBagian('Sudah lewat'),
                  for (final r in selesai)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _KartuRencana(rencana: r, katalog: katalog),
                    ),
                ],
              ],
            ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Text(teks, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

/// Foto kecil destinasi dalam satu rencana, bertumpuk seperti deret avatar; paling banyak empat.
class _TumpukanFoto extends StatelessWidget {
  const _TumpukanFoto({required this.tujuan});

  final List<Destinasi> tujuan;

  @override
  Widget build(BuildContext context) {
    const ukuran = 32.0;
    final tampil = tujuan.take(4).toList();
    final sisa = tujuan.length - tampil.length;
    return ExcludeSemantics(
      child: SizedBox(
        height: ukuran,
        width: ukuran + (tampil.length - 1) * 22 + (sisa > 0 ? 40 : 0),
        child: Stack(
          children: [
            for (var i = 0; i < tampil.length; i++)
              Positioned(
                left: i * 22,
                child: Container(
                  width: ukuran,
                  height: ukuran,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: ClipOval(child: GambarDestinasi(destinasi: tampil[i], ukuranIkon: 14)),
                ),
              ),
            if (sisa > 0)
              Positioned(
                left: tampil.length * 22 + 14,
                top: 6,
                child: Text('+$sisa', style: Theme.of(context).textTheme.labelMedium),
              ),
          ],
        ),
      ),
    );
  }
}

class _KartuRencana extends StatelessWidget {
  const _KartuRencana({required this.rencana, required this.katalog});

  final Rencana rencana;
  final KatalogDestinasi katalog;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final store = StoreScope.of<RencanaStore>(context);
    final cuaca = StoreScope.of<CuacaStore>(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final lewat = store.sudahLewat(rencana);
    final tujuan = [for (final id in rencana.idDestinasi) ?katalog.cari(id)];
    final penilaian = lewat ? null : nilaiRencana(rencana, tujuan, cuaca.untukDestinasi);
    final titik = lokasi.aktif;
    final total = titik == null || tujuan.length < 2 ? null : susunRute(tujuan, titik).totalKm;
    final w = rencana.waktu;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/rencana/detail', arguments: rencana.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: skema.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${w.day}',
                      style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: skema.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      namaBulanSingkat(w),
                      style: tema.textTheme.labelMedium?.copyWith(color: skema.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rencana.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${namaHari(w)}, ${formatJamWaktu(w)} WIB',
                      style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                    ),
                    Text(
                      total == null
                          ? '${tujuan.length} destinasi'
                          : '${tujuan.length} destinasi, rute sekitar ${formatJarak(total)}',
                      style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                    ),
                    if (tujuan.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _TumpukanFoto(tujuan: tujuan),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (penilaian != null) ChipPenilaian(penilaian: penilaian),
                        if (!lewat && rencana.pengingat != Pengingat.tidakAda)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_active_outlined, size: 14, color: skema.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                rencana.pengingat.label,
                                style: tema.textTheme.labelSmall?.copyWith(color: skema.onSurfaceVariant),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: skema.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
