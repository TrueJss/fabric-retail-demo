# Warehouse DDL – execution guide

Run scripts in the numbered order below. All scripts are re-runnable
(idempotent where noted). Execute them in the Fabric Warehouse SQL editor
or via SSMS connected to the Warehouse SQL endpoint.

## Execution order

| # | Script | Re-runnable | Notes |
|---|---|---|---|
| 1 | `00_schema.sql` | ✓ | Creates `gold` schema if absent |
| 2 | `01_dim_date.sql` | ✗ | Table + indexes — run once |
| 3 | `02_dim_customer.sql` | ✗ | Table + indexes — run once |
| 4 | `03_dim_product.sql` | ✗ | Table + indexes — run once |
| 5 | `04_dim_store.sql` | ✗ | Table + indexes — run once |
| 6 | `05_fact_sales.sql` | ✗ | Table + FK constraints + indexes — run once |
| 7 | `06_user_region_mapping.sql` | ✗ | Table + sample RLS rows — run once |
| 8 | `07_populate_dim_date.sql` | ✓ | TRUNCATE + INSERT — safe to re-run |
| 9 | `08_views.sql` | ✓ | `CREATE OR ALTER VIEW` — safe to re-run |

Tables in steps 2–7 must be dropped manually before re-running if the schema
changes. Stored procedures handle subsequent data loads — do not re-run the
DDL scripts to reload data.

## Star schema overview

```
                    ┌─────────────┐
                    │  DimDate    │
                    │  (DateKey)  │
                    └──────┬──────┘
                           │
┌──────────────┐    ┌──────┴──────┐    ┌──────────────┐
│ DimCustomer  │    │  FactSales  │    │  DimProduct  │
│ (CustomerSK) ├────┤             ├────┤  (ProductSK) │
└──────────────┘    │             │    └──────────────┘
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │  DimStore   │
                    │  (StoreSK)  │
                    └─────────────┘
```

## RLS architecture

`UserRegionMapping` maps user email → permitted region(s). The Power BI
semantic model applies this filter on `DimCustomer.Region`, which then
propagates to `FactSales` via the CustomerSK relationship.

A user assigned to a single region sees only that region's orders.
A user with multiple rows in `UserRegionMapping` sees all their permitted
regions (OR logic via LOOKUPVALUE returning the first matching row —
see stored procedure notes for multi-region handling).

## Fabric Warehouse FK behaviour

Foreign key constraints are defined on `FactSales` for documentation and
query-optimizer hints. Fabric Warehouse defines FK metadata but does **not**
enforce referential integrity at write time. Integrity is guaranteed by the
stored procedure load logic (dimension tables are always loaded before the
fact table, and SK lookups use INNER JOINs that silently exclude unmatched
rows).
