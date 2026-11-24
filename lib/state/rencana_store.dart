import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/destinasi_repository.dart';
import '../models/destinasi.dart';
import '../models/format.dart';
import '../models/rencana.dart';
import '../models/saran_cuaca.dart';
import '../models/waktu.dart';
import '../services/notifikasi_service.dart';
import 'cuaca_store.dart';
import 'pengaturan_store.dart';

/// Hasil menyimpan rencana: apakah pengingat terjadwal dan, bila tidak, alasannya.
class HasilSimpan {
  const HasilSimpan({required this.pengingatTerjadwal, this.catatan});

  final bool pengingatTerjadwal;

  /// Penjelasan singkat bila pengingat yang diminta tidak terjadwal.
  final String? catatan;
}

/// Menyimpan rencana kunjungan secara permanen dan mengatur notifikasi yang menyertainya.
class RencanaStore extends ChangeNotifier {
  RencanaStore({
    required this._penyimpanan,
    required this._notifikasi,
    required this._pengaturan,
    this._waktu = sekarangWib,
  }) {
    _bacaTersimpan();
  }

  static const String _kunciDaftar = 'rencana_daftar';
  static const String _kunciId = 'rencana_id_terakhir';
  static const String _kunciPeringatan = 'peringatan_terkirim';

  final SharedPreferences _penyimpanan;
  final NotifikasiService _notifikasi;
  final PengaturanStore _pengaturan;
  final PenyediaWaktu _waktu;
  final List<Rencana> _daftar = [];

  /// Semua rencana, diurutkan dari yang paling awal.
  List<Rencana> get daftar => List.unmodifiable(_daftar);

  List<Rencana> get mendatang => _daftar.where((r) => !sudahLewat(r)).toList();

  List<Rencana> get selesai => _daftar.where(sudahLewat).toList().reversed.toList();

  bool sudahLewat(Rencana rencana) => rencana.waktu.isBefore(_waktu());

