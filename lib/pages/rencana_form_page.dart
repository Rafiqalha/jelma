import 'package:flutter/material.dart';

import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/rencana.dart';
import '../state/cuaca_store.dart';
import '../state/katalog_store.dart';
import '../state/lokasi_store.dart';
import '../state/rencana_store.dart';
import '../state/store_scope.dart';
import '../widgets/gambar_destinasi.dart';
import '../widgets/keadaan_halaman.dart';

/// Argumen halaman form: [ubah] untuk mengubah rencana yang ada, [destinasiAwal] untuk
/// membuka form baru dengan satu destinasi sudah terpilih.
class FormRencanaArgumen {
  const FormRencanaArgumen({this.ubah, this.destinasiAwal});

  final Rencana? ubah;
  final Destinasi? destinasiAwal;
}

/// Halaman form untuk membuat atau mengubah rencana kunjungan.
class RencanaFormPage extends StatefulWidget {
  const RencanaFormPage({super.key});

  @override
  State<RencanaFormPage> createState() => _RencanaFormPageState();
}

class _RencanaFormPageState extends State<RencanaFormPage> {
  /// Prakiraan cuaca tersedia tujuh hari ke depan, termasuk hari ini.
  static const int _hariTersedia = 7;

  final TextEditingController _nama = TextEditingController();
  final TextEditingController _cari = TextEditingController();
  final Set<int> _terpilih = {};

  /// Pilihan saat form dibuka; dipakai untuk urutan daftar agar baris tidak berpindah saat dicentang.
  final Set<int> _terpilihAwal = {};

  Rencana? _ubah;
  late DateTime _tanggal;
  late TimeOfDay _jam;
  Pengingat _pengingat = Pengingat.satuJam;
  String _kata = '';
  String? _galatDestinasi;
  String? _galatWaktu;
  bool _siap = false;
  bool _menyimpan = false;

