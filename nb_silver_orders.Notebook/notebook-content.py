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

# ## Silver – orders
# 
# Reads `orders.csv` from Bronze, enforces schema, deduplicates, validates order
# status, and writes the result as a Delta table (`silver_orders`) in the Lakehouse
# Tables section.
# 
# **Bronze → Silver transformations applied:**
# - All columns cast from string to correct types
# - `order_date` cast to `DateType`
# - `unit_price` cast to `DecimalType(10, 2)`
# - `status` normalised to lowercase; unexpected values mapped to `"unknown"`
# - Duplicates removed on `order_id` (keep first)
# - Rows with null `order_id` or `customer_id` dropped
# - Audit columns `_load_timestamp` and `_source` appended

# CELL ********************

from pyspark.sql import functions as F
from pyspark.sql.types import IntegerType, DecimalType, TimestampType
from datetime import datetime, timezone

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# PARAMETERS CELL ********************

BRONZE_PATH = "Files/bronze/orders"
SILVER_TABLE = "silver_orders"
LOAD_TS = datetime.now(timezone.utc)
VALID_STATUSES = ["completed", "pending", "cancelled"]

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_raw = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "false")
    .csv(f"{BRONZE_PATH}/*/*/*/orders.csv")
)
print(f"Bronze row count : {df_raw.count():>7,}")
df_raw.printSchema()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_typed = (
    df_raw
    .withColumn("order_id", F.col("order_id").cast(IntegerType()))
    .withColumn("customer_id", F.col("customer_id").cast(IntegerType()))
    .withColumn("store_id", F.col("store_id").cast(IntegerType()))
    .withColumn("product_id", F.col("product_id").cast(IntegerType()))
    .withColumn("quantity", F.col("quantity").cast(IntegerType()))
    .withColumn("unit_price", F.col("unit_price").cast(DecimalType(10, 2)))
    .withColumn("order_date", F.to_date(F.col("order_date"), "yyyy-MM-dd"))
    .withColumn("status", F.trim(F.lower(F.col("status"))))
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_clean = (
    df_typed
    .filter(F.col("order_id").isNotNull())
    .filter(F.col("customer_id").isNotNull())
    .filter(F.col("product_id").isNotNull())
    .withColumn(
        "status",
        F.when(F.col("status").isin(VALID_STATUSES), F.col("status"))
        .otherwise(F.lit("unknown")),
    )
    .dropDuplicates(["order_id"])
    .withColumn("_load_timestamp", F.lit(LOAD_TS.isoformat()).cast(TimestampType()))
    .withColumn("_source", F.lit(BRONZE_PATH))
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

silver_count = df_clean.count()
null_order_ids = df_clean.filter(F.col("order_id").isNull()).count()
null_dates = df_clean.filter(F.col("order_date").isNull()).count()
null_prices = df_clean.filter(F.col("unit_price").isNull()).count()
unknown_status = df_clean.filter(F.col("status") == "unknown").count()

print(f"Silver row count   : {silver_count:>7,}")
print(f"Null order_ids     : {null_order_ids}")
print(f"Null order_dates   : {null_dates}")
print(f"Null unit_prices   : {null_prices}")
print(f"Unknown statuses   : {unknown_status}")

assert null_order_ids == 0, "QUALITY FAILED: null order_ids"
assert null_dates == 0, "QUALITY FAILED: null order_dates"
assert null_prices == 0, "QUALITY FAILED: null unit_prices"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

(
    df_clean
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
