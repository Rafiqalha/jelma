import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan identitas destinasi favorit dan memberi tahu tampilan saat berubah.
///
/// Bila [penyimpanan] diberikan, daftar dibaca saat dibuat dan ditulis setiap kali berubah,
/// sehingga favorit bertahan setelah aplikasi ditutup.
class FavoritStore extends ChangeNotifier {
  FavoritStore({SharedPreferences? penyimpanan}) : _penyimpanan = penyimpanan {
    final tersimpan = penyimpanan?.getStringList(_kunci) ?? const <String>[];
    _ids.addAll(tersimpan.map(int.tryParse).whereType<int>());
  }

  static const String _kunci = 'favorit_ids';

  final SharedPreferences? _penyimpanan;
  final Set<int> _ids = {};

  bool apakahFavorit(int id) => _ids.contains(id);

  int get jumlah => _ids.length;

  /// Menambahkan destinasi ke favorit, atau menghapusnya bila sudah ada.
  void toggle(int id) {
    if (!_ids.remove(id)) _ids.add(id);
    _penyimpanan?.setStringList(_kunci, [for (final i in _ids) '$i']);
    notifyListeners();
  }
}
