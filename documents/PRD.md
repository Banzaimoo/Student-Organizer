# Product Requirements Document (PRD)
## Student Organizer

| | |
|---|---|
| **Versi** | 0.1 (Draft) |
| **Tanggal** | 26 Oktober 2026 |
| **Mata Kuliah** | Pengembangan Aplikasi Multiplatform |
| **Tech stack** | Flutter (frontend) · Supabase (Auth + PostgreSQL) |
| **Status** | Draft — menunggu validasi dosen pengampu (Progress 1) |
| **Dokumen terkait** | [SRS.md](SRS.md) |

---

## 1. Ringkasan Produk

**Student Organizer** adalah aplikasi multiplatform yang membantu mahasiswa mengelola aktivitas perkuliahan dalam satu platform: mencatat tugas, mengatur jadwal kuliah, menyimpan catatan materi, dan mengelola kegiatan mahasiswa. Tujuannya agar aktivitas akademik dan nonakademik mahasiswa menjadi lebih terorganisir.

## 2. Latar Belakang & Masalah

Mahasiswa umumnya menyebar informasi perkuliahan di banyak tempat — tugas di grup chat, jadwal di foto/screenshot KRS, catatan di buku atau aplikasi notes terpisah, dan info kegiatan di poster/Instagram. Akibatnya:

- Deadline tugas sering terlewat karena tidak tercatat di satu tempat.
- Sulit melihat jadwal kuliah hari ini secara cepat (ruangan, jam, dosen).
- Catatan materi tercecer dan tidak terhubung ke mata kuliahnya.
- Kegiatan seminar/rapat/kepanitiaan bentrok dengan jadwal lain karena tidak terlihat bersamaan.

## 3. Tujuan Produk

| ID | Tujuan |
|---|---|
| G-1 | Menyediakan satu aplikasi untuk tugas, jadwal, catatan, dan kegiatan mahasiswa. |
| G-2 | Data tersimpan di cloud (Supabase) sehingga bisa diakses dari minimal 2 platform dengan akun yang sama. |
| G-3 | Setiap fitur utama mendukung operasi CRUD penuh (Read, Insert, Update, Delete). |
| G-4 | Dashboard memberi ringkasan cepat: tugas terdekat, jadwal hari ini, catatan terbaru, kegiatan mendatang. |

### Non-Goals (di luar cakupan versi ini)
- Kolaborasi/berbagi data antar pengguna (misal tugas kelompok bersama).
- Integrasi dengan SIAKAD / sistem akademik kampus.
- Push notification / reminder terjadwal (kandidat pengembangan lanjutan).
- Mode offline penuh dengan sinkronisasi.
- Lampiran file/gambar pada catatan.

## 4. Target Pengguna

**Persona utama — "Mahasiswa aktif"**
- Mahasiswa S1, mengambil 6–10 mata kuliah per semester.
- Aktif di organisasi/kepanitiaan.
- Menggunakan smartphone Android sebagai perangkat utama, sesekali laptop (browser).
- Kebutuhan: tahu *apa yang harus dikerjakan* dan *di mana harus berada* hari ini.

## 5. Target Platform

Proposal mensyaratkan **minimal 2 platform**. Usulan:

| Platform | Alasan |
|---|---|
| **Android** (utama) | Perangkat mayoritas mahasiswa; bisa diuji di emulator/HP tanpa biaya. |
| **Web** | Bisa diakses dari laptop; tidak butuh Mac (berbeda dengan iOS). |

> ⚠️ **Keputusan tim diperlukan:** Jika ada anggota dengan Mac, iOS bisa ditambahkan sebagai platform ke-3. Windows desktop juga memungkinkan.

## 6. Tim & Kepemilikan Fitur

| No | Nama | NIM | Tanggung Jawab |
|---|---|---|---|
| 1 | Novita Azka Maghfira (Ketua) | 245150407111078 | Fitur 1 — Task Management |
| 2 | Alifah Putri Rhandiny | 245150401111047 | Fitur 2 — Jadwal Kuliah |
| 3 | Mifzal Arif Maulana | 245150400111016 | Fitur 3 — Catatan (Notes) |
| 4 | Audy Fitrah Habibie | 235150400111018 | Fitur 4 — Kegiatan Mahasiswa |

