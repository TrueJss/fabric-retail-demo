# pl_master_load – setup guide

## What this pipeline does

`pl_master_load` is the single entry point for a full data refresh. It
orchestrates every phase of the pipeline in dependency order, maximising
parallelism where activities are independent of each other.

## Execution flow

```
execute_bronze_pipeline (pl_bronze_ingest child)
         │
         │  Succeeded
         ▼
┌─────────────────────────────────────────────────────┐
│  run_nb_silver_orders    ─────────────────────────┐ │
│  run_nb_silver_stores    (parallel)               │ │
│  run_nb_silver_products  (parallel)               │ │
│  run_nb_silver_customers (parallel)               │ │
└───────────────────────────────────────────────────┼─┘
                                                    │ Succeeded
                                                    ▼
                                         run_nb_silver_returns
                                         (waits for orders only —
                                          validates order_id FK)
         │ all 5 notebooks Succeeded
         ▼
┌─────────────────────────────────────────────────────┐
│  exec_usp_Load_DimCustomer  ──────────────────────┐ │
│  exec_usp_Load_DimProduct   (parallel)            │ │
│  exec_usp_Load_DimStore     (parallel)            │ │
└───────────────────────────────────────────────────┼─┘
         │ all 3 dims Succeeded                     │
         ▼                                          │
exec_usp_Load_FactSales
(waits for all 3 dims)
```

**Why `nb_silver_returns` is not fully parallel:**
It performs a `left_anti` join against `silver_orders` to validate that every
return references a real order. `silver_orders` must therefore exist before
`nb_silver_returns` runs. The three other notebooks (stores, products,
customers) have no such dependency and run immediately after bronze.

**Why the three dimension procs wait for ALL five notebooks:**
The dimension procs depend on all Silver tables being ready — not just their
direct source. This avoids a race where a notebook fails late (e.g. returns)
while a dim proc has already started, leaving Gold in a partial state.

## Placeholder GUIDs to replace

| Placeholder | Where to find it |
|---|---|
| `WORKSPACE_ID` | Fabric workspace URL — the GUID after `/groups/` |
| `NB_SILVER_ORDERS_ID` | Open the notebook → Settings → Artifact ID |
| `NB_SILVER_STORES_ID` | As above |
| `NB_SILVER_PRODUCTS_ID` | As above |
| `NB_SILVER_CUSTOMERS_ID` | As above |
| `NB_SILVER_RETURNS_ID` | As above |
| `RetailDemo_Warehouse` | Name of the linked service pointing to the Warehouse SQL endpoint |

When importing via Fabric Git integration, workspace-specific IDs are resolved
automatically — only the `RetailDemo_Warehouse` linked service needs manual
configuration in the Fabric UI.

## Linked service setup (RetailDemo_Warehouse)

In the Fabric workspace, create a linked service named `RetailDemo_Warehouse`:

1. Go to Data Factory → Manage → Linked services → New
2. Choose: **Azure SQL Database** (Fabric Warehouse exposes a SQL endpoint)
3. Connection string: use the Warehouse SQL connection string from
   Fabric workspace → `RetailDemo_Warehouse` → Settings → SQL connection string
4. Authentication: **Managed Identity** (recommended) or service principal
5. Name the linked service exactly `RetailDemo_Warehouse`

## Expected run time (demo scale)

| Phase | Activities | Expected duration |
|---|---|---|
| Bronze | 5 parallel Copy | ~1–2 min |
| Silver | 4 parallel + 1 sequential | ~3–5 min (Spark startup dominates) |
| Gold dims | 3 parallel MERGE | < 30 sec |
| Gold fact | 1 TRUNCATE + INSERT | < 30 sec |
| **Total** | | **~5–8 min** |

Spark session startup (~2–3 min) dominates Silver runtime. This is expected
and normal for Fabric notebooks at demo scale.

## Retry policy

All activities have `retry: 1` with a 30–60 second interval. Transient
failures (network, Spark session timeout) are recovered automatically on
the first retry. If a second attempt fails, the pipeline marks the run
as failed and stops — no partial Gold state is possible because FactSales
only runs after all dimensions succeed.
