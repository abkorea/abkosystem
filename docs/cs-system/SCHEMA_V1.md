# CS System Schema v1 (Draft)

This is the first draft schema for the ABKO CS improvement program.

## Naming rules

- snake_case
- CS domain tables prefixed with `cs_`
- "Manage" tables end with `_manage`

## Entities

### Management (reference)

- `cs_business_group_manage`
- `cs_category_manage`
- `cs_product_manage` (ERP synced)
- `cs_staff_manage` (scope stored as JSONB)
- `cs_symptom_manage`
- `cs_material_manage`

### Core CS

- `cs_tickets`
- `cs_ticket_items`
- `cs_ticket_events`
- `cs_ticket_assets`
- `cs_ticket_shipments`
- `cs_ticket_payments` (item-first, ticket-level compatible)
- `cs_ticket_item_materials`
- `cs_ticket_ai_artifacts`
- `cs_ai_runs`
- `cs_customers`

## Notes

- PII fields must use 2-step envelope encryption.
- Use hash columns for lookup (phone/email) without revealing raw PII.

