/// Pemformat angka, jarak, tanggal, dan jam berbahasa Indonesia.
///
/// Ditulis manual tanpa paket intl agar hasilnya sama di semua perangkat dan pengujian.
library;

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

/// Jarak yang mudah dibaca: `850 m`, `3,4 km`, `21 km`, atau `14.052 km`.
String formatJarak(double km) {
  if (km < 0.995) return '${(km * 100).round() * 10} m';
  if (km < 9.95) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${formatRibuan(km.round())} km';
}

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _hariSingkat = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _bulanSingkat = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String namaHari(DateTime d) => _hari[d.weekday - 1];

String namaHariSingkat(DateTime d) => _hariSingkat[d.weekday - 1];

String namaBulanSingkat(DateTime d) => _bulanSingkat[d.month - 1];

/// Contoh: `Sabtu, 29 November 2026`.
String formatTanggal(DateTime d) => '${namaHari(d)}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// Contoh: `29 Nov`.
String formatTanggalSingkat(DateTime d) => '${d.day} ${namaBulanSingkat(d)}';

/// Menit sejak tengah malam menjadi teks jam bertitik, misalnya `570` menjadi `09.30`.
String formatJam(int menit) {
  final jam = (menit ~/ 60).toString().padLeft(2, '0');
  final sisa = (menit % 60).toString().padLeft(2, '0');
  return '$jam.$sisa';
}

String formatJamWaktu(DateTime d) => formatJam(d.hour * 60 + d.minute);

/// Suhu bulat dengan simbol derajat, misalnya `26°`.
String formatSuhu(double celsius) => '${celsius.round()}°';

/// Apakah [a] dan [b] jatuh pada tanggal kalender yang sama.
bool sehari(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
