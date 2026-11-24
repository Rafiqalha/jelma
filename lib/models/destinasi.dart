import 'package:flutter/material.dart';

import 'format.dart';
import 'jam_buka.dart';
import 'koordinat.dart';

export 'format.dart' show formatRibuan;

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

/// Tempat kegiatan utama destinasi berlangsung; menentukan seberapa besar cuaca memengaruhinya.
enum Ruang {
  terbuka('Area terbuka'),
  tertutup('Dalam ruangan'),
  campuran('Dalam dan luar ruangan');

  const Ruang(this.label);

  final String label;

  /// Nama yang tidak dikenal dianggap terbuka agar penilaian cuaca tetap berhati-hati.
  static Ruang dariTeks(String? teks) =>
      Ruang.values.firstWhere((r) => r.name == teks, orElse: () => Ruang.terbuka);
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
    required this.koordinat,
    this.ruang = Ruang.terbuka,
    this.koordinatPerkiraan = false,
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

  /// Titik lokasi yang dipakai untuk jarak dan cuaca setempat.
  final Koordinat koordinat;
  final Ruang ruang;

  /// Benar untuk hidangan yang tersebar di banyak tempat; titiknya hanya pusat area.
  final bool koordinatPerkiraan;
  final bool populer;

  bool get gratis => harga == 0;

  /// Teks harga siap tampil, misalnya `Rp 35.000` atau `Gratis`.
  String get hargaLabel => gratis ? 'Gratis' : 'Rp ${formatRibuan(harga)}';

  /// Judul bidang harga; kuliner memakai "Kisaran harga" dan lainnya "Tiket masuk".
  String get judulHarga => kategori == 'kuliner' ? 'Kisaran harga' : 'Tiket masuk';

  /// Jam buka yang sudah diurai; null bila teksnya tidak berbentuk `07.00 - 16.00`.
  JamBuka? get jam => JamBuka.baca(jamBuka);

  StatusBuka? statusPada(DateTime waktuWib) => jam?.status(waktuWib);

  /// Jarak garis lurus dari [titik] dalam kilometer; null bila [titik] belum diketahui.
  double? jarakDari(Koordinat? titik) => titik?.jarakKm(koordinat);

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
        koordinat: Koordinat((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble()),
        ruang: Ruang.dariTeks(json['ruang'] as String?),
        koordinatPerkiraan: json['koordinat_perkiraan'] as bool? ?? false,
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
        'lat': koordinat.lintang,
        'lng': koordinat.bujur,
        'ruang': ruang.name,
        'koordinat_perkiraan': koordinatPerkiraan,
        'populer': populer,
      };
}
