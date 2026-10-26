# Software Requirements Specification (SRS)
## Student Organizer

| | |
|---|---|
| **Versi** | 0.1 (Draft) |
| **Tanggal** | 26 Oktober 2026 |
| **Acuan** | IEEE 830 (disederhanakan) |
| **Dokumen terkait** | [PRD.md](PRD.md) |

---

## 1. Pendahuluan

### 1.1 Tujuan
Dokumen ini menjabarkan kebutuhan fungsional, non-fungsional, desain data, dan arsitektur teknis aplikasi **Student Organizer** sebagai acuan implementasi dengan **Flutter** dan **Supabase**.

### 1.2 Ruang Lingkup
Aplikasi mobile/web untuk mahasiswa yang mencakup: autentikasi, profil, dashboard, serta 4 fitur utama CRUD — Tugas, Jadwal Kuliah, Catatan, Kegiatan Mahasiswa. Semua data disimpan per pengguna di Supabase PostgreSQL.

### 1.3 Definisi & Singkatan
| Istilah | Arti |
|---|---|
| CRUD | Create (Insert), Read, Update, Delete |
| RLS | Row Level Security — kebijakan akses baris di PostgreSQL/Supabase |
| FAB | Floating Action Button |
| `auth.uid()` | ID pengguna yang sedang login di Supabase |
| FR / NFR | Functional / Non-Functional Requirement |

## 2. Deskripsi Umum

### 2.1 Perspektif Produk
```
┌─────────────────────────┐          HTTPS (REST/PostgREST)       ┌──────────────────────────┐
│  Flutter App            │  ───────────────────────────────────► │  Supabase                │
│  (Android, Web)         │                                       │  ├─ Auth (email/pass)    │
│  supabase_flutter SDK   │  ◄─────────────────────────────────── │  ├─ PostgreSQL + RLS     │
└─────────────────────────┘          JSON + JWT session           │  └─ (Storage: opsional)  │
                                                                  └──────────────────────────┘
```
Tidak ada backend kustom; aplikasi berkomunikasi langsung dengan Supabase melalui SDK. Keamanan data dijamin oleh RLS di database, bukan oleh logika di aplikasi.

### 2.2 Kelas Pengguna
| Kelas | Deskripsi |
|---|---|
| Tamu | Belum login; hanya bisa akses halaman Login/Register. |
| Mahasiswa (terautentikasi) | Akses penuh ke data miliknya sendiri. |

### 2.3 Lingkungan Operasi
- Android 7.0 (API 24) ke atas.
- Browser modern (Chrome, Edge, Firefox versi terbaru) untuk Flutter Web.
- Flutter SDK stable 3.x, Dart 3.x.
- Supabase Cloud (Free tier cukup).

### 2.4 Batasan
- Wajib koneksi internet (tidak ada mode offline).
- Supabase Free tier: project di-pause setelah 1 minggu tidak aktif — perlu di-*resume* sebelum demo.
- `anon key` Supabase boleh ada di aplikasi; **`service_role key` tidak boleh** dimasukkan ke kode aplikasi.

## 3. Arsitektur Teknis

### 3.1 Paket Flutter (usulan)
| Paket | Fungsi |
|---|---|
| `supabase_flutter` | Auth, query database, session persistence |
| `provider` | State management (alternatif: `flutter_riverpod`) |
| `go_router` | Routing deklaratif + redirect berdasarkan status login |
| `intl` | Format tanggal/jam bahasa Indonesia (`id_ID`) |
| `flutter_dotenv` *(opsional)* | Menyimpan URL & anon key di `.env` |

### 3.2 Struktur Folder (feature-first)
Dirancang agar 4 anggota bisa bekerja paralel dengan konflik minimal — setiap orang bekerja di folder fiturnya sendiri.

