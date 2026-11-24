import 'package:flutter/widgets.dart';

import '../models/waktu.dart';
import 'cuaca_store.dart';
import 'favorit_store.dart';
import 'katalog_store.dart';
import 'lokasi_store.dart';
import 'notifikasi_store.dart';
import 'pengaturan_store.dart';
import 'rencana_store.dart';
import 'store_scope.dart';

/// Menyediakan semua store, jam sistem, dan pembuka tautan kepada seluruh halaman dalam satu tempat.
class CakupanAplikasi extends StatelessWidget {
  const CakupanAplikasi({
    super.key,
    required this.katalog,
    required this.pengaturan,
    required this.lokasi,
    required this.cuaca,
    required this.rencana,
    required this.favorit,
    required this.notifikasi,
    required this.waktu,
    required this.bukaTautan,
    required this.child,
  });

  final KatalogStore katalog;
  final PengaturanStore pengaturan;
  final LokasiStore lokasi;
  final CuacaStore cuaca;
  final RencanaStore rencana;
  final FavoritStore favorit;
  final NotifikasiStore notifikasi;
  final PenyediaWaktu waktu;
  final PembukaTautan bukaTautan;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TautanScope(
      buka: bukaTautan,
      child: WaktuScope(
        sekarang: waktu,
        child: StoreScope<KatalogStore>(
          store: katalog,
          child: StoreScope<PengaturanStore>(
            store: pengaturan,
            child: StoreScope<LokasiStore>(
              store: lokasi,
              child: StoreScope<CuacaStore>(
                store: cuaca,
                child: StoreScope<RencanaStore>(
                  store: rencana,
                  child: StoreScope<FavoritStore>(
                    store: favorit,
                    child: StoreScope<NotifikasiStore>(store: notifikasi, child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
