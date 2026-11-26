create table if not exists public.closed_days (
 id uuid primary key default gen_random_uuid(),
 closed_date date not null unique,
 reason text not null default 'Día de descanso' check (char_length(reason) between 1 and 120),
 created_at timestamptz not null default now()
);
create index if not exists closed_days_date_idx on public.closed_days (closed_date);
alter table public.closed_days enable row level security;
grant select on table public.closed_days to anon, authenticated;
grant select, insert, update, delete on table public.closed_days to service_role;
