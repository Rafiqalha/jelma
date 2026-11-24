import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/cuaca_service.dart';
import '../models/waktu.dart';
import '../state/store_scope.dart';
import 'lokasi_service.dart';
import 'notifikasi_service.dart';

/// Kumpulan layanan luar (penyimpanan, GPS, cuaca, notifikasi, jam) yang dipakai aplikasi.
///
/// Semuanya diberikan dari luar sehingga pengujian dapat menggantinya dengan tiruan.
class LayananAplikasi {
  const LayananAplikasi({
    required this.penyimpanan,
    required this.lokasi,
    required this.cuaca,
    required this.notifikasi,
    this.waktu = sekarangWib,
    this.bukaTautan = _bukaDiLuarAplikasi,
  });

  final SharedPreferences penyimpanan;
  final LokasiService lokasi;
  final CuacaService cuaca;
  final NotifikasiService notifikasi;
  final PenyediaWaktu waktu;
  final PembukaTautan bukaTautan;

  static Future<bool> _bukaDiLuarAplikasi(Uri tautan) => launchUrl(tautan, mode: LaunchMode.externalApplication);

  /// Layanan sungguhan untuk dijalankan di perangkat.
  static Future<LayananAplikasi> bawaan() async {
    final penyimpanan = await SharedPreferences.getInstance();
    final notifikasi = LocalNotifikasiService();
    await notifikasi.inisialisasi();
    return LayananAplikasi(
      penyimpanan: penyimpanan,
      lokasi: GeolocatorLokasiService(),
      cuaca: OpenMeteoCuacaService(),
      notifikasi: notifikasi,
    );
  }
}
