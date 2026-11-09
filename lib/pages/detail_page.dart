import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../models/gaya_kategori.dart';
import '../state/favorit_store.dart';
import '../widgets/gambar_kategori.dart';

/// Halaman Detail: informasi lengkap satu destinasi.
///
/// Objek [Destinasi] diterima melalui `arguments` pada `Navigator.pushNamed`.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

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
    final warna = warnaKategori(d.kategori);
    final store = FavoritScope.of(context);
    final favorit = store.apakahFavorit(d.id);

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
                        _BarisInfo(ikon: Icons.place_outlined, judul: 'Lokasi', nilai: d.lokasi),
                        const Divider(height: 1),
                        _BarisInfo(ikon: Icons.schedule, judul: 'Jam buka', nilai: d.jamBuka),
                        const Divider(height: 1),
                        _BarisInfo(
                          ikon: Icons.confirmation_number_outlined,
                          judul: d.judulHarga,
                          nilai: d.hargaLabel,
                        ),
                      ],
                    ),
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
                const SizedBox(height: 2),
                Text(nilai, style: tema.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
