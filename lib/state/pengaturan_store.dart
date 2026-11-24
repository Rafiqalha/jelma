import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/area_referensi.dart';

/// Dari mana lokasi pengguna diambil.
enum ModeLokasi { gps, manual }

/// Pengaturan pengguna yang disimpan permanen pada `SharedPreferences`.
class PengaturanStore extends ChangeNotifier {
  PengaturanStore(this._penyimpanan)
      : _modeLokasi = ModeLokasi.values.firstWhere(
          (m) => m.name == _penyimpanan.getString(_kMode),
          orElse: () => ModeLokasi.gps,
        ),
        _idArea = _penyimpanan.getString(_kArea) ?? areaBawaan.id,
        _radiusKm = _penyimpanan.getDouble(_kRadius) ?? radiusBawaanKm,
        _pengingatAktif = _penyimpanan.getBool(_kPengingat) ?? true,
        _peringatanCuacaAktif = _penyimpanan.getBool(_kPeringatan) ?? true,
        _onboardingSelesai = _penyimpanan.getBool(_kOnboarding) ?? false;

  static const String _kMode = 'mode_lokasi';
  static const String _kArea = 'id_area';
  static const String _kRadius = 'radius_km';
  static const String _kPengingat = 'pengingat_aktif';
  static const String _kPeringatan = 'peringatan_cuaca_aktif';
  static const String _kOnboarding = 'onboarding_selesai';

  static const double radiusBawaanKm = 25;
  static const double radiusMinKm = 5;
  static const double radiusMaksKm = 50;

  final SharedPreferences _penyimpanan;
  ModeLokasi _modeLokasi;
  String _idArea;
  double _radiusKm;
  bool _pengingatAktif;
  bool _peringatanCuacaAktif;
  bool _onboardingSelesai;

  ModeLokasi get modeLokasi => _modeLokasi;

  AreaReferensi get area => areaDariId(_idArea) ?? areaBawaan;

  /// Radius pencarian "Dekat Anda" dalam kilometer.
  double get radiusKm => _radiusKm;

  bool get pengingatAktif => _pengingatAktif;

  bool get peringatanCuacaAktif => _peringatanCuacaAktif;

  /// Benar setelah pengguna menyelesaikan atau melewati pengenalan aplikasi pada pembukaan pertama.
  bool get onboardingSelesai => _onboardingSelesai;

  void aturModeLokasi(ModeLokasi mode) {
    _modeLokasi = mode;
    _penyimpanan.setString(_kMode, mode.name);
    notifyListeners();
  }

  void aturArea(String id) {
    _idArea = id;
    _penyimpanan.setString(_kArea, id);
    notifyListeners();
  }

  void aturRadius(double km) {
    _radiusKm = km.clamp(radiusMinKm, radiusMaksKm);
    _penyimpanan.setDouble(_kRadius, _radiusKm);
    notifyListeners();
  }

  void aturPengingat(bool aktif) {
    _pengingatAktif = aktif;
    _penyimpanan.setBool(_kPengingat, aktif);
    notifyListeners();
  }

  void aturPeringatanCuaca(bool aktif) {
    _peringatanCuacaAktif = aktif;
    _penyimpanan.setBool(_kPeringatan, aktif);
    notifyListeners();
  }

  void selesaikanOnboarding() {
    _onboardingSelesai = true;
    _penyimpanan.setBool(_kOnboarding, true);
    notifyListeners();
  }
}
