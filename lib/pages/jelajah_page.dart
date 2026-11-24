import 'package:flutter/material.dart';

import '../data/destinasi_repository.dart';
import '../models/destinasi.dart';
import '../state/lokasi_store.dart';
import '../state/store_scope.dart';
import '../widgets/destinasi_card.dart';
import '../widgets/keadaan_halaman.dart';
import '../widgets/tombol_pengaturan.dart';

/// Cara mengurutkan daftar pada halaman Jelajah.
enum UrutanDaftar {
  katalog('Urutan katalog'),
  terdekat('Terdekat'),
  ratingTertinggi('Rating tertinggi'),
  nama('Nama A-Z');

  const UrutanDaftar(this.label);

  final String label;
}

/// Halaman Jelajah: daftar destinasi yang dapat disaring berdasarkan kategori, kata kunci,
/// dan status buka, serta diurutkan menurut jarak, rating, atau nama.
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
  UrutanDaftar _urutan = UrutanDaftar.katalog;
  bool _bukaSaja = false;

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

  /// Destinasi yang cocok dengan kategori, kata kunci pada nama atau lokasi, dan status buka,
  /// lalu diurutkan sesuai pilihan. Urutan terdekat memakai lokasi aktif; tanpa lokasi, urutan katalog dipakai.
  List<Destinasi> _hasil(BuildContext context) {
    final kata = _kata.trim().toLowerCase();
    final sekarang = WaktuScope.baca(context);
    final titik = StoreScope.of<LokasiStore>(context).aktif;
    final hasil = widget.katalog.destinasi.where((d) {
      final cocokKategori =
          widget.kategoriTerpilih == 'semua' || d.kategori == widget.kategoriTerpilih;
      final cocokKata = kata.isEmpty ||
          d.nama.toLowerCase().contains(kata) ||
          d.lokasi.toLowerCase().contains(kata);
      final cocokBuka = !_bukaSaja || (d.statusPada(sekarang)?.terbuka ?? false);
      return cocokKategori && cocokKata && cocokBuka;
    }).toList();
    switch (_urutan) {
      case UrutanDaftar.katalog:
        break;
      case UrutanDaftar.terdekat:
        if (titik != null) hasil.sort((a, b) => a.jarakDari(titik)!.compareTo(b.jarakDari(titik)!));
      case UrutanDaftar.ratingTertinggi:
        hasil.sort((a, b) {
          final banding = b.rating.compareTo(a.rating);
          return banding != 0 ? banding : a.id.compareTo(b.id);
        });
      case UrutanDaftar.nama:
        hasil.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    }
    return hasil;
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
    final lokasi = StoreScope.of<LokasiStore>(context);
    final hasil = _hasil(context);
    final bisaUrutJarak = lokasi.aktif != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Jelajah'), actions: const [TombolPengaturan()]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _kata = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Cari nama atau lokasi',
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
          // Penyaring status buka dan pengurutan berada pada baris sendiri agar tidak tersembunyi di ujung deretan chip.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                FilterChip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: const Text('Buka sekarang'),
                  selected: _bukaSaja,
                  onSelected: (nilai) => setState(() => _bukaSaja = nilai),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<UrutanDaftar>(
                      tooltip: 'Urutkan daftar',
                      initialValue: _urutan,
                      onSelected: (nilai) => setState(() => _urutan = nilai),
                      itemBuilder: (context) => [
                        for (final u in UrutanDaftar.values)
                          PopupMenuItem(
                            value: u,
                            enabled: u != UrutanDaftar.terdekat || bisaUrutJarak,
                            child: Text(
                              u == UrutanDaftar.terdekat && !bisaUrutJarak ? 'Terdekat (perlu lokasi)' : u.label,
                            ),
                          ),
                      ],
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _urutan == UrutanDaftar.terdekat && !bisaUrutJarak
                                      ? UrutanDaftar.katalog.label
                                      : _urutan.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tema.textTheme.labelLarge,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.sort, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
                ? KeadaanHalaman(
                    ikon: Icons.search_off,
                    judul: 'Tidak ada destinasi yang cocok',
                    pesan: _bukaSaja
                        ? 'Tidak ada destinasi yang buka sekarang dengan penyaring ini. Matikan Buka sekarang atau ubah kata kunci.'
                        : 'Ubah kata kunci atau pilih kategori lain.',
                  )
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
