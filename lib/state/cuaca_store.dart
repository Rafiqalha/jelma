import 'package:flutter/foundation.dart';

import '../data/cuaca_service.dart';
import '../models/cuaca.dart';
import '../models/destinasi.dart';
import '../models/koordinat.dart';
import '../models/waktu.dart';

/// Keadaan pengambilan data cuaca.
enum StatusCuaca { kosong, memuat, siap, galat }

/// Menyimpan prakiraan cuaca untuk lokasi pengguna dan seluruh destinasi.
class CuacaStore extends ChangeNotifier {
  CuacaStore({required this._layanan, this._waktu = sekarangWib});

  final CuacaService _layanan;
  final PenyediaWaktu _waktu;
  final Map<String, PrakiraanCuaca> _data = {};

  StatusCuaca _status = StatusCuaca.kosong;
  String? _pesanGalat;
  DateTime? _diperbaruiPada;
  bool _sedangMemuat = false;
  (Koordinat, List<Destinasi>)? _tertunda;

  StatusCuaca get status => _status;

  String? get pesanGalat => _pesanGalat;

  /// Kapan data terakhir berhasil diambil (jam WIB); null bila belum pernah.
  DateTime? get diperbaruiPada => _diperbaruiPada;

  bool get adaData => _data.isNotEmpty;

  PrakiraanCuaca? untukTitik(Koordinat titik) => _data[titik.kunci];

  PrakiraanCuaca? untukDestinasi(Destinasi destinasi) => _data[destinasi.koordinat.kunci];

  /// Mengambil cuaca untuk [lokasi] dan semua [destinasi] dengan satu permintaan.
  ///
  /// Data lama tetap dipakai bila pengambilan gagal; [status] dan [pesanGalat] menjelaskannya.
  /// Panggilan yang datang saat pengambilan berjalan dijalankan setelahnya.
  Future<void> muat({required Koordinat lokasi, required List<Destinasi> destinasi}) async {
    if (_sedangMemuat) {
      _tertunda = (lokasi, destinasi);
      return;
    }
    _sedangMemuat = true;
    _status = StatusCuaca.memuat;
    notifyListeners();
    final titik = <String, Koordinat>{
      lokasi.kunci: lokasi,
      for (final d in destinasi) d.koordinat.kunci: d.koordinat,
    };
    try {
      final hasil = await _layanan.ambil(titik.values.toList());
      final kunci = titik.keys.toList();
      for (var i = 0; i < kunci.length; i++) {
        _data[kunci[i]] = hasil[i];
      }
      _pesanGalat = null;
      _diperbaruiPada = _waktu();
      _status = StatusCuaca.siap;
    } on CuacaGagal catch (e) {
      _pesanGalat = e.pesan;
      _status = StatusCuaca.galat;
    }
    _sedangMemuat = false;
    notifyListeners();
    final berikutnya = _tertunda;
    _tertunda = null;
    if (berikutnya != null) await muat(lokasi: berikutnya.$1, destinasi: berikutnya.$2);
  }
}
