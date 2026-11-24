import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cuaca.dart';
import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/gaya_kategori.dart';
import '../models/saran_cuaca.dart';
import '../navigasi.dart';
import '../state/cuaca_store.dart';
import '../state/lokasi_store.dart';
import '../state/store_scope.dart';
import '../tema.dart';
import '../widgets/chip_saran.dart';
import '../widgets/gambar_destinasi.dart';
import '../widgets/ikon_cuaca.dart';
import '../widgets/tombol_favorit.dart';
import 'rencana_form_page.dart';

/// Halaman Detail: foto besar destinasi beserta kreditnya, fakta ringkas (rating, status buka,
/// jarak, jenis ruang), cuaca di lokasi destinasi, deskripsi, fasilitas, dan rute.
///
/// Menerima [ArgumenDetail] (atau langsung [Destinasi]) melalui `arguments` pada `Navigator.pushNamed`.
class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ScrollController _gulir = ScrollController();
  double _tinggiFoto = 320;
  bool _ringkas = false;

  @override
  void initState() {
    super.initState();
    _gulir.addListener(_cekRingkas);
  }

  @override
  void dispose() {
    _gulir.dispose();
    super.dispose();
  }

  /// Judul bilah atas muncul setelah foto tergulung habis, karena saat itu nama di bawah foto tidak terlihat lagi.
  void _cekRingkas() {
    final batas = _tinggiFoto - kToolbarHeight - MediaQuery.paddingOf(context).top - 8;
    final ringkas = _gulir.offset > batas;
    if (ringkas != _ringkas) setState(() => _ringkas = ringkas);
  }

  Future<void> _buka(Uri tautan, String gagal) async {
    final buka = TautanScope.baca(context);
    final pesan = ScaffoldMessenger.of(context);
    var berhasil = false;
    try {
      berhasil = await buka(tautan);
    } catch (_) {
      berhasil = false;
    }
    if (!berhasil) pesan.showSnackBar(SnackBar(content: Text(gagal)));
  }

  void _bukaRute(Destinasi d) => _buka(
        Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          'destination': '${d.koordinat.lintang},${d.koordinat.bujur}',
        }),
        'Tidak dapat membuka aplikasi peta atau peramban.',
      );

  @override
  Widget build(BuildContext context) {
    final argumen = ModalRoute.of(context)?.settings.arguments;
    final ArgumenDetail? data = switch (argumen) {
      ArgumenDetail a => a,
      Destinasi d => ArgumenDetail(d),
      _ => null,
    };
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Data destinasi tidak tersedia')),
      );
    }
    final d = data.destinasi;
    _tinggiFoto = (MediaQuery.sizeOf(context).height * 0.42).clamp(240.0, 420.0);

    return Scaffold(
      body: CustomScrollView(
        controller: _gulir,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _tinggiFoto,
            backgroundColor: WarnaJelma.latar,
            systemOverlayStyle: _ringkas ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: TombolBulat(
                  tooltip: 'Kembali',
                  onPressed: () => Navigator.maybePop(context),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            ),
            leadingWidth: 60,
            title: AnimatedOpacity(
              opacity: _ringkas ? 1 : 0,
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
              child: Text(d.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            ),
            actions: [
              TombolFavorit(destinasi: d, diAtasFoto: true),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  GambarDestinasi(
                    destinasi: d,
                    heroTag: data.heroTag,
                    ukuranIkon: 88,
                    keteranganPengganti: true,
                    semantik: true,
                  ),
                  // Scrim atas agar ikon bilah status tetap terbaca di atas langit yang terang.
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 112,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x73000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Isi(
              destinasi: d,
              onBukaRute: () => _bukaRute(d),
              onBukaSumberFoto: (tautan) => _buka(tautan, 'Tidak dapat membuka halaman sumber foto.'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BilahAksi(destinasi: d),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.destinasi, required this.onBukaRute, required this.onBukaSumberFoto});

  final Destinasi destinasi;
  final VoidCallback onBukaRute;
  final ValueChanged<Uri> onBukaSumberFoto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final d = destinasi;
    final lokasi = StoreScope.of<LokasiStore>(context);
    final jarak = d.jarakDari(lokasi.aktif);
    final status = d.statusPada(WaktuScope.baca(context));
    final foto = d.foto;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (foto == null)
            Text(
              'Foto belum tersedia untuk destinasi ini.',
              style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
            )
          else
            _BarisKredit(foto: foto, onBuka: onBukaSumberFoto),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: namaKategori(d.kategori),
                  style: const TextStyle(color: WarnaJelma.hijau, fontWeight: FontWeight.w800),
                ),
                TextSpan(text: '  ·  ${d.lokasi}'),
              ],
            ),
            style: tema.textTheme.labelLarge?.copyWith(color: WarnaJelma.tintaLembut, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(d.nama, style: tema.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Fakta(ikon: Icons.star_rounded, nilai: d.rating.toStringAsFixed(1), keterangan: 'rating dari 5'),
              _Fakta(
                ikon: Icons.schedule,
                nilai: status?.singkat ?? d.jamBuka,
                keterangan: d.jamBuka,
                warnaNilai: status == null ? null : (status.terbuka ? WarnaJelma.hijau : skema.error),
              ),
              if (jarak != null)
                _Fakta(ikon: Icons.near_me_outlined, nilai: formatJarak(jarak), keterangan: 'garis lurus dari Anda'),
              _Fakta(
                ikon: switch (d.ruang) {
                  Ruang.terbuka => Icons.park_outlined,
                  Ruang.tertutup => Icons.roofing,
                  Ruang.campuran => Icons.holiday_village_outlined,
                },
                nilai: d.ruang.label,
                keterangan: 'jenis tempat',
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(status.label, style: tema.textTheme.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(
            'Rating, harga, dan jam buka adalah data contoh.',
            style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
          ),
          const _Judul('Cuaca di lokasi ini'),
          _KartuCuacaDestinasi(destinasi: d),
          const _Judul('Tentang'),
          Text(d.deskripsi, style: tema.textTheme.bodyLarge),
          const _Judul('Fasilitas'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in d.fasilitas)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WarnaJelma.garis),
                  ),
                  child: Text(f, style: tema.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const _Judul('Lokasi'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined, color: WarnaJelma.hijau),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.lokasi, style: tema.textTheme.titleSmall),
                            if (d.koordinatPerkiraan)
                              Text(
                                'Titik perkiraan di pusat kota karena hidangan ini tersebar di banyak tempat.',
                                style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                              ),
                            if (jarak != null)
                              Text(
                                '${formatJarak(jarak)} garis lurus dari ${lokasi.label}',
                                style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onBukaRute,
                      icon: const Icon(Icons.directions),
                      label: const Text('Buka rute di Google Maps'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kredit foto sesuai atribusi Creative Commons; mengetuknya membuka halaman sumber foto.
class _BarisKredit extends StatelessWidget {
  const _BarisKredit({required this.foto, required this.onBuka});

  final FotoDestinasi foto;
  final ValueChanged<Uri> onBuka;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sumber = Uri.tryParse(foto.sumber);
    return Semantics(
      button: sumber != null,
      label: '${foto.kredit}. Buka halaman sumber foto',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: sumber == null ? null : () => onBuka(sumber),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              const Icon(Icons.photo_camera_outlined, size: 16, color: WarnaJelma.tintaLembut),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${foto.kredit}, Wikimedia Commons',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: WarnaJelma.tintaLembut),
            ],
          ),
        ),
      ),
    );
  }
}

