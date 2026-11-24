import 'package:flutter/widgets.dart';

import 'models/destinasi.dart';

/// Argumen halaman Detail: destinasi dan tag Hero foto kartu yang diketuk.
class ArgumenDetail {
  const ArgumenDetail(this.destinasi, {this.heroTag});

  final Destinasi destinasi;
  final String? heroTag;
}

/// Membuka halaman Detail. [heroTag] membuat foto kartu terbang ke kepala halaman Detail.
Future<void> bukaDetail(BuildContext context, Destinasi destinasi, {String? heroTag}) =>
    Navigator.pushNamed(context, '/detail', arguments: ArgumenDetail(destinasi, heroTag: heroTag));

/// Tag Hero foto; [asal] membedakan kemunculan destinasi yang sama di beberapa bagian satu halaman.
String tagFoto(String asal, Destinasi destinasi) => 'foto-$asal-${destinasi.id}';
