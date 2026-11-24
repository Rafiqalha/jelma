import 'package:flutter/material.dart';

import 'format.dart';
import 'koordinat.dart';

/// Suhu terasa (derajat Celsius) mulai dari mana cuaca cerah disebut panas.
///
/// Ambang ini aturan aplikasi, bukan standar resmi lembaga cuaca.
const double ambangPanas = 32;

/// Kondisi cuaca yang ditampilkan kepada pengguna.
enum KondisiCuaca {
  cerah('Cerah', Icons.wb_sunny),
  cerahBerawan('Cerah berawan', Icons.wb_cloudy),
  berawan('Berawan', Icons.cloud_queue),
  mendung('Mendung', Icons.cloud),
  kabut('Berkabut', Icons.foggy),
  gerimis('Gerimis', Icons.grain),
  hujan('Hujan', Icons.water_drop),
  hujanLebat('Hujan lebat', Icons.water_drop),
  badaiPetir('Badai petir', Icons.thunderstorm),
  panas('Panas', Icons.device_thermostat);

  const KondisiCuaca(this.label, this.ikon);

  final String label;
  final IconData ikon;

  /// Kondisi yang membuat area terbuka basah atau berbahaya.
  bool get basah =>
      this == KondisiCuaca.gerimis ||
      this == KondisiCuaca.hujan ||
      this == KondisiCuaca.hujanLebat ||
      this == KondisiCuaca.badaiPetir;
}

/// Mengubah kode cuaca WMO dari Open-Meteo menjadi [KondisiCuaca].
///
/// Langit cerah atau berawan dengan [suhuTerasa] di atas [ambangPanas] disebut panas.
KondisiCuaca kondisiDariKode(int kode, {double? suhuTerasa}) {
  final dasar = switch (kode) {
    0 => KondisiCuaca.cerah,
    1 => KondisiCuaca.cerahBerawan,
    2 => KondisiCuaca.berawan,
    3 => KondisiCuaca.mendung,
    45 || 48 => KondisiCuaca.kabut,
    51 || 53 || 55 || 56 || 57 => KondisiCuaca.gerimis,
    61 || 63 || 66 || 80 || 81 => KondisiCuaca.hujan,
    65 || 67 || 82 => KondisiCuaca.hujanLebat,
    95 || 96 || 99 => KondisiCuaca.badaiPetir,
    _ => KondisiCuaca.berawan,
  };
  final langitTerbuka = dasar == KondisiCuaca.cerah ||
      dasar == KondisiCuaca.cerahBerawan ||
      dasar == KondisiCuaca.berawan;
  if (suhuTerasa != null && suhuTerasa >= ambangPanas && langitTerbuka) return KondisiCuaca.panas;
  return dasar;
}

/// Cuaca pada saat prakiraan diambil.
class CuacaSaatIni {
  const CuacaSaatIni({
    required this.waktu,
    required this.suhu,
    required this.suhuTerasa,
    required this.kelembapan,
    required this.curah,
    required this.kode,
    required this.angin,
    required this.siang,
  });

  /// Jam dinding WIB pada titik tersebut.
  final DateTime waktu;
  final double suhu;
  final double suhuTerasa;
  final int kelembapan;

  /// Curah hujan dalam milimeter pada jam terakhir.
  final double curah;
  final int kode;

  /// Kecepatan angin dalam kilometer per jam.
  final double angin;
  final bool siang;

  KondisiCuaca get kondisi => kondisiDariKode(kode, suhuTerasa: suhuTerasa);
}

/// Ringkasan cuaca untuk satu hari.
class CuacaHarian {
  const CuacaHarian({
    required this.tanggal,
    required this.kode,
    required this.suhuMaks,
    required this.suhuMin,
    required this.suhuTerasaMaks,
    required this.peluangHujan,
    required this.curahTotal,
    required this.uvMaks,
  });

  final DateTime tanggal;
  final int kode;
  final double suhuMaks;
  final double suhuMin;
  final double suhuTerasaMaks;

  /// Peluang hujan tertinggi pada hari itu, persen.
  final int peluangHujan;
  final double curahTotal;
  final double uvMaks;

  KondisiCuaca get kondisi => kondisiDariKode(kode, suhuTerasa: suhuTerasaMaks);
}

/// Cuaca saat ini dan prakiraan harian untuk satu titik.
class PrakiraanCuaca {
  const PrakiraanCuaca({required this.titik, required this.saatIni, required this.harian});

  final Koordinat titik;
  final CuacaSaatIni saatIni;
  final List<CuacaHarian> harian;

  /// Hari pertama pada data adalah hari ini menurut jam WIB.
  CuacaHarian? get hariIni => harian.isEmpty ? null : harian.first;

  CuacaHarian? hariPada(DateTime tanggal) {
    for (final hari in harian) {
      if (sehari(hari.tanggal, tanggal)) return hari;
    }
    return null;
  }
}
