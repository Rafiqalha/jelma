import 'package:flutter/foundation.dart';

import '../services/notifikasi_service.dart';

/// Menyimpan keadaan izin notifikasi dan menyediakan notifikasi uji untuk halaman Pengaturan.
class NotifikasiStore extends ChangeNotifier {
  NotifikasiStore(this._layanan);

  final NotifikasiService _layanan;

  bool? _izin;

  /// Apakah notifikasi diizinkan; null selama belum diperiksa.
  bool? get izin => _izin;

  Future<void> periksa() async {
    _izin = await _layanan.izinDiberikan();
    notifyListeners();
  }

  Future<bool> mintaIzin() async {
    _izin = await _layanan.mintaIzin();
    notifyListeners();
    return _izin ?? false;
  }

  /// Menampilkan satu notifikasi contoh; meminta izin lebih dulu bila perlu.
  ///
  /// Mengembalikan false bila izin tidak diberikan sehingga notifikasi tidak tampil.
  Future<bool> kirimUji() async {
    var diizinkan = await _layanan.izinDiberikan();
    if (!diizinkan) diizinkan = await _layanan.mintaIzin();
    _izin = diizinkan;
    notifyListeners();
    if (!diizinkan) return false;
    await _layanan.tampilkan(
      id: 1,
      judul: 'Notifikasi uji Jelajah Malang',
      isi: 'Pengingat rencana dan peringatan cuaca akan tampil seperti ini.',
      saluran: SaluranNotifikasi.pengingat,
    );
    return true;
  }
}
