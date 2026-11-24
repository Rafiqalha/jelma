import 'dart:math' as math;

/// Titik pada permukaan bumi dalam derajat desimal.
class Koordinat {
  const Koordinat(this.lintang, this.bujur);

  final double lintang;
  final double bujur;

  static const double _jariBumiKm = 6371.0088;

  /// Jarak garis lurus ke [lain] dalam kilometer (rumus Haversine).
  ///
  /// Jarak lewat jalan selalu lebih panjang, sehingga angka ini hanya perkiraan.
  double jarakKm(Koordinat lain) {
    double rad(double derajat) => derajat * math.pi / 180;
    final dLat = rad(lain.lintang - lintang);
    final dBujur = rad(lain.bujur - bujur);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lintang)) * math.cos(rad(lain.lintang)) * math.pow(math.sin(dBujur / 2), 2);
    return 2 * _jariBumiKm * math.asin(math.min(1.0, math.sqrt(a)));
  }

  /// Kunci pembulatan tiga desimal (sekitar 110 m) untuk menyimpan hasil per titik.
  String get kunci => '${lintang.toStringAsFixed(3)},${bujur.toStringAsFixed(3)}';

  @override
  bool operator ==(Object other) =>
      other is Koordinat && other.lintang == lintang && other.bujur == bujur;

  @override
  int get hashCode => Object.hash(lintang, bujur);

  @override
  String toString() => 'Koordinat($lintang, $bujur)';
}
