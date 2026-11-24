import 'format.dart';

/// Keadaan buka atau tutup pada satu saat, lengkap dengan keterangan siap tampil.
class StatusBuka {
  const StatusBuka({required this.terbuka, required this.label});

  final bool terbuka;

  /// Contoh: `Buka sampai 16.00` atau `Tutup, buka 07.00`.
  final String label;

  String get singkat => terbuka ? 'Buka' : 'Tutup';
}

/// Rentang jam operasional harian dalam menit sejak tengah malam.
class JamBuka {
  const JamBuka({required this.buka, required this.tutup});

  final int buka;
  final int tutup;

  static final RegExp _pola = RegExp(r'^\s*(\d{1,2})[.:](\d{2})\s*-\s*(\d{1,2})[.:](\d{2})\s*$');

  /// Membaca teks seperti `07.00 - 16.00`; null bila bentuknya tidak dikenal.
  static JamBuka? baca(String teks) {
    final cocok = _pola.firstMatch(teks);
    if (cocok == null) return null;
    final jamBuka = int.parse(cocok[1]!);
    final jamTutup = int.parse(cocok[3]!);
    final menitBuka = int.parse(cocok[2]!);
    final menitTutup = int.parse(cocok[4]!);
    if (jamBuka > 23 || jamTutup > 24 || menitBuka > 59 || menitTutup > 59) return null;
    return JamBuka(buka: jamBuka * 60 + menitBuka, tutup: jamTutup * 60 + menitTutup);
  }

  bool get duaPuluhEmpatJam => buka == tutup;

  /// Rentang yang melewati tengah malam (misalnya 18.00 - 02.00) dihitung sebagai buka malam hari.
  bool terbukaPada(int menit) {
    if (duaPuluhEmpatJam) return true;
    if (buka < tutup) return menit >= buka && menit < tutup;
    return menit >= buka || menit < tutup;
  }

  /// Status pada [sekarang], yang dibaca sebagai jam dinding WIB.
  StatusBuka status(DateTime sekarang) {
    final menit = sekarang.hour * 60 + sekarang.minute;
    if (duaPuluhEmpatJam) return const StatusBuka(terbuka: true, label: 'Buka 24 jam');
    if (terbukaPada(menit)) {
      return StatusBuka(terbuka: true, label: 'Buka sampai ${formatJam(tutup % 1440)}');
    }
    final belumBuka = buka < tutup ? menit < buka : menit >= tutup && menit < buka;
    final kapan = belumBuka ? '' : 'besok ';
    return StatusBuka(terbuka: false, label: 'Tutup, buka $kapan${formatJam(buka)}');
  }
}
