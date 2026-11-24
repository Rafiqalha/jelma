import 'cuaca.dart';
import 'destinasi.dart';
import 'rencana.dart';

/// Seberapa baik cuaca mendukung kunjungan ke suatu destinasi.
enum TingkatSaran {
  baik('Cocok'),
  waspada('Waspada'),
  hindari('Tunda');

  const TingkatSaran(this.label);

  final String label;
}

/// Hasil penilaian cuaca untuk satu destinasi pada satu hari.
class SaranCuaca {
  const SaranCuaca({required this.tingkat, required this.judul, required this.penjelasan});

  final TingkatSaran tingkat;

  /// Kalimat pendek untuk chip, misalnya `Bawa jas hujan`.
  final String judul;
  final String penjelasan;
}

/// Peluang hujan (persen) mulai dari mana kunjungan ke area terbuka sebaiknya ditunda.
const int peluangTunda = 70;

/// Peluang hujan (persen) mulai dari mana pengunjung area terbuka perlu membawa jas hujan.
const int peluangWaspada = 40;

/// Peluang hujan (persen) mulai dari mana destinasi campuran perlu rencana dalam ruangan.
const int peluangCampuran = 60;

/// Menilai kecocokan [destinasi] dengan cuaca pada hari [hari].
///
/// Aturannya sederhana dan dapat dijelaskan: destinasi dalam ruangan aman dari hujan,
/// sedangkan area terbuka dinilai dari peluang hujan, badai petir, dan suhu terasa.
SaranCuaca saranKunjungan(Destinasi destinasi, CuacaHarian hari) {
  final kondisi = hari.kondisi;
  final peluang = hari.peluangHujan;
  final badai = kondisi == KondisiCuaca.badaiPetir;
  final hujan = kondisi.basah;
  final panas = kondisi == KondisiCuaca.panas;

  switch (destinasi.ruang) {
    case Ruang.tertutup:
      if (hujan || peluang >= peluangWaspada) {
        return const SaranCuaca(
          tingkat: TingkatSaran.baik,
          judul: 'Aman saat hujan',
          penjelasan: 'Kegiatan utama berlangsung di dalam ruangan sehingga tetap nyaman meski hujan.',
        );
      }
      return const SaranCuaca(
        tingkat: TingkatSaran.baik,
        judul: 'Cocok dikunjungi',
        penjelasan: 'Kegiatan utama berlangsung di dalam ruangan, jadi cuaca tidak mengganggu.',
      );
    case Ruang.campuran:
      if (badai) {
        return const SaranCuaca(
          tingkat: TingkatSaran.waspada,
          judul: 'Pilih area dalam ruangan',
          penjelasan: 'Badai petir diperkirakan. Hindari area terbuka dan tetap berada di dalam bangunan.',
        );
      }
      if (hujan || peluang >= peluangCampuran) {
        return SaranCuaca(
          tingkat: TingkatSaran.waspada,
          judul: 'Siapkan rencana dalam ruangan',
          penjelasan: 'Peluang hujan $peluang%. Sebagian area tersedia di dalam ruangan.',
        );
      }
      return SaranCuaca(
        tingkat: TingkatSaran.baik,
        judul: 'Cocok dikunjungi',
        penjelasan: 'Peluang hujan $peluang%, tidak mengganggu area terbuka maupun ruangan.',
      );
    case Ruang.terbuka:
      if (badai) {
        return const SaranCuaca(
          tingkat: TingkatSaran.hindari,
          judul: 'Sebaiknya ditunda',
          penjelasan: 'Badai petir diperkirakan. Area terbuka tidak aman saat ada petir.',
        );
      }
      if (peluang >= peluangTunda || kondisi == KondisiCuaca.hujanLebat) {
        return SaranCuaca(
          tingkat: TingkatSaran.hindari,
          judul: 'Sebaiknya ditunda',
          penjelasan: 'Peluang hujan $peluang%. Kegiatan di area terbuka akan terganggu dan jalur bisa licin.',
        );
      }
      if (peluang >= peluangWaspada || hujan) {
        return SaranCuaca(
          tingkat: TingkatSaran.waspada,
          judul: 'Bawa jas hujan',
          penjelasan: 'Peluang hujan $peluang%. Siapkan jas hujan dan alas kaki anti selip.',
        );
      }
      if (panas) {
        return SaranCuaca(
          tingkat: TingkatSaran.waspada,
          judul: 'Datang pagi atau sore',
          penjelasan: 'Suhu terasa hingga ${hari.suhuTerasaMaks.round()} °C. Bawa air minum dan pelindung kepala.',
        );
      }
      return SaranCuaca(
        tingkat: TingkatSaran.baik,
        judul: 'Cuaca mendukung',
        penjelasan: 'Peluang hujan $peluang% dan langit tidak mengganggu kunjungan.',
      );
  }
}

