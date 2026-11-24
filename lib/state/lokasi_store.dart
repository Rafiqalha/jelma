import 'package:flutter/foundation.dart';

import '../models/area_referensi.dart';
import '../models/koordinat.dart';
import '../models/waktu.dart';
import '../services/lokasi_service.dart';
import 'pengaturan_store.dart';

/// Keadaan penentuan lokasi pengguna.
enum StatusLokasi { belumDicek, memuat, siap, izinDitolak, izinDitolakPermanen, layananMati, galat }

/// Menyimpan lokasi aktif pengguna, baik dari GPS maupun dari area yang dipilih manual.
class LokasiStore extends ChangeNotifier {
  LokasiStore({required this._layanan, required this._pengaturan, this._waktu = sekarangWib});

  /// Jarak dari area acuan terdekat (km) di atas mana pengguna dianggap jauh dari Malang Raya.
  static const double batasJauhKm = 100;

  final LokasiService _layanan;
  final PengaturanStore _pengaturan;
  final PenyediaWaktu _waktu;

  StatusLokasi _status = StatusLokasi.belumDicek;
  Koordinat? _posisiGps;
  String? _namaGps;
  String? _pesanGalat;
  DateTime? _diperbaruiPada;
  bool _sedangMemuat = false;

  StatusLokasi get status => _status;

  String? get pesanGalat => _pesanGalat;

  DateTime? get diperbaruiPada => _diperbaruiPada;

  ModeLokasi get mode => _pengaturan.modeLokasi;

  /// Titik untuk menghitung jarak dan saran: area manual atau GPS; null bila belum diketahui.
  Koordinat? get aktif => mode == ModeLokasi.manual ? _pengaturan.area.koordinat : _posisiGps;

  /// Titik untuk mengambil cuaca; area bawaan dipakai selama lokasi belum diketahui.
  Koordinat get untukCuaca => aktif ?? areaBawaan.koordinat;

  bool get memakaiBawaan => aktif == null;

  /// Nama lokasi yang ditampilkan, misalnya `Lowokwaru, Malang` atau nama area pilihan.
  String get label {
    if (mode == ModeLokasi.manual) return _pengaturan.area.nama;
    final gps = _posisiGps;
    if (gps == null) return areaBawaan.nama;
    return _namaGps ?? 'Dekat ${areaTerdekat(gps).nama}';
  }

  /// Asal lokasi: `GPS`, `Area pilihan`, atau `Bawaan`.
  String get sumberLabel {
    if (mode == ModeLokasi.manual) return 'Area pilihan';
    return _posisiGps == null ? 'Bawaan' : 'GPS';
  }

  bool get jauhDariMalang {
    final titik = aktif;
    return titik != null && areaTerdekat(titik).koordinat.jarakKm(titik) > batasJauhKm;
  }

  /// Dipanggil saat aplikasi dibuka: memakai GPS bila izin sudah ada, tanpa memunculkan dialog.
  Future<void> mulai() async {
    if (mode == ModeLokasi.manual) {
      _status = StatusLokasi.siap;
      notifyListeners();
      return;
    }
    final izin = await _layanan.cekIzin();
    if (izin == IzinLokasi.diberikan) {
      await perbarui();
    } else {
      _terapkanIzin(izin);
    }
  }

  /// Mengambil posisi GPS terbaru; [mintaIzin] memunculkan dialog izin sistem bila perlu.
  Future<void> perbarui({bool mintaIzin = false}) async {
    if (mode == ModeLokasi.manual || _sedangMemuat) return;
    _sedangMemuat = true;
    _status = StatusLokasi.memuat;
    notifyListeners();
    try {
      final izin = mintaIzin ? await _layanan.mintaIzin() : await _layanan.cekIzin();
      if (izin != IzinLokasi.diberikan) {
        _terapkanIzin(izin);
        return;
      }
      final titik = await _layanan.posisiSekarang();
      _posisiGps = titik;
      _namaGps = await _layanan.namaTempat(titik);
      _diperbaruiPada = _waktu();
      _pesanGalat = null;
      _status = StatusLokasi.siap;
      notifyListeners();
    } on LokasiGagal catch (e) {
      _pesanGalat = e.pesan;
      _status = StatusLokasi.galat;
      notifyListeners();
    } catch (_) {
      _pesanGalat = 'Lokasi tidak dapat dibaca dari perangkat. Coba lagi.';
      _status = StatusLokasi.galat;
      notifyListeners();
    } finally {
      _sedangMemuat = false;
    }
  }

  /// Beralih ke GPS dan langsung meminta izin serta posisi.
  Future<void> pakaiGps() async {
    _pengaturan.aturModeLokasi(ModeLokasi.gps);
    _status = StatusLokasi.belumDicek;
    await perbarui(mintaIzin: true);
  }

  /// Beralih ke area manual; GPS tidak dipakai lagi sampai pengguna memilihnya.
  void pakaiArea(String id) {
    _pengaturan.aturArea(id);
    _pengaturan.aturModeLokasi(ModeLokasi.manual);
    _status = StatusLokasi.siap;
    notifyListeners();
  }

  Future<void> bukaPengaturanLokasi() => _layanan.bukaPengaturanLokasi();

  Future<void> bukaPengaturanAplikasi() => _layanan.bukaPengaturanAplikasi();

  void _terapkanIzin(IzinLokasi izin) {
    _status = switch (izin) {
      IzinLokasi.diberikan => StatusLokasi.siap,
      IzinLokasi.ditolak => StatusLokasi.izinDitolak,
      IzinLokasi.ditolakPermanen => StatusLokasi.izinDitolakPermanen,
      IzinLokasi.layananMati => StatusLokasi.layananMati,
    };
    notifyListeners();
  }
}
