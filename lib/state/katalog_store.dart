import 'package:flutter/foundation.dart';

import '../data/destinasi_repository.dart';

/// Keadaan pemuatan katalog destinasi.
enum StatusKatalog { memuat, siap, galat }

/// Memuat katalog destinasi dari repositori dan menyimpannya untuk seluruh halaman.
class KatalogStore extends ChangeNotifier {
  KatalogStore(this._repository);

  final DestinasiRepository _repository;

  StatusKatalog _status = StatusKatalog.memuat;
  KatalogDestinasi? _katalog;

  StatusKatalog get status => _status;

  /// Katalog yang sudah dimuat; null selama [status] bukan [StatusKatalog.siap].
  KatalogDestinasi? get katalog => _katalog;

  Future<void> muat() async {
    _status = StatusKatalog.memuat;
    notifyListeners();
    try {
      _katalog = await _repository.muat();
      _status = StatusKatalog.siap;
    } catch (_) {
      _status = StatusKatalog.galat;
    }
    notifyListeners();
  }
}
