-- PropertyWorks production schema (Supabase/Postgres)
-- All public tables use RLS. Authorization is based on auth.uid() relationships.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null check (role in ('owner','tenant','contractor')),
  created_at timestamptz not null default now()
);

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  address text not null,
  property_type text,
  units integer not null default 1,
  occupied_units integer not null default 0,
  scheduled_monthly_rent numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.tenant_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_user_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  unit text,
  owner_id uuid not null references auth.users(id) on delete cascade,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.tenant_invites (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  unit text,
  tenant_name text not null,
  email text not null,
  token_hash text not null unique,
  expires_at timestamptz not null,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.leases (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  tenant_user_id uuid references auth.users(id) on delete set null,
  unit text,
  monthly_rent numeric(12,2) not null default 0,
  security_deposit numeric(12,2) not null default 0,
  start_date date,
  end_date date,
  status text not null default 'Active',
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  tenant_user_id uuid references auth.users(id) on delete set null,
  unit text,
  payment_date date not null default current_date,
  source text not null default 'Tenant',
  amount numeric(12,2) not null default 0,
  status text not null default 'Paid',
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  expense_date date not null default current_date,
  category text not null,
  vendor text,
  amount numeric(12,2) not null default 0,
  description text,
  tax_year integer generated always as (extract(year from expense_date)::integer) stored,
  created_at timestamptz not null default now()
);

create table if not exists public.maintenance_requests (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  tenant_user_id uuid references auth.users(id) on delete set null,
  unit text,
  title text not null,
  description text,
  priority text not null default 'Normal',
  permission_to_enter text,
  status text not null default 'Open',
  marketplace_status text,
  scheduled_for timestamptz,
  awarded_bid_id uuid,
  payment_status text,
  payment_method text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.contractor_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  business_name text,
  trades text,
  phone text,
  email text,
  service_area text,
  credential_status text,
  rating numeric(3,2) not null default 5.0,
  jobs_completed integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.job_bids (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.maintenance_requests(id) on delete cascade,
  contractor_user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(12,2) not null,
  availability text,
  notes text,
  status text not null default 'Submitted',
  created_at timestamptz not null default now()
);

alter table public.maintenance_requests
  drop constraint if exists maintenance_requests_awarded_bid_fk;
alter table public.maintenance_requests
  add constraint maintenance_requests_awarded_bid_fk
  foreign key (awarded_bid_id) references public.job_bids(id) on delete set null;

create table if not exists public.renovations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  name text not null,
  budget numeric(12,2) not null default 0,
  spent numeric(12,2) not null default 0,
  contractor text,
  status text not null default 'Planning',
  created_at timestamptz not null default now()
);

create table if not exists public.deals (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  deal_type text,
  address text,
  price numeric(14,2) not null default 0,
  stage text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid references public.properties(id) on delete cascade,
  tenant_user_id uuid references auth.users(id) on delete set null,
  storage_path text not null,
  document_name text not null,
  document_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text not null,
  job_id uuid references public.maintenance_requests(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.profiles enable row level security;
alter table public.properties enable row level security;
alter table public.tenant_assignments enable row level security;
alter table public.tenant_invites enable row level security;
alter table public.leases enable row level security;
alter table public.payments enable row level security;
alter table public.expenses enable row level security;
alter table public.maintenance_requests enable row level security;
alter table public.contractor_profiles enable row level security;
alter table public.job_bids enable row level security;
alter table public.renovations enable row level security;
alter table public.deals enable row level security;
alter table public.documents enable row level security;
alter table public.notifications enable row level security;

create policy "profiles_self_select" on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy "profiles_self_update" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "properties_owner_all" on public.properties for all to authenticated
using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
create policy "properties_tenant_select" on public.properties for select to authenticated
using (exists (select 1 from public.tenant_assignments ta where ta.property_id=id and ta.tenant_user_id=(select auth.uid()) and ta.active));

create policy "tenant_assignments_owner_all" on public.tenant_assignments for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy "tenant_assignments_tenant_select" on public.tenant_assignments for select to authenticated
using ((select auth.uid())=tenant_user_id);

create policy "tenant_invites_owner_all" on public.tenant_invites for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);

create policy "leases_owner_all" on public.leases for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy "leases_tenant_select" on public.leases for select to authenticated
using ((select auth.uid())=tenant_user_id);

create policy "payments_owner_all" on public.payments for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy "payments_tenant_select" on public.payments for select to authenticated
using ((select auth.uid())=tenant_user_id);

create policy "expenses_owner_all" on public.expenses for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);

create policy "maintenance_owner_all" on public.maintenance_requests for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy "maintenance_tenant_select" on public.maintenance_requests for select to authenticated
using ((select auth.uid())=tenant_user_id);
create policy "maintenance_tenant_insert" on public.maintenance_requests for insert to authenticated
with check (
  (select auth.uid())=tenant_user_id
  and exists (
    select 1 from public.tenant_assignments ta
    where ta.tenant_user_id=(select auth.uid())
      and ta.property_id=maintenance_requests.property_id
      and ta.owner_id=maintenance_requests.owner_id
      and ta.active
  )
);

create policy "contractors_public_select" on public.contractor_profiles for select to authenticated using (active);
create policy "contractors_self_all" on public.contractor_profiles for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

create policy "bids_contractor_all" on public.job_bids for all to authenticated
using ((select auth.uid())=contractor_user_id) with check ((select auth.uid())=contractor_user_id);
create policy "bids_owner_select" on public.job_bids for select to authenticated
using (exists (select 1 from public.maintenance_requests mr where mr.id=job_id and mr.owner_id=(select auth.uid())));

create policy "renovations_owner_all" on public.renovations for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy "deals_owner_all" on public.deals for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy "documents_owner_all" on public.documents for all to authenticated
using ((select auth.uid())=owner_id) with check ((select auth.uid())=owner_id);
create policy "documents_tenant_select" on public.documents for select to authenticated
using ((select auth.uid())=tenant_user_id);
create policy "notifications_self_all" on public.notifications for all to authenticated
using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);

-- Storage buckets should be created as private:
-- maintenance-photos, property-documents
-- Storage policies will be added after the live project exists so they can be tested against Auth.