> Fitur **Login** dan **Profil** tidak dihitung sebagai fitur utama, tetapi wajib ada karena data per pengguna. Usulan: dikerjakan bersama di awal (fondasi proyek) oleh ketua, atau dibagi rata.

## 7. Ruang Lingkup Fitur

### 7.0 Fondasi (non-fitur utama)
- **Autentikasi**: register, login, logout dengan email & password (Supabase Auth).
- **Profil**: lihat & ubah nama lengkap, NIM, program studi.
- **Dashboard / Halaman Utama**: ringkasan dari 4 fitur + navigasi ke tiap fitur.

### 7.1 Fitur 1 — Task Management
Mengelola tugas kuliah: mencatat tugas baru, melihat detail, mengubah, dan menghapus tugas.

| Atribut data | Keterangan |
|---|---|
| Nama tugas | wajib |
| Mata kuliah | wajib, dipilih dari dropdown |
| Deskripsi | opsional |
| Deadline | wajib, date picker |
| Status pengerjaan | wajib: *Belum Dikerjakan / Sedang Dikerjakan / Selesai* |

**Halaman:** Daftar Tugas (ListView + FAB) → Detail Tugas → Form Tambah/Edit Tugas.

### 7.2 Fitur 2 — Jadwal Kuliah
Mengelola jadwal perkuliahan mingguan.

| Atribut data | Keterangan |
|---|---|
| Nama mata kuliah | wajib |
| Hari | wajib, dropdown Senin–Minggu |
| Jam mulai & jam selesai | wajib, time picker; jam selesai > jam mulai |
| Ruangan | wajib |
| Nama dosen | wajib |

**Halaman:** Daftar Jadwal (ListView + filter hari + FAB) → Detail Jadwal (tombol Edit & Hapus) → Form Tambah/Edit Jadwal.

### 7.3 Fitur 3 — Catatan (Notes)
Menyimpan dan mengelola catatan materi perkuliahan.

| Atribut data | Keterangan |
|---|---|
| Judul catatan | wajib |
| Mata kuliah | wajib, dropdown |
| Tanggal catatan | wajib, date picker |
| Isi catatan | wajib, multiline |
| Tanggal dibuat / diperbarui | otomatis |

**Halaman:** Daftar Catatan (GridView/ListView + FAB) → Detail Catatan (PageView, tombol Edit & Hapus) → Form Tambah/Edit Catatan.

### 7.4 Fitur 4 — Kegiatan Mahasiswa
Mengelola kegiatan akademik/nonakademik: seminar, rapat organisasi, kepanitiaan, acara kampus.

| Atribut data | Keterangan |
|---|---|
| Nama kegiatan | wajib |
| Tanggal | wajib, date picker |
| Waktu mulai & selesai | wajib, time picker; selesai > mulai |
| Lokasi | wajib |
| Penyelenggara | wajib |
| Deskripsi | opsional |

**Halaman:** Daftar Kegiatan (ListView + tombol tambah) → Detail Kegiatan (tombol Edit & Hapus) → Form Tambah/Edit Kegiatan.

## 8. Alur Navigasi

```
[Splash] ──► [Login] ◄──► [Register]
                │
                ▼
[Halaman Utama / Dashboard] ──► [Profil]
   │
   ├──► [Fitur 1: Tugas]
   │       ├──► [Detail Tugas]
   │       └──► [Form Tambah / Edit Tugas]
   ├──► [Fitur 2: Jadwal Kuliah]
   │       ├──► [Daftar Jadwal Kuliah]
   │       ├──► [Detail Jadwal Kuliah]
   │       └──► [Form Tambah / Edit Jadwal Kuliah]
   ├──► [Fitur 3: Catatan]
   │       ├──► [Daftar Catatan]
   │       ├──► [Detail Catatan]
   │       └──► [Form Tambah / Edit Catatan]
   └──► [Fitur 4: Kegiatan Mahasiswa]
           ├──► [Detail Kegiatan]
           └──► [Form Tambah / Edit Kegiatan]
```

Usulan navigasi utama: **Bottom Navigation Bar** dengan 5 tab — Beranda, Tugas, Jadwal, Catatan, Kegiatan. Profil diakses dari ikon di AppBar Beranda.

## 9. User Stories