```
lib/
├── main.dart                     # init Supabase, runApp
├── app.dart                      # MaterialApp.router, tema
├── core/
│   ├── config/supabase_config.dart
│   ├── router/app_router.dart    # semua rute (diubah lewat koordinasi)
│   ├── theme/app_theme.dart
│   ├── utils/validators.dart     # validasi wajib isi, jam selesai > mulai
│   ├── utils/date_formatter.dart
│   └── widgets/                  # EmptyState, ConfirmDeleteDialog, LoadingView, dll.
├── features/
│   ├── auth/        (login, register, profile)
│   ├── dashboard/
│   ├── courses/     (repository mata kuliah — dipakai dropdown)
│   ├── tasks/       ← Novita
│   ├── schedules/   ← Alifah
│   ├── notes/       ← Mifzal
│   └── activities/  ← Audy
│       ├── data/
│       │   ├── models/<entity>.dart          # fromJson / toJson
│       │   └── <entity>_repository.dart      # query Supabase
│       ├── providers/<entity>_provider.dart  # ChangeNotifier
│       └── presentation/
│           ├── <entity>_list_page.dart
│           ├── <entity>_detail_page.dart
│           ├── <entity>_form_page.dart
│           └── widgets/<entity>_card.dart
```

### 3.3 Pola Lapisan
`Page (UI)` → `Provider (state)` → `Repository (akses Supabase)` → `Supabase`.
UI tidak memanggil `Supabase.instance.client` secara langsung.

Contoh repository (Fitur 1):
```dart
class TaskRepository {
  final _db = Supabase.instance.client;

  Future<List<Task>> fetchAll() async {
    final rows = await _db
        .from('tasks')
        .select('*, courses(name)')
        .order('deadline', ascending: true);
    return rows.map(Task.fromJson).toList();
  }

  Future<void> insert(Task t) => _db.from('tasks').insert(t.toInsertJson());
  Future<void> update(Task t) => _db.from('tasks').update(t.toUpdateJson()).eq('id', t.id);
  Future<void> delete(String id) => _db.from('tasks').delete().eq('id', id);
}
```
> `user_id` diisi otomatis oleh `DEFAULT auth.uid()` di database, sehingga aplikasi tidak perlu mengirimkannya.

### 3.4 Rute
| Path | Halaman | Akses |
|---|---|---|
| `/login`, `/register` | Auth | Tamu |
| `/` | Dashboard | Login |
| `/profile` | Profil | Login |
| `/tasks`, `/tasks/new`, `/tasks/:id`, `/tasks/:id/edit` | Fitur 1 | Login |
| `/schedules`, `/schedules/new`, `/schedules/:id`, `/schedules/:id/edit` | Fitur 2 | Login |
| `/notes`, `/notes/new`, `/notes/:id`, `/notes/:id/edit` | Fitur 3 | Login |
| `/activities`, `/activities/new`, `/activities/:id`, `/activities/:id/edit` | Fitur 4 | Login |

`go_router` `redirect`: jika belum login → `/login`; jika sudah login dan membuka `/login` → `/`. Router mendengarkan `onAuthStateChange` agar logout langsung mengarahkan ke Login.

## 4. Kebutuhan Fungsional

Prioritas: **M** = Must, **S** = Should, **C** = Could.

### 4.1 Autentikasi & Profil (FR-AUTH)
| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-AUTH-01 | Sistem menyediakan registrasi dengan nama lengkap, email, dan password (min. 6 karakter). | M |
| FR-AUTH-02 | Sistem menyediakan login email & password via Supabase Auth. | M |
| FR-AUTH-03 | Sesi login tersimpan; aplikasi langsung membuka Dashboard jika sesi masih valid. | M |
| FR-AUTH-04 | Pengguna dapat logout dari halaman Profil. | M |
| FR-AUTH-05 | Saat registrasi, baris `profiles` dibuat otomatis (trigger database). | M |
| FR-AUTH-06 | Pengguna dapat melihat & mengubah nama lengkap, NIM, program studi. | S |
| FR-AUTH-07 | Pesan error login ditampilkan dalam bahasa Indonesia (mis. "Email atau password salah"). | S |

