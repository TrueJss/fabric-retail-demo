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

# ## Silver – customers
# 
# Reads `customers.json` from Bronze, **flattens the nested `address` struct**,
# standardises text fields, and writes the result as `silver_customers`.
# 
# **Transformations applied:**
# - Nested `address` object exploded into flat columns:
#   `address.street → address_street`, `address.city → address_city`,
#   `address.state → address_state`, `address.region → region`
# - Original `address` struct dropped
# - `registration_date` cast to `DateType`
# - `email` lowercased and trimmed
# - `state` uppercased; `region` title-cased
# - Duplicates removed on `customer_id`

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

BRONZE_PATH = "Files/bronze/customers"
SILVER_TABLE = "silver_customers"
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
    .json(f"{BRONZE_PATH}/*/*/*/customers.json")
)
print(f"Bronze row count : {df_raw.count():>7,}")
df_raw.printSchema()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_flat = (
    df_raw
    .withColumn("address_street", F.col("address.street"))
    .withColumn("address_city", F.col("address.city"))
    .withColumn("address_state", F.col("address.state"))
    .withColumn("region", F.col("address.region"))
    .drop("address")
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_clean = (
    df_flat
    .withColumn("customer_id", F.col("customer_id").cast(IntegerType()))
    .withColumn("registration_date", F.to_date(F.col("registration_date"), "yyyy-MM-dd"))
    .withColumn("first_name", F.trim(F.col("first_name")))
    .withColumn("last_name", F.trim(F.col("last_name")))
    .withColumn("email", F.trim(F.lower(F.col("email"))))
    .withColumn("phone", F.trim(F.col("phone")))
    .withColumn("address_street", F.trim(F.col("address_street")))
    .withColumn("address_city", F.trim(F.col("address_city")))
    .withColumn("address_state", F.upper(F.trim(F.col("address_state"))))
    .withColumn("region", F.initcap(F.trim(F.col("region"))))
    .filter(F.col("customer_id").isNotNull())
    .dropDuplicates(["customer_id"])
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
null_cust_ids = df_clean.filter(F.col("customer_id").isNull()).count()
null_emails = df_clean.filter(F.col("email").isNull()).count()
null_regions = df_clean.filter(F.col("region").isNull()).count()

print(f"Silver row count  : {silver_count:>7,}")
print(f"Null customer_ids : {null_cust_ids}")
print(f"Null emails       : {null_emails}")
print(f"Null regions      : {null_regions}")
print()
df_clean.groupBy("region").count().orderBy("region").show()

assert null_cust_ids == 0, "QUALITY FAILED: null customer_ids"
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
