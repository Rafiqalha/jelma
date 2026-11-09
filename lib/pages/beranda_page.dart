import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/destinasi_repository.dart';
import '../models/destinasi.dart';
import '../models/gaya_kategori.dart';
import '../widgets/destinasi_card.dart';
import '../widgets/gambar_kategori.dart';

/// Halaman Beranda: sambutan, pintasan pencarian, kategori, destinasi populer,
/// dan destinasi dengan rating tertinggi.
class BerandaPage extends StatelessWidget {
  const BerandaPage({
    super.key,
    required this.katalog,
    required this.onKategori,
    required this.onCari,
  });

  final KatalogDestinasi katalog;

  /// Dipanggil saat kategori diketuk; menerima identitas kategori.
  final ValueChanged<String> onKategori;

  /// Dipanggil saat kolom pencarian diketuk.
  final VoidCallback onCari;

  @override
  Widget build(BuildContext context) {
    final populer = katalog.populer;
    final skema = Theme.of(context).colorScheme;
    final atas = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Header berlatar gelap sehingga ikon status bar dibuat terang.
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Column(
        children: [
          // Blok berwarna sama dengan awal gradasi header agar isi daftar tidak tampak di bawah ikon sistem.
          Container(height: atas, color: skema.primary),
          Expanded(child: _isi(context, populer)),
        ],
      ),
    );
  }

  Widget _isi(BuildContext context, List<Destinasi> populer) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(onCari: onCari),
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
        const _JudulBagian('Populer'),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: populer.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _PopulerCard(destinasi: populer[i]),
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
            'Data pada aplikasi ini adalah data contoh (dummy).',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Jelajah Malang',
                    style: tema.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        teks,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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

class _PopulerCard extends StatelessWidget {
  const _PopulerCard({required this.destinasi});

  final Destinasi destinasi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SizedBox(
      width: 168,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/detail', arguments: destinasi),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GambarKategori(kategori: destinasi.kategori, ukuranIkon: 44),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF9A825)),
                            const SizedBox(width: 2),
                            Text(
                              destinasi.rating.toStringAsFixed(1),
                              style: tema.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destinasi.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destinasi.lokasi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
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