> Catatan: matikan *Confirm email* di Supabase Auth Settings selama pengembangan agar registrasi langsung bisa login.

### 4.2 Dashboard (FR-DASH)
| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-DASH-01 | Menampilkan sapaan dengan nama pengguna. | S |
| FR-DASH-02 | Menampilkan maks. 3 tugas belum selesai dengan deadline terdekat. | M |
| FR-DASH-03 | Menampilkan jadwal kuliah hari ini (berdasarkan hari perangkat). | M |
| FR-DASH-04 | Menampilkan maks. 3 catatan terakhir diperbarui. | S |
| FR-DASH-05 | Menampilkan maks. 3 kegiatan mendatang (tanggal ≥ hari ini). | M |
| FR-DASH-06 | Setiap bagian memiliki tautan "Lihat semua" ke halaman fitur terkait. | M |
| FR-DASH-07 | Ringkasan ditampilkan sebagai carousel `PageView` atau kartu bertumpuk. | C |

### 4.3 Mata Kuliah — pendukung dropdown (FR-CRS)
| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-CRS-01 | Saat jadwal kuliah disimpan, nama mata kuliah otomatis ditambahkan ke tabel `courses` jika belum ada (upsert berdasarkan `user_id + name`). | M |
| FR-CRS-02 | Dropdown mata kuliah pada form Tugas dan Catatan mengambil data dari `courses` milik pengguna. | M |
| FR-CRS-03 | Dropdown menyediakan opsi "+ Tambah mata kuliah baru" untuk mengisi nama secara manual bila belum ada jadwal. | S |

### 4.4 Fitur 1 — Task Management (FR-TASK) · PJ: Novita
| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-TASK-01 | **Read:** Menampilkan daftar tugas dengan `ListView`; tiap card berisi nama tugas, mata kuliah, deadline, dan status (chip berwarna). | M |
| FR-TASK-02 | Daftar diurutkan berdasarkan deadline terdekat; tugas berstatus *Selesai* diletakkan paling bawah. | S |
| FR-TASK-03 | Card tugas yang deadline-nya sudah lewat dan belum selesai diberi penanda "Terlambat". | S |
| FR-TASK-04 | Filter berdasarkan status (Semua / Belum / Sedang / Selesai). | C |
| FR-TASK-05 | **Detail:** Menampilkan nama tugas, mata kuliah, deskripsi, deadline, dan status secara lengkap, dengan tombol Edit & Hapus. | M |
| FR-TASK-06 | **Insert:** FAB (+) membuka form tambah: `TextFormField` nama & deskripsi, `DropdownButtonFormField` mata kuliah & status, date picker deadline. | M |
| FR-TASK-07 | **Update:** Form edit terisi data lama; menyimpan memperbarui baris di Supabase. | M |
| FR-TASK-08 | **Delete:** Hapus dari card atau detail setelah dialog konfirmasi. | M |
| FR-TASK-09 | Validasi: nama tugas, mata kuliah, deadline, status wajib diisi. | M |

### 4.5 Fitur 2 — Jadwal Kuliah (FR-SCH) · PJ: Alifah
| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-SCH-01 | **Read:** Menampilkan daftar jadwal dengan `ListView`; card berisi nama mata kuliah, hari, jam mulai–selesai, ruangan, dosen. | M |
| FR-SCH-02 | Daftar diurutkan berdasarkan hari (Senin→Minggu) lalu jam mulai. | M |
| FR-SCH-03 | Filter berdasarkan hari (`ChoiceChip`/`TabBar`: Semua, Senin … Minggu). | S |
| FR-SCH-04 | **Detail:** Menampilkan informasi lengkap dengan tombol Edit dan Hapus. | M |
| FR-SCH-05 | **Insert:** FAB (+) membuka form: `TextFormField` mata kuliah, ruangan, dosen; `DropdownButtonFormField` hari; time picker jam mulai & selesai; tombol Simpan. | M |
| FR-SCH-06 | **Update:** Form edit terisi data lama. | M |
| FR-SCH-07 | **Delete:** Dengan dialog konfirmasi. | M |
| FR-SCH-08 | Validasi: semua field wajib; **jam selesai harus lebih besar dari jam mulai**. | M |
| FR-SCH-09 | Peringatan (bukan blokir) jika jadwal bentrok dengan jadwal lain di hari yang sama. | C |

