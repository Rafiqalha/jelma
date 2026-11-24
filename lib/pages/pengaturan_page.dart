import 'package:flutter/material.dart';

import '../models/area_referensi.dart';
import '../models/format.dart';
import '../state/katalog_store.dart';
import '../state/lokasi_store.dart';
import '../state/notifikasi_store.dart';
import '../state/pengaturan_store.dart';
import '../state/store_scope.dart';
import '../widgets/logo_jelma.dart';
import '../widgets/panel_izin_lokasi.dart';

/// Versi yang ditampilkan; sama dengan `version` pada pubspec.yaml.
const String _versiAplikasi = '2.1.0';

/// Halaman Pengaturan: tentang aplikasi dan kredit foto, sumber lokasi, radius pencarian,
/// notifikasi, dan keterangan sumber data.
class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StoreScope.baca<NotifikasiStore>(context).periksa();
    });
  }

  void _beritahu(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _kirimUji() async {
    final berhasil = await StoreScope.baca<NotifikasiStore>(context).kirimUji();
    if (!mounted) return;
    _beritahu(
      berhasil
          ? 'Notifikasi uji dikirim. Lihat di bilah notifikasi perangkat.'
          : 'Izin notifikasi belum diberikan. Aktifkan izin notifikasi di pengaturan perangkat.',
    );
  }

  Future<void> _muatUlangKatalog() async {
    final store = StoreScope.baca<KatalogStore>(context);
    await store.muat();
    if (!mounted) return;
    final katalog = store.katalog;
    _beritahu(
      katalog == null ? 'Katalog gagal dimuat.' : 'Katalog dimuat. Sumber: ${katalog.sumber.label}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final pengaturan = StoreScope.of<PengaturanStore>(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    final notifikasi = StoreScope.of<NotifikasiStore>(context);
    final katalog = StoreScope.of<KatalogStore>(context).katalog;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const MerekJelma(),
                      const Spacer(),
                      Text('Versi $_versiAplikasi', style: tema.textTheme.labelMedium?.copyWith(color: skema.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jelajah Malang: katalog destinasi Malang Raya dengan lokasi, cuaca, dan rencana kunjungan.',
                    style: tema.textTheme.bodyMedium?.copyWith(color: skema.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Kredit foto'),
                    subtitle: const Text('Pembuat, lisensi, dan sumber setiap foto destinasi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/kredit-foto'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.slideshow_outlined),
                    title: const Text('Lihat pengenalan lagi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/pengenalan'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Bagian(
            ikon: Icons.my_location,
            judul: 'Lokasi',
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ModeLokasi>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ModeLokasi.gps, label: Text('GPS otomatis')),
                      ButtonSegment(value: ModeLokasi.manual, label: Text('Pilih area')),
                    ],
                    selected: {lokasi.mode},
                    onSelectionChanged: (pilihan) {
                      if (pilihan.first == ModeLokasi.gps) {
                        lokasi.pakaiGps();
                      } else {
                        lokasi.pakaiArea(pengaturan.area.id);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (lokasi.mode == ModeLokasi.gps) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(lokasi.label),
                    subtitle: Text(_keteranganStatus(lokasi)),
                    trailing: IconButton(
                      tooltip: 'Perbarui lokasi',
                      icon: const Icon(Icons.refresh),
                      onPressed: () => lokasi.perbarui(mintaIzin: true),
                    ),
                  ),
                  const PanelIzinLokasi(tombolArea: false),
                ] else
                  DropdownMenu<String>(
                    key: ValueKey(pengaturan.area.id),
                    initialSelection: pengaturan.area.id,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Area acuan'),
                    dropdownMenuEntries: [
                      for (final area in daftarArea) DropdownMenuEntry(value: area.id, label: area.nama),
                    ],
                    onSelected: (id) {
                      if (id != null) lokasi.pakaiArea(id);
                    },
                  ),
                const SizedBox(height: 16),
                Text(
                  'Radius Dekat Anda: ${pengaturan.radiusKm.round()} km',
                  style: tema.textTheme.titleSmall,
                ),
                Slider(
                  value: pengaturan.radiusKm,
                  min: PengaturanStore.radiusMinKm,
                  max: PengaturanStore.radiusMaksKm,
                  divisions: 9,
                  label: '${pengaturan.radiusKm.round()} km',
                  semanticFormatterCallback: (nilai) => '${nilai.round()} kilometer',
                  onChanged: pengaturan.aturRadius,
                ),
                Text(
                  'Bagian Dekat Anda di Beranda hanya memuat destinasi dalam radius ini dari lokasi aktif.',
                  style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Bagian(
            ikon: Icons.notifications_active_outlined,
            judul: 'Notifikasi',
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pengingat rencana'),
                  subtitle: const Text('Notifikasi sebelum jam kunjungan yang Anda atur.'),
                  value: pengaturan.pengingatAktif,
                  onChanged: pengaturan.aturPengingat,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Peringatan cuaca'),
                  subtitle: const Text('Memberi tahu bila hujan atau badai diperkirakan pada hari rencana Anda.'),
                  value: pengaturan.peringatanCuacaAktif,
                  onChanged: pengaturan.aturPeringatanCuaca,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    notifikasi.izin == false ? Icons.notifications_off_outlined : Icons.notifications_outlined,
                  ),
                  title: const Text('Izin notifikasi'),
                  subtitle: Text(switch (notifikasi.izin) {
                    true => 'Diberikan',
                    false => 'Belum diberikan',
                    null => 'Memeriksa...',
                  }),
                  trailing: notifikasi.izin == false
                      ? TextButton(onPressed: notifikasi.mintaIzin, child: const Text('Izinkan'))
                      : null,
                ),
                const SizedBox(height: 4),
                FilledButton.tonalIcon(
                  onPressed: _kirimUji,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Kirim notifikasi uji'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Bagian(
            ikon: Icons.info_outline,
            judul: 'Data',
            anak: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sumber katalog destinasi'),
                  subtitle: Text(katalog == null ? 'Belum dimuat' : '${katalog.sumber.label}, versi data ${katalog.versi}'),
                  trailing: TextButton(onPressed: _muatUlangKatalog, child: const Text('Muat ulang')),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cuaca: Open-Meteo.com (lisensi CC BY 4.0).\n'
                  'Koordinat destinasi dan area acuan: OpenStreetMap contributors (lisensi ODbL).\n'
                  'Foto destinasi: Wikimedia Commons, lihat Kredit foto.\n'
                  'Rating, harga, dan jam buka pada katalog adalah data contoh.',
                  style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant, height: 1.5),
                ),
                if (lokasi.diperbaruiPada != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lokasi GPS terakhir diperbarui pukul ${formatJamWaktu(lokasi.diperbaruiPada!)} WIB.',
                    style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _keteranganStatus(LokasiStore lokasi) => switch (lokasi.status) {
        StatusLokasi.siap => 'Sumber: ${lokasi.sumberLabel}',
        StatusLokasi.memuat || StatusLokasi.belumDicek => 'Mencari lokasi...',
        StatusLokasi.izinDitolak => 'Izin lokasi belum diberikan. Cuaca memakai Pusat Kota Malang.',
        StatusLokasi.izinDitolakPermanen => 'Izin lokasi ditolak.',
        StatusLokasi.layananMati => 'GPS perangkat belum aktif.',
        StatusLokasi.galat => lokasi.pesanGalat ?? 'Lokasi belum ditemukan.',
      };
}

class _Bagian extends StatelessWidget {
  const _Bagian({required this.ikon, required this.judul, required this.anak});

  final IconData ikon;
  final String judul;
  final Widget anak;

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
                Icon(ikon, color: tema.colorScheme.primary),
                const SizedBox(width: 8),
                Text(judul, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            anak,
          ],
        ),
      ),
    );
  }
}