class _Judul extends StatelessWidget {
  const _Judul(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Text(teks, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
    );
  }
}

/// Satu fakta ringkas di bawah nama destinasi, misalnya rating atau status buka.
class _Fakta extends StatelessWidget {
  const _Fakta({required this.ikon, required this.nilai, required this.keterangan, this.warnaNilai});

  final IconData ikon;
  final String nilai;
  final String keterangan;
  final Color? warnaNilai;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WarnaJelma.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, size: 18, color: warnaNilai ?? WarnaJelma.tinta),
              const SizedBox(width: 6),
              Text(nilai, style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: warnaNilai)),
            ],
          ),
          Text(keterangan, style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut)),
        ],
      ),
    );
  }
}

/// Bilah aksi yang menempel di bawah: harga dan tombol Rencanakan kunjungan.
///
/// Satu-satunya elemen berbayangan di halaman, karena melayang di atas isi yang bergulir.
class _BilahAksi extends StatelessWidget {
  const _BilahAksi({required this.destinasi});

  final Destinasi destinasi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final besar = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final harga = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(destinasi.judulHarga, style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut)),
        Text(destinasi.hargaLabel, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
    final tombol = FilledButton.icon(
      onPressed: () => Navigator.pushNamed(
        context,
        '/rencana/form',
        arguments: FormRencanaArgumen(destinasiAwal: destinasi),
      ),
      icon: const Icon(Icons.event_available),
      label: const Text('Rencanakan kunjungan'),
      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
    );
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: besar
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [harga, const SizedBox(height: 8), tombol],
                )
              : Row(children: [Expanded(child: harga), const SizedBox(width: 12), tombol]),
        ),
      ),
    );
  }
}

