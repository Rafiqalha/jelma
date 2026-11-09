import 'package:flutter/material.dart';

/// Warna khas setiap kategori agar kartu dan halaman detail mudah dikenali.
Color warnaKategori(String id) => switch (id) {
      'alam' => const Color(0xFF2E7D32),
      'budaya' => const Color(0xFF8D5A2B),
      'kuliner' => const Color(0xFFD84315),
      'edukasi' => const Color(0xFF1565C0),
      _ => const Color(0xFF455A64),
    };

/// Ikon khas setiap kategori.
IconData ikonKategori(String id) => switch (id) {
      'alam' => Icons.terrain,
      'budaya' => Icons.museum,
      'kuliner' => Icons.restaurant,
      'edukasi' => Icons.school,
      _ => Icons.place,
    };

/// Nama kategori yang ditampilkan kepada pengguna.
String namaKategori(String id) => switch (id) {
      'alam' => 'Alam',
      'budaya' => 'Budaya',
      'kuliner' => 'Kuliner',
      'edukasi' => 'Edukasi',
      _ => 'Lainnya',
    };
