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

# ## Silver – stores
# 
# Reads `stores.csv` from Bronze, enforces schema, standardises string formatting,
# and writes the result as a Delta table (`silver_stores`).
# 
# **Transformations applied:**
# - `store_id` cast to `IntegerType`
# - `open_date` cast to `DateType`
# - Text columns trimmed; `state` uppercased; `region` title-cased
# - Duplicates removed on `store_id`

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

BRONZE_PATH = "Files/bronze/stores"
SILVER_TABLE = "silver_stores"
LOAD_TS = datetime.now(timezone.utc)

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
    .csv(f"{BRONZE_PATH}/*/*/*/stores.csv")
)
print(f"Bronze row count : {df_raw.count():>7,}")
df_raw.printSchema()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_clean = (
    df_raw
    .withColumn("store_id", F.col("store_id").cast(IntegerType()))
    .withColumn("open_date", F.to_date(F.col("open_date"), "yyyy-MM-dd"))
    .withColumn("name", F.trim(F.col("name")))
    .withColumn("region", F.initcap(F.trim(F.col("region"))))
    .withColumn("city", F.trim(F.col("city")))
    .withColumn("state", F.upper(F.trim(F.col("state"))))
    .withColumn("manager", F.trim(F.col("manager")))
    .filter(F.col("store_id").isNotNull())
    .dropDuplicates(["store_id"])
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
null_store_ids = df_clean.filter(F.col("store_id").isNull()).count()
null_regions = df_clean.filter(F.col("region").isNull()).count()

print(f"Silver row count  : {silver_count:>7,}")
print(f"Null store_ids    : {null_store_ids}")
print(f"Null regions      : {null_regions}")
print()
df_clean.groupBy("region").count().orderBy("region").show()

assert null_store_ids == 0, "QUALITY FAILED: null store_ids"
assert null_regions == 0, "QUALITY FAILED: null regions"

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
