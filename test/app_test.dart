import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts_jelajah_malang/data/destinasi_repository.dart';
import 'package:uts_jelajah_malang/main.dart';
import 'package:uts_jelajah_malang/models/rencana.dart';
import 'package:uts_jelajah_malang/services/lokasi_service.dart';

import 'alat_uji.dart';

/// Menggulir halaman aktif hingga [finder] terlihat.
Future<void> gulirKe(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

/// Mengetuk tab pada bilah navigasi bawah berdasarkan labelnya.
Future<void> bukaTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Menggulirkan halaman aktif ke posisi paling atas.
Future<void> gulirKeAtas(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
  await tester.pumpAndSettle();
}

/// Membuat [finder] terlihat dan menunggu gulir selesai; `ensureVisible` saja tidak memajukan frame.
Future<void> lihat(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Mengetuk tombol kembali pada AppBar. Tooltipnya "Kembali" karena aplikasi berbahasa Indonesia,
/// sedangkan `pageBack()` mencari tooltip "Back".
Future<void> kembali(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Kembali'));
  await tester.pumpAndSettle();
}

/// Membuka halaman Detail [nama] dari tab Jelajah; kartu berfoto tinggi, jadi daftar digulir dulu.
Future<void> bukaDetailDari(WidgetTester tester, String nama) async {
  await bukaTab(tester, 'Jelajah');
  await gulirKe(tester, find.text(nama));
  await tester.tap(find.text(nama));
  await tester.pumpAndSettle();
}

/// Repositori yang gagal pada pemanggilan pertama lalu berhasil.
class _RepositoriGagalDulu implements DestinasiRepository {
  int panggilan = 0;

  @override
  Future<KatalogDestinasi> muat() async {
    panggilan++;
    if (panggilan == 1) throw Exception('jaringan mati');
    return katalogUji;
  }
}

void main() {
  group('Beranda', () {
    testWidgets('menampilkan sambutan, cuaca di lokasi, dan kategori', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());

      expect(find.bySemanticsLabel('JELMA, Jelajah Malang'), findsOneWidget);
      expect(find.text('Selamat pagi'), findsOneWidget, reason: 'jam uji 09.00 WIB');
      expect(find.text('Mau ke mana hari ini?'), findsOneWidget);
      expect(find.text('26°'), findsOneWidget);
      expect(find.text('Hujan, peluang hujan hari ini 80%'), findsOneWidget);
      expect(find.text('Klojen, Malang'), findsWidgets);
      await gulirKe(tester, find.text('Kategori'));
      expect(find.text('Alam'), findsOneWidget);
      await gulirKe(tester, find.text('Populer'));
      expect(find.text('Coban Uji'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saat hujan hanya destinasi dalam ruangan yang disarankan', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());

      expect(find.text('Cocok untuk cuaca hari ini'), findsOneWidget);
      expect(find.text('Aman saat hujan'), findsWidgets);
      expect(find.text('Sebaiknya ditunda'), findsNothing);
    });

    testWidgets('saat cerah destinasi terbuka ikut disarankan', (tester) async {
      await bukaAplikasi(tester, await buatLayanan(cuaca: CuacaPalsu(kode: 1, peluang: 5, suhu: 25, suhuTerasa: 26)));

      expect(find.text('25°'), findsOneWidget);
      expect(find.text('Cerah berawan, peluang hujan hari ini 5%'), findsOneWidget);
      expect(find.text('Cocok dikunjungi'), findsWidgets, reason: 'destinasi dalam ruangan');
      // Kartu ketiga (Coban Uji, area terbuka) berada di luar layar sampai daftar digeser ke samping.
      await tester.drag(find.text('Bakso Uji').first, const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Cuaca mendukung'), findsWidgets);
    });

    testWidgets('bagian Dekat Anda memuat destinasi terdekat dengan jaraknya', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await gulirKe(tester, find.text('Dekat Anda'));

      expect(find.textContaining('Dalam radius 25 km dari Klojen, Malang'), findsOneWidget);
      expect(find.textContaining('0 m · Kota Malang'), findsWidgets);
    });

    testWidgets('radius kecil di luar jangkauan menampilkan penjelasan dan tombol Pengaturan', (tester) async {
      final layanan = await buatLayanan(awal: {'radius_km': 5.0});
      await bukaAplikasi(tester, layanan);
      // Destinasi terdekat dari posisi uji tetap dalam 5 km, jadi geser lokasi ke Kepanjen yang jauh dari semuanya.
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih area'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kepanjen (Stasiun Kepanjen)').last);
      await tester.pumpAndSettle();
      await kembali(tester);
      await gulirKe(tester, find.text('Dekat Anda'));

      expect(find.textContaining('Tidak ada destinasi dalam radius 5 km'), findsOneWidget);
      expect(find.text('Buka Pengaturan'), findsOneWidget);
    });

    testWidgets('izin lokasi belum diberikan: panel penjelasan lalu hilang setelah diizinkan', (tester) async {
      final lokasi = LokasiPalsu(izin: IzinLokasi.ditolak);
      await bukaAplikasi(tester, await buatLayanan(lokasi: lokasi));
      await gulirKe(tester, find.text('Lokasi belum diizinkan'));

      expect(find.text('Izinkan lokasi'), findsOneWidget);
      expect(find.text('Pilih area manual'), findsOneWidget);
      expect(lokasi.jumlahMintaIzin, 0);

      await tester.tap(find.text('Izinkan lokasi'));
      await tester.pumpAndSettle();
      expect(lokasi.jumlahMintaIzin, 1);
      expect(find.text('Lokasi belum diizinkan'), findsNothing);
      await gulirKeAtas(tester);
      await gulirKe(tester, find.textContaining('Dalam radius 25 km'));
      expect(find.textContaining('Dalam radius 25 km dari Klojen, Malang'), findsOneWidget);
    });

    testWidgets('kartu cuaca membuka tab Cuaca', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await tester.tap(find.text('26°'));
      await tester.pumpAndSettle();
      expect(find.text('Prakiraan 7 hari'), findsOneWidget);
    });
  });

  group('Jelajah', () {
    testWidgets('memilih kategori membuka Jelajah dan menyaring daftar', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());

      await gulirKe(tester, find.text('Kuliner'));
      await tester.tap(find.text('Kuliner').first);
      await tester.pumpAndSettle();

      expect(find.text('1 destinasi ditemukan'), findsOneWidget);
      expect(find.text('Bakso Uji'), findsOneWidget);
      expect(find.text('Coban Uji'), findsNothing);
    });

    testWidgets('kolom cari Beranda membuka Jelajah dengan kolom cari langsung aktif', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await tester.tap(find.bySemanticsLabel('Cari destinasi'));
      await tester.pumpAndSettle();

      expect(find.text('3 destinasi ditemukan'), findsOneWidget, reason: 'tab Jelajah dengan kategori Semua');
      final kolom = tester.widget<EditableText>(find.byType(EditableText));
      expect(kolom.focusNode.hasFocus, isTrue);
    });

    testWidgets('memilih urutan tidak memunculkan lagi keyboard kolom cari', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaTab(tester, 'Jelajah');
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);

      await tester.tap(find.byTooltip('Urutkan daftar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nama A-Z'));
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isFalse);
    });

    testWidgets('pencarian menyaring daftar dan menampilkan keadaan kosong', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaTab(tester, 'Jelajah');

      await tester.enterText(find.byType(TextField), 'coban');
      await tester.pumpAndSettle();
      expect(find.text('1 destinasi ditemukan'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada destinasi yang cocok'), findsOneWidget);
      expect(find.text('Ubah kata kunci atau pilih kategori lain.'), findsOneWidget);
    });

    testWidgets('urutan Terdekat memakai lokasi aktif', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await layarTinggi(tester);
      await bukaTab(tester, 'Jelajah');
      expect(find.text('Urutan katalog'), findsOneWidget);

      await tester.tap(find.byTooltip('Urutkan daftar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terdekat'));
      await tester.pumpAndSettle();

      final bakso = tester.getTopLeft(find.text('Bakso Uji')).dy;
      final museum = tester.getTopLeft(find.text('Museum Uji')).dy;
      final coban = tester.getTopLeft(find.text('Coban Uji')).dy;
      expect(bakso, lessThan(museum));
      expect(museum, lessThan(coban));
    });

    testWidgets('urutan Rating tertinggi dan Nama A-Z', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await layarTinggi(tester);
      await bukaTab(tester, 'Jelajah');

      await tester.tap(find.byTooltip('Urutkan daftar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rating tertinggi'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Bakso Uji')).dy, lessThan(tester.getTopLeft(find.text('Coban Uji')).dy));

      await tester.tap(find.byTooltip('Urutkan daftar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nama A-Z'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Bakso Uji')).dy, lessThan(tester.getTopLeft(find.text('Coban Uji')).dy));
      expect(tester.getTopLeft(find.text('Coban Uji')).dy, lessThan(tester.getTopLeft(find.text('Museum Uji')).dy));
    });

    testWidgets('Terdekat tidak dapat dipilih sebelum lokasi diketahui', (tester) async {
      await bukaAplikasi(tester, await buatLayanan(lokasi: LokasiPalsu(izin: IzinLokasi.ditolak)));
      await bukaTab(tester, 'Jelajah');

      await tester.tap(find.byTooltip('Urutkan daftar'));
      await tester.pumpAndSettle();
      expect(find.text('Terdekat (perlu lokasi)'), findsOneWidget);
    });

    testWidgets('penyaring Buka sekarang menyembunyikan destinasi yang tutup', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await layarTinggi(tester);
      await bukaTab(tester, 'Jelajah');
      expect(find.text('3 destinasi ditemukan'), findsOneWidget);
      expect(find.text('Museum Uji'), findsOneWidget, reason: 'buka pukul 12.00, sekarang 09.00');

      await tester.tap(find.text('Buka sekarang'));
      await tester.pumpAndSettle();
      expect(find.text('2 destinasi ditemukan'), findsOneWidget);
      expect(find.text('Museum Uji'), findsNothing);
    });

    testWidgets('kartu menampilkan status buka, jarak dari lokasi, dan harga', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await layarTinggi(tester);
      await bukaTab(tester, 'Jelajah');

      expect(find.text('Buka'), findsNWidgets(2));
      expect(find.text('Tutup'), findsOneWidget);
      expect(find.text('0 m · Kota Malang'), findsOneWidget);
      expect(find.text('Rp 35.000  tiket masuk'), findsOneWidget);
      expect(find.byTooltip('Tambah ke favorit'), findsNWidgets(3));
    });

    testWidgets('layar lebar menata kartu dalam dua kolom', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      tester.view.physicalSize = const Size(3000, 2000);
      await tester.pumpAndSettle();
      await bukaTab(tester, 'Jelajah');
      expect(tester.getTopLeft(find.text('Coban Uji')).dy, tester.getTopLeft(find.text('Bakso Uji')).dy);
      expect(tester.getTopLeft(find.text('Coban Uji')).dx, lessThan(tester.getTopLeft(find.text('Bakso Uji')).dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('kepala daftar ikut tergulung sehingga layar lanskap tetap memuat kartu', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      tester.view.physicalSize = const Size(2400, 1080);
      await tester.pumpAndSettle();
      await bukaTab(tester, 'Jelajah');
      await gulirKe(tester, find.text('Museum Uji'));
      expect(find.text('Museum Uji'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Detail', () {
    testWidgets('menampilkan informasi, status buka, cuaca, dan saran kunjungan', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaDetailDari(tester, 'Coban Uji');

      expect(find.text('Coban Uji'), findsWidgets, reason: 'judul halaman dan judul bilah atas yang tersembunyi');
      expect(find.text('Tentang'), findsOneWidget);
      expect(find.text('Rp 35.000'), findsOneWidget, reason: 'harga pada bilah aksi bawah');
      expect(find.text('Buka sampai 16.00'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Area terbuka'), findsOneWidget);
      expect(find.text('Cuaca di lokasi ini'), findsOneWidget);
      expect(find.text('26° Hujan'), findsOneWidget);
      expect(find.text('Sebaiknya ditunda'), findsOneWidget);
      expect(find.textContaining('Peluang hujan 80%'), findsOneWidget);
      expect(find.byTooltip('Tambah ke favorit'), findsOneWidget);
      expect(find.text('Rencanakan kunjungan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('destinasi dalam ruangan aman saat hujan dan titik perkiraan dijelaskan', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaDetailDari(tester, 'Bakso Uji');

      expect(find.text('Aman saat hujan'), findsOneWidget);
      expect(find.textContaining('Titik perkiraan di pusat kota'), findsOneWidget);
    });

    testWidgets('favorit berubah, tersimpan permanen, dan muncul pada tab Favorit', (tester) async {
      final layanan = await buatLayanan();
      await bukaAplikasi(tester, layanan);
      await bukaDetailDari(tester, 'Coban Uji');

      await tester.tap(find.byTooltip('Tambah ke favorit'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Hapus dari favorit'), findsOneWidget);
      expect(layanan.penyimpanan.getStringList('favorit_ids'), ['1']);

      await kembali(tester);
      await bukaTab(tester, 'Favorit');
      expect(find.text('Coban Uji'), findsOneWidget);
      expect(find.text('Belum ada favorit'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Buka rute mengirim koordinat destinasi ke pembuka tautan', (tester) async {
      final dibuka = <Uri>[];
      await bukaAplikasi(tester, await buatLayanan(tautanDibuka: dibuka));
      await bukaTab(tester, 'Jelajah');
      await tester.tap(find.text('Coban Uji'));
      await tester.pumpAndSettle();

      await lihat(tester, find.text('Buka rute di Google Maps'));
      await tester.tap(find.text('Buka rute di Google Maps'));
      await tester.pumpAndSettle();

      expect(dibuka, hasLength(1));
      expect(dibuka.single.host, 'www.google.com');
      expect(dibuka.single.queryParameters['destination'], '-7.86962,112.48397');
    });

    testWidgets('rute yang tidak dapat dibuka dijelaskan kepada pengguna', (tester) async {
      await bukaAplikasi(tester, await buatLayanan(tautanBerhasil: false));
      await bukaTab(tester, 'Jelajah');
      await tester.tap(find.text('Coban Uji'));
      await tester.pumpAndSettle();
      await lihat(tester, find.text('Buka rute di Google Maps'));
      await tester.tap(find.text('Buka rute di Google Maps'));
      await tester.pumpAndSettle();
      expect(find.text('Tidak dapat membuka aplikasi peta atau peramban.'), findsOneWidget);
    });
  });

  group('Cuaca', () {
    testWidgets('menampilkan kartu utama, prakiraan, perlengkapan, dan destinasi menurut kecocokan', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaTab(tester, 'Cuaca');

      expect(find.text('Prakiraan 7 hari'), findsOneWidget);
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Untuk cuaca hujan'), findsOneWidget);
      expect(find.textContaining('Bawa jas hujan dan alas kaki anti selip'), findsOneWidget);

      final daftar = find.text('Destinasi hari ini');
      await gulirKe(tester, daftar);
      await gulirKe(tester, find.textContaining('Open-Meteo.com'));
      expect(find.text('Sebaiknya ditunda'), findsOneWidget);
      final bakso = tester.getTopLeft(find.text('Bakso Uji')).dy;
      final coban = tester.getTopLeft(find.text('Coban Uji')).dy;
      expect(bakso, lessThan(coban), reason: 'yang cocok ditampilkan lebih dulu');
      expect(tester.takeException(), isNull);
    });

    testWidgets('penyaring Cocok dan Dalam ruangan mengubah daftar', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaTab(tester, 'Cuaca');
      await gulirKe(tester, find.text('Destinasi hari ini'));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Cocok'));
      await tester.pumpAndSettle();
      await gulirKe(tester, find.textContaining('Open-Meteo.com'));
      expect(find.text('Coban Uji'), findsNothing);
      expect(find.text('Bakso Uji'), findsOneWidget);
    });

    testWidgets('cuaca gagal dimuat menampilkan penyebab dan dapat dicoba lagi', (tester) async {
      final cuaca = CuacaPalsu(gagal: true);
      await bukaAplikasi(tester, await buatLayanan(cuaca: cuaca));
      expect(find.textContaining('Cuaca belum dapat dimuat. Ketuk'), findsOneWidget);

      await bukaTab(tester, 'Cuaca');
      expect(find.text('Cuaca belum dapat dimuat'), findsOneWidget);
      expect(find.textContaining('Periksa koneksi internet'), findsOneWidget);

      cuaca.gagal = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Cuaca belum dapat dimuat'), findsNothing);
      expect(find.text('Prakiraan 7 hari'), findsOneWidget);
    });

    testWidgets('pembaruan yang gagal mempertahankan data lama dengan keterangan', (tester) async {
      final cuaca = CuacaPalsu();
      await bukaAplikasi(tester, await buatLayanan(cuaca: cuaca));
      await bukaTab(tester, 'Cuaca');
      expect(find.textContaining('Diperbarui pukul 09.00 WIB'), findsOneWidget);

      cuaca.gagal = true;
      await tester.tap(find.byTooltip('Muat ulang cuaca'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Menampilkan data pukul 09.00 WIB'), findsOneWidget);
      expect(find.text('Prakiraan 7 hari'), findsOneWidget);
    });

    testWidgets('lokasi belum diizinkan: cuaca memakai Pusat Kota Malang dan panel izin tampil', (tester) async {
      final cuaca = CuacaPalsu();
      await bukaAplikasi(tester, await buatLayanan(lokasi: LokasiPalsu(izin: IzinLokasi.ditolak), cuaca: cuaca));
      await bukaTab(tester, 'Cuaca');

      expect(find.text('Lokasi belum diizinkan'), findsOneWidget);
      expect(find.text('Pusat Kota Malang (Alun-alun Merdeka)'), findsOneWidget);
      expect(find.text('Bawaan'), findsOneWidget);
      expect(cuaca.jumlahPanggilan, 1);
    });

    testWidgets('lokasi GPS yang berubah memuat cuaca untuk titik baru', (tester) async {
      final lokasi = LokasiPalsu();
      final cuaca = CuacaPalsu();
      await bukaAplikasi(tester, await buatLayanan(lokasi: lokasi, cuaca: cuaca));
      expect(cuaca.jumlahPanggilan, 1);

      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih area'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kota Batu (Alun-alun Batu)').last);
      await tester.pumpAndSettle();
      expect(cuaca.jumlahPanggilan, 2);
      expect(cuaca.titikTerakhir.first.lintang, closeTo(-7.87118, 1e-6));
    });
  });

  group('Rencana', () {
    testWidgets('keadaan kosong mengarahkan ke pembuatan rencana', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaTab(tester, 'Rencana');

      expect(find.text('Belum ada rencana kunjungan'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Buat rencana'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('membuat, melihat, dan menghapus rencana', (tester) async {
      final notif = NotifikasiPalsu();
      final layanan = await buatLayanan(notifikasi: notif);
      await bukaAplikasi(tester, layanan);
      await bukaTab(tester, 'Rencana');

      await tester.tap(find.widgetWithText(FilledButton, 'Buat rencana'));
      await tester.pumpAndSettle();
      expect(find.text('Rencana baru'), findsOneWidget);
      expect(find.text('Rabu, 25 November 2026'), findsOneWidget, reason: 'bawaan: besok');
      expect(find.text('09.00 WIB'), findsOneWidget);

      await tester.tap(find.text('Simpan rencana'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih minimal satu destinasi.'), findsOneWidget);

      await lihat(tester, find.text('Bakso Uji'));
      await tester.tap(find.text('Bakso Uji'));
      await tester.pumpAndSettle();
      expect(find.text('Destinasi (1 dipilih)'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Makan siang');
      await tester.tap(find.text('Simpan rencana'));
      await tester.pumpAndSettle();

      expect(find.text('Makan siang'), findsOneWidget);
      expect(find.text('Rencana disimpan. Pengingat: 1 jam sebelumnya.'), findsOneWidget);
      expect(find.textContaining('Rabu, 09.00 WIB'), findsOneWidget);
      expect(notif.terjadwal, hasLength(1));
      expect(layanan.penyimpanan.getString('rencana_daftar'), contains('Makan siang'));

      await tester.tap(find.text('Makan siang'));
      await tester.pumpAndSettle();
      expect(find.text('Rabu, 25 November 2026'), findsOneWidget);
      expect(find.text('Urutan kunjungan yang disarankan'), findsOneWidget);
      expect(find.text('Bakso Uji'), findsOneWidget);
      expect(find.text('1 jam sebelumnya'), findsOneWidget);

      await tester.tap(find.byTooltip('Hapus rencana'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus rencana ini?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus rencana ini?'), findsNothing);
      expect(find.text('Urutan kunjungan yang disarankan'), findsOneWidget);

      await tester.tap(find.byTooltip('Hapus rencana'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada rencana kunjungan'), findsOneWidget);
      expect(notif.dibatalkan, isNotEmpty);
    });

    testWidgets('rencana dari halaman Detail memilih destinasinya dan menampilkan cuaca di daftar', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaDetailDari(tester, 'Coban Uji');
      await tester.tap(find.text('Rencanakan kunjungan'));
      await tester.pumpAndSettle();
      expect(find.text('Destinasi (1 dipilih)'), findsOneWidget);

      await tester.tap(find.text('Simpan rencana'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tambah ke favorit'), findsOneWidget, reason: 'kembali ke halaman Detail');

      await kembali(tester);
      await bukaTab(tester, 'Rencana');
      expect(find.text('Kunjungan ke Coban Uji'), findsOneWidget);
      expect(find.text('Tunda · Hujan 80%'), findsOneWidget);
      expect(find.text('1 jam sebelumnya'), findsOneWidget);
    });

    testWidgets('rencana yang tersimpan dimuat saat aplikasi dibuka, dipisah menurut waktu', (tester) async {
      final tersimpan = jsonEncode([
        Rencana(id: 1, nama: 'Sudah lewat', waktu: DateTime.utc(2026, 11, 23, 9), idDestinasi: const [1]).toJson(),
        Rencana(id: 2, nama: 'Akhir pekan', waktu: DateTime.utc(2026, 11, 28, 8), idDestinasi: const [1, 2]).toJson(),
      ]);
      await bukaAplikasi(tester, await buatLayanan(awal: {'rencana_daftar': tersimpan, 'rencana_id_terakhir': 2}));
      await bukaTab(tester, 'Rencana');

      expect(find.text('Mendatang'), findsOneWidget);
      expect(find.text('Sudah lewat'), findsNWidgets(2), reason: 'judul bagian dan nama rencana');
      expect(find.text('Akhir pekan'), findsOneWidget);
      expect(find.textContaining('2 destinasi, rute sekitar'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('pesan rencana disimpan tampil di atas tombol Buat rencana, tidak menutupinya', (tester) async {
      final tersimpan = jsonEncode([
        Rencana(id: 1, nama: 'Rencana lama', waktu: DateTime.utc(2026, 11, 26, 10), idDestinasi: const [1]).toJson(),
      ]);
      await bukaAplikasi(tester, await buatLayanan(awal: {'rencana_daftar': tersimpan, 'rencana_id_terakhir': 1}));
      await bukaTab(tester, 'Rencana');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await lihat(tester, find.text('Bakso Uji'));
      await tester.tap(find.text('Bakso Uji'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan rencana'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final pesan = tester.getRect(find.byType(SnackBar));
      final tombol = tester.getRect(find.byType(FloatingActionButton));
      expect(pesan.bottom, lessThanOrEqualTo(tombol.top), reason: 'pesan $pesan, tombol $tombol');
    });

    testWidgets('rencana yang sudah ada dapat diubah', (tester) async {
      final tersimpan = jsonEncode([
        Rencana(id: 1, nama: 'Rencana lama', waktu: DateTime.utc(2026, 11, 26, 10), idDestinasi: const [1]).toJson(),
      ]);
      final layanan = await buatLayanan(awal: {'rencana_daftar': tersimpan, 'rencana_id_terakhir': 1});
      await bukaAplikasi(tester, layanan);
      await bukaTab(tester, 'Rencana');
      await tester.tap(find.text('Rencana lama'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ubah rencana'));
      await tester.pumpAndSettle();
      expect(find.text('Ubah rencana'), findsOneWidget);
      expect(find.text('Kamis, 26 November 2026'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Rencana baru');
      await tester.tap(find.text('Simpan rencana'));
      await tester.pumpAndSettle();

      expect(find.text('Rencana baru'), findsWidgets);
      expect(layanan.penyimpanan.getString('rencana_daftar'), allOf(contains('Rencana baru'), isNot(contains('Rencana lama'))));
    });

    testWidgets('form ubah menampilkan destinasi terpilih paling atas dan urutannya tetap saat dicentang', (tester) async {
      final tersimpan = jsonEncode([
        Rencana(id: 1, nama: 'Ke air terjun', waktu: DateTime.utc(2026, 11, 26, 10), idDestinasi: const [1]).toJson(),
      ]);
      await bukaAplikasi(tester, await buatLayanan(awal: {'rencana_daftar': tersimpan, 'rencana_id_terakhir': 1}));
      await bukaTab(tester, 'Rencana');
      await tester.tap(find.text('Ke air terjun'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ubah rencana'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Destinasi yang sudah dipilih tampil paling atas'), findsOneWidget);
      await lihat(tester, find.text('Bakso Uji'));
      final bakso = tester.getTopLeft(find.text('Bakso Uji')).dy;
      expect(tester.getTopLeft(find.text('Coban Uji')).dy, lessThan(bakso), reason: 'Bakso Uji lebih dekat tetapi belum dipilih');

      await tester.tap(find.text('Bakso Uji'));
      await tester.pumpAndSettle();
      expect(find.text('Destinasi (2 dipilih)'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Bakso Uji')).dy, bakso, reason: 'baris tidak berpindah setelah dicentang');
    });
  });

  group('Pengaturan', () {
    testWidgets('membuka halaman dari Beranda dan mengganti sumber lokasi', (tester) async {
      final layanan = await buatLayanan();
      await bukaAplikasi(tester, layanan);
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('GPS otomatis'), findsOneWidget);
      expect(find.text('Klojen, Malang'), findsOneWidget);
      expect(find.text('Sumber: GPS'), findsOneWidget);
      expect(find.text('Radius Dekat Anda: 25 km'), findsOneWidget);

      await tester.tap(find.text('Pilih area'));
      await tester.pumpAndSettle();
      expect(find.text('Area acuan'), findsWidgets);
      expect(layanan.penyimpanan.getString('mode_lokasi'), 'manual');

      await tester.tap(find.text('GPS otomatis'));
      await tester.pumpAndSettle();
      expect(layanan.penyimpanan.getString('mode_lokasi'), 'gps');
      expect(find.text('Sumber: GPS'), findsOneWidget);
    });

    testWidgets('saklar notifikasi tersimpan', (tester) async {
      final layanan = await buatLayanan();
      await bukaAplikasi(tester, layanan);
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();

      await lihat(tester, find.text('Pengingat rencana'));
      await tester.tap(find.text('Pengingat rencana'));
      await tester.pumpAndSettle();
      expect(layanan.penyimpanan.getBool('pengingat_aktif'), isFalse);

      await tester.tap(find.text('Peringatan cuaca'));
      await tester.pumpAndSettle();
      expect(layanan.penyimpanan.getBool('peringatan_cuaca_aktif'), isFalse);
    });

    testWidgets('notifikasi uji tampil bila izin ada', (tester) async {
      final notif = NotifikasiPalsu();
      await bukaAplikasi(tester, await buatLayanan(notifikasi: notif));
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();

      expect(find.text('Diberikan'), findsOneWidget);
      await lihat(tester, find.text('Kirim notifikasi uji'));
      await tester.tap(find.text('Kirim notifikasi uji'));
      await tester.pumpAndSettle();
      expect(notif.ditampilkan, hasLength(1));
      expect(find.textContaining('Notifikasi uji dikirim'), findsOneWidget);
    });

    testWidgets('tanpa izin notifikasi: status dijelaskan dan tombol Izinkan tersedia', (tester) async {
      final notif = NotifikasiPalsu(izin: false);
      await bukaAplikasi(tester, await buatLayanan(notifikasi: notif));
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();

      expect(find.text('Belum diberikan'), findsOneWidget);
      await lihat(tester, find.text('Kirim notifikasi uji'));
      await tester.tap(find.text('Kirim notifikasi uji'));
      await tester.pumpAndSettle();
      expect(notif.ditampilkan, isEmpty);
      expect(notif.jumlahMintaIzin, 1);
      expect(find.textContaining('Izin notifikasi belum diberikan'), findsOneWidget);
      expect(find.text('Izinkan'), findsOneWidget);
    });

    testWidgets('sumber data dan atribusi ditampilkan, katalog dapat dimuat ulang', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();

      await gulirKe(tester, find.text('Muat ulang'));
      expect(find.textContaining('Open-Meteo.com'), findsOneWidget);
      expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
      expect(find.textContaining('Foto destinasi: Wikimedia Commons'), findsOneWidget);
      expect(find.text('Bawaan aplikasi, versi data 3'), findsOneWidget);

      await tester.tap(find.text('Muat ulang'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Katalog dimuat. Sumber: Bawaan aplikasi.'), findsOneWidget);
    });

    testWidgets('izin lokasi ditolak permanen: tombol membuka pengaturan aplikasi', (tester) async {
      final lokasi = LokasiPalsu(izin: IzinLokasi.ditolakPermanen);
      await bukaAplikasi(tester, await buatLayanan(lokasi: lokasi));
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();

      expect(find.text('Izin lokasi ditolak'), findsWidgets);
      await tester.tap(find.text('Buka pengaturan aplikasi'));
      await tester.pumpAndSettle();
      expect(lokasi.jumlahBukaPengaturanAplikasi, 1);
      expect(find.text('Pilih area manual'), findsNothing, reason: 'sudah berada di Pengaturan');
    });
  });

  group('Favorit dan pemuatan', () {
    testWidgets('tab Favorit kosong menampilkan petunjuk', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaTab(tester, 'Favorit');
      expect(find.text('Belum ada favorit'), findsOneWidget);
      expect(find.text('Ketuk ikon hati pada destinasi untuk menyimpannya di sini.'), findsOneWidget);
    });

    testWidgets('favorit tersimpan dimuat saat aplikasi dibuka', (tester) async {
      await bukaAplikasi(tester, await buatLayanan(awal: {'favorit_ids': ['2']}));
      await bukaTab(tester, 'Favorit');
      expect(find.text('Bakso Uji'), findsOneWidget);
      expect(find.text('Belum ada favorit'), findsNothing);
    });

    testWidgets('katalog gagal dimuat menampilkan penyebab dan dapat dicoba lagi', (tester) async {
      final layanan = await buatLayanan();
      final repo = _RepositoriGagalDulu();
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(JelajahApp(repository: repo, layanan: layanan));
      await tester.pumpAndSettle();

      expect(find.text('Data destinasi gagal dimuat'), findsOneWidget);
      expect(find.text('Periksa koneksi internet lalu coba lagi.'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Mau ke mana hari ini?'), findsOneWidget);
      expect(repo.panggilan, 2);
    });
  });

  group('Pengenalan', () {
    testWidgets('pembukaan pertama menampilkan pengenalan; Lewati membuka Beranda dan tersimpan', (tester) async {
      final layanan = await buatLayanan(onboardingSelesai: false);
      await bukaAplikasi(tester, layanan);

      expect(find.text('Kenali tempatnya sebelum berangkat'), findsOneWidget);
      expect(find.textContaining('3 destinasi alam, budaya, kuliner'), findsOneWidget, reason: 'jumlah dari katalog');
      expect(find.bySemanticsLabel('Halaman 1 dari 3'), findsOneWidget);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(find.text('Mau ke mana hari ini?'), findsOneWidget);
      expect(layanan.penyimpanan.getBool('onboarding_selesai'), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lanjut sampai halaman terakhir lalu Izinkan lokasi meminta izin sekali', (tester) async {
      final lokasi = LokasiPalsu(izin: IzinLokasi.ditolak, izinSetelahMinta: IzinLokasi.diberikan);
      await bukaAplikasi(tester, await buatLayanan(lokasi: lokasi, onboardingSelesai: false));

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Cuaca dicek di titik destinasinya'), findsOneWidget);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Mulai dari lokasi Anda'), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);
      expect(lokasi.jumlahMintaIzin, 0, reason: 'izin baru diminta setelah alasannya dibaca');

      await tester.tap(find.text('Izinkan lokasi'));
      await tester.pumpAndSettle();
      expect(lokasi.jumlahMintaIzin, 1);
      expect(find.text('Mau ke mana hari ini?'), findsOneWidget);
      await gulirKe(tester, find.textContaining('Dalam radius 25 km'));
      expect(find.textContaining('Dalam radius 25 km dari Klojen, Malang'), findsOneWidget);
    });

    testWidgets('Nanti saja tidak meminta izin dan Beranda menjelaskan langkah berikutnya', (tester) async {
      final lokasi = LokasiPalsu(izin: IzinLokasi.ditolak);
      await bukaAplikasi(tester, await buatLayanan(lokasi: lokasi, onboardingSelesai: false));
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nanti saja'));
      await tester.pumpAndSettle();
      expect(lokasi.jumlahMintaIzin, 0);
      await gulirKe(tester, find.text('Lokasi belum diizinkan'));
      expect(find.text('Izinkan lokasi'), findsOneWidget);
    });

    testWidgets('tombol kembali sistem kembali ke halaman pengenalan sebelumnya', (tester) async {
      await bukaAplikasi(tester, await buatLayanan(onboardingSelesai: false));
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Cuaca dicek di titik destinasinya'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Kenali tempatnya sebelum berangkat'), findsOneWidget);
    });

    testWidgets('pengenalan dapat dibuka lagi dari Pengaturan', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat pengenalan lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Kenali tempatnya sebelum berangkat'), findsOneWidget);

      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan'), findsOneWidget);
    });
  });

  group('Foto dan kredit', () {
    testWidgets('Detail menampilkan kredit foto dan membuka halaman sumbernya', (tester) async {
      final dibuka = <Uri>[];
      await bukaAplikasi(tester, await buatLayanan(tautanDibuka: dibuka));
      await bukaDetailDari(tester, 'Coban Uji');

      expect(find.bySemanticsLabel('Foto Coban Uji'), findsOneWidget);
      expect(find.text('Foto: Penulis Uji, CC BY-SA 4.0, Wikimedia Commons'), findsOneWidget);
      await tester.tap(find.text('Foto: Penulis Uji, CC BY-SA 4.0, Wikimedia Commons'));
      await tester.pumpAndSettle();
      expect(dibuka.single.toString(), 'https://commons.wikimedia.org/wiki/File:Coban_rondo_waterfall.jpg');
    });

    testWidgets('destinasi tanpa foto memakai gambar pengganti yang berlabel', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await bukaDetailDari(tester, 'Museum Uji');

      expect(find.text('Foto belum tersedia'), findsOneWidget);
      expect(find.text('Foto belum tersedia untuk destinasi ini.'), findsOneWidget);
    });

    testWidgets('halaman Kredit foto mencantumkan pembuat, lisensi, dan destinasi tanpa foto', (tester) async {
      final dibuka = <Uri>[];
      await bukaAplikasi(tester, await buatLayanan(tautanDibuka: dibuka));
      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kredit foto'));
      await tester.pumpAndSettle();

      expect(find.text('Coban rondo waterfall.jpg'), findsOneWidget);
      expect(find.text('Penulis Uji, CC BY-SA 4.0'), findsOneWidget);
      expect(find.text('Belum ada foto'), findsOneWidget);
      expect(find.textContaining('Bakso Uji, Museum Uji.'), findsOneWidget);
      expect(find.textContaining('Plus Jakarta Sans oleh Tokotype'), findsOneWidget);

      await tester.tap(find.text('Baca lisensi CC BY-SA 4.0'));
      await tester.pumpAndSettle();
      expect(dibuka.single.toString(), 'https://creativecommons.org/licenses/by-sa/4.0');
    });

    testWidgets('mengetuk kartu menerbangkan foto ke Detail tanpa tabrakan tag Hero', (tester) async {
      await bukaAplikasi(tester, await buatLayanan());
      await layarTinggi(tester);
      await bukaTab(tester, 'Jelajah');
      await tester.tap(find.text('Coban Uji'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(Hero), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('Cuaca di lokasi ini'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Ukuran teks besar', () {
    testWidgets('semua tab dan halaman tetap tertata pada teks 1,5 kali', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await bukaAplikasi(tester, await buatLayanan());
      expect(tester.takeException(), isNull);

      for (final tab in ['Jelajah', 'Cuaca', 'Rencana', 'Favorit']) {
        await bukaTab(tester, tab);
        expect(tester.takeException(), isNull, reason: 'tab $tab');
      }

      await tester.tap(find.byTooltip('Pengaturan').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Pengaturan');
      await kembali(tester);

      await bukaTab(tester, 'Jelajah');
      await tester.tap(find.text('Coban Uji'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Detail');
    });
  });
}
