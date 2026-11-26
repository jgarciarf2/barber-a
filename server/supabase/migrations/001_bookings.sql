create extension if not exists pgcrypto;
create table if not exists public.bookings (
 id uuid primary key default gen_random_uuid(),
 customer_name text not null,
 customer_phone text not null,
 service text not null check (service in ('Corte clásico','Corte y barba','Arreglo de barba')),
 price_cop integer not null check (price_cop > 0),
 appointment_date date not null,
 appointment_time time not null,
 status text not null default 'confirmed' check (status in ('confirmed','cancelled')),
 privacy_accepted boolean not null default false check (privacy_accepted = true),
 created_at timestamptz not null default now(),
 constraint no_duplicate_active_slot unique (appointment_date, appointment_time, status)
);
create index if not exists bookings_date_status_idx on public.bookings (appointment_date, status);
alter table public.bookings enable row level security;
-- No policies: browser clients cannot read/write bookings. The API uses service role server-side only.
