import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts_jelajah_malang/data/cuaca_service.dart';
import 'package:uts_jelajah_malang/data/destinasi_repository.dart';
import 'package:uts_jelajah_malang/models/cuaca.dart';
import 'package:uts_jelajah_malang/models/koordinat.dart';

import 'alat_uji.dart';

const String _responsDuaTitik = '''
[
  {
    "latitude": -7.97, "longitude": 112.59,
    "current": {"time": "2026-11-24T08:45", "temperature_2m": 26.4, "apparent_temperature": 30.7,
      "relative_humidity_2m": 76, "precipitation": 0.0, "weather_code": 2, "wind_speed_10m": 5.2, "is_day": 1},
    "daily": {"time": ["2026-11-24", "2026-11-25"], "weather_code": [95, 80],
      "temperature_2m_max": [28.7, 26.3], "temperature_2m_min": [22.2, 22.0],
      "apparent_temperature_max": [33.1, 30.0], "precipitation_probability_max": [100, 100],
      "precipitation_sum": [10.4, 7.2], "uv_index_max": [8.15, 8.35]}
  },
  {
    "latitude": -7.87, "longitude": 112.48,
    "current": {"time": "2026-11-24T08:45", "temperature_2m": 20.0, "apparent_temperature": 21.0,
      "relative_humidity_2m": 90, "precipitation": 1.2, "weather_code": 63, "wind_speed_10m": 9.0, "is_day": 1},
    "daily": {"time": ["2026-11-24", "2026-11-25"], "weather_code": [63, 3],
      "temperature_2m_max": [23.0, 24.0], "temperature_2m_min": [16.0, 16.5],
      "apparent_temperature_max": [24.0, 25.0], "precipitation_probability_max": [90, 40],
      "precipitation_sum": [12.0, 1.0], "uv_index_max": [5.0, 6.0]}
  }
]
''';

const String _responsSatuTitik = '''
{
  "latitude": -7.97, "longitude": 112.59,
  "current": {"time": "2026-11-24T14:00", "temperature_2m": 31.0, "apparent_temperature": 35.5,
    "relative_humidity_2m": 60, "precipitation": 0.0, "weather_code": 0, "wind_speed_10m": 3.0, "is_day": 1},
  "daily": {"time": ["2026-11-24"], "weather_code": [0],
    "temperature_2m_max": [32.0], "temperature_2m_min": [22.0], "apparent_temperature_max": [36.0],
    "precipitation_probability_max": [null], "precipitation_sum": [0.0], "uv_index_max": [11.0]}
}
''';