### Fondasi
- **US-01** Sebagai mahasiswa, saya ingin mendaftar dengan email dan password agar data saya tersimpan di akun saya.
- **US-02** Sebagai mahasiswa, saya ingin tetap login saat membuka ulang aplikasi agar tidak perlu login berulang.
- **US-03** Sebagai mahasiswa, saya ingin melihat ringkasan hari ini di dashboard agar tahu prioritas saya.
- **US-04** Sebagai mahasiswa, saya ingin mengubah profil (nama, NIM, prodi).

### Fitur 1 — Tugas
- **US-11** Saya ingin menambah tugas beserta mata kuliah dan deadline-nya.
- **US-12** Saya ingin melihat daftar tugas terurut berdasarkan deadline terdekat.
- **US-13** Saya ingin mengubah status tugas menjadi "Selesai" setelah dikerjakan.
- **US-14** Saya ingin menghapus tugas yang tidak diperlukan, dengan konfirmasi terlebih dahulu.

### Fitur 2 — Jadwal
- **US-21** Saya ingin memasukkan jadwal kuliah mingguan (hari, jam, ruangan, dosen).
- **US-22** Saya ingin memfilter jadwal berdasarkan hari.
- **US-23** Saya ingin dicegah menyimpan jadwal dengan jam selesai lebih awal dari jam mulai.

### Fitur 3 — Catatan
- **US-31** Saya ingin menulis catatan materi panjang dan mengaitkannya ke mata kuliah.
- **US-32** Saya ingin melihat catatan dalam tampilan grid agar mudah dipindai.
- **US-33** Saya ingin menggeser (swipe) antar catatan di halaman detail.

### Fitur 4 — Kegiatan
- **US-41** Saya ingin mencatat kegiatan beserta tanggal, waktu, lokasi, dan penyelenggara.
- **US-42** Saya ingin melihat kegiatan yang akan datang terlebih dahulu.
- **US-43** Saya ingin mengubah atau menghapus kegiatan yang batal/berubah.

## 10. Kebutuhan UX Umum

- Material Design 3, satu tema warna konsisten (light mode wajib, dark mode opsional).
- Setiap aksi hapus menampilkan dialog konfirmasi.
- Setiap operasi simpan/hapus menampilkan feedback (SnackBar) berhasil/gagal.
- State kosong (empty state) dengan ilustrasi/teks ajakan, misal "Belum ada tugas. Tekan + untuk menambah."
- Indikator loading saat mengambil data dari Supabase.
- Pull-to-refresh di setiap halaman daftar.
- Tampilan responsif: di web/layar lebar, daftar memakai Grid dengan lebih banyak kolom.

## 11. Metrik Keberhasilan (untuk penilaian proyek)

| Metrik | Target |
|---|---|
| Fitur utama dengan CRUD berfungsi | 4/4 |
| Platform yang berhasil di-build & dijalankan | ≥ 2 |
| Halaman sesuai alur navigasi proposal | 100% |
| Validasi form sesuai spesifikasi | 100% field wajib & aturan waktu |
| Data terisolasi per pengguna (RLS) | Pengguna A tidak bisa melihat data pengguna B |

## 12. Asumsi & Keputusan Terbuka

| # | Topik | Usulan default | Perlu konfirmasi |
|---|---|---|---|
| A-1 | Platform kedua | Web | Tim |
| A-2 | Sumber dropdown mata kuliah (Tugas & Catatan) | Tabel `courses` milik user, otomatis terisi dari Jadwal Kuliah, bisa juga ditambah manual | Tim |
| A-3 | State management | Provider (sederhana, umum di perkuliahan) | Tim / dosen |
| A-4 | Penggunaan PageView | Halaman detail bisa di-swipe ke item sebelum/sesudahnya | Tim |
| A-5 | Login dengan Google | Tidak di versi ini | Tim |

## 13. Milestone (usulan)

| Tahap | Isi | Output |
|---|---|---|
| Progress 1 | Proposal, pembagian tugas, alur navigasi | ✅ Proposal |
| Minggu 1 | Setup proyek Flutter, Supabase project, skema DB + RLS, auth, struktur folder, routing, dashboard kosong | Fondasi siap; tiap anggota bisa mulai |
| Minggu 2–3 | Pengembangan paralel 4 fitur (Daftar → Form → Detail) | CRUD per fitur |
| Minggu 4 | Integrasi dashboard, profil, polishing UI, uji di 2 platform | Release candidate |
| Final | Demo, laporan, APK + build web | Rilis |
