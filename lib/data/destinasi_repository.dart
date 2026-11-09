import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/destinasi.dart';

/// Kumpulan kategori dan destinasi hasil pemuatan data.
class KatalogDestinasi {
  const KatalogDestinasi({required this.kategori, required this.destinasi});

  final List<Kategori> kategori;
  final List<Destinasi> destinasi;

  /// Membangun katalog dari peta JSON. Bentuk yang sama dapat dikembalikan oleh API.
  factory KatalogDestinasi.fromJson(Map<String, dynamic> json) => KatalogDestinasi(
        kategori: (json['kategori'] as List)
            .map((e) => Kategori.fromJson(e as Map<String, dynamic>))
            .toList(),
        destinasi: (json['destinasi'] as List)
            .map((e) => Destinasi.fromJson(e as Map<String, dynamic>))
            .toList(),
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
}

/// Sumber data destinasi.
///
/// Halaman hanya bergantung pada kelas ini. Untuk beralih dari data dummy ke API,
/// cukup membuat kelas baru yang mengimplementasikan [muat] dengan `http.get`
/// lalu mengganti objek yang diberikan pada `JelajahApp`.
abstract class DestinasiRepository {
  Future<KatalogDestinasi> muat();
}

/// Membaca data dummy dari berkas JSON yang disertakan pada aset aplikasi.
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
