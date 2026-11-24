import 'package:flutter_test/flutter_test.dart';
import 'package:uts_jelajah_malang/models/area_referensi.dart';
import 'package:uts_jelajah_malang/models/cuaca.dart';
import 'package:uts_jelajah_malang/models/destinasi.dart';
import 'package:uts_jelajah_malang/models/format.dart';
import 'package:uts_jelajah_malang/models/jam_buka.dart';
import 'package:uts_jelajah_malang/models/koordinat.dart';
import 'package:uts_jelajah_malang/models/rencana.dart';
import 'package:uts_jelajah_malang/models/saran_cuaca.dart';

import 'alat_uji.dart';

void main() {
  group('Pemformat', () {
    test('formatRibuan memberi pemisah titik', () {
      expect(formatRibuan(0), '0');
      expect(formatRibuan(950), '950');
      expect(formatRibuan(35000), '35.000');
      expect(formatRibuan(1250000), '1.250.000');
    });

    test('formatJarak memilih satuan dan pembulatan yang sesuai', () {
      expect(formatJarak(0.0), '0 m');
      expect(formatJarak(0.854), '850 m');
      expect(formatJarak(3.44), '3,4 km');
      expect(formatJarak(9.96), '10 km');
      expect(formatJarak(21.4), '21 km');
      expect(formatJarak(14052.4), '14.052 km');
    });

    test('tanggal dan jam memakai bahasa Indonesia', () {
      final selasa = DateTime.utc(2026, 11, 24, 9, 5);
      expect(formatTanggal(selasa), 'Selasa, 24 November 2026');
      expect(formatTanggalSingkat(selasa), '24 Nov');
      expect(namaHariSingkat(selasa), 'Sel');
      expect(formatJamWaktu(selasa), '09.05');
      expect(formatJam(570), '09.30');
      expect(formatSuhu(26.4), '26°');
    });
  });

  group('Koordinat', () {
    test('jarak garis lurus Alun-alun Merdeka ke Alun-alun Batu sekitar 17 km', () {
      final km = areaDariId('alun_alun_malang')!.koordinat.jarakKm(areaDariId('alun_alun_batu')!.koordinat);
      expect(km, inInclusiveRange(16.5, 17.5));
    });

    test('jarak ke titik yang sama nol dan simetris', () {
      const a = Koordinat(-7.9, 112.6);
      const b = Koordinat(-8.4, 112.5);
      expect(a.jarakKm(a), 0);
      expect(a.jarakKm(b), closeTo(b.jarakKm(a), 1e-9));
    });

    test('areaTerdekat memilih area acuan terdekat', () {
      expect(areaTerdekat(const Koordinat(-7.8712, 112.5269)).id, 'alun_alun_batu');
      expect(areaTerdekat(const Koordinat(-8.13, 112.57)).id, 'kepanjen');
    });
  });

  group('JamBuka', () {
    test('membaca teks jam dan menolak bentuk yang salah', () {
      final jam = JamBuka.baca('07.00 - 16.30')!;
      expect(jam.buka, 420);
      expect(jam.tutup, 990);
      expect(JamBuka.baca('buka setiap hari'), isNull);
      expect(JamBuka.baca('25.00 - 26.00'), isNull);
    });

    test('status buka pada beberapa waktu', () {
      final jam = JamBuka.baca('07.00 - 16.00')!;
      expect(jam.status(DateTime.utc(2026, 1, 1, 6, 59)).label, 'Tutup, buka 07.00');
      expect(jam.status(DateTime.utc(2026, 1, 1, 7)).terbuka, isTrue);
      expect(jam.status(DateTime.utc(2026, 1, 1, 15, 59)).label, 'Buka sampai 16.00');
      expect(jam.status(DateTime.utc(2026, 1, 1, 16)).label, 'Tutup, buka besok 07.00');
    });

    test('rentang melewati tengah malam dan 24 jam', () {
      final malam = JamBuka.baca('18.00 - 02.00')!;
      expect(malam.terbukaPada(23 * 60), isTrue);
      expect(malam.terbukaPada(60), isTrue);
      expect(malam.terbukaPada(12 * 60), isFalse);
      expect(malam.status(DateTime.utc(2026, 1, 1, 12)).label, 'Tutup, buka 18.00');
      expect(JamBuka.baca('00.00 - 00.00')!.status(DateTime.utc(2026, 1, 1, 3)).label, 'Buka 24 jam');
    });
  });

  group('Destinasi', () {
    test('fromJson membaca koordinat, ruang, dan nilai bawaan', () {
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
        'lat': -7.9,
        'lng': 112.6,
      });
      expect(d.rating, 4.0);
      expect(d.hargaLabel, 'Gratis');
      expect(d.fasilitas, ['Parkir', 'Toilet']);
      expect(d.populer, isFalse);
      expect(d.koordinat, const Koordinat(-7.9, 112.6));
      expect(d.ruang, Ruang.terbuka);
      expect(d.koordinatPerkiraan, isFalse);
    });

    test('toJson lalu fromJson mengembalikan objek yang sama', () {
      final d = Destinasi.fromJson(baksoUji.toJson());
      expect(d.nama, baksoUji.nama);
      expect(d.ruang, Ruang.tertutup);
      expect(d.koordinatPerkiraan, isTrue);
      expect(d.koordinat, baksoUji.koordinat);
    });

    test('jarakDari null bila lokasi belum diketahui', () {
      expect(cobanUji.jarakDari(null), isNull);
      expect(cobanUji.jarakDari(posisiUji), greaterThan(10));
    });

    test('foto dibaca beserta kreditnya; destinasi tanpa foto bernilai null', () {
      final d = Destinasi.fromJson(cobanUji.toJson());
      expect(d.foto?.berkas, 'assets/images/destinasi/01-coban-rondo.jpg');
      expect(d.foto?.kredit, 'Foto: Penulis Uji, CC BY-SA 4.0');
      expect(d.foto?.sumber, startsWith('https://commons.wikimedia.org/wiki/File:'));
      expect(d.foto?.dariJaringan, isFalse);
      expect(Destinasi.fromJson(baksoUji.toJson()).foto, isNull);
    });

    test('foto beralamat https dianggap dari jaringan dan kolom kosong diberi nilai bawaan', () {
      final foto = FotoDestinasi.fromJson({'berkas': 'https://contoh.test/foto.jpg'});
      expect(foto.dariJaringan, isTrue);
      expect(foto.penulis, 'Tanpa nama');
      expect(foto.lisensi, isEmpty);
    });
  });

  group('KondisiCuaca', () {
    test('kode WMO dipetakan ke kondisi hujan, mendung, dan lainnya', () {
      expect(kondisiDariKode(0), KondisiCuaca.cerah);
      expect(kondisiDariKode(2), KondisiCuaca.berawan);
      expect(kondisiDariKode(3), KondisiCuaca.mendung);
      expect(kondisiDariKode(45), KondisiCuaca.kabut);
      expect(kondisiDariKode(53), KondisiCuaca.gerimis);
      expect(kondisiDariKode(61), KondisiCuaca.hujan);
      expect(kondisiDariKode(82), KondisiCuaca.hujanLebat);
      expect(kondisiDariKode(95), KondisiCuaca.badaiPetir);
      expect(kondisiDariKode(999), KondisiCuaca.berawan);
    });

    test('langit cerah dengan suhu terasa tinggi disebut panas, hujan tidak', () {
      expect(kondisiDariKode(0, suhuTerasa: 33), KondisiCuaca.panas);
      expect(kondisiDariKode(0, suhuTerasa: 31.9), KondisiCuaca.cerah);
      expect(kondisiDariKode(3, suhuTerasa: 36), KondisiCuaca.mendung);
      expect(kondisiDariKode(61, suhuTerasa: 36), KondisiCuaca.hujan);
    });

    test('hanya kondisi basah yang bertanda basah', () {
      expect(KondisiCuaca.gerimis.basah, isTrue);
      expect(KondisiCuaca.badaiPetir.basah, isTrue);
      expect(KondisiCuaca.mendung.basah, isFalse);
      expect(KondisiCuaca.panas.basah, isFalse);
    });
  });

  group('saranKunjungan', () {
    CuacaHarian hari({int kode = 0, int peluang = 0, double terasa = 28}) => CuacaHarian(
          tanggal: DateTime.utc(2026, 11, 24),
          kode: kode,
          suhuMaks: terasa - 2,
          suhuMin: 20,
          suhuTerasaMaks: terasa,
          peluangHujan: peluang,
          curahTotal: 0,
          uvMaks: 8,
        );

    test('dalam ruangan aman saat hujan', () {
      final saran = saranKunjungan(baksoUji, hari(kode: 65, peluang: 100));
      expect(saran.tingkat, TingkatSaran.baik);
      expect(saran.judul, 'Aman saat hujan');
    });

    test('area terbuka ditunda saat badai atau peluang hujan tinggi', () {
      expect(saranKunjungan(cobanUji, hari(kode: 95, peluang: 20)).tingkat, TingkatSaran.hindari);
      final tinggi = saranKunjungan(cobanUji, hari(kode: 3, peluang: 70));
      expect(tinggi.tingkat, TingkatSaran.hindari);
      expect(tinggi.penjelasan, contains('70%'));
    });

    test('area terbuka diminta membawa jas hujan pada peluang sedang', () {
      final saran = saranKunjungan(cobanUji, hari(kode: 3, peluang: 45));
      expect(saran.tingkat, TingkatSaran.waspada);
      expect(saran.judul, 'Bawa jas hujan');
    });

    test('area terbuka cerah tetapi panas diminta datang pagi atau sore', () {
      final saran = saranKunjungan(cobanUji, hari(kode: 0, terasa: 34));
      expect(saran.tingkat, TingkatSaran.waspada);
      expect(saran.judul, 'Datang pagi atau sore');
      expect(saran.penjelasan, contains('34'));
    });

    test('area terbuka cerah dan tidak panas cocok dikunjungi', () {
      final saran = saranKunjungan(cobanUji, hari(kode: 1, peluang: 10));
      expect(saran.tingkat, TingkatSaran.baik);
      expect(saran.judul, 'Cuaca mendukung');
    });

    test('destinasi campuran waspada saat hujan, baik saat cerah', () {
      const campuran = Destinasi(
        id: 9,
        nama: 'Campuran',
        kategori: 'edukasi',
        lokasi: 'Batu',
        deskripsi: '-',
        rating: 4,
        harga: 0,
        jamBuka: '09.00 - 17.00',
        fasilitas: [],
        koordinat: Koordinat(-7.88, 112.52),
        ruang: Ruang.campuran,
      );
      expect(saranKunjungan(campuran, hari(kode: 61, peluang: 90)).tingkat, TingkatSaran.waspada);
      expect(saranKunjungan(campuran, hari(kode: 0, peluang: 5)).tingkat, TingkatSaran.baik);
    });

    test('perlengkapan tersedia untuk setiap kondisi', () {
      for (final kondisi in KondisiCuaca.values) {
        expect(perlengkapanUntuk(kondisi), isNotEmpty, reason: kondisi.name);
      }
    });
  });

  group('Rencana', () {
    final waktu = DateTime.utc(2026, 11, 25, 9);

    test('waktu pengingat dihitung dari pilihan', () {
      expect(Pengingat.tidakAda.hitung(waktu), isNull);
      expect(Pengingat.satuJam.hitung(waktu), DateTime.utc(2026, 11, 25, 8));
      expect(Pengingat.tigaJam.hitung(waktu), DateTime.utc(2026, 11, 25, 6));
      expect(Pengingat.malamSebelumnya.hitung(waktu), DateTime.utc(2026, 11, 24, 19));
      expect(Pengingat.malamSebelumnya.hitung(DateTime.utc(2026, 12, 1, 9)), DateTime.utc(2026, 11, 30, 19));
    });

    test('toJson lalu fromJson mempertahankan semua bidang', () {
      final rencana = Rencana(
        id: 4,
        nama: 'Akhir pekan di Batu',
        waktu: waktu,
        idDestinasi: const [1, 3],
        pengingat: Pengingat.tigaJam,
      );
      final salinan = Rencana.fromJson(rencana.toJson());
      expect(salinan.id, 4);
      expect(salinan.nama, 'Akhir pekan di Batu');
      expect(salinan.waktu, waktu);
      expect(salinan.idDestinasi, [1, 3]);
      expect(salinan.pengingat, Pengingat.tigaJam);
    });

    test('nama pengingat yang tidak dikenal kembali ke satu jam', () {
      expect(Pengingat.dariTeks('tidak ada'), Pengingat.satuJam);
    });
  });

  group('susunRute', () {
    test('memilih destinasi terdekat dari titik awal lalu bergerak ke tetangga terdekat', () {
      final rute = susunRute([cobanUji, museumUji, baksoUji], posisiUji);
      expect(rute.urutan.map((d) => d.id), [2, 3, 1]);
      expect(rute.ruas.first, closeTo(0, 1e-9));
      expect(rute.ruas.every((k) => k != null), isTrue);
      expect(rute.totalKm, greaterThan(rute.ruas.last!));
    });

    test('tanpa titik awal urutan daftar dipertahankan dari yang pertama', () {
      final rute = susunRute([cobanUji, baksoUji], null);
      expect(rute.urutan.first.id, 1);
      expect(rute.ruas.first, isNull);
      expect(rute.ruas.last, isNotNull);
    });

    test('daftar kosong menghasilkan rute kosong', () {
      final rute = susunRute(const [], posisiUji);
      expect(rute.urutan, isEmpty);
      expect(rute.totalKm, 0);
    });
  });

  group('nilaiRencana', () {
    final rencana = Rencana(
      id: 1,
      nama: 'Uji',
      waktu: DateTime.utc(2026, 11, 25, 9),
      idDestinasi: const [1, 2],
    );

    test('memilih destinasi yang paling terdampak cuaca', () {
      final nilai = nilaiRencana(
        rencana,
        [baksoUji, cobanUji],
        (d) => buatPrakiraan(d.koordinat, kode: 61, peluang: 90),
      )!;
      expect(nilai.tingkat, TingkatSaran.hindari);
      expect(nilai.penyebab.id, 1);
      expect(nilai.peluangHujan, 90);
    });

    test('null bila belum ada data cuaca', () {
      expect(nilaiRencana(rencana, [cobanUji], (_) => null), isNull);
    });
  });
}
