# Power BI report – design specification

## Report overview

Three pages. Each page answers a distinct business question so a client
can immediately see the value of the data model without context.

| Page | Question answered |
|---|---|
| Executive Summary | How is the business performing overall? |
| Regional Performance | Which regions are driving results — and what does each manager see? |
| Product Deep Dive | Which products and categories are generating the most value? |

Canvas size: 1280 × 720 (16:9 widescreen). Theme: default with brand colours
customised to a clean dark-header / white-body palette.

---

## Page 1 — Executive Summary

**Purpose:** top-line KPIs and revenue trend visible at a glance.

### Visuals

| Visual | Type | Fields / Measure | Notes |
|---|---|---|---|
| Total Revenue | Card | `[Total Revenue]` | Large font, bold |
| Total Orders | Card | `[Total Orders]` | |
| Avg Order Value | Card | `[Avg Order Value]` | |
| Completion Rate | Card | `[Completion Rate %]` | |
| Revenue trend | Line chart | X: `DimDate[MonthName]` Y: `[Total Revenue]`, `[Completed Revenue]` | Two lines, monthly grain |
| YTD vs PY | Clustered bar | X: `DimDate[YearNumber]` Y: `[YTD Revenue]` | Slicer-driven |
| MoM Growth | KPI visual | Value: `[Total Revenue]` Target: `[Revenue PY]` Trend: `DimDate[FullDate]` | Shows positive/negative indicator |
| Orders by status | Donut chart | Legend: `FactSales[OrderStatus]` Values: `[Total Orders]` | Completed / pending / cancelled |

### Slicers

- `DimDate[YearNumber]` — single select, top-right
- `DimDate[QuarterName]` — multi select

### Interactions

Line chart → KPI cards: cross-filter on. Donut → line chart: cross-filter on.

---

## Page 2 — Regional Performance

**Purpose:** demonstrate RLS in a visible, testable way. Each regional manager
sees only their region's bars. The national manager sees all four.

### Visuals

| Visual | Type | Fields / Measure | Notes |
|---|---|---|---|
| Revenue by region | Clustered bar | X: `[Total Revenue]` Y: `DimCustomer[Region]` | Sorted descending |
| Orders by region | Clustered bar | X: `[Total Orders]` Y: `DimCustomer[Region]` | Same Y axis, side by side |
| Regional map | Filled map or bubble map | Location: `DimStore[City]` Size: `[Total Revenue]` | Bubble size = revenue |
| Store performance | Table | `DimStore[StoreName]`, `DimStore[Region]`, `DimStore[Manager]`, `[Total Revenue]`, `[Total Orders]`, `[Completion Rate %]` | Sortable |
| Revenue trend by region | Line chart | X: `DimDate[MonthName]` Y: `[Total Revenue]` Legend: `DimCustomer[Region]` | One line per region |

### Slicers

- `DimDate[YearNumber]`
- `DimCustomer[Region]` — multi select (admin view only; RLS overrides selection)

### RLS demo note

To demonstrate RLS in the published report:
1. Publish to Power BI service
2. Go to the dataset → Security → assign `north.manager@demo.com` to the
   Regional Sales Manager role
3. "View as" that user — the bar chart collapses to a single North bar
4. Switch to `national.manager@demo.com` — all four bars return

---

## Page 3 — Product Deep Dive

**Purpose:** show the category hierarchy and product-level detail using
the `Product Hierarchy` defined in the semantic model.

### Visuals

| Visual | Type | Fields / Measure | Notes |
|---|---|---|---|
| Revenue by category | Treemap | Group: `DimProduct[CategoryName]` Values: `[Total Revenue]` | Click to drill |
| Top 10 products | Bar chart | Y: `DimProduct[ProductName]` X: `[Total Revenue]` | Top N filter: 10 |
| Category matrix | Matrix | Rows: `DimProduct[CategoryName]` / `DimProduct[ProductName]` Cols: `DimDate[YearNumber]` Values: `[Total Revenue]`, `[Units Sold]`, `[Avg Order Value]` | Expandable hierarchy |
| Margin vs Revenue | Scatter | X: `[Total Revenue]` Y: `DimProduct[MarginPct]` Size: `[Units Sold]` Legend: `DimProduct[CategoryName]` | Each bubble = one product |
| Revenue vs PY | Waterfall | `[Total Revenue]`, `[Revenue PY]`, `[Revenue YoY %]` | Category grain |

### Slicers

- `DimDate[YearNumber]`
- `DimProduct[CategoryName]` — multi select

### Drill-through

Set up drill-through from Page 1 and Page 2 to Page 3 on `DimProduct[ProductName]`.
Right-click any product in the report → Drill through → Product Deep Dive.

---

## DAX measures reference

All measures are defined in `FactSales.tmdl` and organised into display folders.

| Folder | Measure | Format |
|---|---|---|
| Revenue | Total Revenue | $#,##0.00 |
| Revenue | Completed Revenue | $#,##0.00 |
| Revenue | Avg Order Value | $#,##0.00 |
| Orders | Total Orders | #,##0 |
| Orders | Completed Orders | #,##0 |
| Orders | Completion Rate % | 0.0% |
| Orders | Units Sold | #,##0 |
| Time Intelligence | YTD Revenue | $#,##0.00 |
| Time Intelligence | Revenue PY | $#,##0.00 |
| Time Intelligence | Revenue YoY % | +0.0%;-0.0%;0.0% |
| Time Intelligence | Revenue MoM % | +0.0%;-0.0%;0.0% |

---

## Semantic model checklist

Before publishing, verify the following in Power BI Desktop:

- [ ] All six tables import successfully from Fabric Warehouse
- [ ] Four relationships exist (FactSales → each dim) — verify in Model view
- [ ] DimDate is marked as date table (right-click → Mark as date table → FullDate)
- [ ] `UserRegionMapping` table is hidden from report view
- [ ] Surrogate key columns (CustomerSK, ProductSK, StoreSK, DateKey, OrderDateKey) are hidden
- [ ] `Product Hierarchy` drill-down works in the matrix visual
- [ ] `Date Hierarchy` drill-down works in line charts
- [ ] RLS role visible under Modeling → Manage roles
- [ ] "View as role" with `north.manager@demo.com` shows North data only
- [ ] "View as role" with `national.manager@demo.com` shows all regions
