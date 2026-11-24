import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cuaca.dart';
import '../models/koordinat.dart';

/// Kegagalan mengambil atau membaca data cuaca, dengan pesan yang siap ditampilkan.
class CuacaGagal implements Exception {
  const CuacaGagal(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

/// Sumber prakiraan cuaca per titik.
abstract class CuacaService {
  /// Mengambil cuaca untuk setiap titik; hasilnya berurutan sesuai [titik].
  Future<List<PrakiraanCuaca>> ambil(List<Koordinat> titik);
}

/// Mengambil cuaca dari Open-Meteo (https://open-meteo.com), tanpa kunci API.
///
/// Semua titik dikirim dalam satu permintaan sehingga satu kali muat cukup untuk lokasi
/// pengguna dan seluruh destinasi.
class OpenMeteoCuacaService implements CuacaService {
  OpenMeteoCuacaService({http.Client? klien, this.batas = const Duration(seconds: 12)})
      : klien = klien ?? http.Client();

  final http.Client klien;
  final Duration batas;

  @override
  Future<List<PrakiraanCuaca>> ambil(List<Koordinat> titik) async {
    if (titik.isEmpty) return const [];
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': titik.map((t) => t.lintang.toStringAsFixed(4)).join(','),
      'longitude': titik.map((t) => t.bujur.toStringAsFixed(4)).join(','),
      'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,'
          'weather_code,wind_speed_10m,is_day',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,'
          'precipitation_probability_max,precipitation_sum,uv_index_max',
      'timezone': 'Asia/Jakarta',
      'forecast_days': '7',
    });
    final http.Response respons;
    try {
      respons = await klien.get(uri).timeout(batas);
    } on TimeoutException {
      throw const CuacaGagal('Server cuaca tidak merespons. Coba lagi sebentar lagi.');
    } catch (_) {
      throw const CuacaGagal('Tidak dapat terhubung ke server cuaca. Periksa koneksi internet.');
    }
    if (respons.statusCode != 200) {
      throw CuacaGagal('Server cuaca menolak permintaan (kode ${respons.statusCode}).');
    }
    try {
      return bacaOpenMeteo(utf8.decode(respons.bodyBytes), titik);
    } catch (_) {
      throw const CuacaGagal('Data cuaca dari server tidak dapat dibaca.');
    }
  }
}

/// Mengurai respons Open-Meteo menjadi satu [PrakiraanCuaca] per titik.
///
/// Satu titik dibalas sebagai objek, beberapa titik sebagai larik; keduanya ditangani.
List<PrakiraanCuaca> bacaOpenMeteo(String badan, List<Koordinat> titik) {
  final json = jsonDecode(badan);
  final daftar = json is List ? json : [json];
  if (daftar.length != titik.length) {
    throw FormatException('Jumlah hasil ${daftar.length} tidak sama dengan jumlah titik ${titik.length}');
  }
  return [
    for (var i = 0; i < titik.length; i++) _bacaSatu(daftar[i] as Map<String, dynamic>, titik[i]),
  ];
}

double _angka(Object? nilai) => (nilai as num?)?.toDouble() ?? 0;

/// Waktu dari Open-Meteo sudah berupa jam WIB tanpa zona; "Z" menjaga komponennya tidak bergeser.
DateTime _waktu(String teks) => DateTime.parse(teks.length == 10 ? '${teks}T00:00:00Z' : '${teks}Z');

PrakiraanCuaca _bacaSatu(Map<String, dynamic> json, Koordinat titik) {
  final kini = json['current'] as Map<String, dynamic>;
  final harian = json['daily'] as Map<String, dynamic>;
  final tanggal = List<String>.from(harian['time'] as List);

  double ambilHari(String bidang, int i) {
    final larik = harian[bidang] as List?;
    return larik != null && i < larik.length ? _angka(larik[i]) : 0;
  }

  return PrakiraanCuaca(
    titik: titik,
    saatIni: CuacaSaatIni(
      waktu: _waktu(kini['time'] as String),
      suhu: _angka(kini['temperature_2m']),
      suhuTerasa: _angka(kini['apparent_temperature']),
      kelembapan: _angka(kini['relative_humidity_2m']).round(),
      curah: _angka(kini['precipitation']),
      kode: _angka(kini['weather_code']).round(),
      angin: _angka(kini['wind_speed_10m']),
      siang: _angka(kini['is_day']) == 1,
    ),
    harian: [
      for (var i = 0; i < tanggal.length; i++)
        CuacaHarian(
          tanggal: _waktu(tanggal[i]),
          kode: ambilHari('weather_code', i).round(),
          suhuMaks: ambilHari('temperature_2m_max', i),
          suhuMin: ambilHari('temperature_2m_min', i),
          suhuTerasaMaks: ambilHari('apparent_temperature_max', i),
          peluangHujan: ambilHari('precipitation_probability_max', i).round(),
          curahTotal: ambilHari('precipitation_sum', i),
          uvMaks: ambilHari('uv_index_max', i),
        ),
    ],
  );
}
