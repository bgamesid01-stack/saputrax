# Kelas Ceria

Web kelas bertema bunga sakura. Dibuat dengan HTML, CSS, dan JavaScript biasa (tanpa framework dan tanpa build), jadi bisa langsung dijalankan dan dipasang di GitHub Pages.

## Fitur

- **Login Google**, dengan mode demo selama Client ID belum diisi.
- **Wajib isi nama lengkap** setelah login pertama kali (bisa diubah lewat menu).
- **Beranda bertema sakura**: langit, matahari/bulan, gunung, bukit, ranting, dan kelopak berjatuhan. Suasana berganti sesuai jam (pagi, siang, sore, malam) dan matahari/bulan bergerak di langit.
- **Pengumuman, tugas kelas** (bisa dicentang, tersimpan per akun), dan **jadwal pelajaran** (tabel di desktop, tab per hari di HP).
- **Catatan** di halaman tersendiri: catatan teks, daftar centang, dan struktur bertingkat (misalnya struktur organisasi kelas).
- **Tampilan responsif**: HP dan desktop punya tata letak berbeda.
- **Teks tidak bisa disalin sembarangan** (kolom isian tetap bisa diketik).

## Struktur folder

```
web-kelas/
├── index.html            Halaman utama (kerangka HTML saja)
├── README.md
├── .gitignore
├── .nojekyll             Agar GitHub Pages menyajikan file apa adanya
├── assets/
│   └── favicon.svg       Ikon tab browser (bunga sakura)
├── css/
│   ├── variables.css     Warna utama dan suasana pagi/siang/sore/malam
│   ├── base.css          Reset, tipografi, tombol, kartu, form
│   ├── animations.css    Keyframes dan pengaturan "kurangi gerakan"
│   ├── auth.css          Layar login dan kotak nama lengkap
│   ├── navbar.css        Navbar, menu garis tiga, panel menu
│   ├── hero.css          Bagian pembuka (langit, gunung, bukit, ranting, bunga)
│   ├── sections.css      Pengumuman, tugas, jadwal, footer
│   ├── notes.css         Halaman Catatan
│   └── protect.css       Pencegah pilih/salin teks
└── js/
    ├── config.js         Pengaturan dan data konten (EDIT DI SINI)
    ├── utils.js          Penyimpanan lokal, pemilih elemen, notifikasi, sesi
    ├── sakura.js         Gambar bunga sakura dan kelopak berjatuhan
    ├── waktu.js          Suasana waktu dan gerak matahari/bulan
    ├── auth.js           Login Google, mode demo, nama lengkap
    ├── home.js           Isi beranda (pengumuman, tugas, jadwal)
    ├── navigation.js     Perpindahan halaman dan menu garis tiga
    ├── notes.js          Fitur Catatan
    ├── protect.js        Pembatasan salin teks
    └── main.js           Titik awal aplikasi
```

**Urutan `<script>` di `index.html` penting.** File JavaScript saling berbagi fungsi dan variabel global, jadi `config.js` dan `utils.js` harus dimuat lebih dulu dan `main.js` paling akhir. Jangan mengubah urutannya.

## Menjalankan di komputer atau HP

Login Google membutuhkan alamat `http://` atau `https://`, jadi jalankan lewat server lokal, bukan dengan membuka file langsung.

```bash
cd web-kelas
python3 -m http.server 8000
```

Lalu buka `http://localhost:8000`. Alternatif: ekstensi **Live Server** di VS Code. Di Termux (Android) perintahnya sama setelah `pkg install python`.

## Mengatur isi web

Semua yang perlu kamu ubah ada di **`js/config.js`**:

| Pengaturan | Fungsi |
|---|---|
| `GOOGLE_CLIENT_ID` | Client ID untuk login Google (lihat bagian di bawah) |
| `NAMA_KELAS` | Nama kelas, dipakai di judul tab |
| `JADWAL` | Jadwal pelajaran per hari (Senin sampai Jumat) |
| `PENGUMUMAN` | Daftar pengumuman: `["Judul", "Isi"]` |
| `TUGAS` | Daftar tugas: `["id-unik", "Nama tugas", "Keterangan"]` |

Warna utama bisa diganti di `css/variables.css`.

## Mengaktifkan login Google

1. Buka [Google Cloud Console](https://console.cloud.google.com/), buat project, lalu masuk ke **APIs & Services > Credentials**.
2. Pilih **Create Credentials > OAuth client ID** dengan tipe **Web application**. Kalau diminta, atur dulu **OAuth consent screen**.
3. Pada **Authorized JavaScript origins**, tambahkan:
   - `https://USERNAME.github.io` (tanpa nama repo dan tanpa garis miring di akhir)
   - `http://localhost:8000` (untuk uji coba di komputer)
4. Salin Client ID, lalu tempel di `GOOGLE_CLIENT_ID` pada `js/config.js`.
5. Kalau status consent screen masih **Testing**, tambahkan email siswa sebagai **Test users**, atau ubah ke **In production** agar semua akun bisa masuk.

Client ID bukan rahasia dan aman disimpan di repo publik. Jangan pernah menaruh *client secret* di repo ini (web ini memang tidak membutuhkannya).

Selama `GOOGLE_CLIENT_ID` kosong, yang muncul hanya tombol **Coba mode demo**. Mode demo memakai satu akun bersama, jadi data beberapa orang di satu perangkat akan tercampur.

## Mengunggah ke GitHub dan memasang di GitHub Pages

```bash
cd web-kelas
git init
git add .
git commit -m "Web kelas pertama"
git branch -M main
git remote add origin https://github.com/USERNAME/web-kelas.git
git push -u origin main
```

Lalu di GitHub: **Settings > Pages > Build and deployment > Source: Deploy from a branch**, pilih branch `main` dan folder `/ (root)`, lalu **Save**. Setelah beberapa menit web bisa dibuka di `https://USERNAME.github.io/web-kelas/`.

## Mencoba suasana waktu

Tambahkan parameter di alamat web:

- `?waktu=pagi`, `?waktu=siang`, `?waktu=sore`, atau `?waktu=malam`
- `?jam=14.5` untuk memilih jam tertentu (0 sampai 24)

Tanpa parameter, web memakai jam asli di perangkat.

## Catatan penting

- **Data tersimpan di browser** (`localStorage`): nama, centang tugas, dan catatan hanya ada di perangkat yang dipakai dan hilang kalau data browser dihapus. Untuk data yang tersimpan di server, hubungkan ke layanan seperti Firebase atau Supabase.
- **Semua isi di `config.js` bersifat publik** karena repo dan halaman GitHub Pages bisa dibaca siapa pun. Jangan menaruh data pribadi siswa di sana.
- **Proteksi salin hanya penghalang ringan.** Orang yang paham teknis tetap bisa membaca kode sumber atau mengambil tangkapan layar.
- Token Google hanya dibaca di sisi browser untuk menampilkan nama dan foto. Kalau suatu saat dipakai untuk hal yang butuh keamanan, token harus diverifikasi di server.
