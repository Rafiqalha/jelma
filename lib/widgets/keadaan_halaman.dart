import 'package:flutter/material.dart';

/// Tombol langkah berikutnya pada keadaan kosong, galat, atau butuh izin.
class AksiHalaman {
  const AksiHalaman({required this.label, required this.onTekan, this.ikon});

  final String label;
  final VoidCallback onTekan;
  final IconData? ikon;
}

/// Keadaan kosong atau galat: ikon, judul, penyebab, dan satu langkah yang dapat dilakukan pengguna.
class KeadaanHalaman extends StatelessWidget {
  const KeadaanHalaman({
    super.key,
    required this.ikon,
    required this.judul,
    required this.pesan,
    this.aksi,
    this.aksiLain,
  });

  final IconData ikon;
  final String judul;
  final String pesan;
  final AksiHalaman? aksi;
  final AksiHalaman? aksiLain;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 64, color: tema.colorScheme.outline),
            const SizedBox(height: 12),
            Text(judul, textAlign: TextAlign.center, style: tema.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            if (aksi != null) ...[
              const SizedBox(height: 16),
              _Tombol(aksi: aksi!, utama: true),
            ],
            if (aksiLain != null) ...[
              const SizedBox(height: 8),
              _Tombol(aksi: aksiLain!, utama: false),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tombol extends StatelessWidget {
  const _Tombol({required this.aksi, required this.utama});

  final AksiHalaman aksi;
  final bool utama;

  @override
  Widget build(BuildContext context) {
    final label = Text(aksi.label);
    if (utama) {
      return aksi.ikon == null
          ? FilledButton(onPressed: aksi.onTekan, child: label)
          : FilledButton.icon(onPressed: aksi.onTekan, icon: Icon(aksi.ikon), label: label);
    }
    return aksi.ikon == null
        ? TextButton(onPressed: aksi.onTekan, child: label)
        : TextButton.icon(onPressed: aksi.onTekan, icon: Icon(aksi.ikon), label: label);
  }
}

/// Indikator memuat yang selalu disertai teks tentang apa yang dimuat.
class KeadaanMemuat extends StatelessWidget {
  const KeadaanMemuat({super.key, required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
