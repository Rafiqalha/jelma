import 'package:flutter/material.dart';

/// Memetakan nama ikon pada JSON menjadi [IconData] Material.
///
/// Dengan cara ini berkas JSON (atau respons API) cukup menyimpan teks,
/// sedangkan tampilan tetap memakai ikon bawaan Flutter.
const Map<String, IconData> _petaIkon = {
  'apps': Icons.apps,
  'terrain': Icons.terrain,
  'museum': Icons.museum,
  'restaurant': Icons.restaurant,
  'school': Icons.school,
};

/// Mengembalikan ikon untuk [nama]; ikon lokasi dipakai bila nama tidak dikenal.
IconData ikonDariNama(String nama) => _petaIkon[nama] ?? Icons.place;

/// Mengubah bilangan bulat menjadi teks dengan pemisah ribuan titik,
/// misalnya `35000` menjadi `35.000`.
String formatRibuan(int nilai) {
  final teks = nilai.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < teks.length; i++) {
    if (i > 0 && (teks.length - i) % 3 == 0) buffer.write('.');
    buffer.write(teks[i]);
  }
  return nilai < 0 ? '-$buffer' : buffer.toString();
}

/// Kategori destinasi, misalnya Alam atau Kuliner.
class Kategori {
  const Kategori({required this.id, required this.nama, required this.ikon});

  final String id;
  final String nama;

  /// Nama ikon pada JSON (lihat [ikonDariNama]).
  final String ikon;

  IconData get ikonData => ikonDariNama(ikon);

  factory Kategori.fromJson(Map<String, dynamic> json) => Kategori(
        id: json['id'] as String,
        nama: json['nama'] as String,
        ikon: json['ikon'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama, 'ikon': ikon};
}

/// Satu destinasi wisata beserta informasi yang ditampilkan pada aplikasi.
class Destinasi {
  const Destinasi({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.lokasi,
    required this.deskripsi,
    required this.rating,
    required this.harga,
    required this.jamBuka,
    required this.fasilitas,
    this.populer = false,
  });

  final int id;
  final String nama;

  /// Identitas kategori (mis. `alam`).
  final String kategori;
  final String lokasi;
  final String deskripsi;
  final double rating;

  /// Harga tiket masuk atau kisaran harga makanan dalam rupiah; 0 berarti gratis.
  final int harga;
  final String jamBuka;
  final List<String> fasilitas;
  final bool populer;

  bool get gratis => harga == 0;

  /// Teks harga siap tampil, misalnya `Rp 35.000` atau `Gratis`.
  String get hargaLabel => gratis ? 'Gratis' : 'Rp ${formatRibuan(harga)}';

  /// Judul bidang harga; kuliner memakai "Kisaran harga" dan lainnya "Tiket masuk".
  String get judulHarga => kategori == 'kuliner' ? 'Kisaran harga' : 'Tiket masuk';

  factory Destinasi.fromJson(Map<String, dynamic> json) => Destinasi(
        id: json['id'] as int,
        nama: json['nama'] as String,
        kategori: json['kategori'] as String,
        lokasi: json['lokasi'] as String,
        deskripsi: json['deskripsi'] as String,
        rating: (json['rating'] as num).toDouble(),
        harga: json['harga'] as int,
        jamBuka: json['jam_buka'] as String,
        fasilitas: List<String>.from(json['fasilitas'] as List),
        populer: json['populer'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'kategori': kategori,
        'lokasi': lokasi,
        'deskripsi': deskripsi,
        'rating': rating,
        'harga': harga,
        'jam_buka': jamBuka,
        'fasilitas': fasilitas,
        'populer': populer,
      };
}
