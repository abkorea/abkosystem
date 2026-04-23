-- CS System Schema v1
-- NOTE: PII fields should be stored encrypted (2-step envelope encryption) + hash for lookup.

create extension if not exists pgcrypto;

-- 1) Business group / category / product
create table if not exists cs_business_group_manage (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists cs_category_manage (
  id uuid primary key default gen_random_uuid(),
  business_group_id uuid not null references cs_business_group_manage(id),
  name text not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists cs_product_manage (
  id uuid primary key default gen_random_uuid(),
  erp_item_code text not null unique,
  erp_name text not null,
  category_id uuid references cs_category_manage(id),
  status text,
  attrs jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2) Staff
create table if not exists cs_staff_manage (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  scope jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3) Symptom / material
create table if not exists cs_symptom_manage (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references cs_category_manage(id),
  symptom_code text,
  symptom_name text not null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(category_id, symptom_code)
);

create table if not exists cs_material_manage (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references cs_category_manage(id),
  material_code text,
  material_name text not null,
  unit_cost numeric,
  stock_qty numeric,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(category_id, material_code)
);

-- 4) Customers (member)
create table if not exists cs_customers (
  id uuid primary key default gen_random_uuid(),

  -- encrypted PII fields
  encrypted_name text,
  encrypted_phone text,
  encrypted_email text,
  encrypted_address text,

  -- lookup hashes (not encrypted)
  phone_hash text,
  email_hash text,

  internal_customer_code text,

  phone_verified boolean not null default false,
  phone_verified_at timestamptz,

  consent_required boolean not null default false,
  consent_required_version text,
  consent_required_at timestamptz,

  consent_third_party boolean not null default false,
  consent_third_party_version text,
  consent_third_party_at timestamptz,

  consent_marketing boolean not null default false,
  consent_marketing_version text,
  consent_marketing_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_cs_customers_phone_hash on cs_customers(phone_hash);
create index if not exists idx_cs_customers_email_hash on cs_customers(email_hash);

-- 5) Tickets
create table if not exists cs_tickets (
  id uuid primary key default gen_random_uuid(),
  ticket_no text unique,

  customer_id uuid references cs_customers(id),

  -- encrypted PII for non-member intake
  encrypted_contact_name text,
  encrypted_contact_phone text,
  encrypted_contact_email text,
  encrypted_contact_address text,
  contact_phone_hash text,
  contact_email_hash text,

  customer_type text not null, -- 고객/고객사
  inquiry_type text not null,  -- 문의/고장 및 수리/기타

  status text not null,        -- 8-step
  priority text not null default 'normal',
  intake_channel text,
  tags text[],

  assignee_staff_id uuid references cs_staff_manage(id),

  first_response_at timestamptz,
  closed_at timestamptz,

  resolution_code text,
  root_cause_code text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_cs_tickets_status on cs_tickets(status);
create index if not exists idx_cs_tickets_created_at on cs_tickets(created_at);
create index if not exists idx_cs_tickets_assignee on cs_tickets(assignee_staff_id);

-- 6) Ticket items
create table if not exists cs_ticket_items (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references cs_tickets(id) on delete cascade,

  product_id uuid references cs_product_manage(id),
  qty numeric not null default 1,
  color text,
  serial_no text,

  warranty_type text not null, -- 무상/유상

  purchase_channel text,
  purchase_date date,

  receipt_asset_id uuid,

  reported_symptom_text text,
  diagnosed_symptom_id uuid references cs_symptom_manage(id),
  diagnosed_symptom_text text,

  repair_method text,
  repair_status text,

  is_repeat boolean not null default false,
  resolution_code text,
  root_cause_code text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_cs_ticket_items_ticket on cs_ticket_items(ticket_id);
create index if not exists idx_cs_ticket_items_product on cs_ticket_items(product_id);

-- 7) Item materials usage
create table if not exists cs_ticket_item_materials (
  id uuid primary key default gen_random_uuid(),
  ticket_item_id uuid not null references cs_ticket_items(id) on delete cascade,
  material_id uuid not null references cs_material_manage(id),
  used_qty numeric not null,
  used_unit_cost numeric,
  used_at timestamptz not null default now(),
  memo text
);

-- 8) Payments
create table if not exists cs_ticket_payments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references cs_tickets(id) on delete cascade,
  ticket_item_id uuid references cs_ticket_items(id),
  amount numeric not null,
  is_paid boolean not null default false,
  paid_at timestamptz,
  method text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 9) Shipments
create table if not exists cs_ticket_shipments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references cs_tickets(id) on delete cascade,
  direction text not null, -- 입고/반송
  carrier text,
  tracking_no text,
  sent_at timestamptz,
  received_at timestamptz,
  status text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 10) Assets
create table if not exists cs_ticket_assets (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references cs_tickets(id) on delete cascade,
  ticket_item_id uuid references cs_ticket_items(id),
  kind text not null,
  storage_path text not null,
  uploaded_at timestamptz not null default now(),
  memo text
);

-- 11) Events / audit
create table if not exists cs_ticket_events (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references cs_tickets(id) on delete cascade,
  event_type text not null,
  from_status text,
  to_status text,
  note text,
  actor_staff_id uuid references cs_staff_manage(id),
  created_at timestamptz not null default now()
);

-- 12) AI artifacts
create table if not exists cs_ticket_ai_artifacts (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references cs_tickets(id) on delete cascade,
  audio_asset_id uuid references cs_ticket_assets(id),
  transcript_text text,
  summary_text text,
  raw jsonb not null default '{}'::jsonb,
  model text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
