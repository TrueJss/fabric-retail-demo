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

# ## Silver – products
# 
# Reads `products.xlsx` from Bronze (two sheets: `Products` and `Categories`),
# joins them on `category_id`, and writes the enriched result as `silver_products`.
# 
# **Why pandas for XLSX?** PySpark has no native Excel reader. We use pandas to
# read both sheets, convert to Spark DataFrames, then apply all remaining
# transformations in PySpark. Pandas is only used for the initial file read.
# 
# **Transformations applied:**
# - Both sheets read via `pandas.read_excel`, converted to Spark DataFrames
# - `Products` joined to `Categories` on `category_id` (inner join)
# - `cost_price` and `retail_price` cast to `DecimalType(10, 2)`
# - `margin_pct` derived: `(retail_price - cost_price) / retail_price`
# - Text columns trimmed
# - Duplicates removed on `product_id`

# CELL ********************

import glob
import pandas as pd
from pyspark.sql import functions as F
from pyspark.sql.types import IntegerType, DecimalType, DoubleType, TimestampType
from datetime import datetime, timezone

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# PARAMETERS CELL ********************

BRONZE_PATH = "Files/bronze/products"
SILVER_TABLE = "silver_products"
LOAD_TS = datetime.now(timezone.utc)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

local_base = "/lakehouse/default"
xlsx_pattern = f"{local_base}/{BRONZE_PATH}/*/*/*/products.xlsx"
xlsx_files = sorted(glob.glob(xlsx_pattern))

if not xlsx_files:
    raise FileNotFoundError(f"No products.xlsx found under {BRONZE_PATH}")

latest_xlsx = xlsx_files[-1]
print(f"Reading: {latest_xlsx}")

pdf_products = pd.read_excel(latest_xlsx, sheet_name="Products")
pdf_categories = pd.read_excel(latest_xlsx, sheet_name="Categories")

print(f"Products sheet   : {len(pdf_products):,} rows")
print(f"Categories sheet : {len(pdf_categories):,} rows")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_products = spark.createDataFrame(pdf_products.astype(str))
df_categories = spark.createDataFrame(pdf_categories.astype(str))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_joined = (
    df_products
    .join(
        df_categories.select(
            F.col("category_id"),
            F.col("name").alias("category_name"),
        ),
        on="category_id",
        how="inner",
    )
)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_clean = (
    df_joined
    .withColumn("product_id", F.col("product_id").cast(IntegerType()))
    .withColumn("category_id", F.col("category_id").cast(IntegerType()))
    .withColumn("cost_price", F.col("cost_price").cast(DecimalType(10, 2)))
    .withColumn("retail_price", F.col("retail_price").cast(DecimalType(10, 2)))
    .withColumn("name", F.trim(F.col("name")))
    .withColumn("category_name", F.trim(F.col("category_name")))
    .withColumn(
        "margin_pct",
        F.round(
            (F.col("retail_price") - F.col("cost_price"))
            / F.col("retail_price") * 100,
            2,
        ).cast(DoubleType()),
    )
    .filter(F.col("product_id").isNotNull())
    .dropDuplicates(["product_id"])
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
null_product_ids = df_clean.filter(F.col("product_id").isNull()).count()
null_prices = df_clean.filter(F.col("retail_price").isNull()).count()

print(f"Silver row count   : {silver_count:>7,}")
print(f"Null product_ids   : {null_product_ids}")
print(f"Null retail_prices : {null_prices}")
print()
df_clean.groupBy("category_name").count().orderBy("category_name").show()

assert null_product_ids == 0, "QUALITY FAILED: null product_ids"
assert null_prices == 0, "QUALITY FAILED: null retail_prices"

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
