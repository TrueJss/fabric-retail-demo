"""
generate_mock_data.py

Generates realistic synthetic retail data for the Microsoft Fabric Retail Demo.
Run from the repo root:

    python scripts/generate_mock_data.py

Outputs are written to data/mock/:
    orders.csv          – 5,000 sales transactions
    stores.csv          – 20 store locations across 4 regions
    products.xlsx       – 105 products (sheet: Products) + 7 categories (sheet: Categories)
    customers.json      – 500 customers with nested address structure
    returns.json        – ~400 returns (intentionally denormalised for Silver cleaning demo)
"""

import json
import random
from datetime import date, timedelta
from pathlib import Path

import pandas as pd
from faker import Faker

# ── Reproducibility ───────────────────────────────────────────────────────────
SEED = 42
random.seed(SEED)
fake = Faker("en_US")
Faker.seed(SEED)

# ── Config ────────────────────────────────────────────────────────────────────
OUTPUT_DIR = Path(__file__).parent.parent / "data" / "mock"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

N_CUSTOMERS = 500
N_ORDERS = 5_000
N_STORES = 20
ORDER_START = date(2023, 1, 1)
ORDER_END = date(2024, 12, 31)
REGIONS = ["North", "South", "East", "West"]

RETURN_REASONS = [
    "Defective product",
    "Wrong item received",
    "Changed my mind",
    "Item not as described",
    "Better price found elsewhere",
    "Arrived too late",
    "Damaged in shipping",
    "Duplicate order",
    "Gift not needed",
    "Quality not as expected",
]


# ── Helpers ───────────────────────────────────────────────────────────────────
def random_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


# ── 1. Categories ─────────────────────────────────────────────────────────────
df_categories = pd.DataFrame([
    {"category_id": 1, "name": "Electronics"},
    {"category_id": 2, "name": "Clothing"},
    {"category_id": 3, "name": "Home & Garden"},
    {"category_id": 4, "name": "Sports"},
    {"category_id": 5, "name": "Food & Beverage"},
    {"category_id": 6, "name": "Books"},
    {"category_id": 7, "name": "Toys"},
])


