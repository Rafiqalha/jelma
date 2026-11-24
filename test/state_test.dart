import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uts_jelajah_malang/models/area_referensi.dart';
import 'package:uts_jelajah_malang/models/koordinat.dart';
import 'package:uts_jelajah_malang/models/rencana.dart';
import 'package:uts_jelajah_malang/services/lokasi_service.dart';
import 'package:uts_jelajah_malang/services/notifikasi_service.dart';
import 'package:uts_jelajah_malang/state/cuaca_store.dart';
import 'package:uts_jelajah_malang/state/favorit_store.dart';
import 'package:uts_jelajah_malang/state/lokasi_store.dart';
import 'package:uts_jelajah_malang/state/notifikasi_store.dart';
import 'package:uts_jelajah_malang/state/pengaturan_store.dart';
import 'package:uts_jelajah_malang/state/rencana_store.dart';

import 'alat_uji.dart';

Future<SharedPreferences> _prefs([Map<String, Object> awal = const {}]) async {
  SharedPreferences.setMockInitialValues(awal);
  return SharedPreferences.getInstance();
}

void main() {
  group('FavoritStore', () {
    test('favorit bertahan setelah store dibuat ulang dari penyimpanan yang sama', () async {
      final prefs = await _prefs();
      final pertama = FavoritStore(penyimpanan: prefs)
        ..toggle(1)
        ..toggle(5);
      expect(pertama.jumlah, 2);

      final kedua = FavoritStore(penyimpanan: prefs);
      expect(kedua.apakahFavorit(1), isTrue);
      expect(kedua.apakahFavorit(5), isTrue);
      expect(kedua.apakahFavorit(2), isFalse);

      kedua.toggle(1);
      expect(FavoritStore(penyimpanan: prefs).apakahFavorit(1), isFalse);
    });

    test('tanpa penyimpanan tetap berfungsi di memori', () {
      final store = FavoritStore()..toggle(3);
      expect(store.apakahFavorit(3), isTrue);
    });
  });

  group('PengaturanStore', () {
    test('nilai bawaan', () async {
      final p = PengaturanStore(await _prefs());
      expect(p.modeLokasi, ModeLokasi.gps);
      expect(p.area.id, areaBawaan.id);
      expect(p.radiusKm, 25);
      expect(p.pengingatAktif, isTrue);
      expect(p.peringatanCuacaAktif, isTrue);
    });

    test('perubahan disimpan dan dibaca kembali', () async {
      final prefs = await _prefs();
      PengaturanStore(prefs)
        ..aturModeLokasi(ModeLokasi.manual)
        ..aturArea('alun_alun_batu')
        ..aturRadius(80)
        ..aturPengingat(false)
        ..aturPeringatanCuaca(false);
      final baru = PengaturanStore(prefs);
      expect(baru.modeLokasi, ModeLokasi.manual);
      expect(baru.area.id, 'alun_alun_batu');
      expect(baru.radiusKm, PengaturanStore.radiusMaksKm, reason: 'dibatasi ke radius maksimum');
      expect(baru.pengingatAktif, isFalse);
      expect(baru.peringatanCuacaAktif, isFalse);
    });

    test('area yang tidak dikenal kembali ke area bawaan', () async {
      final p = PengaturanStore(await _prefs({'id_area': 'tidak_ada'}));
      expect(p.area.id, areaBawaan.id);
    });
  });

  group('LokasiStore', () {
    Future<(LokasiStore, LokasiPalsu, PengaturanStore)> buat({LokasiPalsu? layanan}) async {
      final lokasi = layanan ?? LokasiPalsu();
      final pengaturan = PengaturanStore(await _prefs());
      return (
        LokasiStore(layanan: lokasi, pengaturan: pengaturan, waktu: () => waktuUji),
        lokasi,
        pengaturan,
      );
    }

    test('izin ada: posisi GPS dipakai dan diberi nama tempat', () async {
      final (store, _, _) = await buat();
      await store.mulai();
      expect(store.status, StatusLokasi.siap);
      expect(store.aktif, posisiUji);
      expect(store.label, 'Klojen, Malang');
      expect(store.sumberLabel, 'GPS');
      expect(store.memakaiBawaan, isFalse);
      expect(store.diperbaruiPada, waktuUji);
    });

    test('nama tempat tidak tersedia: memakai area acuan terdekat', () async {
      final (store, _, _) = await buat(layanan: LokasiPalsu(nama: null));
      await store.mulai();
      expect(store.label, 'Dekat ${areaBawaan.nama}');
    });

    test('izin belum diberikan: cuaca memakai area bawaan sampai izin diminta', () async {
      final (store, layanan, _) = await buat(layanan: LokasiPalsu(izin: IzinLokasi.ditolak));
      await store.mulai();
      expect(store.status, StatusLokasi.izinDitolak);
      expect(store.aktif, isNull);
      expect(store.untukCuaca, areaBawaan.koordinat);
      expect(store.label, areaBawaan.nama);
      expect(store.sumberLabel, 'Bawaan');
      expect(layanan.jumlahMintaIzin, 0, reason: 'mulai() tidak boleh memunculkan dialog');

      await store.perbarui(mintaIzin: true);
      expect(layanan.jumlahMintaIzin, 1);
      expect(store.status, StatusLokasi.siap);
      expect(store.aktif, posisiUji);
    });

    test('izin ditolak permanen dan GPS mati dibedakan', () async {
      final (permanen, _, _) = await buat(layanan: LokasiPalsu(izin: IzinLokasi.ditolakPermanen));
      await permanen.mulai();
      expect(permanen.status, StatusLokasi.izinDitolakPermanen);

      final (mati, _, _) = await buat(layanan: LokasiPalsu(izin: IzinLokasi.layananMati));
      await mati.mulai();
      expect(mati.status, StatusLokasi.layananMati);
    });

    test('posisi gagal menjadi galat dengan pesan', () async {
      final (store, _, _) = await buat(layanan: LokasiPalsu(posisiGagal: true));
      await store.mulai();
      expect(store.status, StatusLokasi.galat);
      expect(store.pesanGalat, contains('belum berhasil'));
      expect(store.aktif, isNull);
    });

    test('area manual tidak meminta GPS dan tersimpan di pengaturan', () async {
      final (store, layanan, pengaturan) = await buat();
      store.pakaiArea('alun_alun_batu');
      expect(store.mode, ModeLokasi.manual);
      expect(store.status, StatusLokasi.siap);
      expect(store.aktif, areaDariId('alun_alun_batu')!.koordinat);
      expect(store.label, areaDariId('alun_alun_batu')!.nama);
      expect(store.sumberLabel, 'Area pilihan');
      expect(pengaturan.area.id, 'alun_alun_batu');

      await store.mulai();
      await store.perbarui();
      expect(layanan.jumlahMintaIzin, 0);
      expect(store.aktif, areaDariId('alun_alun_batu')!.koordinat);
    });

    test('kembali ke GPS meminta izin dan posisi', () async {
      final (store, layanan, _) = await buat(layanan: LokasiPalsu(izin: IzinLokasi.ditolak));
      store.pakaiArea('kepanjen');
      await store.pakaiGps();
      expect(store.mode, ModeLokasi.gps);
      expect(layanan.jumlahMintaIzin, 1);
      expect(store.aktif, posisiUji);
    });

    test('lokasi jauh dari Malang Raya dikenali', () async {
      final (dekat, _, _) = await buat();
      await dekat.mulai();
      expect(dekat.jauhDariMalang, isFalse);

      final (jauh, _, _) = await buat(layanan: LokasiPalsu(posisi: const Koordinat(37.422, -122.084), nama: null));
      await jauh.mulai();
      expect(jauh.jauhDariMalang, isTrue);
    });
  });

  group('CuacaStore', () {
    test('memuat cuaca untuk lokasi dan semua destinasi dengan satu permintaan', () async {
      final layanan = CuacaPalsu();
      final store = CuacaStore(layanan: layanan, waktu: () => waktuUji);
      expect(store.status, StatusCuaca.kosong);
      await store.muat(lokasi: posisiUji, destinasi: katalogUji.destinasi);
      expect(store.status, StatusCuaca.siap);
      expect(store.diperbaruiPada, waktuUji);
      expect(layanan.jumlahPanggilan, 1);
      expect(layanan.titikTerakhir, hasLength(3), reason: 'titik lokasi sama dengan Bakso Uji sehingga digabung');
      expect(store.untukTitik(posisiUji), isNotNull);
      expect(store.untukDestinasi(cobanUji)!.saatIni.kondisi.label, 'Hujan');
      expect(store.adaData, isTrue);
    });

    test('gagal memberi status galat dan mempertahankan data sebelumnya', () async {
      final layanan = CuacaPalsu();
      final store = CuacaStore(layanan: layanan, waktu: () => waktuUji);
      await store.muat(lokasi: posisiUji, destinasi: katalogUji.destinasi);

      layanan.gagal = true;
      await store.muat(lokasi: posisiUji, destinasi: katalogUji.destinasi);
      expect(store.status, StatusCuaca.galat);
      expect(store.pesanGalat, contains('koneksi internet'));
      expect(store.untukDestinasi(cobanUji), isNotNull, reason: 'data lama tetap tersedia');

      layanan.gagal = false;
      await store.muat(lokasi: posisiUji, destinasi: katalogUji.destinasi);
      expect(store.status, StatusCuaca.siap);
      expect(store.pesanGalat, isNull);
    });

    test('permintaan yang datang saat memuat dijalankan setelahnya', () async {
      final layanan = CuacaPalsu();
      final store = CuacaStore(layanan: layanan, waktu: () => waktuUji);
      final pertama = store.muat(lokasi: posisiUji, destinasi: katalogUji.destinasi);
      final kedua = store.muat(lokasi: areaDariId('alun_alun_batu')!.koordinat, destinasi: katalogUji.destinasi);
      await Future.wait([pertama, kedua]);
      expect(layanan.jumlahPanggilan, 2);
      expect(store.untukTitik(areaDariId('alun_alun_batu')!.koordinat), isNotNull);
    });
  });

  group('RencanaStore', () {
    // Rabu 25 November 2026 pukul 09.00, atau 24 jam setelah waktu uji.
    final besok = DateTime.utc(2026, 11, 25, 9);

    Future<({RencanaStore store, NotifikasiPalsu notif, PengaturanStore pengaturan, CuacaStore cuaca, SharedPreferences prefs})> buat({
      NotifikasiPalsu? notif,
      CuacaPalsu? layananCuaca,
      Map<String, Object> awal = const {},
    }) async {
      final prefs = await _prefs(awal);
      final pengaturan = PengaturanStore(prefs);
      final n = notif ?? NotifikasiPalsu();
      final cuaca = CuacaStore(layanan: layananCuaca ?? CuacaPalsu(), waktu: () => waktuUji);
      await cuaca.muat(lokasi: posisiUji, destinasi: katalogUji.destinasi);
      return (
        store: RencanaStore(penyimpanan: prefs, notifikasi: n, pengaturan: pengaturan, waktu: () => waktuUji),
        notif: n,
        pengaturan: pengaturan,
        cuaca: cuaca,
        prefs: prefs,
      );
    }

    Rencana rencana(int id, {DateTime? waktu, List<int> tujuan = const [1], Pengingat pengingat = Pengingat.satuJam}) =>
        Rencana(id: id, nama: 'Rencana $id', waktu: waktu ?? besok, idDestinasi: tujuan, pengingat: pengingat);

    test('identitas baru berurutan dan tersimpan', () async {
      final t = await buat();
      expect(t.store.buatId(), 1);
      expect(t.store.buatId(), 2);
      final baru = RencanaStore(
        penyimpanan: t.prefs,
        notifikasi: t.notif,
        pengaturan: t.pengaturan,
        waktu: () => waktuUji,
      );
      expect(baru.buatId(), 3);
    });

    test('menyimpan rencana: urut menurut waktu, tersimpan, dan pengingat terjadwal dengan ringkasan cuaca', () async {
      final t = await buat();
      final lebihAwal = rencana(1, waktu: DateTime.utc(2026, 11, 26, 9));
      final lebihLambat = rencana(2, tujuan: const [1, 2]);
      await t.store.simpan(lebihAwal, katalog: katalogUji, cuaca: t.cuaca);
      final hasil = await t.store.simpan(lebihLambat, katalog: katalogUji, cuaca: t.cuaca);

      expect(hasil.pengingatTerjadwal, isTrue);
      expect(t.store.daftar.map((r) => r.id), [2, 1], reason: 'rencana 25 November lebih awal dari 26 November');
      expect(t.notif.terjadwal, hasLength(2));
      final jadwal = t.notif.terjadwal.last;
      expect(jadwal.id, 2 * 2);
      expect(jadwal.waktu, DateTime.utc(2026, 11, 25, 8));
      expect(jadwal.judul, 'Pengingat: Rencana 2');
      expect(jadwal.isi, contains('09.00 di Coban Uji, Bakso Uji'));
      expect(jadwal.isi, contains('hujan, peluang hujan 80%'));

      final baru = RencanaStore(
        penyimpanan: t.prefs,
        notifikasi: t.notif,
        pengaturan: t.pengaturan,
        waktu: () => waktuUji,
      );
      expect(baru.daftar.map((r) => r.id), [2, 1]);
      expect(baru.cari(2)!.idDestinasi, [1, 2]);
    });

    test('mengubah rencana yang ada tidak menggandakannya dan membatalkan jadwal lama', () async {
      final t = await buat();
      await t.store.simpan(rencana(1), katalog: katalogUji);
      await t.store.simpan(rencana(1).salin(nama: 'Nama baru'), katalog: katalogUji);
      expect(t.store.daftar, hasLength(1));
      expect(t.store.cari(1)!.nama, 'Nama baru');
      expect(t.notif.dibatalkan, contains(2));
    });

    test('tanpa pengingat atau pengingat dimatikan, tidak ada jadwal', () async {
      final t = await buat();
      final tanpa = await t.store.simpan(rencana(1, pengingat: Pengingat.tidakAda), katalog: katalogUji);
      expect(tanpa.pengingatTerjadwal, isFalse);
      expect(tanpa.catatan, isNull);

      t.pengaturan.aturPengingat(false);
      final mati = await t.store.simpan(rencana(2), katalog: katalogUji);
      expect(mati.pengingatTerjadwal, isFalse);
      expect(mati.catatan, 'Pengingat dimatikan di Pengaturan.');
      expect(t.notif.terjadwal, isEmpty);
    });

    test('waktu pengingat yang sudah lewat tidak dijadwalkan', () async {
      final t = await buat();
      final hasil = await t.store.simpan(
        rencana(1, waktu: DateTime.utc(2026, 11, 24, 9, 30)),
        katalog: katalogUji,
      );
      expect(hasil.pengingatTerjadwal, isFalse);
      expect(hasil.catatan, contains('sudah lewat'));
      expect(t.notif.terjadwal, isEmpty);
    });

    test('izin notifikasi diminta sekali dan penolakan dijelaskan', () async {
      final t = await buat(notif: NotifikasiPalsu(izin: false));
      final hasil = await t.store.simpan(rencana(1), katalog: katalogUji);
      expect(t.notif.jumlahMintaIzin, 1);
      expect(hasil.pengingatTerjadwal, isFalse);
      expect(hasil.catatan, contains('Izin notifikasi'));
      expect(t.store.daftar, hasLength(1), reason: 'rencana tetap tersimpan walau pengingat gagal');
    });

    test('menghapus rencana membatalkan pengingat dan peringatannya', () async {
      final t = await buat();
      await t.store.simpan(rencana(3), katalog: katalogUji);
      await t.store.hapus(3);
      expect(t.store.daftar, isEmpty);
      expect(t.notif.dibatalkan, containsAll([6, 7]));
      final baru = RencanaStore(
        penyimpanan: t.prefs,
        notifikasi: t.notif,
        pengaturan: t.pengaturan,
        waktu: () => waktuUji,
      );
      expect(baru.daftar, isEmpty);
    });

    test('rencana dipisah menjadi mendatang dan selesai menurut jam', () async {
      final t = await buat();
      await t.store.simpan(rencana(1, waktu: DateTime.utc(2026, 11, 24, 8), pengingat: Pengingat.tidakAda), katalog: katalogUji);
      await t.store.simpan(rencana(2, pengingat: Pengingat.tidakAda), katalog: katalogUji);
      expect(t.store.mendatang.map((r) => r.id), [2]);
      expect(t.store.selesai.map((r) => r.id), [1]);
    });

    test('peringatan cuaca terkirim sekali untuk rencana dalam 48 jam yang cuacanya buruk', () async {
      final t = await buat();
      await t.store.simpan(rencana(1), katalog: katalogUji);
      await t.store.sinkronkan(katalog: katalogUji, cuaca: t.cuaca);
      expect(t.notif.ditampilkan, hasLength(1));
      final peringatan = t.notif.ditampilkan.single;
      expect(peringatan.saluran, SaluranNotifikasi.cuaca);
      expect(peringatan.id, 1 * 2 + 1);
      expect(peringatan.judul, 'Cuaca kurang mendukung: Rencana 1');
      expect(peringatan.isi, contains('Coban Uji'));
      expect(peringatan.isi, contains('peluang hujan 80%'));

      await t.store.sinkronkan(katalog: katalogUji, cuaca: t.cuaca);
      expect(t.notif.ditampilkan, hasLength(1), reason: 'peringatan yang sama tidak diulang');
    });

    test('tidak ada peringatan bila dimatikan, bila rencana terlalu jauh, atau bila tujuannya dalam ruangan', () async {
      final mati = await buat();
      mati.pengaturan.aturPeringatanCuaca(false);
      await mati.store.simpan(rencana(1), katalog: katalogUji);
      await mati.store.sinkronkan(katalog: katalogUji, cuaca: mati.cuaca);
      expect(mati.notif.ditampilkan, isEmpty);

      final jauh = await buat();
      await jauh.store.simpan(rencana(1, waktu: DateTime.utc(2026, 11, 28, 9)), katalog: katalogUji);
      await jauh.store.sinkronkan(katalog: katalogUji, cuaca: jauh.cuaca);
      expect(jauh.notif.ditampilkan, isEmpty);

      final dalam = await buat();
      await dalam.store.simpan(rencana(1, tujuan: const [2, 3]), katalog: katalogUji);
      await dalam.store.sinkronkan(katalog: katalogUji, cuaca: dalam.cuaca);
      expect(dalam.notif.ditampilkan, isEmpty);
    });

    test('cuaca cerah tidak memicu peringatan', () async {
      final t = await buat(layananCuaca: CuacaPalsu(kode: 1, peluang: 10));
      await t.store.simpan(rencana(1), katalog: katalogUji, cuaca: t.cuaca);
      await t.store.sinkronkan(katalog: katalogUji, cuaca: t.cuaca);
      expect(t.notif.ditampilkan, isEmpty);
    });

    test('tanpa izin notifikasi, sinkronisasi tidak menjadwalkan atau menampilkan apa pun', () async {
      final t = await buat(notif: NotifikasiPalsu(izin: false));
      await t.store.simpan(rencana(1), katalog: katalogUji);
      await t.store.sinkronkan(katalog: katalogUji, cuaca: t.cuaca);
      expect(t.notif.ditampilkan, isEmpty);
      expect(t.notif.terjadwal, isEmpty);
    });

    test('sinkronisasi memperbarui teks pengingat dengan prakiraan terbaru', () async {
      final t = await buat();
      await t.store.simpan(rencana(1), katalog: katalogUji);
      expect(t.notif.terjadwal.single.isi, isNot(contains('peluang')), reason: 'disimpan sebelum cuaca tersedia');
      await t.store.sinkronkan(katalog: katalogUji, cuaca: t.cuaca);
      expect(t.notif.terjadwal.last.isi, contains('peluang hujan 80%'));
    });
  });

  group('NotifikasiStore', () {
    test('periksa mengisi status izin', () async {
      final store = NotifikasiStore(NotifikasiPalsu(izin: false));
      expect(store.izin, isNull);
      await store.periksa();
      expect(store.izin, isFalse);
    });

    test('kirimUji menampilkan satu notifikasi bila izin ada', () async {
      final notif = NotifikasiPalsu();
      final store = NotifikasiStore(notif);
      expect(await store.kirimUji(), isTrue);
      expect(notif.ditampilkan.single.judul, 'Notifikasi uji Jelajah Malang');
      expect(notif.jumlahMintaIzin, 0);
    });

    test('kirimUji meminta izin dan gagal bila ditolak', () async {
      final notif = NotifikasiPalsu(izin: false);
      final store = NotifikasiStore(notif);
      expect(await store.kirimUji(), isFalse);
      expect(notif.jumlahMintaIzin, 1);
      expect(notif.ditampilkan, isEmpty);
      expect(store.izin, isFalse);
    });
  });
}