  /// Penanda bagian waktu dan destinasi; form digulir ke bagian yang bermasalah saat gagal disimpan.
  final GlobalKey _kunciWaktu = GlobalKey();
  final GlobalKey _kunciDestinasi = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_siap) return;
    _siap = true;
    final sekarang = WaktuScope.baca(context);
    final hariIni = DateTime.utc(sekarang.year, sekarang.month, sekarang.day);
    final argumen = ModalRoute.of(context)?.settings.arguments;
    final ubah = argumen is FormRencanaArgumen ? argumen.ubah : null;
    if (ubah != null) {
      _ubah = ubah;
      _nama.text = ubah.nama;
      _tanggal = DateTime.utc(ubah.waktu.year, ubah.waktu.month, ubah.waktu.day);
      _jam = TimeOfDay(hour: ubah.waktu.hour, minute: ubah.waktu.minute);
      _terpilih.addAll(ubah.idDestinasi);
      _pengingat = ubah.pengingat;
    } else {
      _tanggal = hariIni.add(const Duration(days: 1));
      _jam = const TimeOfDay(hour: 9, minute: 0);
      if (argumen is FormRencanaArgumen && argumen.destinasiAwal != null) {
        _terpilih.add(argumen.destinasiAwal!.id);
      }
    }
    _terpilihAwal.addAll(_terpilih);
  }

  @override
  void dispose() {
    _nama.dispose();
    _cari.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final sekarang = WaktuScope.baca(context);
    final hariIni = DateTime.utc(sekarang.year, sekarang.month, sekarang.day);
    final terakhir = hariIni.add(const Duration(days: _hariTersedia - 1));
    final awal = _tanggal.isBefore(hariIni) ? hariIni : _tanggal;
    final dipilih = await showDatePicker(
      context: context,
      initialDate: awal.isAfter(terakhir) ? terakhir : awal,
      firstDate: hariIni,
      lastDate: terakhir,
      helpText: 'Tanggal kunjungan',
    );
    if (dipilih == null) return;
    setState(() {
      _tanggal = DateTime.utc(dipilih.year, dipilih.month, dipilih.day);
      _galatWaktu = null;
    });
  }

  Future<void> _pilihJam() async {
    final dipilih = await showTimePicker(context: context, initialTime: _jam, helpText: 'Jam kunjungan');
    if (dipilih == null) return;
    setState(() {
      _jam = dipilih;
      _galatWaktu = null;
    });
  }

  String _namaOtomatis(List<Destinasi> tujuan) {
    if (tujuan.length == 1) return 'Kunjungan ke ${tujuan.first.nama}';
    return '${tujuan.first.nama} dan ${tujuan.length - 1} lainnya';
  }

  Future<void> _simpan() async {
    final katalog = StoreScope.baca<KatalogStore>(context).katalog;
    final store = StoreScope.baca<RencanaStore>(context);
    final cuaca = StoreScope.baca<CuacaStore>(context);
    if (katalog == null) return;
    final waktu = DateTime.utc(_tanggal.year, _tanggal.month, _tanggal.day, _jam.hour, _jam.minute);
    final tujuan = [for (final id in _terpilih) ?katalog.cari(id)];
    final tanpaTujuan = tujuan.isEmpty;
    final terlambat = !waktu.isAfter(WaktuScope.baca(context));
    setState(() {
      _galatDestinasi = tanpaTujuan ? 'Pilih minimal satu destinasi.' : null;
      _galatWaktu = terlambat ? 'Waktu ini sudah lewat. Pilih tanggal atau jam yang akan datang.' : null;
    });
    if (tanpaTujuan || terlambat) {
      // Pesan galat bisa berada di luar layar pada form yang panjang, jadi bagian itu digulir ke atas.
      final tanpaAnimasi = MediaQuery.disableAnimationsOf(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final konteks = (terlambat ? _kunciWaktu : _kunciDestinasi).currentContext;
        if (konteks == null || !konteks.mounted) return;
        Scrollable.ensureVisible(
          konteks,
          alignment: 0.1,
          duration: tanpaAnimasi ? Duration.zero : const Duration(milliseconds: 250),
        );
      });
      return;
    }

    setState(() => _menyimpan = true);
    final nama = _nama.text.trim().isEmpty ? _namaOtomatis(tujuan) : _nama.text.trim();
    final rencana = Rencana(
      id: _ubah?.id ?? store.buatId(),
      nama: nama,
      waktu: waktu,
      idDestinasi: _terpilih.toList(),
      pengingat: _pengingat,
    );
    final hasil = await store.simpan(rencana, katalog: katalog, cuaca: cuaca);
    if (!mounted) return;
    final pesan = hasil.pengingatTerjadwal
        ? 'Rencana disimpan. Pengingat: ${_pengingat.label.toLowerCase()}.'
        : hasil.catatan == null
            ? 'Rencana disimpan.'
            : 'Rencana disimpan. ${hasil.catatan}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final skema = tema.colorScheme;
    final katalog = StoreScope.of<KatalogStore>(context).katalog;
    final lokasi = StoreScope.of<LokasiStore>(context);

    if (katalog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rencana baru')),
        body: const KeadaanMemuat(pesan: 'Memuat katalog destinasi...'),
      );
    }

    final kata = _kata.trim().toLowerCase();
    final titik = lokasi.aktif;
    final indeks = {for (var i = 0; i < katalog.destinasi.length; i++) katalog.destinasi[i].id: i};
    final daftar = katalog.destinasi
        .where((d) => kata.isEmpty || d.nama.toLowerCase().contains(kata) || d.lokasi.toLowerCase().contains(kata))
        .toList()
      // Pilihan awal di atas, lalu jarak, lalu urutan katalog; sort Dart tidak stabil sehingga indeks katalog jadi penentu akhir.
      ..sort((a, b) {
        final pilihan = (_terpilihAwal.contains(a.id) ? 0 : 1).compareTo(_terpilihAwal.contains(b.id) ? 0 : 1);
        if (pilihan != 0) return pilihan;
        if (titik != null) {
          final jarak = a.jarakDari(titik)!.compareTo(b.jarakDari(titik)!);
          if (jarak != 0) return jarak;
        }
        return indeks[a.id]!.compareTo(indeks[b.id]!);
      });
    final urutanSisa = titik == null
        ? 'mengikuti urutan katalog karena lokasi Anda belum diketahui'
        : 'diurutkan dari yang terdekat dengan lokasi Anda';

    return Scaffold(
      appBar: AppBar(title: Text(_ubah == null ? 'Rencana baru' : 'Ubah rencana')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _nama,
            textInputAction: TextInputAction.next,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: const InputDecoration(
              labelText: 'Nama rencana (opsional)',
              hintText: 'Contoh: Akhir pekan di Batu',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            key: _kunciWaktu,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Tanggal'),
                  subtitle: Text(formatTanggal(_tanggal)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pilihTanggal,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Jam'),
                  subtitle: Text('${formatJam(_jam.hour * 60 + _jam.minute)} WIB'),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pilihJam,
                ),
              ],
            ),
          ),
          if (_galatWaktu != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(_galatWaktu!, style: tema.textTheme.bodySmall?.copyWith(color: skema.error)),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Pengingat>(
            initialValue: _pengingat,
            // Label pengingat terpanjang tidak muat di layar sempit; isExpanded membuatnya terpotong rapi.
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Pengingat',
              prefixIcon: Icon(Icons.notifications_active_outlined),
            ),
            items: [
              for (final p in Pengingat.values)
                DropdownMenuItem(value: p, child: Text(p.label, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (p) => setState(() => _pengingat = p ?? _pengingat),
          ),
          const SizedBox(height: 24),
          Text(
            'Destinasi (${_terpilih.length} dipilih)',
            key: _kunciDestinasi,
            style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _terpilihAwal.isEmpty
                ? 'Daftar $urutanSisa.'
                : 'Destinasi yang sudah dipilih tampil paling atas; sisanya $urutanSisa.',
            style: tema.textTheme.bodySmall?.copyWith(color: skema.onSurfaceVariant),
          ),
          // Pesan galat diletakkan di bawah judul bagian agar terlihat tanpa harus menggulir daftar.
          if (_galatDestinasi != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: skema.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_galatDestinasi!, style: tema.textTheme.bodyMedium?.copyWith(color: skema.error)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _cari,
            onChanged: (v) => setState(() => _kata = v),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              labelText: 'Cari destinasi',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _kata.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus kata kunci',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _cari.clear();
                        setState(() => _kata = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (daftar.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Tidak ada destinasi yang cocok dengan kata kunci.', style: tema.textTheme.bodyMedium),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final d in daftar)
                    CheckboxListTile(
                      value: _terpilih.contains(d.id),
                      onChanged: (pilih) => setState(() {
                        if (pilih ?? false) {
                          _terpilih.add(d.id);
                        } else {
                          _terpilih.remove(d.id);
                        }
                        _galatDestinasi = null;
                      }),
                      secondary: SizedBox.square(
                        dimension: 48,
                        child: GambarDestinasi(destinasi: d, ukuranIkon: 22, radius: BorderRadius.circular(12)),
                      ),
                      title: Text(d.nama),
                      subtitle: Text(
                        lokasi.aktif == null ? d.lokasi : '${formatJarak(d.jarakDari(lokasi.aktif)!)} · ${d.lokasi}',
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _menyimpan ? null : _simpan,
            icon: _menyimpan
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan rencana'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ),
      ),
    );
  }
}
