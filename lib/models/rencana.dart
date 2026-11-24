import 'destinasi.dart';
import 'koordinat.dart';

/// Kapan pengingat rencana dikirim sebelum waktu kunjungan.
enum Pengingat {
  tidakAda('Tanpa pengingat'),
  satuJam('1 jam sebelumnya'),
  tigaJam('3 jam sebelumnya'),
  malamSebelumnya('Malam sebelumnya pukul 19.00');

  const Pengingat(this.label);

  final String label;

  /// Waktu pengingat untuk kunjungan pada [waktu]; null bila tanpa pengingat.
  DateTime? hitung(DateTime waktu) => switch (this) {
        Pengingat.tidakAda => null,
        Pengingat.satuJam => waktu.subtract(const Duration(hours: 1)),
        Pengingat.tigaJam => waktu.subtract(const Duration(hours: 3)),
        Pengingat.malamSebelumnya => DateTime.utc(waktu.year, waktu.month, waktu.day - 1, 19),
      };

  static Pengingat dariTeks(String? teks) =>
      Pengingat.values.firstWhere((p) => p.name == teks, orElse: () => Pengingat.satuJam);
}

/// Rencana kunjungan ke satu atau beberapa destinasi pada tanggal dan jam tertentu.
class Rencana {
  const Rencana({
    required this.id,
    required this.nama,
    required this.waktu,
    required this.idDestinasi,
    this.pengingat = Pengingat.satuJam,
  });

  /// Bilangan bulat kecil yang berurutan; juga dasar identitas notifikasi.
  final int id;
  final String nama;

  /// Jam dinding WIB (bertanda UTC, lihat `sekarangWib`).
  final DateTime waktu;
  final List<int> idDestinasi;
  final Pengingat pengingat;

  Rencana salin({String? nama, DateTime? waktu, List<int>? idDestinasi, Pengingat? pengingat}) => Rencana(
        id: id,
        nama: nama ?? this.nama,
        waktu: waktu ?? this.waktu,
        idDestinasi: idDestinasi ?? this.idDestinasi,
        pengingat: pengingat ?? this.pengingat,
      );

  factory Rencana.fromJson(Map<String, dynamic> json) => Rencana(
        id: json['id'] as int,
        nama: json['nama'] as String,
        waktu: DateTime.parse(json['waktu'] as String),
        idDestinasi: List<int>.from(json['destinasi'] as List),
        pengingat: Pengingat.dariTeks(json['pengingat'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'waktu': waktu.toIso8601String(),
        'destinasi': idDestinasi,
        'pengingat': pengingat.name,
      };
}

/// Urutan kunjungan yang disarankan beserta jarak setiap ruasnya.
class RuteKunjungan {
  const RuteKunjungan({required this.urutan, required this.ruas});

  final List<Destinasi> urutan;

  /// Jarak garis lurus ke setiap destinasi dari titik sebelumnya; null bila titik awal tidak diketahui.
  final List<double?> ruas;

  double get totalKm => ruas.fold(0.0, (jumlah, km) => jumlah + (km ?? 0));
}

/// Menyusun urutan kunjungan dengan tetangga terdekat: selalu pindah ke destinasi
/// terdekat berikutnya, dimulai dari [mulai]. Tanpa [mulai], urutan daftar dipertahankan.
RuteKunjungan susunRute(List<Destinasi> daftar, Koordinat? mulai) {
  final sisa = [...daftar];
  final urutan = <Destinasi>[];
  final ruas = <double?>[];
  var posisi = mulai;
  while (sisa.isNotEmpty) {
    var pilihan = sisa.first;
    if (posisi != null) {
      var jarak = posisi.jarakKm(pilihan.koordinat);
      for (final d in sisa.skip(1)) {
        final kandidat = posisi.jarakKm(d.koordinat);
        if (kandidat < jarak) {
          pilihan = d;
          jarak = kandidat;
        }
      }
    }
    ruas.add(posisi?.jarakKm(pilihan.koordinat));
    urutan.add(pilihan);
    sisa.remove(pilihan);
    posisi = pilihan.koordinat;
  }
  return RuteKunjungan(urutan: urutan, ruas: ruas);
}
