import 'dart:io';

import 'package:flutter/services.dart';

bool _sudahDimuat = false;

/// Memuat huruf aplikasi (Plus Jakarta Sans), Roboto, dan ikon Material ke dalam pengujian.
///
/// Huruf bawaan pengujian (Ahem) memberi setiap karakter lebar satu em, sehingga teks tampak
/// jauh lebih lebar daripada di perangkat dan menimbulkan galat overflow semu. Dengan huruf asli,
/// lebar teks pada pengujian sama dengan di Android.
Future<void> muatFontNyata() async {
  if (_sudahDimuat) return;
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
  final folder = '$sdk/bin/cache/artifacts/material_fonts';

  Future<ByteData> baca(String jalur) async => ByteData.sublistView(await File(jalur).readAsBytes());

  final jakarta = FontLoader('PlusJakartaSans');
  for (final tebal in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    jakarta.addFont(baca('assets/fonts/PlusJakartaSans-$tebal.ttf'));
  }
  final roboto = FontLoader('Roboto')
    ..addFont(baca('$folder/roboto-regular.ttf'))
    ..addFont(baca('$folder/roboto-medium.ttf'))
    ..addFont(baca('$folder/roboto-bold.ttf'));
  final ikon = FontLoader('MaterialIcons')..addFont(baca('$folder/materialicons-regular.otf'));
  await jakarta.load();
  await roboto.load();
  await ikon.load();
  _sudahDimuat = true;
}