### 4.6 Fitur 3 — Catatan (FR-NOTE) · PJ: Mifzal
| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-NOTE-01 | **Read:** Menampilkan daftar catatan dengan `GridView` (2 kolom di HP, 3–4 di layar lebar) dengan opsi beralih ke `ListView`. | M |
| FR-NOTE-02 | Card menampilkan judul, nama mata kuliah, cuplikan isi (maks. 3 baris), dan tanggal dibuat/diperbarui. | M |
| FR-NOTE-03 | Urutan default: terakhir diperbarui di atas. | S |
| FR-NOTE-04 | Pencarian berdasarkan judul/isi, dan filter per mata kuliah. | C |
| FR-NOTE-05 | **Detail:** Menampilkan judul, mata kuliah, tanggal, dan seluruh isi; menggunakan `PageView` sehingga pengguna dapat swipe ke catatan sebelum/sesudahnya. | M |
| FR-NOTE-06 | Detail memiliki tombol/menu Edit dan Hapus. | M |
| FR-NOTE-07 | **Insert:** FAB (+) membuka form: `TextFormField` judul & isi (multiline), `DropdownButtonFormField` mata kuliah, date picker tanggal catatan. | M |
| FR-NOTE-08 | **Update:** Form edit terisi data lama; kolom `updated_at` diperbarui otomatis. | M |
| FR-NOTE-09 | **Delete:** Dengan dialog konfirmasi. | M |
| FR-NOTE-10 | Validasi: judul, mata kuliah, tanggal, isi wajib diisi. | M |

### 4.7 Fitur 4 — Kegiatan Mahasiswa (FR-ACT) · PJ: Audy
| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-ACT-01 | **Read:** Menampilkan daftar kegiatan dengan `ListView`; card berisi nama kegiatan, tanggal, waktu, lokasi, penyelenggara. | M |
| FR-ACT-02 | Kegiatan mendatang ditampilkan lebih dulu (urut tanggal naik); kegiatan yang sudah lewat dikelompokkan di bagian "Selesai". | S |
| FR-ACT-03 | **Detail:** Menampilkan nama, tanggal, waktu mulai & selesai, lokasi, penyelenggara, deskripsi, dengan tombol Edit & Hapus. | M |
| FR-ACT-04 | **Insert:** Tombol tambah membuka form: `TextFormField` nama, lokasi, penyelenggara, deskripsi; date picker tanggal; time picker waktu mulai & selesai; tombol Simpan. | M |
| FR-ACT-05 | **Update:** Form edit terisi data lama. | M |
| FR-ACT-06 | **Delete:** Dengan dialog konfirmasi. | M |
| FR-ACT-07 | Validasi: semua field kecuali deskripsi wajib; **waktu selesai harus lebih besar dari waktu mulai**. | M |
| FR-ACT-08 | Kategori kegiatan (Seminar / Rapat / Kepanitiaan / Acara Kampus / Lainnya). | C |

### 4.8 Perilaku Umum CRUD (berlaku untuk semua fitur)
| ID | Kebutuhan |
|---|---|
| FR-GEN-01 | Halaman daftar menampilkan `CircularProgressIndicator` saat memuat, pesan error + tombol "Coba lagi" bila gagal, dan empty state bila kosong. |
| FR-GEN-02 | Halaman daftar mendukung pull-to-refresh (`RefreshIndicator`). |
| FR-GEN-03 | Setelah insert/update/delete berhasil, daftar diperbarui tanpa perlu restart dan muncul `SnackBar` konfirmasi. |
| FR-GEN-04 | Tombol Simpan dinonaktifkan dan menampilkan loading selama request berlangsung (mencegah submit ganda). |
| FR-GEN-05 | Form yang sama dipakai untuk Tambah dan Edit (mode ditentukan oleh ada/tidaknya objek awal). |

