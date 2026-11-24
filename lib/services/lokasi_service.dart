import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/koordinat.dart';

/// Keadaan izin lokasi dan layanan GPS pada perangkat.
enum IzinLokasi { diberikan, ditolak, ditolakPermanen, layananMati }

/// Posisi tidak dapat ditentukan; [pesan] siap ditampilkan kepada pengguna.
class LokasiGagal implements Exception {
  const LokasiGagal(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

/// Akses lokasi perangkat. Dipisahkan dari plugin agar dapat diganti pada pengujian.
abstract class LokasiService {
  /// Keadaan izin saat ini tanpa memunculkan dialog sistem.
  Future<IzinLokasi> cekIzin();

  /// Memunculkan dialog izin bila izin belum pernah ditolak permanen.
  Future<IzinLokasi> mintaIzin();

  Future<Koordinat> posisiSekarang();

  /// Nama tempat dari koordinat (geocoding balik); null bila tidak tersedia.
  Future<String?> namaTempat(Koordinat titik);

  Future<void> bukaPengaturanLokasi();

  Future<void> bukaPengaturanAplikasi();
}

/// Implementasi dengan paket geolocator dan geocoding.
class GeolocatorLokasiService implements LokasiService {
  @override
  Future<IzinLokasi> cekIzin() async {
    if (!await Geolocator.isLocationServiceEnabled()) return IzinLokasi.layananMati;
    return _petakan(await Geolocator.checkPermission());
  }

  @override
  Future<IzinLokasi> mintaIzin() async {
    if (!await Geolocator.isLocationServiceEnabled()) return IzinLokasi.layananMati;
    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) izin = await Geolocator.requestPermission();
    return _petakan(izin);
  }

  IzinLokasi _petakan(LocationPermission izin) => switch (izin) {
        LocationPermission.always || LocationPermission.whileInUse => IzinLokasi.diberikan,
        LocationPermission.deniedForever => IzinLokasi.ditolakPermanen,
        _ => IzinLokasi.ditolak,
      };

  @override
  Future<Koordinat> posisiSekarang() async {
    try {
      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Koordinat(posisi.latitude, posisi.longitude);
    } catch (_) {
      // Posisi terakhir yang diketahui lebih baik daripada gagal total saat sinyal GPS lemah.
      final terakhir = await Geolocator.getLastKnownPosition();
      if (terakhir != null) return Koordinat(terakhir.latitude, terakhir.longitude);
      throw const LokasiGagal('Posisi belum berhasil ditentukan. Coba lagi di tempat terbuka.');
    }
  }

  @override
  Future<String?> namaTempat(Koordinat titik) async {
    try {
      final hasil = await Geocoding()
          .placemarkFromCoordinates(titik.lintang, titik.bujur, locale: const Locale('id', 'ID'))
          .timeout(const Duration(seconds: 6));
      if (hasil.isEmpty) return null;
      final tempat = hasil.first;
      final bagian = <String>{
        for (final nama in [tempat.subLocality, tempat.locality ?? tempat.subAdministrativeArea])
          if (nama != null && nama.isNotEmpty) nama,
      };
      return bagian.isEmpty ? null : bagian.join(', ');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> bukaPengaturanLokasi() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Future<void> bukaPengaturanAplikasi() async {
    await Geolocator.openAppSettings();
  }
}