# ── 2. Products ───────────────────────────────────────────────────────────────
# (category_id, name, cost_price, retail_price)
_PRODUCTS_RAW = [
    # Electronics
    (1, "Wireless Headphones Pro",           42.00, 129.99),
    (1, "Wireless Headphones Lite",          18.00,  49.99),
    (1, "Smart Watch Series X",              85.00, 249.99),
    (1, "Smart Watch Fitness",               45.00, 129.99),
    (1, "Bluetooth Speaker Mini",            22.00,  59.99),
    (1, "Bluetooth Speaker Max",             55.00, 149.99),
    (1, "USB-C Hub 7-Port",                  25.00,  69.99),
    (1, "Laptop Stand Aluminium",            18.00,  49.99),
    (1, "Mechanical Keyboard",               65.00, 179.99),
    (1, "Wireless Mouse",                    22.00,  59.99),
    (1, "Power Bank 20000mAh",               28.00,  79.99),
    (1, "Webcam HD 1080p",                   35.00,  99.99),
    (1, "Monitor Light Bar",                 20.00,  54.99),
    (1, "Smart Plug 4-Pack",                 15.00,  39.99),
    (1, "Cable Management Kit",               8.00,  24.99),
    # Clothing
    (2, "Classic White T-Shirt",              6.00,  24.99),
    (2, "Slim Fit Jeans",                    22.00,  69.99),
    (2, "Hooded Sweatshirt",                 18.00,  54.99),
    (2, "Running Shorts",                    10.00,  34.99),
    (2, "Winter Jacket",                     55.00, 159.99),
    (2, "Athletic Leggings",                 14.00,  44.99),
    (2, "Polo Shirt",                        12.00,  39.99),
    (2, "Canvas Sneakers",                   28.00,  79.99),
    (2, "Wool Beanie",                        7.00,  22.99),
    (2, "Baseball Cap",                       8.00,  27.99),
    (2, "Cotton Socks 6-Pack",                5.00,  17.99),
    (2, "Leather Belt",                      12.00,  39.99),
    (2, "Waterproof Rain Jacket",            45.00, 129.99),
    (2, "Compression Tights",               16.00,  49.99),
    (2, "Casual Dress",                      20.00,  59.99),
    # Home & Garden
    (3, "Drip Coffee Maker",                 35.00,  99.99),
    (3, "French Press 1L",                   12.00,  34.99),
    (3, "Blender 600W",                      28.00,  79.99),
    (3, "Throw Pillow Set (2)",              14.00,  44.99),
    (3, "Scented Candle Large",               8.00,  27.99),
    (3, "Ceramic Plant Pot",                  7.00,  19.99),
    (3, "LED Desk Lamp",                     18.00,  54.99),
    (3, "Bamboo Cutting Board",              10.00,  29.99),
    (3, "Airtight Storage Jars (4)",         12.00,  34.99),
    (3, "Picture Frame Set (3)",              9.00,  27.99),
    (3, "Non-Stick Frying Pan",              16.00,  49.99),
    (3, "Electric Kettle 1.7L",              22.00,  64.99),
    (3, "Wall Clock Minimalist",             14.00,  39.99),
    (3, "Bath Towel Set",                    18.00,  54.99),
    (3, "Woven Storage Basket",              11.00,  32.99),
    # Sports
    (4, "Yoga Mat 6mm",                      12.00,  39.99),
    (4, "Stainless Water Bottle",            10.00,  32.99),
    (4, "Resistance Bands Set",               8.00,  27.99),
    (4, "Jump Rope Speed",                    5.00,  16.99),
    (4, "Foam Roller 45cm",                  10.00,  29.99),
    (4, "Gym Gloves Padded",                  8.00,  24.99),
    (4, "Pull-Up Bar Doorway",               22.00,  64.99),
    (4, "Dumbbell Set 5-25lb",               85.00, 229.99),
    (4, "Running Belt",                       7.00,  22.99),
    (4, "Cycling Gloves",                     9.00,  27.99),
    (4, "Massage Gun Mini",                  35.00,  99.99),
    (4, "Sport Backpack 30L",                22.00,  64.99),
    (4, "Knee Support Brace",                 9.00,  27.99),
    (4, "Adjustable Bench",                  75.00, 199.99),
    (4, "Skipping Mat",                      14.00,  39.99),
    # Food & Beverage
    (5, "Single Origin Coffee Beans 500g",   12.00,  34.99),
    (5, "Protein Bar Box (12)",              18.00,  49.99),
    (5, "Green Tea Collection",               8.00,  24.99),
    (5, "Extra Virgin Olive Oil 750ml",      10.00,  29.99),
    (5, "Hot Sauce Trio Set",                 9.00,  27.99),
    (5, "Almond Butter 500g",                 8.00,  24.99),
    (5, "Granola Mix 1kg",                    7.00,  22.99),
    (5, "Herbal Tea Sampler 40pc",            7.00,  21.99),
    (5, "Matcha Powder 100g",                12.00,  34.99),
    (5, "Dark Chocolate Box (16)",           14.00,  39.99),
    (5, "Sea Salt Caramel Mix",               9.00,  27.99),
    (5, "Collagen Coffee Creamer",           11.00,  32.99),
    (5, "Sparkling Water Maker",             55.00, 149.99),
    (5, "Moringa Superfood Powder",          14.00,  39.99),
    (5, "Reusable Coffee Pods 3-Pack",        6.00,  19.99),
    # Books
    (6, "Atomic Habits",                      8.00,  18.99),
    (6, "The Lean Startup",                   9.00,  22.99),
    (6, "Python for Data Analysis",          28.00,  59.99),
    (6, "Deep Work",                          9.00,  21.99),
    (6, "Thinking Fast and Slow",            10.00,  24.99),
    (6, "The Psychology of Money",            9.00,  21.99),
    (6, "Designing Data-Intensive Apps",     35.00,  69.99),
    (6, "Sapiens A Brief History",           10.00,  24.99),
    (6, "Zero to One",                        9.00,  21.99),
    (6, "The Pragmatic Programmer",          30.00,  59.99),
    (6, "Good to Great",                     10.00,  24.99),
    (6, "The Art of War Annotated",           6.00,  14.99),
    (6, "Build An Unorthodox Guide",          9.00,  22.99),
    (6, "Clean Code",                        28.00,  54.99),
    (6, "No Rules Rules",                    10.00,  24.99),
    # Toys
    (7, "Classic Building Bricks 500pc",     18.00,  54.99),
    (7, "Strategy Board Game",               22.00,  64.99),
    (7, "1000-Piece Jigsaw Puzzle",          12.00,  34.99),
    (7, "Wooden Train Set",                  28.00,  79.99),
    (7, "Remote Control Car",                35.00,  99.99),
    (7, "Art and Craft Kit Kids",            14.00,  42.99),
    (7, "Science Experiment Kit",            18.00,  54.99),
    (7, "Magnetic Tiles 60pc",               25.00,  74.99),
    (7, "Play-Doh Mega Set",                 14.00,  39.99),
    (7, "Trivia Card Game Family",           10.00,  29.99),
    (7, "Dinosaur Figures Set 12pc",         12.00,  35.99),
    (7, "Giant Jenga Outdoor",               20.00,  59.99),
    (7, "Dollhouse Furniture Set",           22.00,  64.99),
    (7, "Learning Tablet for Kids",          35.00,  99.99),
    (7, "Mini Basketball Hoop Indoor",       18.00,  54.99),
]

