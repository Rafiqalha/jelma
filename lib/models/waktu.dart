/// Sumber waktu yang dapat diganti pada pengujian.
typedef PenyediaWaktu = DateTime Function();

/// Jam dinding di Malang (WIB, UTC+7), terlepas dari zona waktu perangkat.
///
/// Nilainya bertanda UTC hanya supaya zona perangkat tidak menggesernya lagi;
/// komponen tanggal dan jamnya tetap jam WIB.
DateTime sekarangWib() => DateTime.now().toUtc().add(const Duration(hours: 7));
