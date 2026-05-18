# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "31e591ee-c81f-49f8-9c1e-f8410811538a",
# META       "default_lakehouse_name": "RetailDemo_Lakehouse",
# META       "default_lakehouse_workspace_id": "91736df8-b0c0-4e30-aa8c-c964e288e92f",
# META       "known_lakehouses": [
# META         {
# META           "id": "31e591ee-c81f-49f8-9c1e-f8410811538a"
# META         }
# META       ]
# META     }
# META   }
# META }

# MARKDOWN ********************

# ## Silver – returns
# 
# Reads `returns.json` from Bronze and applies the most intensive cleaning in the
# Silver layer. This source has three intentional data quality issues introduced
# during mock data generation, each demonstrated and resolved here.
# 
# **Issues resolved:**
# | Issue | Fix |
# |---|---|
# | ~10% null `reason` values | `COALESCE` to `"Not specified"` |
# | ~15% whitespace-padded `reason` strings | `trim()` |
# | Denormalised `customer_id`, `product_id`, `product_name` columns | Dropped |
# | `return_date` as ISO datetime string (`2023-11-03T00:00:00`) | Cast to `DateType` |
# 
# **Additional quality check:**
# Every `order_id` in returns is validated to exist in `silver_orders`. Orphaned
# returns are logged and excluded from Silver.

# CELL ********************

from pyspark.sql import functions as F
from pyspark.sql.types import IntegerType, TimestampType
from datetime import datetime, timezone

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# PARAMETERS CELL ********************

BRONZE_PATH = "Files/bronze/returns"
SILVER_TABLE = "silver_returns"
LOAD_TS = datetime.now(timezone.utc)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_raw = (
    spark.read
    .option("multiLine", "true")
    .json(f"{BRONZE_PATH}/*/*/*/returns.json")
)
print(f"Bronze row count : {df_raw.count():>7,}")
df_raw.printSchema()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

null_reasons = df_raw.filter(F.col("reason").isNull()).count()
padded_reasons = df_raw.filter(F.col("reason") != F.trim(F.col("reason"))).count()
print(f"Null reason values    : {null_reasons}")
print(f"Whitespace-padded     : {padded_reasons}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_clean = (
    df_raw
    .withColumn("reason", F.trim(F.col("reason")))
    .withColumn("reason", F.coalesce(F.col("reason"), F.lit("Not specified")))
    .withColumn(
        "return_date",
        F.to_date(F.col("return_date"), "yyyy-MM-dd'T'HH:mm:ss"),
    )
    .withColumn("return_id", F.col("return_id").cast(IntegerType()))
    .withColumn("order_id", F.col("order_id").cast(IntegerType()))
    .drop("customer_id", "product_id", "product_name")
    .filter(F.col("return_id").isNotNull())
    .filter(F.col("order_id").isNotNull())
    .dropDuplicates(["return_id"])
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_orders = spark.table("silver_orders").select("order_id")

df_orphans = df_clean.join(df_orders, on="order_id", how="left_anti")
orphan_count = df_orphans.count()

if orphan_count > 0:
    print(f"WARNING: {orphan_count} returns reference non-existent orders — excluding from Silver")
    df_orphans.show(10)

df_valid = df_clean.join(df_orders, on="order_id", how="inner")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_final = (
    df_valid
    .withColumn("_load_timestamp", F.lit(LOAD_TS.isoformat()).cast(TimestampType()))
    .withColumn("_source", F.lit(BRONZE_PATH))
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

silver_count = df_final.count()
null_returns = df_final.filter(F.col("return_id").isNull()).count()
null_dates = df_final.filter(F.col("return_date").isNull()).count()
null_reasons = df_final.filter(F.col("reason").isNull()).count()
padded_after = df_final.filter(F.col("reason") != F.trim(F.col("reason"))).count()

print(f"Silver row count   : {silver_count:>7,}")
print(f"Orphaned returns   : {orphan_count}")
print(f"Null return_ids    : {null_returns}")
print(f"Null return_dates  : {null_dates}")
print(f"Null reasons       : {null_reasons}  (should be 0 — coalesced above)")
print(f"Padded reasons     : {padded_after}  (should be 0 — trimmed above)")

assert null_returns == 0, "QUALITY FAILED: null return_ids"
assert null_dates == 0, "QUALITY FAILED: null return_dates"
assert null_reasons == 0, "QUALITY FAILED: null reasons after coalesce"
assert padded_after == 0, "QUALITY FAILED: padded reasons after trim"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

(
    df_final
    .write
    .format("delta")
    .mode("overwrite")
    .option("overwriteSchema", "true")
    .saveAsTable(SILVER_TABLE)
)
print(f"✓ {silver_count:,} rows written to {SILVER_TABLE}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