void main() {
  const titikDua = [Koordinat(-7.9826, 112.6308), Koordinat(-7.8696, 112.4840)];

  group('bacaOpenMeteo', () {
    test('mengurai respons larik untuk beberapa titik', () {
      final hasil = bacaOpenMeteo(_responsDuaTitik, titikDua);
      expect(hasil, hasLength(2));
      final pertama = hasil.first;
      expect(pertama.titik, titikDua.first);
      expect(pertama.saatIni.suhu, 26.4);
      expect(pertama.saatIni.kelembapan, 76);
      expect(pertama.saatIni.waktu, DateTime.utc(2026, 11, 24, 8, 45));
      expect(pertama.saatIni.kondisi, KondisiCuaca.berawan);
      expect(pertama.hariIni!.kondisi, KondisiCuaca.badaiPetir);
      expect(pertama.hariIni!.peluangHujan, 100);
      expect(pertama.harian, hasLength(2));
      expect(pertama.hariPada(DateTime.utc(2026, 11, 25))!.kondisi, KondisiCuaca.hujan);
      expect(hasil.last.saatIni.kondisi, KondisiCuaca.hujan);
    });

    test('mengurai respons objek tunggal dan nilai null menjadi nol', () {
      final hasil = bacaOpenMeteo(_responsSatuTitik, [titikDua.first]);
      expect(hasil, hasLength(1));
      expect(hasil.single.hariIni!.peluangHujan, 0);
      expect(hasil.single.saatIni.kondisi, KondisiCuaca.panas);
    });

    test('jumlah hasil yang tidak sama dengan jumlah titik ditolak', () {
      expect(() => bacaOpenMeteo(_responsDuaTitik, [titikDua.first]), throwsFormatException);
    });
  });

  group('OpenMeteoCuacaService', () {
    test('mengirim semua titik dalam satu permintaan dengan zona waktu Jakarta', () async {
      late Uri diminta;
      final klien = MockClient((request) async {
        diminta = request.url;
        return http.Response(_responsDuaTitik, 200);
      });
      final hasil = await OpenMeteoCuacaService(klien: klien).ambil(titikDua);
      expect(hasil, hasLength(2));
      expect(diminta.host, 'api.open-meteo.com');
      expect(diminta.path, '/v1/forecast');
      expect(diminta.queryParameters['latitude'], '-7.9826,-7.8696');
      expect(diminta.queryParameters['longitude'], '112.6308,112.4840');
      expect(diminta.queryParameters['timezone'], 'Asia/Jakarta');
      expect(diminta.queryParameters['forecast_days'], '7');
      expect(diminta.queryParameters['current'], contains('weather_code'));
    });

    test('daftar titik kosong tidak memanggil jaringan', () async {
      var dipanggil = false;
      final klien = MockClient((_) async {
        dipanggil = true;
        return http.Response('', 200);
      });
      expect(await OpenMeteoCuacaService(klien: klien).ambil(const []), isEmpty);
      expect(dipanggil, isFalse);
    });

    test('kode status bukan 200 menjadi CuacaGagal', () async {
      final klien = MockClient((_) async => http.Response('galat', 500));
      await expectLater(
        OpenMeteoCuacaService(klien: klien).ambil(titikDua),
        throwsA(isA<CuacaGagal>().having((e) => e.pesan, 'pesan', contains('500'))),
      );
    });

    test('kegagalan jaringan menjadi CuacaGagal dengan saran memeriksa koneksi', () async {
      final klien = MockClient((_) async => throw const SocketException('mati'));
      await expectLater(
        OpenMeteoCuacaService(klien: klien).ambil(titikDua),
        throwsA(isA<CuacaGagal>().having((e) => e.pesan, 'pesan', contains('koneksi internet'))),
      );
    });

    test('waktu habis menjadi CuacaGagal', () async {
      final klien = MockClient((_) => Completer<http.Response>().future);
      await expectLater(
        OpenMeteoCuacaService(klien: klien, batas: const Duration(milliseconds: 20)).ambil(titikDua),
        throwsA(isA<CuacaGagal>().having((e) => e.pesan, 'pesan', contains('tidak merespons'))),
      );
    });

    test('isi yang bukan JSON menjadi CuacaGagal', () async {
      final klien = MockClient((_) async => http.Response('bukan json', 200));
      await expectLater(
        OpenMeteoCuacaService(klien: klien).ambil(titikDua),
        throwsA(isA<CuacaGagal>().having((e) => e.pesan, 'pesan', contains('tidak dapat dibaca'))),
      );
    });
  });

  group('ApiDestinasiRepository', () {
    final jsonV2 = jsonEncode({
      'versi': 2,
      'kategori': [
        {'id': 'alam', 'nama': 'Alam', 'ikon': 'terrain'},
      ],
      'destinasi': [cobanUji.toJson()],
    });
    final jsonV1 = jsonEncode({
      'kategori': [
        {'id': 'alam', 'nama': 'Alam', 'ikon': 'terrain'},
      ],
      'destinasi': [cobanUji.toJson()],
    });

    Future<ApiDestinasiRepository> buat(
      Future<http.Response> Function(http.Request) balas, {
      Map<String, Object> awal = const {},
    }) async {
      SharedPreferences.setMockInitialValues(awal);
      return ApiDestinasiRepository(
        cadangan: RepositoriUji(),
        klien: MockClient(balas),
        penyimpanan: await SharedPreferences.getInstance(),
        batas: const Duration(milliseconds: 50),
      );
    }

    test('memakai data jaringan versi 2 dan menyimpannya', () async {
      final repo = await buat((_) async => http.Response(jsonV2, 200));
      final katalog = await repo.muat();
      expect(katalog.sumber, SumberKatalog.jaringan);
      expect(katalog.destinasi, hasLength(1));
      expect(repo.penyimpanan!.getString('katalog_simpanan'), jsonV2);
    });

    test('menolak data jaringan versi lama dan memakai aset', () async {
      final repo = await buat((_) async => http.Response(jsonV1, 200));
      final katalog = await repo.muat();
      expect(katalog.sumber, SumberKatalog.aset);
      expect(katalog.destinasi, hasLength(3));
    });

    test('jaringan gagal memakai salinan tersimpan bila ada', () async {
      final repo = await buat((_) async => http.Response('', 503), awal: {'katalog_simpanan': jsonV2});
      final katalog = await repo.muat();
      expect(katalog.sumber, SumberKatalog.simpanan);
    });

    test('jaringan dan salinan tidak tersedia memakai aset', () async {
      final repo = await buat((_) async => throw const SocketException('mati'));
      expect((await repo.muat()).sumber, SumberKatalog.aset);
    });

    test('waktu habis memakai aset', () async {
      final repo = await buat((_) => Completer<http.Response>().future);
      expect((await repo.muat()).sumber, SumberKatalog.aset);
    });

    test('JSON rusak dan salinan rusak tetap berakhir pada aset', () async {
      final repo = await buat((_) async => http.Response('{rusak', 200), awal: {'katalog_simpanan': '{rusak'});
      expect((await repo.muat()).sumber, SumberKatalog.aset);
    });
  });

  group('Berkas data destinasi.json', () {
    late KatalogDestinasi katalog;

    setUpAll(() {
      final teks = File('assets/data/destinasi.json').readAsStringSync();
      katalog = KatalogDestinasi.fromJson(jsonDecode(teks) as Map<String, dynamic>);
    });

    test('berstruktur versi 2 dengan 19 destinasi dan empat kategori', () {
      expect(katalog.versi, 2);
      expect(katalog.destinasi, hasLength(19));
      expect(katalog.kategori.map((k) => k.id), ['alam', 'budaya', 'kuliner', 'edukasi']);
    });

    test('identitas unik dan setiap kategori dikenal', () {
      final ids = katalog.destinasi.map((d) => d.id).toSet();
      expect(ids, hasLength(katalog.destinasi.length));
      final kategori = katalog.kategori.map((k) => k.id).toSet();
      expect(katalog.destinasi.every((d) => kategori.contains(d.kategori)), isTrue);
    });

    test('semua koordinat berada di wilayah Malang Raya', () {
      for (final d in katalog.destinasi) {
        expect(d.koordinat.lintang, inInclusiveRange(-8.6, -7.7), reason: d.nama);
        expect(d.koordinat.bujur, inInclusiveRange(112.2, 113.0), reason: d.nama);
      }
    });

    test('semua jam buka dapat dibaca dan semua jenis ruang dikenal', () {
      for (final d in katalog.destinasi) {
        expect(d.jam, isNotNull, reason: d.nama);
      }
      final data = jsonDecode(File('assets/data/destinasi.json').readAsStringSync()) as Map<String, dynamic>;
      for (final d in data['destinasi'] as List) {
        expect(['terbuka', 'tertutup', 'campuran'], contains((d as Map<String, dynamic>)['ruang']), reason: '${d['nama']}');
      }
    });

    test('hanya hidangan kuliner yang bertitik perkiraan', () {
      final perkiraan = katalog.destinasi.where((d) => d.koordinatPerkiraan).toList();
      expect(perkiraan.map((d) => d.kategori).toSet(), {'kuliner'});
      expect(perkiraan, hasLength(3));
    });
  });
}
