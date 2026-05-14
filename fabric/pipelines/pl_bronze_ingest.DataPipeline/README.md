# Bronze layer setup guide

## What this pipeline does

`pl_bronze_ingest` copies raw source files from the Lakehouse staging area
(`/Files/raw_upload/`) into the structured Bronze layer (`/Files/bronze/`).
Files land in date-partitioned folders with no transformation applied —
Bronze is a pure landing zone that preserves the original schema and format.

```
/Files/
  raw_upload/
    orders.csv
    stores.csv
    products.xlsx
    customers.json
    returns.json
  bronze/
    orders/2024/06/15/orders.csv
    stores/2024/06/15/stores.csv
    products/2024/06/15/products.xlsx
    customers/2024/06/15/customers.json
    returns/2024/06/15/returns.json
```

The five Copy Activities all depend on a single `set_load_date` step and
then execute in parallel, so the total runtime is bounded by the slowest
individual file copy — not the sum of all five.

## Pipeline execution flow

```
set_load_date
     │
     ├── copy_orders_csv     ─┐
     ├── copy_stores_csv      │  parallel
     ├── copy_products_xlsx   │  execution
     ├── copy_customers_json  │
     └── copy_returns_json   ─┘
```

## First-time workspace setup

### 1. Create the Lakehouse
In your Fabric workspace, create a Lakehouse named `RetailDemo_Lakehouse`.

### 2. Upload source files
Upload the contents of `data/mock/` to the Lakehouse under `/Files/raw_upload/`:

```
/Files/raw_upload/
  orders.csv
  stores.csv
  products.xlsx
  customers.json
  returns.json
```

You can do this via the Fabric UI (Files section → Upload) or the ADLS
Gen2 API using the Lakehouse's DFS endpoint.

### 3. Import the pipeline
Option A — Fabric Git integration (recommended):
  Connect your workspace to this GitHub repo (Settings → Git integration).
  Fabric will automatically import all pipeline definitions on sync.

Option B — Manual import:
  In the Fabric workspace, create a new Data Pipeline named `pl_bronze_ingest`
  and paste the contents of `pipeline-content.json` into the JSON editor.

### 4. Replace LAKEHOUSE_ID
Open the pipeline in the Fabric editor and update all occurrences of
`LAKEHOUSE_ID` with your actual Lakehouse artifact GUID.

To find the GUID: open the Lakehouse → Settings → copy the Artifact ID.

The GUID format is: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

If you imported via Git integration, Fabric resolves this automatically
via the `.platform` logical ID mapping — no manual replacement needed.

### 5. Run the pipeline
Trigger the pipeline manually from the Fabric UI.
Leave `p_load_date` empty to use today's date automatically,
or supply a specific date in `yyyy-MM-dd` format for a backfill.

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `p_load_date` | String | `""` (today) | Load date for partition folder. Format: `yyyy-MM-dd`. |

## Error handling

Each Copy Activity is configured with:
- **Retry:** 2 attempts
- **Retry interval:** 30 seconds
- **Timeout:** 1 hour per activity

If a single copy fails after retries, the pipeline run is marked as failed
but the other four parallel copies are unaffected — they complete normally.
The master pipeline (`pl_master_load`) checks overall success before
proceeding to Silver notebooks.

## After this pipeline

Once all five copy activities succeed, run `pl_master_load` (or trigger the
Silver notebooks manually in order):

1. `nb_silver_orders`
2. `nb_silver_stores`
3. `nb_silver_products`
4. `nb_silver_customers`
5. `nb_silver_returns`
