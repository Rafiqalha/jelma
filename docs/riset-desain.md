# Riset dan arah desain JELMA 2.1

Dokumen ini mencatat riset sebelum antarmuka Jelajah Malang (JELMA) dirombak menjadi gaya aplikasi
startup: foto asli setiap destinasi, tipografi, warna, onboarding, logo, ikon aplikasi, dan splash.
Setiap keputusan di bagian akhir disertai alasan satu baris dan sumbernya.

## 1. Temuan riset

### Tata letak dan kartu

- Aplikasi perjalanan global menonjolkan foto besar sebagai isi utama kartu, membatasi tab bawah
  paling banyak lima, menaruh aksi utama di zona jempol, dan memakai bilah aksi yang menempel di bawah
  halaman detail ([Saasfactor](https://www.saasfactor.co/blogs/travel-mobile-app-design-ideas),
  [Justinmind](https://www.justinmind.com/ui-design/cards),
  [Webpo](https://webpo.space/blog/best-mobile-app-ui-design)).
- Sistem desain Airbnb menekankan pengekangan: satu jenis huruf, satu warna khas, sudut lembut,
  fotografi dengan ruang kosong yang lega, dan bintang rating berwarna gelap alih-alih kuning
  ([Fast Company tentang Airbnb Cereal](https://www.fastcompany.com/90172242)).

### Tipografi

- Plus Jakarta Sans dirancang Gumpita Rahayu (Tokotype) untuk identitas kota "+Jakarta City of
  Collaboration" dan dirilis dengan SIL Open Font License 1.1, sehingga boleh dibundel di aplikasi
  ([GitHub Tokotype](https://github.com/tokotype/PlusJakartaSans),
  [Google Fonts](https://fonts.google.com/specimen/Plus+Jakarta+Sans/about)).
- Tren 2026 menempatkan keterbacaan di atas ekspresi dan memakai tipografi sebagai alat merek
  ([Moburst](https://www.moburst.com/blog/top-mobile-web-design-trends/),
  [Design Studio](https://www.designstudiouiux.com/blog/mobile-app-ui-ux-design-trends/)).

### Warna dan teks di atas foto

- Antarmuka bergerak ke arah yang lebih tenang, dengan proporsi 60% netral, 30% warna sekunder, dan
  10% aksen ([Moburst](https://www.moburst.com/blog/top-mobile-web-design-trends/)).
- Teks di atas foto perlu scrim atau bidang warna solid. Kontras diperiksa di titik terburuk, bukan
  di titik terbaik; bila tidak ada scrim yang aman untuk semua potongan foto, teks dipindah ke bidang
  solid di samping foto ([Material Design: Imagery](https://m1.material.io/style/imagery.html),
  [Accessibility.build](https://accessibility.build/guides/text-over-images)).

### Onboarding dan izin

- Tutorial bergaya tumpukan kartu jarang dibaca dan tidak membuat pengguna lebih cepat memakai
  aplikasi. Onboarding sebaiknya singkat, bisa dilewati, dan bantuan diberikan dalam konteks
  ([NN/g: Mobile-App Onboarding](https://www.nngroup.com/articles/mobile-app-onboarding/),
  [NN/g: Onboarding Tutorials](https://www.nngroup.com/articles/onboarding-tutorials/),
  [NN/g: Mobile Tutorials](https://www.nngroup.com/articles/mobile-tutorials/)).
- Airbnb membiarkan orang menjelajah dulu sebelum meminta apa pun. Izin notifikasi lebih tepat
  diminta setelah pengguna menyimpan sesuatu, bukan saat pertama membuka aplikasi
  ([UXCam](https://uxcam.com/blog/10-apps-with-great-user-onboarding/),
  [Wolfpixel](https://www.wolfpixel.agency/blogs/app-onboarding-examples)).
- Android meminta izin diajukan saat pengguna mulai memakai fitur yang membutuhkannya, selalu
  menyediakan pilihan batal, dan tetap berfungsi bila izin ditolak
  ([Android Developers: Request runtime permissions](https://developer.android.com/training/permissions/requesting)).

### Logo, ikon aplikasi, dan splash

- Ikon adaptif Android terdiri atas lapisan latar dan depan berukuran 108 dp. Logo minimal 48 dp dan
  tidak lebih dari zona aman 66 dp; lapisan monokrom membuat ikon ikut tema di Android 13 ke atas
  ([Android Developers: Adaptive icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)).
- Ikon sebaiknya sederhana, satu bentuk yang mudah dikenali, tanpa teks kecil
  ([ringkasan pedoman ikon Apple oleh Median](https://median.co/blog/what-are-apples-ui-guidelines-for-app-icons)).
- Splash Android 12 ke atas memakai ikon di atas satu warna latar tanpa transparansi; gambar merek di
  bawah splash tidak dianjurkan
  ([Android Developers: Splash screens](https://developer.android.com/develop/ui/views/launch/splash-screen)).

### Foto dan lisensi

- Foto berlisensi Creative Commons wajib diberi atribusi TASL: judul, pembuat, sumber, dan lisensi,
  sebaiknya dengan tautan, dan perubahan (misalnya diperkecil) disebutkan
  ([Creative Commons: Recommended practices for attribution](https://wiki.creativecommons.org/wiki/Recommended_practices_for_attribution),
  [Wikimedia Foundation: Attributing Creative Commons Content](https://upload.wikimedia.org/wikipedia/commons/e/e5/Attributing_Creative_Commons_Content_-_A_guide.pdf)).

## 2. Design Read dan dial

> Membaca proyek ini sebagai aplikasi penemuan wisata untuk pengunjung dan warga Malang Raya, dengan
> bahasa visual editorial yang mendahulukan foto asli, permukaan netral yang tenang, dan satu aksen
> hangat. Dial: ENERGY 2 / RHYTHM 2 / MOTION 2.

- ENERGY 2: foto yang bersuara, antarmuka di sekitarnya tenang.
- RHYTHM 2: bagian Beranda berganti bentuk (korsel foto besar, deret kategori, daftar baris, korsel
  kecil), sedangkan halaman daftar konsisten.
- MOTION 2: transisi Hero foto dari kartu ke Detail dan pergantian halaman onboarding. Tidak ada
  animasi berulang tanpa pemicu; animasi dimatikan bila pengguna menonaktifkan animasi di sistem.

## 3. Keputusan

| Aspek | Keputusan | Alasan |
| --- | --- | --- |
| Warna utama | Hijau pinus `#0B6457` | Melanjutkan identitas hijau JELMA versi UTS, menggambarkan dataran tinggi berhutan di sekitar Malang; teks putih di atasnya 7,06:1. |
| Teks | Tinta `#102A26` di latar `#F6F5F1` | Hitam kehijauan lebih lembut daripada hitam murni dan tetap 13,94:1. |
| Teks sekunder | `#56625F` | 5,82:1 di latar dan 6,35:1 di kartu putih, lolos AA untuk teks kecil. |
| Latar | Kertas hangat `#F6F5F1`, kartu putih | Netral hangat membuat warna foto tampil apa adanya. |
| Aksen | Jingga `#E2572B` (latar terang) dan `#FFB547` (latar hijau) | Hanya pada titik logo, titik lokasi di Beranda, penanda halaman onboarding, dan hati favorit yang aktif; kontras grafis 3,42:1 dan 4,02:1. |
| Bintang rating | Warna tinta, bukan kuning | Mengurangi warna di kartu dan mengikuti praktik Airbnb. |
| Huruf | Plus Jakarta Sans 400 sampai 800 | Karya desainer Indonesia untuk identitas kota, bukaan huruf lebar sehingga terbaca di ukuran kecil, lisensi OFL. |
| Kartu destinasi | Foto di atas, teks di bawah pada bidang putih | Teks tidak menumpang di foto sehingga kontras pasti lolos di semua foto. |
| Teks di atas foto | Hanya tombol bundar putih berisi ikon | Ikon gelap di lingkaran putih kontrasnya tidak bergantung pada isi foto. |
| Onboarding | Tiga halaman, bisa dilewati kapan saja, izin lokasi diminta di halaman terakhir dengan pilihan "Nanti saja" | Tiga halaman karena ada tiga hal yang perlu diketahui sebelum mulai: isi katalog, cuaca per lokasi, dan alasan izin lokasi. |
| Izin notifikasi | Diminta saat rencana kunjungan pertama disimpan | Sesuai saran meminta izin setelah pengguna menyimpan sesuatu. |
| Logo | Huruf "j" kecil dengan titik jingga | Titik pada "j" dibaca sebagai titik lokasi sekaligus matahari, dua fitur inti JELMA (lokasi dan cuaca). |
| Ikon aplikasi | Ikon adaptif vektor: latar hijau pinus, "j" putih dengan titik `#FFB547`, lapisan monokrom | Mengikuti spesifikasi 108 dp dengan logo di dalam zona aman 66 dp. |
| Splash | Latar hijau pinus dengan ikon yang sama | Splash sistem Android 12 ke atas tidak menyarankan gambar merek tambahan. |
| Mode gelap | Tetap terang | Aplikasi dipakai di luar ruangan pada siang hari saat merencanakan dan menuju destinasi; foto juga tampil paling akurat di latar terang. |
| Radius | 20 untuk kartu foto, 14 untuk tombol dan kolom isian, 12 untuk foto kecil, penuh untuk chip | Variasi radius membedakan jenis elemen. |
| Bayangan | Tanpa bayangan pada kartu; hanya bilah aksi bawah Detail dan tombol bundar di atas foto | Bilah aksi melayang di atas isi yang bergulir, dan tombol putih perlu dipisahkan dari bagian foto yang juga terang. |
| Tata letak Beranda | Logo dan salam, kolom cari, kartu lokasi dan cuaca, deret foto "Cocok untuk cuaca hari ini", kategori, Dekat Anda, Populer, Rating tertinggi | Titik fokusnya rekomendasi berdasarkan cuaca, hal yang membedakan JELMA; bentuk tiap bagian berganti (RHYTHM 2). |
| Halaman Detail | Foto besar dengan kredit di bawahnya, fakta ringkas, cuaca, deskripsi, fasilitas, lokasi, dan bilah aksi berisi harga serta "Rencanakan kunjungan" | Aksi utama selalu terjangkau jempol, sesuai pola bilah aksi menempel pada aplikasi perjalanan. |

## 4. Foto destinasi

Foto diambil dari Wikimedia Commons dengan lisensi yang mengizinkan pemakaian ulang (CC BY, CC BY-SA,
CC0, atau domain publik). Setiap foto diperiksa satu per satu agar benar menampilkan tempat yang
dimaksud, lalu diperkecil dan dikompres untuk aplikasi. Kredit lengkap (judul berkas, pembuat,
lisensi, tautan sumber) disimpan di `assets/data/destinasi.json`, ditampilkan di bawah foto pada
halaman Detail, dan dikumpulkan di halaman Kredit foto. Destinasi tanpa foto yang layak memakai
gambar pengganti berwarna kategori dengan keterangan "Foto belum tersedia".
