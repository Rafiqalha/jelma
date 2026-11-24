import 'package:flutter/material.dart';

import '../models/cuaca.dart';
import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/rencana.dart';
import '../models/saran_cuaca.dart';
import '../state/cuaca_store.dart';
import '../state/katalog_store.dart';
import '../state/lokasi_store.dart';
import '../state/rencana_store.dart';
import '../state/store_scope.dart';
import '../navigasi.dart';
import '../widgets/chip_saran.dart';
import '../widgets/gambar_destinasi.dart';
import '../widgets/ikon_cuaca.dart';
import '../widgets/keadaan_halaman.dart';
import 'rencana_form_page.dart';

/// Halaman rincian satu rencana: waktu, pengingat, ringkasan cuaca, dan urutan kunjungan yang disarankan.
///
/// Identitas rencana diterima melalui `arguments` pada `Navigator.pushNamed`.
class RencanaDetailPage extends StatelessWidget {
  const RencanaDetailPage({super.key});

  Future<void> _hapus(BuildContext context, Rencana rencana) async {
    final store = StoreScope.baca<RencanaStore>(context);
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Hapus rencana ini?'),
        content: Text('Rencana "${rencana.nama}" dan pengingatnya akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yakin != true || !context.mounted) return;
    await store.hapus(rencana.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rencana dihapus.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final argumen = ModalRoute.of(context)?.settings.arguments;
    final store = StoreScope.of<RencanaStore>(context);
    final katalog = StoreScope.of<KatalogStore>(context).katalog;
    final cuaca = StoreScope.of<CuacaStore>(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final rencana = argumen is int ? store.cari(argumen) : null;

    if (rencana == null || katalog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rencana')),
        body: KeadaanHalaman(
          ikon: Icons.event_busy,
          judul: 'Rencana tidak ditemukan',
          pesan: 'Rencana ini mungkin sudah dihapus.',
          aksi: AksiHalaman(label: 'Kembali', onTekan: () => Navigator.pop(context)),
        ),
      );
    }

    final tujuan = [for (final id in rencana.idDestinasi) ?katalog.cari(id)];
    final rute = susunRute(tujuan, lokasi.aktif);
    final lewat = store.sudahLewat(rencana);
    final penilaian = lewat ? null : nilaiRencana(rencana, tujuan, cuaca.untukDestinasi);
    final w = rencana.waktu;

    return Scaffold(
      appBar: AppBar(
        title: Text(rencana.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Ubah rencana',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              '/rencana/form',
              arguments: FormRencanaArgumen(ubah: rencana),
            ),
          ),
          IconButton(
            tooltip: 'Hapus rencana',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _hapus(context, rencana),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Column(
              children: [
                _BarisInfo(ikon: Icons.event, judul: 'Tanggal', nilai: formatTanggal(w)),
                const Divider(height: 1),
                _BarisInfo(ikon: Icons.schedule, judul: 'Jam', nilai: '${formatJamWaktu(w)} WIB'),
                const Divider(height: 1),
                _BarisInfo(
                  ikon: rencana.pengingat == Pengingat.tidakAda
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_outlined,
                  judul: 'Pengingat',
                  nilai: rencana.pengingat.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (lewat)
            Text(
              'Rencana ini sudah lewat, jadi cuaca dan pengingat tidak ditampilkan lagi.',
              style: tema.textTheme.bodyMedium,
            )
          else if (penilaian != null)
            _RingkasanCuaca(penilaian: penilaian)
          else
            Text(
              cuaca.status == StatusCuaca.galat
                  ? 'Prakiraan cuaca belum tersedia karena pemuatan gagal. Buka tab Cuaca lalu muat ulang.'
                  : 'Prakiraan cuaca untuk tanggal ini sedang dimuat atau belum tersedia.',
              style: tema.textTheme.bodyMedium,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
            child: Text(
              'Urutan kunjungan yang disarankan',
              style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              lokasi.aktif == null
                  ? 'Urutan mengikuti pilihan Anda karena lokasi Anda belum diketahui.'
                  : 'Dimulai dari destinasi terdekat dengan lokasi Anda, lalu pindah ke yang terdekat berikutnya.',
              style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
            ),
          ),
          for (var i = 0; i < rute.urutan.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BarisStop(
                nomor: i + 1,
                destinasi: rute.urutan[i],
                ruasKm: rute.ruas[i],
                sebelumnya: i == 0 ? null : rute.urutan[i - 1],
                hari: lewat ? null : cuaca.untukDestinasi(rute.urutan[i])?.hariPada(w),
              ),
            ),
          if (rute.totalKm > 0)
            Text(
              'Total jarak garis lurus sekitar ${formatJarak(rute.totalKm)}. Jarak di jalan lebih jauh.',
              style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({required this.ikon, required this.judul, required this.nilai});

  final IconData ikon;
  final String judul;
  final String nilai;

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
                Text(nilai, style: tema.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingkasanCuaca extends StatelessWidget {
  const _RingkasanCuaca({required this.penilaian});

  final PenilaianRencana penilaian;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final gaya = gayaSaran(tema.colorScheme, penilaian.tingkat);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: gaya.latar, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IkonCuaca(kondisi: penilaian.kondisi, ukuran: 32, warna: gaya.teks),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${penilaian.tingkat.label}: ${penilaian.kondisi.label}, peluang hujan ${penilaian.peluangHujan}%',
                  style: tema.textTheme.titleSmall?.copyWith(color: gaya.teks, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${penilaian.penyebab.nama}: ${penilaian.saran.penjelasan}',
                  style: tema.textTheme.bodyMedium?.copyWith(color: gaya.teks),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisStop extends StatelessWidget {
  const _BarisStop({
    required this.nomor,
    required this.destinasi,
    required this.ruasKm,
    required this.sebelumnya,
    required this.hari,
  });

  final int nomor;
  final Destinasi destinasi;
  final double? ruasKm;
  final Destinasi? sebelumnya;
  final CuacaHarian? hari;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final asal = sebelumnya == null ? 'dari lokasi Anda' : 'dari ${sebelumnya!.nama}';
    final keterangan = ruasKm == null
        ? destinasi.lokasi
        : 'Sekitar ${formatJarak(ruasKm!)} $asal';

    final tag = tagFoto('rute', destinasi);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => bukaDetail(context, destinasi, heroTag: tag),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: skema.primary,
                child: Text('$nomor', style: tema.textTheme.labelLarge?.copyWith(color: skema.onPrimary)),
              ),
              const SizedBox(width: 12),
              SizedBox.square(
                dimension: 56,
                child: GambarDestinasi(destinasi: destinasi, heroTag: tag, ukuranIkon: 24, radius: BorderRadius.circular(14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destinasi.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      keterangan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                    ),
                    if (hari != null) ...[
                      const SizedBox(height: 6),
                      ChipSaran(saran: saranKunjungan(destinasi, hari!)),
                    ],
                  ],
                ),
              ),
              if (hari != null) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IkonCuaca(kondisi: hari!.kondisi, ukuran: 26, warna: skema.primary),
                    Text(
                      '${hari!.suhuMaks.round()}°',
                      style: tema.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
