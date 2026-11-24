"""Membangun logo JELMA menjadi aset ikon Android dan dokumen.

Logo: huruf "j" kecil yang ujung atasnya dipotong miring seperti puncak gunung, dengan titik
jingga sebagai matahari sekaligus titik lokasi. Geometri ditulis sekali di sini, lalu dipakai untuk:

- android/app/src/main/res/drawable/ic_launcher_foreground.xml   (lapisan depan ikon adaptif)
- android/app/src/main/res/drawable/ic_launcher_monochrome.xml   (ikon bertema Android 13+)
- android/app/src/main/res/drawable/ic_stat_jelma.xml            (ikon kecil notifikasi)
- android/app/src/main/res/mipmap-*/ic_launcher.png               (ikon lama untuk API 24-25)
- docs/logo/jelma-ikon.svg dan docs/logo/jelma-ikon-512.png       (dokumentasi dan laporan)

Angka koordinat yang dicetak di akhir juga dipakai `lib/widgets/logo_jelma.dart`.

Pemakaian (dari folder proyek): python tool/ikon/buat_ikon.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

AKAR = Path(__file__).resolve().parents[2]
RES = AKAR / "android/app/src/main/res"
DOKUMEN = AKAR / "docs/logo"

HIJAU = "#0B6457"
JINGGA = "#FFB547"
PUTIH = "#FFFFFF"

# Geometri dalam satuan desain, lalu dipetakan ke kanvas ikon adaptif 108 dp.
W = 12.0                       # tebal garis huruf
KIRI_ATAS, KANAN_ATAS = 10.0, 2.0  # potongan miring ujung batang (naik ke kanan)
BAWAH_BATANG = 34.0
R_KAIT, SUDUT_KAIT = 12.0, 145.0
MATAHARI = (4.0, -12.0, 7.5)   # pusat x, pusat y, jari-jari
TINGGI_DP = 50.0               # tinggi logo; zona aman ikon adaptif 66 dp
GESER_X = 1.0                  # koreksi optis ke kanan


def _batas():
    ujung = -R_KAIT + R_KAIT * math.cos(math.radians(SUDUT_KAIT))
    xs = [ujung - W / 2, W / 2, MATAHARI[0] + MATAHARI[2]]
    ys = [MATAHARI[1] - MATAHARI[2], BAWAH_BATANG + R_KAIT + W / 2]
    return min(xs), max(xs), min(ys), max(ys)


X0, X1, Y0, Y1 = _batas()
SKALA = TINGGI_DP / (Y1 - Y0)
CX, CY = (X0 + X1) / 2, (Y0 + Y1) / 2


def dp(x: float, y: float) -> tuple[float, float]:
    return (54 + GESER_X + (x - CX) * SKALA, 54 + (y - CY) * SKALA)


def geometri() -> dict:
    kiri_bawah, kiri_atas = dp(-W / 2, BAWAH_BATANG), dp(-W / 2, KIRI_ATAS)
    kanan_atas, kanan_bawah = dp(W / 2, KANAN_ATAS), dp(W / 2, BAWAH_BATANG)
    pusat_kait = dp(-R_KAIT, BAWAH_BATANG)
    r = R_KAIT * SKALA
    sudut = math.radians(SUDUT_KAIT)
    ujung_kait = (pusat_kait[0] + r * math.cos(sudut), pusat_kait[1] + r * math.sin(sudut))
    mx, my = dp(MATAHARI[0], MATAHARI[1])
    return {
        "batang": [kiri_bawah, kiri_atas, kanan_atas, kanan_bawah],
        "awal_kait": (pusat_kait[0] + r, pusat_kait[1]),
        "pusat_kait": pusat_kait,
        "ujung_kait": ujung_kait,
        "r_kait": r,
        "tebal": W * SKALA,
        "matahari": (mx, my, MATAHARI[2] * SKALA),
    }


G = geometri()


def _f(v: float) -> str:
    return f"{v:.2f}".rstrip("0").rstrip(".")


def path_batang() -> str:
    a, b, c, d = G["batang"]
    return f"M{_f(a[0])},{_f(a[1])} L{_f(b[0])},{_f(b[1])} L{_f(c[0])},{_f(c[1])} L{_f(d[0])},{_f(d[1])} Z"


def path_kait() -> str:
    (ax, ay), (ex, ey), r = G["awal_kait"], G["ujung_kait"], G["r_kait"]
    return f"M{_f(ax)},{_f(ay)} A{_f(r)},{_f(r)} 0 0 1 {_f(ex)},{_f(ey)}"


def path_matahari() -> str:
    mx, my, mr = G["matahari"]
    return f"M{_f(mx - mr)},{_f(my)} a{_f(mr)},{_f(mr)} 0 1 0 {_f(2 * mr)},0 a{_f(mr)},{_f(mr)} 0 1 0 {_f(-2 * mr)},0 Z"


def vektor(warna_j: str, warna_matahari: str) -> str:
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Dibangun oleh tool/ikon/buat_ikon.py; ubah geometri di skrip itu, bukan di berkas ini. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="{warna_j}"
        android:pathData="{path_batang()}" />
    <path
        android:fillColor="#00000000"
        android:strokeColor="{warna_j}"
        android:strokeWidth="{_f(G['tebal'])}"
        android:strokeLineCap="round"
        android:pathData="{path_kait()}" />
    <path
        android:fillColor="{warna_matahari}"
        android:pathData="{path_matahari()}" />
</vector>
"""