/// Cuaca saat ini di titik destinasi, saran kunjungan hari ini, dan prakiraan beberapa hari ke depan.
class _KartuCuacaDestinasi extends StatelessWidget {
  const _KartuCuacaDestinasi({required this.destinasi});

  final Destinasi destinasi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final cuaca = StoreScope.of<CuacaStore>(context);
    final prakiraan = cuaca.untukDestinasi(destinasi);
    final hari = prakiraan?.hariIni;

    if (prakiraan == null || hari == null) {
      final galat = cuaca.status == StatusCuaca.galat;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              galat
                  ? Icon(Icons.cloud_off, color: skema.error)
                  : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  galat
                      ? 'Cuaca belum dapat dimuat. Buka tab Cuaca lalu muat ulang.'
                      : 'Memuat cuaca di lokasi destinasi...',
                  style: tema.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final kini = prakiraan.saatIni;
    final saran = saranKunjungan(destinasi, hari);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IkonCuaca(kondisi: kini.kondisi, ukuran: 40, warna: WarnaJelma.hijau),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatSuhu(kini.suhu)} ${kini.kondisi.label}',
                        style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Terasa ${formatSuhu(kini.suhuTerasa)}, kelembapan ${kini.kelembapan}%, angin ${kini.angin.round()} km/jam',
                        style: tema.textTheme.bodySmall?.copyWith(color: WarnaJelma.tintaLembut),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ChipSaran(saran: saran),
            const SizedBox(height: 6),
            Text(saran.penjelasan, style: tema.textTheme.bodyMedium),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < prakiraan.harian.length && i < 4; i++)
                  Expanded(child: _HariMini(hari: prakiraan.harian[i], pertama: i == 0)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HariMini extends StatelessWidget {
  const _HariMini({required this.hari, required this.pertama});

  final CuacaHarian hari;
  final bool pertama;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Text(
          pertama ? 'Hari ini' : namaHariSingkat(hari.tanggal),
          style: tema.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        IkonCuaca(kondisi: hari.kondisi, ukuran: 24, warna: WarnaJelma.hijau),
        const SizedBox(height: 4),
        Text('${hari.suhuMaks.round()}° / ${hari.suhuMin.round()}°', style: tema.textTheme.labelSmall),
        Text('Hujan ${hari.peluangHujan}%', style: tema.textTheme.labelSmall),
      ],
    );
  }
}
