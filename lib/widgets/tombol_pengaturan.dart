import 'package:flutter/material.dart';

/// Tombol pada AppBar yang membuka halaman Pengaturan.
class TombolPengaturan extends StatelessWidget {
  const TombolPengaturan({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Pengaturan',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.pushNamed(context, '/pengaturan'),
    );
  }
}
