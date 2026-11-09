import 'package:flutter/material.dart';

import '../data/destinasi_repository.dart';
import '../models/destinasi.dart';
import '../widgets/destinasi_card.dart';

/// Halaman Jelajah: daftar destinasi yang dapat disaring berdasarkan kategori
/// dan kata kunci pencarian.
class JelajahPage extends StatefulWidget {
  const JelajahPage({
    super.key,
    required this.katalog,
    required this.kategoriTerpilih,
    required this.onKategoriBerubah,
  });

  final KatalogDestinasi katalog;

  /// Identitas kategori yang dipilih, atau `semua`.
  final String kategoriTerpilih;
  final ValueChanged<String> onKategoriBerubah;

  @override
  State<JelajahPage> createState() => _JelajahPageState();
}

class _JelajahPageState extends State<JelajahPage> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, GlobalKey> _kunciChip = {};
  String _kata = '';

  @override
  void didUpdateWidget(JelajahPage lama) {
    super.didUpdateWidget(lama);
    if (lama.kategoriTerpilih != widget.kategoriTerpilih) _tampilkanChipTerpilih();
  }

  /// Menggulirkan deretan chip agar chip kategori yang dipilih tidak terpotong di tepi layar.
  void _tampilkanChipTerpilih() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final konteks = _kunciChip[widget.kategoriTerpilih]?.currentContext;
      if (konteks != null && konteks.mounted) {
        Scrollable.ensureVisible(
          konteks,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Destinasi yang cocok dengan kategori terpilih dan kata kunci pada nama atau lokasi.
  List<Destinasi> get _hasil {
    final kata = _kata.trim().toLowerCase();
    return widget.katalog.destinasi.where((d) {
      final cocokKategori =
          widget.kategoriTerpilih == 'semua' || d.kategori == widget.kategoriTerpilih;
      final cocokKata = kata.isEmpty ||
          d.nama.toLowerCase().contains(kata) ||
          d.lokasi.toLowerCase().contains(kata);
      return cocokKategori && cocokKata;
    }).toList();
  }

  Widget _chip(String id, String nama, IconData ikon) {
    return Padding(
      key: _kunciChip.putIfAbsent(id, GlobalKey.new),
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(ikon, size: 18),
        label: Text(nama),
        selected: widget.kategoriTerpilih == id,
        onSelected: (_) => widget.onKategoriBerubah(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final hasil = _hasil;
    return Scaffold(
      appBar: AppBar(title: const Text('Jelajah')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _kata = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama atau lokasi',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _kata.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus kata kunci',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _kata = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: tema.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: tema.colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _chip('semua', 'Semua', Icons.apps),
                for (final k in widget.katalog.kategori) _chip(k.id, k.nama, k.ikonData),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${hasil.length} destinasi ditemukan',
                style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          Expanded(
            child: hasil.isEmpty
                ? const _TidakAdaHasil()
                : LayoutBuilder(
                    builder: (context, batas) {
                      // Tata letak responsif: dua kolom pada layar lebar, satu kolom pada layar sempit.
                      if (batas.maxWidth >= 640) {
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 480,
                            mainAxisExtent: 112,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: hasil.length,
                          itemBuilder: (context, i) => DestinasiCard(destinasi: hasil[i]),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: hasil.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => DestinasiCard(destinasi: hasil[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TidakAdaHasil extends StatelessWidget {
  const _TidakAdaHasil();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: tema.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Tidak ada destinasi yang cocok', style: tema.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Ubah kata kunci atau pilih kategori lain.',
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
