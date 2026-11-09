import 'package:flutter/material.dart';

/// Menyimpan identitas destinasi favorit dan memberi tahu tampilan saat berubah.
class FavoritStore extends ChangeNotifier {
  final Set<int> _ids = {};

  bool apakahFavorit(int id) => _ids.contains(id);

  int get jumlah => _ids.length;

  /// Menambahkan destinasi ke favorit, atau menghapusnya bila sudah ada.
  void toggle(int id) {
    if (!_ids.remove(id)) _ids.add(id);
    notifyListeners();
  }
}

/// Menyediakan [FavoritStore] kepada seluruh halaman di bawahnya.
class FavoritScope extends InheritedNotifier<FavoritStore> {
  const FavoritScope({super.key, required FavoritStore store, required super.child})
      : super(notifier: store);

  /// Mengambil store terdekat dan mendaftarkan [context] agar dibangun ulang saat berubah.
  static FavoritStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavoritScope>();
    assert(scope != null, 'FavoritScope tidak ditemukan pada pohon widget');
    return scope!.notifier!;
  }
}
