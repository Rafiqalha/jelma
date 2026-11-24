import 'package:flutter/material.dart';

import '../models/cuaca.dart';

/// Ikon kondisi cuaca. Selalu dipasangkan dengan teks kondisi di sebelahnya.
class IkonCuaca extends StatelessWidget {
  const IkonCuaca({super.key, required this.kondisi, this.ukuran = 24, this.warna});

  final KondisiCuaca kondisi;
  final double ukuran;
  final Color? warna;

  @override
  Widget build(BuildContext context) => Icon(kondisi.ikon, size: ukuran, color: warna);
}