## 5. Desain Data (Supabase PostgreSQL)

### 5.1 ERD
```
auth.users (Supabase)
    │ 1
    ├──────────── 1  profiles
    │ 1
    ├──────────── *  courses ─┬── 1 ──── *  tasks
    │                         └── 1 ──── *  notes
    ├──────────── *  schedules   (course_id → courses, juga menyimpan nama)
    ├──────────── *  tasks
    ├──────────── *  notes
    └──────────── *  activities
```

### 5.2 Kamus Data

**profiles**
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | = `auth.users.id` |
| full_name | text | |
| nim | text | nullable |
| study_program | text | nullable |
| created_at | timestamptz | default now() |

**courses**
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | default `auth.uid()` |
| name | text | unik per user |

**tasks** (Fitur 1)
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | default `auth.uid()` |
| course_id | uuid FK → courses | `on delete set null` |
| title | text | wajib |
| description | text | nullable |
| deadline | timestamptz | wajib |
| status | `task_status` enum | `belum`, `sedang`, `selesai` |
| created_at / updated_at | timestamptz | |

**schedules** (Fitur 2)
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | default `auth.uid()` |
| course_id | uuid FK → courses | |
| course_name | text | wajib |
| day_of_week | smallint | 1 = Senin … 7 = Minggu |
| start_time | time | wajib |
| end_time | time | wajib, `> start_time` |
| room | text | wajib |
| lecturer | text | wajib |
| created_at / updated_at | timestamptz | |

**notes** (Fitur 3)
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | default `auth.uid()` |
| course_id | uuid FK → courses | `on delete set null` |
| title | text | wajib |
| content | text | wajib |
| note_date | date | wajib |
| created_at / updated_at | timestamptz | |

**activities** (Fitur 4)
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK | default `auth.uid()` |
| name | text | wajib |
| activity_date | date | wajib |
| start_time | time | wajib |
| end_time | time | wajib, `> start_time` |
| location | text | wajib |
| organizer | text | wajib |
| description | text | nullable |
| created_at / updated_at | timestamptz | |

### 5.3 Skrip SQL (jalankan di Supabase → SQL Editor)

```sql
-- ===== Enum =====
create type task_status as enum ('belum', 'sedang', 'selesai');

-- ===== Profiles =====
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  nim text,
  study_program text,
  created_at timestamptz not null default now()
);

-- Buat profil otomatis saat user mendaftar
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''));
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ===== Courses =====
create table public.courses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

-- ===== Tasks (Fitur 1) =====
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  course_id uuid references public.courses(id) on delete set null,
  title text not null check (length(trim(title)) > 0),
  description text,
  deadline timestamptz not null,
  status task_status not null default 'belum',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ===== Schedules (Fitur 2) =====
create table public.schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  course_id uuid references public.courses(id) on delete set null,
  course_name text not null,
  day_of_week smallint not null check (day_of_week between 1 and 7),
  start_time time not null,
  end_time time not null,
  room text not null,
  lecturer text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time)
);

-- ===== Notes (Fitur 3) =====
create table public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  course_id uuid references public.courses(id) on delete set null,
  title text not null check (length(trim(title)) > 0),
  content text not null,
  note_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ===== Activities (Fitur 4) =====
create table public.activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  activity_date date not null,
  start_time time not null,
  end_time time not null,
  location text not null,
  organizer text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time)
);

-- ===== updated_at otomatis =====
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

create trigger trg_tasks_updated      before update on public.tasks      for each row execute function public.set_updated_at();
create trigger trg_schedules_updated  before update on public.schedules  for each row execute function public.set_updated_at();
create trigger trg_notes_updated      before update on public.notes      for each row execute function public.set_updated_at();
create trigger trg_activities_updated before update on public.activities for each row execute function public.set_updated_at();

-- ===== Index =====
create index on public.tasks (user_id, deadline);
create index on public.schedules (user_id, day_of_week, start_time);
create index on public.notes (user_id, updated_at desc);
create index on public.activities (user_id, activity_date);

-- ===== Row Level Security =====
alter table public.profiles   enable row level security;
alter table public.courses    enable row level security;
alter table public.tasks      enable row level security;
alter table public.schedules  enable row level security;
alter table public.notes      enable row level security;
alter table public.activities enable row level security;

create policy "own profile" on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

create policy "own rows" on public.courses    for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own rows" on public.tasks      for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own rows" on public.schedules  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own rows" on public.notes      for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own rows" on public.activities for all using (user_id = auth.uid()) with check (user_id = auth.uid());
```

