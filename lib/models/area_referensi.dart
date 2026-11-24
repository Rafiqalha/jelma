import 'koordinat.dart';

/// Titik acuan yang dapat dipilih pengguna sebagai lokasi manual.
///
/// Koordinatnya diambil dari data OpenStreetMap (lihat README, bagian sumber data).
class AreaReferensi {
  const AreaReferensi({required this.id, required this.nama, required this.koordinat});

  final String id;
  final String nama;
  final Koordinat koordinat;
}

const List<AreaReferensi> daftarArea = [
  AreaReferensi(id: 'alun_alun_malang', nama: 'Pusat Kota Malang (Alun-alun Merdeka)', koordinat: Koordinat(-7.98261, 112.63082)),
  AreaReferensi(id: 'stasiun_malang', nama: 'Stasiun Malang', koordinat: Koordinat(-7.97848, 112.63793)),
  AreaReferensi(id: 'terminal_arjosari', nama: 'Terminal Arjosari', koordinat: Koordinat(-7.93460, 112.65847)),
  AreaReferensi(id: 'bandara_abdul_rachman_saleh', nama: 'Bandara Abdul Rachman Saleh', koordinat: Koordinat(-7.93032, 112.71327)),
  AreaReferensi(id: 'alun_alun_batu', nama: 'Kota Batu (Alun-alun Batu)', koordinat: Koordinat(-7.87118, 112.52690)),
  AreaReferensi(id: 'kepanjen', nama: 'Kepanjen (Stasiun Kepanjen)', koordinat: Koordinat(-8.13191, 112.57329)),
];

/// Area yang dipakai bila lokasi pengguna belum diketahui.
AreaReferensi get areaBawaan => daftarArea.first;

AreaReferensi? areaDariId(String? id) {
  for (final area in daftarArea) {
    if (area.id == id) return area;
  }
  return null;
}

/// Area acuan yang paling dekat dengan [titik].
AreaReferensi areaTerdekat(Koordinat titik) {
  var terbaik = daftarArea.first;
  var jarak = titik.jarakKm(terbaik.koordinat);
  for (final area in daftarArea.skip(1)) {
    final d = titik.jarakKm(area.koordinat);
    if (d < jarak) {
      terbaik = area;
      jarak = d;
    }
  }
  return terbaik;
}
