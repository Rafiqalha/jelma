import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/destinasi.dart';

/// Asal data katalog yang sedang dipakai aplikasi.
enum SumberKatalog {
  aset('Bawaan aplikasi'),
  jaringan('Diunduh dari GitHub'),
  simpanan('Salinan unduhan terakhir');

  const SumberKatalog(this.label);

  final String label;
}

/// Kumpulan kategori dan destinasi hasil pemuatan data.
class KatalogDestinasi {
  const KatalogDestinasi({
    required this.kategori,
    required this.destinasi,
    this.versi = 1,
    this.sumber = SumberKatalog.aset,
  });

  final List<Kategori> kategori;
  final List<Destinasi> destinasi;

  /// Versi struktur data; versi 2 menambah koordinat dan jenis ruang.
  final int versi;
  final SumberKatalog sumber;

  /// Membangun katalog dari peta JSON. Bentuk yang sama dikembalikan oleh API.
  factory KatalogDestinasi.fromJson(Map<String, dynamic> json, {SumberKatalog sumber = SumberKatalog.aset}) =>
      KatalogDestinasi(
        kategori: (json['kategori'] as List)
            .map((e) => Kategori.fromJson(e as Map<String, dynamic>))
            .toList(),
        destinasi: (json['destinasi'] as List)
            .map((e) => Destinasi.fromJson(e as Map<String, dynamic>))
            .toList(),
        versi: json['versi'] as int? ?? 1,
        sumber: sumber,
      );

  /// Destinasi yang bertanda populer.
  List<Destinasi> get populer => destinasi.where((d) => d.populer).toList();

  /// Tiga destinasi dengan rating tertinggi; rating yang sama diurutkan menurut identitas.
  List<Destinasi> get ratingTertinggi {
    final urut = [...destinasi]..sort((a, b) {
        final banding = b.rating.compareTo(a.rating);
        return banding != 0 ? banding : a.id.compareTo(b.id);
      });
    return urut.take(3).toList();
  }

  Destinasi? cari(int id) {
    for (final d in destinasi) {
      if (d.id == id) return d;
    }
    return null;
  }
}

/// Sumber data destinasi.
///
/// Halaman hanya bergantung pada kelas ini, sehingga sumber data dapat diganti
/// tanpa mengubah tampilan.
abstract class DestinasiRepository {
  Future<KatalogDestinasi> muat();
}

/// Membaca data dari berkas JSON yang disertakan pada aset aplikasi.
class LocalDestinasiRepository implements DestinasiRepository {
  LocalDestinasiRepository({AssetBundle? bundle, this.path = 'assets/data/destinasi.json'})
      : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;
  final String path;

  @override
  Future<KatalogDestinasi> muat() async {
    final teks = await bundle.loadString(path);
    return KatalogDestinasi.fromJson(jsonDecode(teks) as Map<String, dynamic>);
  }
}

/// Alamat berkas katalog pada repositori GitHub proyek.
const String urlKatalogBawaan = 'https://raw.githubusercontent.com/Rafiqalha/jelma/main/assets/data/destinasi.json';

/// Versi data terendah yang dimengerti aplikasi ini.
const int versiKatalogMinimal = 2;

/// Mengunduh katalog dari internet, lalu jatuh ke salinan tersimpan dan terakhir ke aset.
///
/// Dengan begitu isi katalog dapat diperbarui tanpa merilis aplikasi baru, dan aplikasi
/// tetap berjalan saat tanpa jaringan.
class ApiDestinasiRepository implements DestinasiRepository {
  ApiDestinasiRepository({
    required this.cadangan,
    http.Client? klien,
    this.penyimpanan,
    this.url = urlKatalogBawaan,
    this.batas = const Duration(seconds: 4),
  }) : klien = klien ?? http.Client();

  final DestinasiRepository cadangan;
  final http.Client klien;
  final SharedPreferences? penyimpanan;
  final String url;
  final Duration batas;

  static const String _kunciSimpanan = 'katalog_simpanan';

  @override
  Future<KatalogDestinasi> muat() async {
    try {
      final respons = await klien.get(Uri.parse(url)).timeout(batas);
      if (respons.statusCode == 200) {
        final teks = utf8.decode(respons.bodyBytes);
        final katalog = KatalogDestinasi.fromJson(
          jsonDecode(teks) as Map<String, dynamic>,
          sumber: SumberKatalog.jaringan,
        );
        if (katalog.versi >= versiKatalogMinimal) {
          await penyimpanan?.setString(_kunciSimpanan, teks);
          return katalog;
        }
      }
    } catch (_) {
      // Jaringan mati, waktu habis, atau JSON tidak sesuai: lanjut ke salinan tersimpan.
    }
    final simpanan = penyimpanan?.getString(_kunciSimpanan);
    if (simpanan != null) {
      try {
        final katalog = KatalogDestinasi.fromJson(
          jsonDecode(simpanan) as Map<String, dynamic>,
          sumber: SumberKatalog.simpanan,
        );
        if (katalog.versi >= versiKatalogMinimal) return katalog;
      } catch (_) {
        // Salinan rusak: abaikan dan pakai aset.
      }
    }
    return cadangan.muat();
  }
}