### 5.4 Pemetaan Operasi CRUD → Supabase
| Operasi | Kode Dart (contoh: `notes`) |
|---|---|
| Read (list) | `.from('notes').select('*, courses(name)').order('updated_at', ascending: false)` |
| Read (detail) | `.from('notes').select('*, courses(name)').eq('id', id).single()` |
| Insert | `.from('notes').insert({...})` |
| Update | `.from('notes').update({...}).eq('id', id)` |
| Delete | `.from('notes').delete().eq('id', id)` |
| Upsert course (FR-CRS-01) | `.from('courses').upsert({'name': n}, onConflict: 'user_id,name').select().single()` |

## 6. Kebutuhan Antarmuka

### 6.1 Antarmuka Pengguna
- Material 3 (`useMaterial3: true`), satu `ColorScheme.fromSeed`.
- Navigasi utama: `NavigationBar` (HP) / `NavigationRail` (lebar layar ≥ 840 px).
- Format tanggal: `Senin, 26 Okt 2026`; jam: `08.00` (locale `id_ID`).
- Status tugas: chip abu-abu (Belum), kuning (Sedang), hijau (Selesai), merah untuk penanda Terlambat.

### 6.2 Antarmuka Perangkat Lunak
- Supabase REST (PostgREST) & Auth melalui `supabase_flutter`.
- Konfigurasi: `SUPABASE_URL` dan `SUPABASE_ANON_KEY`.

## 7. Kebutuhan Non-Fungsional

| ID | Kategori | Kebutuhan |
|---|---|---|
| NFR-01 | Keamanan | RLS aktif di seluruh tabel; pengguna hanya dapat membaca/mengubah baris miliknya. |
| NFR-02 | Keamanan | `service_role key` tidak pernah disertakan di aplikasi atau repositori. |
| NFR-03 | Keamanan | File `.env` / kredensial dimasukkan ke `.gitignore`. |
| NFR-04 | Performa | Halaman daftar tampil < 2 detik pada koneksi 4G untuk ≤ 200 item. |
| NFR-05 | Usabilitas | Setiap aksi destruktif membutuhkan konfirmasi; setiap aksi memberikan feedback. |
| NFR-06 | Portabilitas | Aplikasi berjalan di Android dan Web dari satu codebase tanpa kode khusus platform. |
| NFR-07 | Responsif | Tata letak menyesuaikan lebar layar (HP, tablet, desktop browser). |
| NFR-08 | Keandalan | Error jaringan ditangkap (`try/catch` pada `PostgrestException`/`AuthException`) dan ditampilkan sebagai pesan ramah, bukan crash. |
| NFR-09 | Maintainability | Struktur feature-first; `flutter analyze` tanpa error; penamaan konsisten. |
| NFR-10 | Lokalisasi | Seluruh teks UI dalam Bahasa Indonesia. |

