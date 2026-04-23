-- CS System Schema v1.1 (delta)
-- Add missing fields required by current UI mock pages (AS intake + inquiry + biz intake)

create extension if not exists pgcrypto;

-- 1) cs_tickets: inquiry content (문의내용)
alter table if exists cs_tickets
  add column if not exists inquiry_content_text text;

-- 2) cs_tickets: business intake fields (회사명/사업자번호)
-- Store as encrypted + hash for lookup (align with existing encrypted_* + *_hash pattern)
alter table if exists cs_tickets
  add column if not exists encrypted_company_name text,
  add column if not exists encrypted_business_no text,
  add column if not exists business_no_hash text;

create index if not exists idx_cs_tickets_business_no_hash on cs_tickets(business_no_hash);

-- 3) cs_ticket_items: free-text product name for cases where product_id is unknown/unmatched
alter table if exists cs_ticket_items
  add column if not exists reported_product_name text;
