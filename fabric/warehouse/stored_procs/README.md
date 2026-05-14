# Stored procedures – execution guide

## Load order

Dimensions must be fully loaded before the fact table. Run in this sequence:

```
1. usp_Load_DimCustomer   ← MERGE from silver_customers
2. usp_Load_DimProduct    ← MERGE from silver_products
3. usp_Load_DimStore      ← MERGE from silver_stores
4. usp_Load_FactSales     ← TRUNCATE + INSERT from silver_orders
```

DimDate is populated once by `ddl/07_populate_dim_date.sql` and does not have
a stored procedure — it is a static calendar table that never changes at runtime.

## Quick execution (run all in order)

```sql
EXEC gold.usp_Load_DimCustomer;
EXEC gold.usp_Load_DimProduct;
EXEC gold.usp_Load_DimStore;
EXEC gold.usp_Load_FactSales;
```

## How Silver tables are accessed

Each stored procedure reads from the Silver Delta tables via Fabric's
cross-database query capability. The three-part naming convention:

```
RetailDemo_Lakehouse.dbo.silver_orders
RetailDemo_Lakehouse.dbo.silver_customers
RetailDemo_Lakehouse.dbo.silver_products
RetailDemo_Lakehouse.dbo.silver_stores
```

The Lakehouse SQL Analytics Endpoint is automatically available to all items
in the same Fabric workspace — no additional configuration needed. If your
Lakehouse is named differently, update the three-part prefix in each procedure.

## Dimension strategy: MERGE (SCD Type 1)

| Event | Action |
|---|---|
| New row in Silver | `INSERT` with new surrogate key via `IDENTITY` |
| Existing row, values changed | `UPDATE` all non-key columns |
| Row missing from Silver | No action (soft-delete not implemented) |

Surrogate keys (`CustomerSK`, `ProductSK`, `StoreSK`) are never recycled.
A customer that disappears from source retains their SK and historical orders.

## Fact table strategy: TRUNCATE + INSERT

`FactSales` is fully reloaded on every pipeline run:
1. `TRUNCATE TABLE gold.FactSales` clears all rows
2. All Silver orders are re-inserted with freshly resolved surrogate keys

This is safe because:
- Dimensions are always loaded first (SKs are stable across runs)
- The full Silver dataset fits comfortably in a single INSERT at demo scale
- Any corrections in Silver automatically flow into Gold on the next run

For a production system with millions of rows, replace with a date-partitioned
incremental INSERT that only processes new or updated orders.

## Error handling

All procedures use `TRY / CATCH / THROW`. If a procedure fails:
- The error message is printed
- `THROW` re-raises the original error to the calling pipeline activity
- The master pipeline (`pl_master_load`) marks the run as failed and stops

## Validating a successful load

After running all four procedures, verify row counts:

```sql
SELECT 'DimCustomer' AS TableName, COUNT(*) AS RowCount FROM gold.DimCustomer
UNION ALL
SELECT 'DimProduct',  COUNT(*) FROM gold.DimProduct
UNION ALL
SELECT 'DimStore',    COUNT(*) FROM gold.DimStore
UNION ALL
SELECT 'DimDate',     COUNT(*) FROM gold.DimDate
UNION ALL
SELECT 'FactSales',   COUNT(*) FROM gold.FactSales;
```

Expected (demo data):
| Table | Expected rows |
|---|---|
| DimCustomer | 500 |
| DimProduct | 105 |
| DimStore | 20 |
| DimDate | 1,096 |
| FactSales | ~3,469 (completed orders only excluded by INNER JOIN to DimDate) |

Note: FactSales includes all order statuses (completed, pending, cancelled).
The ~3,469 figure above is wrong — expect ~5,000 rows (all orders).
Filtering to completed-only is a Power BI / DAX concern, not a load concern.
