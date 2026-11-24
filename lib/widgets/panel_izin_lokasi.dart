import 'package:flutter/material.dart';

import '../state/lokasi_store.dart';
import '../state/pengaturan_store.dart';
import '../state/store_scope.dart';

/// Menjelaskan mengapa lokasi pengguna belum tersedia dan menawarkan langkah berikutnya.
///
/// Tidak menampilkan apa pun bila lokasi sudah siap atau pengguna memilih area manual.
class PanelIzinLokasi extends StatelessWidget {
  const PanelIzinLokasi({super.key, this.tombolArea = true});

  /// Menampilkan tombol menuju Pengaturan; dimatikan di halaman Pengaturan sendiri.
  final bool tombolArea;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lokasi = StoreScope.of<LokasiStore>(context);
    if (lokasi.mode == ModeLokasi.manual || lokasi.status == StatusLokasi.siap) {
      return const SizedBox.shrink();
    }
    if (lokasi.status == StatusLokasi.memuat || lokasi.status == StatusLokasi.belumDicek) {
      return _Kartu(
        child: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 16),
            Expanded(child: Text('Mencari lokasi Anda...', style: tema.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    final (judul, pesan) = switch (lokasi.status) {
      StatusLokasi.izinDitolak => (
          'Lokasi belum diizinkan',
          'Izinkan akses lokasi agar jarak dan cuaca dihitung dari posisi Anda. '
              'Selama itu, cuaca ditampilkan untuk Pusat Kota Malang.',
        ),
      StatusLokasi.izinDitolakPermanen => (
          'Izin lokasi ditolak',
          'Aktifkan izin lokasi lewat pengaturan aplikasi, atau pilih area secara manual.',
        ),
      StatusLokasi.layananMati => (
          'GPS belum aktif',
          'Nyalakan layanan lokasi pada perangkat, lalu ketuk Coba lagi. Atau pilih area secara manual.',
        ),
      _ => (
          'Lokasi belum ditemukan',
          lokasi.pesanGalat ?? 'Posisi belum berhasil ditentukan. Coba lagi.',
        ),
    };

    return _Kartu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_off, color: tema.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(judul, style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pesan, style: tema.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _aksiUtama(lokasi),
              if (lokasi.status == StatusLokasi.layananMati)
                OutlinedButton(
                  onPressed: () => lokasi.perbarui(mintaIzin: true),
                  child: const Text('Coba lagi'),
                ),
              if (tombolArea)
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/pengaturan'),
                  child: const Text('Pilih area manual'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aksiUtama(LokasiStore lokasi) {
    return switch (lokasi.status) {
      StatusLokasi.izinDitolakPermanen => FilledButton(
          onPressed: lokasi.bukaPengaturanAplikasi,
          child: const Text('Buka pengaturan aplikasi'),
        ),
      StatusLokasi.layananMati => FilledButton(
          onPressed: lokasi.bukaPengaturanLokasi,
          child: const Text('Aktifkan GPS'),
        ),
      StatusLokasi.izinDitolak => FilledButton(
          onPressed: () => lokasi.perbarui(mintaIzin: true),
          child: const Text('Izinkan lokasi'),
        ),
      _ => FilledButton(
          onPressed: () => lokasi.perbarui(mintaIzin: true),
          child: const Text('Coba lagi'),
        ),
    };
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(child: Padding(padding: const EdgeInsets.all(16), child: child)),
    );
  }
}
