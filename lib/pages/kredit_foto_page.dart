import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../state/katalog_store.dart';
import '../state/store_scope.dart';
import '../tema.dart';
import '../widgets/gambar_destinasi.dart';
import '../widgets/keadaan_halaman.dart';

/// Halaman Kredit foto: atribusi setiap foto destinasi (judul berkas, pembuat, lisensi, sumber)
/// sesuai praktik atribusi Creative Commons, ditambah lisensi huruf yang dibundel.
class KreditFotoPage extends StatelessWidget {
  const KreditFotoPage({super.key});

  Future<void> _buka(BuildContext context, String alamat) async {
    final pesan = ScaffoldMessenger.of(context);
    final tautan = Uri.tryParse(alamat);
    var berhasil = false;
    if (tautan != null) {
      try {
        berhasil = await TautanScope.baca(context)(tautan);
      } catch (_) {
        berhasil = false;
      }
    }
    if (!berhasil) pesan.showSnackBar(const SnackBar(content: Text('Tautan tidak dapat dibuka.')));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final store = StoreScope.of<KatalogStore>(context);
    final katalog = store.katalog;
    if (katalog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kredit foto')),
        body: const KeadaanMemuat(pesan: 'Memuat katalog destinasi...'),
      );
    }
    final berfoto = katalog.destinasi.where((d) => d.foto != null).toList();
    final tanpaFoto = katalog.destinasi.where((d) => d.foto == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kredit foto')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            'Foto destinasi berasal dari Wikimedia Commons dan dipakai sesuai lisensinya. Untuk aplikasi, '
            'foto diperkecil dan dipotong; isinya tidak diubah. Ketuk baris untuk membuka halaman sumber.',
            style: tema.textTheme.bodyMedium?.copyWith(color: WarnaJelma.tintaLembut),
          ),
          const SizedBox(height: 12),
          for (final d in berfoto) _BarisKredit(destinasi: d, onBuka: (alamat) => _buka(context, alamat)),
          if (tanpaFoto.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Belum ada foto', style: tema.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${tanpaFoto.map((d) => d.nama).join(', ')}. Belum ditemukan foto berlisensi bebas yang benar '
              'menampilkan tempat atau hidangan ini, jadi aplikasi memakai gambar pengganti.',
              style: tema.textTheme.bodyMedium?.copyWith(color: WarnaJelma.tintaLembut),
            ),
          ],
          const SizedBox(height: 24),
          Text('Huruf', style: tema.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Plus Jakarta Sans oleh Tokotype (Gumpita Rahayu), SIL Open Font License 1.1.',
            style: tema.textTheme.bodyMedium?.copyWith(color: WarnaJelma.tintaLembut),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _buka(context, 'https://github.com/tokotype/PlusJakartaSans'),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Buka repositori huruf'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisKredit extends StatelessWidget {
  const _BarisKredit({required this.destinasi, required this.onBuka});

  final Destinasi destinasi;
  final ValueChanged<String> onBuka;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final foto = destinasi.foto!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onBuka(foto.sumber),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 56,
                    child: GambarDestinasi(destinasi: destinasi, radius: BorderRadius.circular(12), ukuranIkon: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(destinasi.nama, style: tema.textTheme.titleSmall),
                        Text(
                          foto.judul,
                          style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                        ),
                        Text(
                          '${foto.penulis}, ${foto.lisensi}',
                          style: tema.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 4),
                    child: Icon(Icons.open_in_new, size: 18, color: WarnaJelma.tintaLembut),
                  ),
                ],
              ),
            ),
          ),
          if (foto.urlLisensi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: TextButton(
                onPressed: () => onBuka(foto.urlLisensi),
                child: Text('Baca lisensi ${foto.lisensi}'),
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }
}