def vektor_notifikasi() -> str:
    """Ikon status bar 24 dp: siluet putih logo, memotong kanvas 108 di sekitar pusat (26 sampai 82)."""
    return f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Dibangun oleh tool/ikon/buat_ikon.py. Ikon notifikasi Android harus siluet putih polos. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="56"
    android:viewportHeight="56">
    <group
        android:translateX="-26"
        android:translateY="-26">
        <path
            android:fillColor="#FFFFFFFF"
            android:pathData="{path_batang()}" />
        <path
            android:fillColor="#00000000"
            android:strokeColor="#FFFFFFFF"
            android:strokeWidth="{_f(G['tebal'])}"
            android:strokeLineCap="round"
            android:pathData="{path_kait()}" />
        <path
            android:fillColor="#FFFFFFFF"
            android:pathData="{path_matahari()}" />
    </group>
</vector>
"""


def svg(latar: bool = True) -> str:
    kotak = f'<rect width="108" height="108" fill="{HIJAU}"/>' if latar else ""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" width="512" height="512">
  {kotak}
  <path d="{path_batang()}" fill="{PUTIH}"/>
  <path d="{path_kait()}" fill="none" stroke="{PUTIH}" stroke-width="{_f(G['tebal'])}" stroke-linecap="round"/>
  <path d="{path_matahari()}" fill="{JINGGA}"/>
</svg>
"""


def raster(ukuran: int, bentuk: str) -> Image.Image:
    """Menggambar ikon pada kanvas `ukuran` piksel. Bentuk: penuh (kotak penuh) atau bulat-sudut."""
    s = 8
    besar = ukuran * s
    im = Image.new("RGBA", (besar, besar), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Ikon lama memakai area tampak 72 dp dari kanvas 108 dp, jadi logo diperbesar 1,5 kali.
    k = besar / 72.0

    def p(x: float, y: float) -> tuple[float, float]:
        return ((x - 18) * k, (y - 18) * k)

    if bentuk == "penuh":
        d.rectangle([0, 0, besar, besar], fill=HIJAU)
    else:
        d.rounded_rectangle([0, 0, besar - 1, besar - 1], radius=int(besar * 0.22), fill=HIJAU)
    d.polygon([p(*t) for t in G["batang"]], fill=PUTIH)
    pkx, pky = G["pusat_kait"]
    r, t = G["r_kait"], G["tebal"]
    n = 160
    sudut = [math.radians(SUDUT_KAIT * i / n) for i in range(n + 1)]
    luar = [p(pkx + (r + t / 2) * math.cos(a), pky + (r + t / 2) * math.sin(a)) for a in sudut]
    dalam = [p(pkx + (r - t / 2) * math.cos(a), pky + (r - t / 2) * math.sin(a)) for a in sudut]
    d.polygon(luar + dalam[::-1], fill=PUTIH)
    ex, ey = G["ujung_kait"]
    d.ellipse([p(ex - t / 2, ey - t / 2), p(ex + t / 2, ey + t / 2)], fill=PUTIH)
    mx, my, mr = G["matahari"]
    d.ellipse([p(mx - mr, my - mr), p(mx + mr, my + mr)], fill=JINGGA)
    return im.resize((ukuran, ukuran), Image.LANCZOS)


def main() -> None:
    (RES / "drawable/ic_launcher_foreground.xml").write_text(vektor(PUTIH, JINGGA), encoding="utf-8")
    (RES / "drawable/ic_launcher_monochrome.xml").write_text(vektor(PUTIH, PUTIH), encoding="utf-8")
    (RES / "drawable/ic_stat_jelma.xml").write_text(vektor_notifikasi(), encoding="utf-8")
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        raster(px, "bulat").save(RES / f"mipmap-{folder}/ic_launcher.png")
    DOKUMEN.mkdir(parents=True, exist_ok=True)
    (DOKUMEN / "jelma-ikon.svg").write_text(svg(), encoding="utf-8")
    raster(512, "penuh").save(DOKUMEN / "jelma-ikon-512.png")
    raster(512, "bulat").save(DOKUMEN / "jelma-ikon-bulat-512.png")
    print("Koordinat logo (kanvas 108):")
    for kunci, nilai in G.items():
        print(f"  {kunci}: {nilai}")


if __name__ == "__main__":
    main()
