-- Migration: Initial Schema for Invoixa

-- 1. Create Helper Function to auto-update 'updated_at' timestamps
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 2. USERS TABLE
create table if not exists public.users (
  id uuid references auth.users(id) on delete cascade primary key default auth.uid(),
  name text not null,
  business_name text default '',
  phone text default '',
  email text not null,
  app_status text not null default 'allowed' check (app_status in ('allowed', 'banned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()

);

-- Trigger for users updated_at
create trigger set_users_updated_at
before update on public.users
for each row execute function public.handle_updated_at();

-- 3. PROJECTS TABLE
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade default auth.uid(),
  client_name text not null default '',
  brand_name text default '',
  date_from date,
  date_to date,
  total_no_of_tasks integer not null default 0,
  total_payment numeric(12,2) not null default 0.00,
  paid_amount numeric(12,2) not null default 0.00,
  services jsonb not null default '[]'::jsonb,
  shared_with jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger for projects updated_at
create trigger set_projects_updated_at
before update on public.projects
for each row execute function public.handle_updated_at();

-- 4. TASKS TABLE
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade default auth.uid(),
  task_name text not null,
  status text not null default 'pending' check (status in ('started', 'pending', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger for tasks updated_at
create trigger set_tasks_updated_at
before update on public.tasks
for each row execute function public.handle_updated_at();

-- 5. PAYMENT ENTRIES TABLE
create table if not exists public.payment_entries (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade default auth.uid(),
  account_no text default '',
  payment_method text not null default 'Bank Transfer',
  currency_type text not null default 'USD',
  discount_adjustments numeric(12,2) not null default 0.00,
  payment_amount numeric(12,2) not null default 0.00,
  created_at timestamptz not null default now()
);

-- 6. PREDEFINED SERVICES TABLE
create table if not exists public.predefined_services (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade default auth.uid(),
  name text not null,
  description text default '',
  default_price numeric(12,2) not null default 0.00,
  created_at timestamptz not null default now()
);

-- 7. ROW LEVEL SECURITY (RLS) SETUP
alter table public.users enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.payment_entries enable row level security;
alter table public.predefined_services enable row level security;

-- RLS Policies for USERS
create policy "Users can view profile" on public.users
  for select using (
    auth.uid() = id OR id in (
      select (jsonb_array_elements(shared_with)->>'user_id')::uuid from public.projects
    )
  );

create policy "Users can update own profile" on public.users
  for update using (auth.uid() = id);

create policy "Users can insert own profile" on public.users
  for insert with check (auth.uid() = id);

-- RLS Policies for PROJECTS
create policy "Owners or shared users can view projects" on public.projects
  for select using (
    auth.uid() = user_id OR exists (
      select 1 from jsonb_array_elements(shared_with) elem
      where (elem->>'user_id')::uuid = auth.uid()
    )
  );

create policy "Owners can insert projects" on public.projects
  for insert with check (auth.uid() = user_id);

create policy "Owners can update projects" on public.projects
  for update using (auth.uid() = user_id);

create policy "Owners can delete projects" on public.projects
  for delete using (auth.uid() = user_id);

-- RLS Policies for TASKS
create policy "Owners or shared users with tasks access can view tasks" on public.tasks
  for select using (
    auth.uid() = user_id OR exists (
      select 1 from public.projects p, jsonb_array_elements(p.shared_with) elem
      where p.id = tasks.project_id
      and (elem->>'user_id')::uuid = auth.uid()
      and elem->>'visibility' in ('all', 'tasks')
    )
  );

create policy "Owners can insert tasks" on public.tasks
  for insert with check (auth.uid() = user_id);

create policy "Owners can update tasks" on public.tasks
  for update using (auth.uid() = user_id);

create policy "Owners can delete tasks" on public.tasks
  for delete using (auth.uid() = user_id);

-- RLS Policies for PAYMENT ENTRIES
create policy "Owners or shared users with payments access can view payment entries" on public.payment_entries
  for select using (
    auth.uid() = user_id OR exists (
      select 1 from public.projects p, jsonb_array_elements(p.shared_with) elem
      where p.id = payment_entries.project_id
      and (elem->>'user_id')::uuid = auth.uid()
      and elem->>'visibility' in ('all', 'payments')
    )
  );

create policy "Owners can insert payment entries" on public.payment_entries
  for insert with check (auth.uid() = user_id);

create policy "Owners can update payment entries" on public.payment_entries
  for update using (auth.uid() = user_id);

create policy "Owners can delete payment entries" on public.payment_entries
  for delete using (auth.uid() = user_id);

-- RLS Policies for PREDEFINED SERVICES
create policy "Users can view own predefined services" on public.predefined_services
  for select using (auth.uid() = user_id);

create policy "Users can insert own predefined services" on public.predefined_services
  for insert with check (auth.uid() = user_id);

create policy "Users can update own predefined services" on public.predefined_services
  for update using (auth.uid() = user_id);

create policy "Users can delete own predefined services" on public.predefined_services
  for delete using (auth.uid() = user_id);
