import 'package:flutter/material.dart';

/// Palet JELMA. Alasan setiap warna dan hasil uji kontrasnya ada di `docs/riset-desain.md`.
abstract final class WarnaJelma {
  /// Hijau pinus, warna utama; teks putih di atasnya 7,06:1.
  static const Color hijau = Color(0xFF0B6457);

  /// Latar lembut untuk chip terpilih, indikator navigasi, dan label "cocok".
  static const Color hijauMuda = Color(0xFFD5EDE6);

  /// Teks di atas [hijauMuda].
  static const Color hijauTua = Color(0xFF00423A);

  /// Teks utama; 13,94:1 di [latar].
  static const Color tinta = Color(0xFF102A26);

  /// Teks sekunder; 5,82:1 di [latar] dan 6,35:1 di putih.
  static const Color tintaLembut = Color(0xFF56625F);

  /// Latar halaman: netral hangat agar warna foto tampil apa adanya.
  static const Color latar = Color(0xFFF6F5F1);

  /// Garis tipis pemisah kartu (dekoratif, bukan batas kontrol).
  static const Color garis = Color(0xFFE3E1DA);

  /// Batas kontrol seperti kolom isian dan chip; minimal 3:1 terhadap latar.
  static const Color garisKontrol = Color(0xFF7D8985);

  /// Aksen jingga di latar terang: titik logo dan penanda lokasi.
  static const Color jingga = Color(0xFFE2572B);

  /// Aksen jingga di latar hijau: titik logo pada ikon, splash, dan onboarding.
  static const Color jinggaTerang = Color(0xFFFFB547);
}

const String _huruf = 'PlusJakartaSans';

/// Tema terang JELMA. Aplikasi sengaja tidak memakai mode gelap karena dipakai di luar
/// ruangan pada siang hari, dan foto destinasi tampil paling akurat di latar terang.
ThemeData buatTema() {
  final skema = ColorScheme.fromSeed(seedColor: WarnaJelma.hijau).copyWith(
    primary: WarnaJelma.hijau,
    onPrimary: Colors.white,
    primaryContainer: WarnaJelma.hijauMuda,
    onPrimaryContainer: WarnaJelma.hijauTua,
    secondaryContainer: WarnaJelma.hijauMuda,
    onSecondaryContainer: WarnaJelma.hijauTua,
    surface: WarnaJelma.latar,
    onSurface: WarnaJelma.tinta,
    onSurfaceVariant: WarnaJelma.tintaLembut,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    outline: WarnaJelma.garisKontrol,
    outlineVariant: WarnaJelma.garis,
  );

  final dasar = ThemeData(useMaterial3: true, colorScheme: skema, fontFamily: _huruf);
  final t = dasar.textTheme;
  final teks = t
      .copyWith(
        displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.1),
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.15),
        headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.2),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: t.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: t.bodyMedium?.copyWith(height: 1.45),
        bodySmall: t.bodySmall?.copyWith(height: 1.4),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        labelSmall: t.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      )
      .apply(bodyColor: WarnaJelma.tinta, displayColor: WarnaJelma.tinta);

  final bentukTombol = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const ukuranTombol = Size(64, 48);
  final teksTombol = teks.labelLarge?.copyWith(fontSize: 15);

  return dasar.copyWith(
    textTheme: teks,
    scaffoldBackgroundColor: WarnaJelma.latar,
    appBarTheme: AppBarTheme(
      backgroundColor: WarnaJelma.latar,
      foregroundColor: WarnaJelma.tinta,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: teks.headlineSmall?.copyWith(fontSize: 24),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: WarnaJelma.garis),
      ),
    ),
    dividerTheme: const DividerThemeData(color: WarnaJelma.garis, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: ukuranTombol, shape: bentukTombol, textStyle: teksTombol),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: ukuranTombol,
        shape: bentukTombol,
        textStyle: teksTombol,
        foregroundColor: WarnaJelma.tinta,
        side: const BorderSide(color: WarnaJelma.garisKontrol),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), shape: bentukTombol, textStyle: teksTombol),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: WarnaJelma.hijau,
      foregroundColor: Colors.white,
      extendedTextStyle: teksTombol,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: WidgetStateBorderSide.resolveWith(
        (s) => BorderSide(color: s.contains(WidgetState.selected) ? WarnaJelma.hijau : WarnaJelma.garisKontrol),
      ),
      color: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? WarnaJelma.hijau : Colors.white),
      labelStyle: teks.labelLarge?.copyWith(
        color: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : WarnaJelma.tinta),
      ),
      checkmarkColor: Colors.white,
      iconTheme: const IconThemeData(color: WarnaJelma.tinta, size: 18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: teks.bodyLarge?.copyWith(color: WarnaJelma.tintaLembut),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WarnaJelma.garisKontrol),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WarnaJelma.hijau, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: WarnaJelma.hijauMuda,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => teks.labelMedium?.copyWith(
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? WarnaJelma.tinta : WarnaJelma.tintaLembut,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? WarnaJelma.hijauTua : WarnaJelma.tintaLembut),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: WarnaJelma.tinta,
      contentTextStyle: teks.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    listTileTheme: const ListTileThemeData(iconColor: WarnaJelma.tintaLembut),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
