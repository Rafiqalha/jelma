import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts_jelajah_malang/data/cuaca_service.dart';
import 'package:uts_jelajah_malang/data/destinasi_repository.dart';
import 'package:uts_jelajah_malang/main.dart';
import 'package:uts_jelajah_malang/models/cuaca.dart';
import 'package:uts_jelajah_malang/models/destinasi.dart';
import 'package:uts_jelajah_malang/models/koordinat.dart';
import 'package:uts_jelajah_malang/services/layanan_aplikasi.dart';
import 'package:uts_jelajah_malang/services/lokasi_service.dart';
import 'package:uts_jelajah_malang/services/notifikasi_service.dart';
import 'package:flutter/material.dart';

import 'font_nyata.dart';

/// Selasa, 24 November 2026 pukul 09.00 WIB; jam tetap agar pengujian tidak bergantung pada jam sistem.
final DateTime waktuUji = DateTime.utc(2026, 11, 24, 9);

/// Posisi pengguna tiruan: Alun-alun Merdeka, Kota Malang.
const Koordinat posisiUji = Koordinat(-7.98261, 112.63082);

const Destinasi cobanUji = Destinasi(
  id: 1,
  nama: 'Coban Uji',
  kategori: 'alam',
  lokasi: 'Kabupaten Malang',
  deskripsi: 'Air terjun contoh.',
  rating: 4.5,
  harga: 35000,
  jamBuka: '07.00 - 16.00',
  fasilitas: ['Parkir'],
  koordinat: Koordinat(-7.86962, 112.48397),
  ruang: Ruang.terbuka,
  populer: true,
);

const Destinasi baksoUji = Destinasi(
  id: 2,
  nama: 'Bakso Uji',
  kategori: 'kuliner',
  lokasi: 'Kota Malang',
  deskripsi: 'Bakso contoh.',
  rating: 4.7,
  harga: 15000,
  jamBuka: '09.00 - 21.00',
  fasilitas: ['Makan di tempat'],
  koordinat: Koordinat(-7.98261, 112.63082),
  ruang: Ruang.tertutup,
  koordinatPerkiraan: true,
);

const Destinasi museumUji = Destinasi(
  id: 3,
  nama: 'Museum Uji',
  kategori: 'edukasi',
  lokasi: 'Kota Malang',
  deskripsi: 'Museum contoh.',
  rating: 4.3,
  harga: 25000,
  jamBuka: '12.00 - 20.00',
  fasilitas: ['Ruang pamer'],
  koordinat: Koordinat(-7.98833, 112.62666),
  ruang: Ruang.tertutup,
);

const KatalogDestinasi katalogUji = KatalogDestinasi(
  versi: 2,
  kategori: [
    Kategori(id: 'alam', nama: 'Alam', ikon: 'terrain'),
    Kategori(id: 'kuliner', nama: 'Kuliner', ikon: 'restaurant'),
    Kategori(id: 'edukasi', nama: 'Edukasi', ikon: 'school'),
  ],
  destinasi: [cobanUji, baksoUji, museumUji],
);

/// Repositori tiruan agar pengujian tidak bergantung pada berkas aset.
class RepositoriUji implements DestinasiRepository {
  @override
  Future<KatalogDestinasi> muat() async => katalogUji;
}

/// Prakiraan seragam selama tujuh hari mulai [mulai]; kode 61 adalah hujan.
PrakiraanCuaca buatPrakiraan(
  Koordinat titik, {
  int kode = 61,
  int peluang = 80,
  double suhu = 26,
  double suhuTerasa = 28,
  DateTime? mulai,
}) {
  final awal = mulai ?? DateTime.utc(2026, 11, 24);
  return PrakiraanCuaca(
    titik: titik,
    saatIni: CuacaSaatIni(
      waktu: awal.add(const Duration(hours: 9)),
      suhu: suhu,
      suhuTerasa: suhuTerasa,
      kelembapan: 80,
      curah: 0.4,
      kode: kode,
      angin: 7,
      siang: true,
    ),
    harian: [
      for (var i = 0; i < 7; i++)
        CuacaHarian(
          tanggal: awal.add(Duration(days: i)),
          kode: kode,
          suhuMaks: suhu + 2,
          suhuMin: suhu - 4,
          suhuTerasaMaks: suhuTerasa + 2,
          peluangHujan: peluang,
          curahTotal: 5,
          uvMaks: 8,
        ),
    ],
  );
}

/// Layanan lokasi tiruan: izin dan posisi dapat diatur oleh pengujian.
class LokasiPalsu implements LokasiService {
  LokasiPalsu({
    this.izin = IzinLokasi.diberikan,
    this.izinSetelahMinta = IzinLokasi.diberikan,
    this.posisi = posisiUji,
    this.nama = 'Klojen, Malang',
    this.posisiGagal = false,
  });