df_products = pd.DataFrame([
    {
        "product_id": i + 1,
        "category_id": cat,
        "name": name,
        "cost_price": cost,
        "retail_price": retail,
    }
    for i, (cat, name, cost, retail) in enumerate(_PRODUCTS_RAW)
])

product_price_map = dict(zip(df_products["product_id"], df_products["retail_price"]))
product_name_map = dict(zip(df_products["product_id"], df_products["name"]))


# ── 3. Stores → stores.csv ────────────────────────────────────────────────────
_STORE_NAMES = [
    "Downtown Flagship", "Westfield Mall", "Airport Terminal", "University District",
    "Harbour Front", "Central Station", "Riverside Plaza", "Oakwood Centre",
    "Tech Quarter", "Lakeside Outlet", "Midtown Gallery", "Suburban Hub",
    "Garden District", "Sports Complex", "Historic Quarter", "Beachside Shop",
    "Mountain View", "City Centre East", "North Park", "South Gate",
]

stores = []
for i in range(N_STORES):
    region = REGIONS[i % len(REGIONS)]  # round-robin → 5 stores per region
    stores.append({
        "store_id": i + 1,
        "name": _STORE_NAMES[i],
        "region": region,
        "city": fake.city(),
        "state": fake.state_abbr(),
        "manager": fake.name(),
        "open_date": fake.date_between(
            start_date=date(2018, 1, 1),
            end_date=date(2022, 12, 31),
        ).isoformat(),
    })

df_stores = pd.DataFrame(stores)


# ── 4. Customers → customers.json ─────────────────────────────────────────────
# Intentional design: nested address object → flattened in Silver notebook
customers = []
for i in range(N_CUSTOMERS):
    region = random.choice(REGIONS)
    customers.append({
        "customer_id": i + 1,
        "first_name": fake.first_name(),
        "last_name": fake.last_name(),
        "email": fake.email(),
        "phone": fake.phone_number(),
        "address": {
            "street": fake.street_address(),
            "city": fake.city(),
            "state": fake.state_abbr(),
            "region": region,         # used for dynamic RLS in Gold
        },
        "registration_date": fake.date_between(
            start_date=date(2020, 1, 1),
            end_date=date(2022, 12, 31),
        ).isoformat(),
    })


# ── 5. Orders → orders.csv ────────────────────────────────────────────────────
store_ids = df_stores["store_id"].tolist()
product_ids = df_products["product_id"].tolist()
customer_ids = [c["customer_id"] for c in customers]

_STATUSES = ["completed", "pending", "cancelled"]
_STATUS_WEIGHTS = [0.70, 0.15, 0.15]