/// Penilaian cuaca untuk satu rencana: kondisi terburuk di antara destinasinya pada hari kunjungan.
class PenilaianRencana {
  const PenilaianRencana({
    required this.tingkat,
    required this.kondisi,
    required this.peluangHujan,
    required this.penyebab,
    required this.saran,
  });

  final TingkatSaran tingkat;
  final KondisiCuaca kondisi;
  final int peluangHujan;

  /// Destinasi yang paling terdampak cuaca.
  final Destinasi penyebab;
  final SaranCuaca saran;
}

/// Menilai [rencana] dengan mencari destinasi yang paling terdampak cuaca pada hari kunjungan.
///
/// Mengembalikan null bila belum ada data cuaca untuk satu pun destinasi.
PenilaianRencana? nilaiRencana(
  Rencana rencana,
  List<Destinasi> tujuan,
  PrakiraanCuaca? Function(Destinasi) cuacaUntuk,
) {
  PenilaianRencana? terburuk;
  for (final d in tujuan) {
    final hari = cuacaUntuk(d)?.hariPada(rencana.waktu);
    if (hari == null) continue;
    final saran = saranKunjungan(d, hari);
    final kandidat = PenilaianRencana(
      tingkat: saran.tingkat,
      kondisi: hari.kondisi,
      peluangHujan: hari.peluangHujan,
      penyebab: d,
      saran: saran,
    );
    final lebihBuruk = terburuk == null ||
        kandidat.tingkat.index > terburuk.tingkat.index ||
        (kandidat.tingkat == terburuk.tingkat && kandidat.peluangHujan > terburuk.peluangHujan);
    if (lebihBuruk) terburuk = kandidat;
  }
  return terburuk;
}

/// Saran perlengkapan umum untuk kondisi cuaca tertentu, ditampilkan pada halaman Cuaca.
List<String> perlengkapanUntuk(KondisiCuaca kondisi) => switch (kondisi) {
      KondisiCuaca.badaiPetir => [
          'Hindari air terjun, pantai, dan area terbuka selama ada petir.',
          'Bawa jas hujan dan simpan ponsel di tas kedap air.',
          'Cadangkan destinasi dalam ruangan seperti museum.',
        ],
      KondisiCuaca.hujan || KondisiCuaca.hujanLebat || KondisiCuaca.gerimis => [
          'Bawa jas hujan dan alas kaki anti selip, terutama untuk jalur air terjun.',
          'Tambah waktu perjalanan karena jalan menuju Batu dan Pujon bisa licin.',
          'Pilih museum atau tempat makan jika hujan tidak reda.',
        ],
      KondisiCuaca.panas => [
          'Bawa air minum, topi, dan tabir surya.',
          'Kunjungi area terbuka pada pagi atau sore hari.',
          'Istirahat di tempat teduh bila terasa pusing.',
        ],
      KondisiCuaca.kabut => [
          'Nyalakan lampu dan kurangi kecepatan di jalur pegunungan.',
          'Bawa jaket karena udara di dataran tinggi lebih dingin.',
        ],
      KondisiCuaca.mendung || KondisiCuaca.berawan => [
          'Bawa jas hujan lipat untuk berjaga-jaga.',
          'Bawa jaket tipis bila menuju Batu atau Pujon.',
        ],
      KondisiCuaca.cerah || KondisiCuaca.cerahBerawan => [
          'Waktu yang baik untuk air terjun, pantai, dan kampung wisata.',
          'Tetap bawa air minum dan pelindung dari sinar matahari.',
        ],
    };
