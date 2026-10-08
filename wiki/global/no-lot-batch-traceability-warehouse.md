---
summary: No lot/batch/serial-number traceability in the warehouse — supplier-lot → customer recall questions cannot be answered.
usage_mode: auto
sort_order: 0
tags:
  - data-quality
sl_refs:
  - purchase_orders
  - suppliers
  - shipments
connections:
  - warehouse
---

## No Lot / Batch Traceability in the Warehouse

- **No lot, batch, or serial-number column exists** in any table in the warehouse (`sahil-devx.dev_dna_silver`). This was verified via INFORMATION_SCHEMA on 2026-10-08.
- `purchase_orders` links a supplier to a **product** (`supplier_id` → `product_id`), not to a lot or batch. There is no lot-level receiving record.
- `suppliers` carries identity/meta fields only: `supplier_id`, `supplier_name`, `category`, `country`, `contract_start_date`, `avg_lead_time_days`, `status`. No lot reference.
- All sales/shipment fact tables (`d2c_orders`, `platform_orders`, `international_orders`, `offline_orders`, `qcomm_orders`, `cafe_sales`, `shipments`, `returns`) have **no lot or batch column**.

### Impact

- **Supplier-lot → customer traceability is impossible.** Questions like *"Which customers received units from lot L-4597?"* cannot be answered from this warehouse.
- A full-text scan for lot identifiers (e.g. `L-4597`) across all tables returns no matches (incidental numeric substrings in `shipments` only).

### Best Available Proxy

Supplier → product (via `purchase_orders`) → customers who ordered that product (via sales fact tables). This is **product-level only, not lot-level**, and will over-include customers who received unaffected units from other batches.