  Rencana? cari(int id) {
    for (final r in _daftar) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Identitas baru berupa bilangan bulat berurutan; dipakai juga sebagai dasar identitas notifikasi.
  int buatId() {
    final id = (_penyimpanan.getInt(_kunciId) ?? 0) + 1;
    _penyimpanan.setInt(_kunciId, id);
    return id;
  }

  int _idPengingat(int id) => id * 2;

  int _idPeringatan(int id) => id * 2 + 1;

  void _bacaTersimpan() {
    final teks = _penyimpanan.getString(_kunciDaftar);
    if (teks == null) return;
    try {
      final daftar = (jsonDecode(teks) as List).map((e) => Rencana.fromJson(e as Map<String, dynamic>));
      _daftar
        ..clear()
        ..addAll(daftar);
      _urutkan();
    } catch (_) {
      // Data rusak: mulai dari daftar kosong daripada membuat aplikasi gagal dibuka.
      _daftar.clear();
    }
  }

  void _urutkan() => _daftar.sort((a, b) => a.waktu.compareTo(b.waktu));

  Future<void> _tulis() => _penyimpanan.setString(
        _kunciDaftar,
        jsonEncode([for (final r in _daftar) r.toJson()]),
      );

  List<Destinasi> _tujuan(Rencana rencana, KatalogDestinasi katalog) => [
        for (final id in rencana.idDestinasi) ?katalog.cari(id),
      ];

  /// Menambah rencana baru, atau mengganti rencana dengan identitas yang sama, lalu menjadwalkan pengingatnya.
  Future<HasilSimpan> simpan(Rencana rencana, {required KatalogDestinasi katalog, CuacaStore? cuaca}) async {
    final indeks = _daftar.indexWhere((r) => r.id == rencana.id);
    if (indeks >= 0) {
      _daftar[indeks] = rencana;
    } else {
      _daftar.add(rencana);
    }
    _urutkan();
    await _tulis();
    final hasil = await _jadwalkanPengingat(rencana, katalog, cuaca);
    notifyListeners();
    return hasil;
  }

  Future<void> hapus(int id) async {
    _daftar.removeWhere((r) => r.id == id);
    await _tulis();
    await _notifikasi.batalkan(_idPengingat(id));
    await _notifikasi.batalkan(_idPeringatan(id));
    notifyListeners();
  }

  Future<HasilSimpan> _jadwalkanPengingat(Rencana rencana, KatalogDestinasi katalog, CuacaStore? cuaca) async {
    await _notifikasi.batalkan(_idPengingat(rencana.id));
    final waktuPengingat = rencana.pengingat.hitung(rencana.waktu);
    if (waktuPengingat == null) return const HasilSimpan(pengingatTerjadwal: false);
    if (!_pengaturan.pengingatAktif) {
      return const HasilSimpan(pengingatTerjadwal: false, catatan: 'Pengingat dimatikan di Pengaturan.');
    }
    if (!waktuPengingat.isAfter(_waktu())) {
      return const HasilSimpan(
        pengingatTerjadwal: false,
        catatan: 'Waktu pengingat sudah lewat, jadi pengingat tidak dijadwalkan.',
      );
    }
    var diizinkan = await _notifikasi.izinDiberikan();
    if (!diizinkan) diizinkan = await _notifikasi.mintaIzin();
    if (!diizinkan) {
      return const HasilSimpan(
        pengingatTerjadwal: false,
        catatan: 'Izin notifikasi belum diberikan, jadi pengingat tidak dijadwalkan.',
      );
    }
    final berhasil = await _notifikasi.jadwalkan(
      id: _idPengingat(rencana.id),
      waktu: waktuPengingat,
      judul: 'Pengingat: ${rencana.nama}',
      isi: _isiPengingat(rencana, katalog, cuaca),
      saluran: SaluranNotifikasi.pengingat,
    );
    return HasilSimpan(
      pengingatTerjadwal: berhasil,
      catatan: berhasil ? null : 'Pengingat tidak dapat dijadwalkan.',
    );
  }

  String _isiPengingat(Rencana rencana, KatalogDestinasi katalog, CuacaStore? cuaca) {
    final tujuan = _tujuan(rencana, katalog);
    final awal = '${formatJamWaktu(rencana.waktu)} di ${tujuan.map((d) => d.nama).join(', ')}.';
    final nilai = cuaca == null ? null : nilaiRencana(rencana, tujuan, cuaca.untukDestinasi);
    if (nilai == null) return awal;
    return '$awal Prakiraan: ${nilai.kondisi.label.toLowerCase()}, peluang hujan ${nilai.peluangHujan}%.';
  }

  /// Menyesuaikan notifikasi dengan prakiraan terbaru; dipanggil setiap kali cuaca berhasil dimuat.
  ///
  /// Teks pengingat diperbarui, dan rencana dalam 48 jam yang cuacanya kurang mendukung
  /// memicu satu peringatan per hari kunjungan.
  Future<void> sinkronkan({required KatalogDestinasi katalog, required CuacaStore cuaca}) async {
    if (!await _notifikasi.izinDiberikan()) return;
    final sekarang = _waktu();
    for (final rencana in _daftar) {
      if (!rencana.waktu.isAfter(sekarang)) continue;
      final waktuPengingat = rencana.pengingat.hitung(rencana.waktu);
      if (_pengaturan.pengingatAktif && waktuPengingat != null && waktuPengingat.isAfter(sekarang)) {
        await _notifikasi.jadwalkan(
          id: _idPengingat(rencana.id),
          waktu: waktuPengingat,
          judul: 'Pengingat: ${rencana.nama}',
          isi: _isiPengingat(rencana, katalog, cuaca),
          saluran: SaluranNotifikasi.pengingat,
        );
      }
      if (_pengaturan.peringatanCuacaAktif && rencana.waktu.difference(sekarang) <= const Duration(hours: 48)) {
        await _peringatkan(rencana, katalog, cuaca);
      }
    }
  }

  Future<void> _peringatkan(Rencana rencana, KatalogDestinasi katalog, CuacaStore cuaca) async {
    final nilai = nilaiRencana(rencana, _tujuan(rencana, katalog), cuaca.untukDestinasi);
    if (nilai == null || nilai.tingkat == TingkatSaran.baik) return;
    final w = rencana.waktu;
    final kunci = '${rencana.id}|${w.year}-${w.month}-${w.day}|${nilai.tingkat.name}';
    final terkirim = _penyimpanan.getStringList(_kunciPeringatan) ?? const <String>[];
    if (terkirim.contains(kunci)) return;
    await _notifikasi.tampilkan(
      id: _idPeringatan(rencana.id),
      judul: 'Cuaca kurang mendukung: ${rencana.nama}',
      isi: '${namaHari(w)} ${formatJamWaktu(w)}: ${nilai.kondisi.label.toLowerCase()}, '
          'peluang hujan ${nilai.peluangHujan}%. '
          '${nilai.penyebab.nama}: ${nilai.saran.judul.toLowerCase()}.',
      saluran: SaluranNotifikasi.cuaca,
    );
    await _penyimpanan.setStringList(_kunciPeringatan, [...terkirim, kunci]);
  }
}
