import 'dart:io';

import 'package:flutter/services.dart';

bool _sudahDimuat = false;

/// Memuat huruf Roboto dan ikon Material dari SDK Flutter ke dalam pengujian.
///
/// Huruf bawaan pengujian (Ahem) memberi setiap karakter lebar satu em, sehingga teks tampak
/// jauh lebih lebar daripada di perangkat dan menimbulkan galat overflow semu. Dengan Roboto
/// asli, lebar teks pada pengujian sama dengan di Android.
Future<void> muatFontNyata() async {
  if (_sudahDimuat) return;
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
  final folder = '$sdk/bin/cache/artifacts/material_fonts';

  Future<ByteData> baca(String nama) async => ByteData.sublistView(await File('$folder/$nama').readAsBytes());

  final roboto = FontLoader('Roboto')
    ..addFont(baca('roboto-regular.ttf'))
    ..addFont(baca('roboto-medium.ttf'))
    ..addFont(baca('roboto-bold.ttf'));
  final ikon = FontLoader('MaterialIcons')..addFont(baca('materialicons-regular.otf'));
  await roboto.load();
  await ikon.load();
  _sudahDimuat = true;
}
