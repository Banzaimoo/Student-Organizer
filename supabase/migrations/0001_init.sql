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