  IzinLokasi izin;
  IzinLokasi izinSetelahMinta;
  Koordinat posisi;
  String? nama;
  bool posisiGagal;
  int jumlahMintaIzin = 0;
  int jumlahBukaPengaturanAplikasi = 0;

  @override
  Future<IzinLokasi> cekIzin() async => izin;

  @override
  Future<IzinLokasi> mintaIzin() async {
    jumlahMintaIzin++;
    izin = izinSetelahMinta;
    return izin;
  }

  @override
  Future<Koordinat> posisiSekarang() async {
    if (posisiGagal) throw const LokasiGagal('Posisi belum berhasil ditentukan.');
    return posisi;
  }

  @override
  Future<String?> namaTempat(Koordinat titik) async => nama;

  @override
  Future<void> bukaPengaturanLokasi() async {}

  @override
  Future<void> bukaPengaturanAplikasi() async => jumlahBukaPengaturanAplikasi++;
}

/// Layanan cuaca tiruan; [gagal] menirukan jaringan yang mati.
class CuacaPalsu implements CuacaService {
  CuacaPalsu({this.kode = 61, this.peluang = 80, this.suhu = 26, this.suhuTerasa = 28, this.gagal = false});

  int kode;
  int peluang;
  double suhu;
  double suhuTerasa;
  bool gagal;
  int jumlahPanggilan = 0;
  List<Koordinat> titikTerakhir = const [];

  @override
  Future<List<PrakiraanCuaca>> ambil(List<Koordinat> titik) async {
    jumlahPanggilan++;
    titikTerakhir = titik;
    if (gagal) throw const CuacaGagal('Tidak dapat terhubung ke server cuaca. Periksa koneksi internet.');
    return [
      for (final t in titik)
        buatPrakiraan(t, kode: kode, peluang: peluang, suhu: suhu, suhuTerasa: suhuTerasa),
    ];
  }
}

/// Layanan notifikasi tiruan yang mencatat semua panggilan.
class NotifikasiPalsu implements NotifikasiService {
  NotifikasiPalsu({this.izin = true});

  bool izin;
  final List<({int id, String judul, String isi, SaluranNotifikasi saluran})> ditampilkan = [];
  final List<({int id, DateTime waktu, String judul, String isi})> terjadwal = [];
  final List<int> dibatalkan = [];
  int jumlahMintaIzin = 0;

  @override
  Future<void> inisialisasi() async {}

  @override
  Future<bool> izinDiberikan() async => izin;

  @override
  Future<bool> mintaIzin() async {
    jumlahMintaIzin++;
    return izin;
  }

  @override
  Future<void> tampilkan({
    required int id,
    required String judul,
    required String isi,
    required SaluranNotifikasi saluran,
  }) async {
    ditampilkan.add((id: id, judul: judul, isi: isi, saluran: saluran));
  }

  @override
  Future<bool> jadwalkan({
    required int id,
    required DateTime waktu,
    required String judul,
    required String isi,
    required SaluranNotifikasi saluran,
  }) async {
    terjadwal.add((id: id, waktu: waktu, judul: judul, isi: isi));
    return true;
  }

  @override
  Future<void> batalkan(int id) async => dibatalkan.add(id);
}

/// Membuat [LayananAplikasi] tiruan dengan penyimpanan kosong atau berisi [awal].
Future<LayananAplikasi> buatLayanan({
  LokasiPalsu? lokasi,
  CuacaPalsu? cuaca,
  NotifikasiPalsu? notifikasi,
  Map<String, Object> awal = const {},
  List<Uri>? tautanDibuka,
  bool tautanBerhasil = true,
}) async {
  SharedPreferences.setMockInitialValues(awal);
  return LayananAplikasi(
    penyimpanan: await SharedPreferences.getInstance(),
    lokasi: lokasi ?? LokasiPalsu(),
    cuaca: cuaca ?? CuacaPalsu(),
    notifikasi: notifikasi ?? NotifikasiPalsu(),
    waktu: () => waktuUji,
    bukaTautan: (tautan) async {
      tautanDibuka?.add(tautan);
      return tautanBerhasil;
    },
  );
}

/// Membuka aplikasi pada layar seukuran ponsel (360 x 800 dp) dan menunggu hingga semua pemuatan selesai.
Future<void> bukaAplikasi(WidgetTester tester, LayananAplikasi layanan) async {
  // Membaca berkas huruf adalah I/O nyata, yang tidak selesai di dalam zona waktu palsu milik testWidgets.
  await tester.runAsync(muatFontNyata);
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(JelajahApp(repository: RepositoriUji(), layanan: layanan));
  await tester.pumpAndSettle();
}
