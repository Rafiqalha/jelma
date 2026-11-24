import 'package:flutter/material.dart';

import '../tema.dart';

/// Tanda logo JELMA: huruf "j" yang ujung atasnya miring seperti puncak gunung, dengan titik
/// jingga sebagai matahari sekaligus titik lokasi.
///
/// Koordinat sama persis dengan ikon aplikasi Android, yang dibangun oleh `tool/ikon/buat_ikon.py`
/// pada kanvas ikon adaptif 108 dp. Widget ini menampilkan area tampak 72 dp di tengahnya.
class TandaJelma extends StatelessWidget {
  const TandaJelma({
    super.key,
    this.ukuran = 40,
    this.latar = WarnaJelma.hijau,
    this.warnaHuruf = Colors.white,
    this.warnaTitik = WarnaJelma.jinggaTerang,
  });

  final double ukuran;

  /// Warna lencana di belakang huruf; null untuk tanda tanpa lencana.
  final Color? latar;
  final Color warnaHuruf;
  final Color warnaTitik;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: ukuran,
        child: CustomPaint(
          painter: _PelukisTanda(latar: latar, warnaHuruf: warnaHuruf, warnaTitik: warnaTitik),
        ),
      ),
    );
  }
}

class _PelukisTanda extends CustomPainter {
  const _PelukisTanda({required this.latar, required this.warnaHuruf, required this.warnaTitik});

  final Color? latar;
  final Color warnaHuruf;
  final Color warnaTitik;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 72);
    canvas.translate(-18, -18);
    if (latar != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(18, 18, 72, 72), const Radius.circular(20)),
        Paint()..color = latar!,
      );
    }
    final huruf = Paint()
      ..color = warnaHuruf
      ..isAntiAlias = true;
    final batang = Path()
      ..moveTo(56.51, 66.41)
      ..lineTo(56.51, 49.63)
      ..lineTo(64.91, 44.03)
      ..lineTo(64.91, 66.41)
      ..close();
    canvas.drawPath(batang, huruf);
    final kait = Path()
      ..moveTo(60.71, 66.41)
      ..arcToPoint(const Offset(45.44, 71.23), radius: const Radius.circular(8.39));
    canvas.drawPath(
      kait,
      Paint()
        ..color = warnaHuruf
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.39
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(63.51, 34.24), 5.24, Paint()..color = warnaTitik);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PelukisTanda lama) =>
      lama.latar != latar || lama.warnaHuruf != warnaHuruf || lama.warnaTitik != warnaTitik;
}

/// Logo lengkap: lencana tanda JELMA dan tulisan "jelma".
class MerekJelma extends StatelessWidget {
  const MerekJelma({super.key, this.ukuran = 32, this.warnaTulisan = WarnaJelma.tinta});

  /// Tinggi lencana; ukuran tulisan menyesuaikan.
  final double ukuran;
  final Color warnaTulisan;

  @override
  Widget build(BuildContext context) {
    // Dibacakan sebagai satu gambar bernama, bukan huruf "jelma" yang dieja.
    return Semantics(
      container: true,
      image: true,
      label: 'JELMA, Jelajah Malang',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TandaJelma(ukuran: ukuran),
          SizedBox(width: ukuran * 0.3),
          Text(
            'jelma',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: ukuran * 0.78,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
              color: warnaTulisan,
            ),
          ),
        ],
      ),
    );
  }
}
