import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts_jelajah_malang/data/destinasi_repository.dart';
import 'package:uts_jelajah_malang/main.dart';
import 'package:uts_jelajah_malang/models/destinasi.dart';

/// Repositori tiruan agar pengujian tidak bergantung pada berkas aset.
class _RepositoriUji implements DestinasiRepository {
  @override
  Future<KatalogDestinasi> muat() async => const KatalogDestinasi(
        kategori: [
          Kategori(id: 'alam', nama: 'Alam', ikon: 'terrain'),
          Kategori(id: 'kuliner', nama: 'Kuliner', ikon: 'restaurant'),
        ],
        destinasi: [
          Destinasi(
            id: 1,
            nama: 'Coban Uji',
            kategori: 'alam',
            lokasi: 'Kabupaten Malang',
            deskripsi: 'Air terjun contoh.',
            rating: 4.5,
            harga: 35000,
            jamBuka: '07.00 - 16.00',
            fasilitas: ['Parkir'],
            populer: true,
          ),
          Destinasi(
            id: 2,
            nama: 'Bakso Uji',
            kategori: 'kuliner',
            lokasi: 'Kota Malang',
            deskripsi: 'Bakso contoh.',
            rating: 4.7,
            harga: 15000,
            jamBuka: '09.00 - 21.00',
            fasilitas: ['Makan di tempat'],
          ),
        ],
      );
}

void main() {
  test('formatRibuan memberi pemisah titik', () {
    expect(formatRibuan(0), '0');
    expect(formatRibuan(950), '950');
    expect(formatRibuan(35000), '35.000');
    expect(formatRibuan(1250000), '1.250.000');
  });

  test('Destinasi.fromJson membaca setiap bidang', () {
    final d = Destinasi.fromJson({
      'id': 7,
      'nama': 'Contoh',
      'kategori': 'alam',
      'lokasi': 'Malang',
      'deskripsi': 'Deskripsi',
      'rating': 4,
      'harga': 0,
      'jam_buka': '08.00 - 17.00',
      'fasilitas': ['Parkir', 'Toilet'],
    });
    expect(d.rating, 4.0);
    expect(d.hargaLabel, 'Gratis');
    expect(d.fasilitas, ['Parkir', 'Toilet']);
    expect(d.populer, isFalse);
  });

  testWidgets('Beranda menampilkan kategori dan destinasi populer', (tester) async {
    await tester.pumpWidget(JelajahApp(repository: _RepositoriUji()));
    await tester.pumpAndSettle();

    expect(find.text('Jelajah Malang'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Alam'), findsOneWidget);
    expect(find.text('Coban Uji'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Memilih kategori membuka Jelajah dan menyaring daftar', (tester) async {
    await tester.pumpWidget(JelajahApp(repository: _RepositoriUji()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kuliner').first);
    await tester.pumpAndSettle();

    expect(find.text('1 destinasi ditemukan'), findsOneWidget);
    expect(find.text('Bakso Uji'), findsOneWidget);
    expect(find.text('Coban Uji'), findsNothing);
  });

  testWidgets('Pencarian menyaring daftar dan menampilkan keadaan kosong', (tester) async {
    await tester.pumpWidget(JelajahApp(repository: _RepositoriUji()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jelajah').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'coban');
    await tester.pumpAndSettle();
    expect(find.text('1 destinasi ditemukan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada destinasi yang cocok'), findsOneWidget);
  });

  testWidgets('Detail terbuka dan favorit muncul pada tab Favorit', (tester) async {
    await tester.pumpWidget(JelajahApp(repository: _RepositoriUji()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jelajah').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coban Uji'));
    await tester.pumpAndSettle();

    expect(find.text('Tentang'), findsOneWidget);
    expect(find.text('Rp 35.000'), findsOneWidget);
    expect(find.text('Tambah ke Favorit'), findsOneWidget);

    await tester.tap(find.text('Tambah ke Favorit'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus dari Favorit'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorit').last);
    await tester.pumpAndSettle();
    expect(find.text('Coban Uji'), findsOneWidget);
    expect(find.text('Belum ada favorit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tab Favorit kosong menampilkan petunjuk', (tester) async {
    await tester.pumpWidget(JelajahApp(repository: _RepositoriUji()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorit').last);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada favorit'), findsOneWidget);
  });
}