## 8. Skenario Pengujian (Acceptance Criteria)

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| TC-01 | Register akun baru lalu login | Masuk ke Dashboard; baris `profiles` terbentuk. |
| TC-02 | Buka ulang aplikasi setelah login | Langsung ke Dashboard. |
| TC-03 | Login dengan password salah | Pesan error, tetap di halaman Login. |
| TC-04 | Tambah tugas tanpa nama | Validasi "Nama tugas wajib diisi", data tidak terkirim. |
| TC-05 | Tambah tugas valid | Muncul di daftar, urut sesuai deadline; SnackBar berhasil. |
| TC-06 | Ubah status tugas ke Selesai | Chip berubah hijau; tugas pindah ke bawah daftar. |
| TC-07 | Tambah jadwal jam 10.00–09.00 | Ditolak: "Jam selesai harus setelah jam mulai". |
| TC-08 | Tambah jadwal "Basis Data" | Muncul di daftar jadwal & "Basis Data" tersedia di dropdown Tugas/Catatan. |
| TC-09 | Filter jadwal hari Rabu | Hanya jadwal Rabu yang tampil. |
| TC-10 | Swipe di Detail Catatan | Berpindah ke catatan berikutnya/sebelumnya. |
| TC-11 | Edit catatan | Isi berubah; tanggal diperbarui berubah. |
| TC-12 | Tambah kegiatan waktu selesai < mulai | Ditolak oleh validasi form. |
| TC-13 | Hapus kegiatan, pilih "Batal" di dialog | Data tetap ada. |
| TC-14 | Login sebagai User B | Tidak melihat data apa pun milik User A. |
| TC-15 | Matikan internet lalu buka daftar | Pesan error + tombol Coba lagi; tidak crash. |
| TC-16 | Jalankan di Android & Web | Semua TC di atas lulus di kedua platform. |

## 9. Rencana Implementasi & Pembagian Kerja

| Tahap | Pekerjaan | PJ |
|---|---|---|
| 0. Fondasi | `flutter create`, setup Supabase project + SQL §5.3, `main.dart`, tema, router, auth, shell navigasi, widget umum (`core/`) | Ketua + semua (pair) |
| 1. Model & Repository | Model + repository per fitur | Masing-masing |
| 2. Halaman Daftar | List/Grid + card + empty/loading/error state | Masing-masing |
| 3. Form Tambah/Edit | Validasi + simpan ke Supabase | Masing-masing |
| 4. Halaman Detail | Detail + Edit/Hapus (+ PageView) | Masing-masing |
| 5. Integrasi | Dashboard menarik data 4 fitur; dropdown mata kuliah; profil | Ketua + semua |
| 6. Uji & Rilis | Jalankan TC-01…16 di Android & Web; build APK & web | Semua |

**Konvensi kolaborasi (Git):**
- Branch per fitur: `feat/tasks`, `feat/schedules`, `feat/notes`, `feat/activities`.
- File di `core/` dan `app_router.dart` hanya diubah lewat Pull Request yang di-review anggota lain.
- Satu project Supabase dipakai bersama; perubahan skema ditulis sebagai file SQL di `supabase/migrations/` agar tercatat.

## 10. Lampiran — Pemetaan Proposal → SRS

| Proposal | Bagian SRS |
|---|---|
| Fitur 1: Task Management — List, Detail, Form | §4.4, tabel `tasks` |
| Fitur 2: Jadwal Kuliah — List + filter hari, Detail, Form + validasi jam | §4.5, tabel `schedules` |
| Fitur 3: Catatan — Grid/List + PageView, Detail, Form multiline | §4.6, tabel `notes` |
| Fitur 4: Kegiatan Mahasiswa — List, Detail, Form + validasi waktu | §4.7, tabel `activities` |
| Login & Profil (non-fitur utama) | §4.1, tabel `profiles` |
| Halaman Utama / Dashboard | §4.2 |
| Operasi Read, Insert, Update, Delete (Supabase) | §3.3, §5.4 |