orders = []
for i in range(N_ORDERS):
    product_id = random.choice(product_ids)
    retail_price = product_price_map[product_id]

    # Occasional discount (5–20%) – realistic price variation
    discount = random.choices(
        [0, 0.05, 0.10, 0.15, 0.20],
        weights=[0.60, 0.15, 0.12, 0.08, 0.05],
        k=1,
    )[0]
    unit_price = round(retail_price * (1 - discount), 2)

    orders.append({
        "order_id": i + 1,
        "customer_id": random.choice(customer_ids),
        "store_id": random.choice(store_ids),
        "product_id": product_id,
        "quantity": random.randint(1, 5),
        "unit_price": unit_price,
        "order_date": random_date(ORDER_START, ORDER_END).isoformat(),
        "status": random.choices(_STATUSES, weights=_STATUS_WEIGHTS, k=1)[0],
    })

df_orders = pd.DataFrame(orders)
completed_orders = df_orders[df_orders["status"] == "completed"]


# ── 6. Returns → returns.json ─────────────────────────────────────────────────
# Intentional data quality issues for the Silver cleaning demo:
#   - ~10% null reason values        → ISNULL / fillna handling
#   - ~15% whitespace-padded reasons → str.strip()
#   - Denormalised customer_id, product_id, product_name → dropped in Silver
#   - return_date as ISO datetime string vs order_date as date-only → type cast
n_returns = min(400, len(completed_orders))
return_sample = completed_orders.sample(n=n_returns, random_state=SEED)

returns = []
for idx, (_, order) in enumerate(return_sample.iterrows()):
    order_date = date.fromisoformat(order["order_date"])
    max_return_date = min(order_date + timedelta(days=30), ORDER_END)

    if order_date >= max_return_date:
        return_date = order_date + timedelta(days=1)
    else:
        return_date = random_date(order_date + timedelta(days=1), max_return_date)

    # Null reason (~10%)
    if random.random() < 0.10:
        reason = None
    else:
        reason = random.choice(RETURN_REASONS)
        # Whitespace padding (~15% of non-null reasons)
        if random.random() < 0.15:
            reason = f"  {reason}  "

    returns.append({
        "return_id": idx + 1,
        "order_id": int(order["order_id"]),
        "customer_id": int(order["customer_id"]),            # denormalised
        "product_id": int(order["product_id"]),              # denormalised
        "product_name": product_name_map[order["product_id"]],  # denormalised
        "reason": reason,
        "return_date": f"{return_date.isoformat()}T00:00:00",   # datetime vs date-only
    })


# ── Write outputs ─────────────────────────────────────────────────────────────
print("Generating mock data → data/mock/\n")

df_orders.to_csv(OUTPUT_DIR / "orders.csv", index=False)
print(f"  ✓ orders.csv          {len(df_orders):>6,} rows")

df_stores.to_csv(OUTPUT_DIR / "stores.csv", index=False)
print(f"  ✓ stores.csv          {len(df_stores):>6,} rows")

with pd.ExcelWriter(OUTPUT_DIR / "products.xlsx", engine="openpyxl") as writer:
    df_products.to_excel(writer, sheet_name="Products", index=False)
    df_categories.to_excel(writer, sheet_name="Categories", index=False)
print(f"  ✓ products.xlsx       {len(df_products):>6,} products · {len(df_categories)} categories")

with open(OUTPUT_DIR / "customers.json", "w", encoding="utf-8") as f:
    json.dump(customers, f, indent=2, ensure_ascii=False)
print(f"  ✓ customers.json      {len(customers):>6,} records")

with open(OUTPUT_DIR / "returns.json", "w", encoding="utf-8") as f:
    json.dump(returns, f, indent=2, ensure_ascii=False)
print(f"  ✓ returns.json        {len(returns):>6,} records")

# ── Summary stats ─────────────────────────────────────────────────────────────
print("\nOrder status breakdown:")
print(df_orders["status"].value_counts().to_string())

print("\nOrders by region (via store):")
region_map = dict(zip(df_stores["store_id"], df_stores["region"]))
df_orders["region"] = df_orders["store_id"].map(region_map)
print(df_orders.groupby("region")["order_id"].count().to_string())

print("\nDone. Upload data/mock/ to your Fabric Lakehouse /Files/bronze/.")
