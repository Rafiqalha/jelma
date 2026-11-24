import 'package:flutter/widgets.dart';

import '../models/waktu.dart';

/// Menyediakan satu [ChangeNotifier] kepada seluruh pohon widget di bawahnya.
///
/// Satu kelas generik menggantikan satu `InheritedNotifier` per store.
class StoreScope<T extends ChangeNotifier> extends InheritedNotifier<T> {
  const StoreScope({super.key, required T store, required super.child}) : super(notifier: store);

  /// Mengambil store terdekat dan mendaftarkan [context] agar dibangun ulang saat store berubah.
  static T of<T extends ChangeNotifier>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope<T>>();
    assert(scope != null, 'StoreScope<$T> tidak ditemukan pada pohon widget');
    return scope!.notifier!;
  }

  /// Seperti [of] tetapi tanpa mendaftarkan dependensi, sehingga boleh dipanggil dari `initState`.
  static T baca<T extends ChangeNotifier>(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<StoreScope<T>>();
    assert(scope != null, 'StoreScope<$T> tidak ditemukan pada pohon widget');
    return scope!.notifier!;
  }
}

/// Membuka tautan di luar aplikasi (peramban atau aplikasi peta).
typedef PembukaTautan = Future<bool> Function(Uri tautan);

/// Menyediakan pembuka tautan kepada seluruh pohon widget; dapat diganti pada pengujian.
class TautanScope extends InheritedWidget {
  const TautanScope({super.key, required this.buka, required super.child});

  final PembukaTautan buka;

  /// Pembuka tautan terdekat; mengembalikan `false` bila tidak ada [TautanScope].
  static PembukaTautan baca(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<TautanScope>();
    return scope?.buka ?? (_) async => false;
  }

  @override
  bool updateShouldNotify(TautanScope oldWidget) => false;
}

/// Menyediakan jam sistem kepada seluruh pohon widget; dapat diganti pada pengujian.
class WaktuScope extends InheritedWidget {
  const WaktuScope({super.key, required this.sekarang, required super.child});

  final PenyediaWaktu sekarang;

  /// Jam dinding WIB saat ini; memakai jam sistem bila tidak ada [WaktuScope].
  static DateTime baca(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<WaktuScope>();
    return scope?.sekarang() ?? sekarangWib();
  }

  @override
  bool updateShouldNotify(WaktuScope oldWidget) => false;
}
