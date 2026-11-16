"""SQL 04 - Supply Chain Queries: vendor / lead-time / warehouse analysis on the Kaizen workbook in PostgreSQL.

Usage (from this folder):
    uv run --python 3.12 --with pgserver --with pandas --with openpyxl --with matplotlib --with psycopg2-binary python run_supply_chain.py
"""
import os
import re
import tempfile
from decimal import Decimal
from io import StringIO
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
import psycopg2
import pgserver

HERE = Path(__file__).resolve().parent
RESULTS = HERE / "results"
IMAGES = HERE / "images"
RESULTS.mkdir(exist_ok=True)
IMAGES.mkdir(exist_ok=True)


def connect(db_name):
    """Start (or reuse) an embedded PostgreSQL 16 and return a fresh, empty database."""
    pgdata = Path(os.environ.get("PGDATA_DIR", Path(tempfile.gettempdir()) / "pgdata_sql"))
    srv = pgserver.get_server(pgdata, cleanup_mode=None)
    uri = srv.get_uri()
    adm = psycopg2.connect(uri)
    adm.autocommit = True
    cur = adm.cursor()
    cur.execute(f"DROP DATABASE IF EXISTS {db_name} WITH (FORCE)")
    cur.execute(f"CREATE DATABASE {db_name}")
    adm.close()
    conn = psycopg2.connect(uri.rsplit("/", 1)[0] + "/" + db_name)
    conn.autocommit = True
    return conn


def run_script(conn, path):
    """Execute a whole .sql file (DDL / views / cleaning steps)."""
    conn.cursor().execute(Path(path).read_text(encoding="utf-8"))


def copy_df(conn, table, df):
    """Bulk-load a DataFrame with COPY (NaN -> NULL)."""
    buf = StringIO()
    df.to_csv(buf, index=False, header=False, na_rep="\\N")
    buf.seek(0)
    cols = ", ".join(df.columns)
    conn.cursor().copy_expert(
        f"COPY {table} ({cols}) FROM STDIN WITH (FORMAT csv, NULL '\\N')", buf)


def _num(df):
    for c in df.columns:
        if df[c].dtype == object and df[c].map(lambda v: isinstance(v, Decimal) or v is None).all():
            df[c] = pd.to_numeric(df[c].map(lambda v: None if v is None else float(v)))
    return df


def run_queries(conn, path, save=True):
    """Run an analysis file statement by statement.
    A line '-- [name] title' labels the next statement; every SELECT result is
    returned as {name: (title, DataFrame)} and saved to results/<name>.csv"""
    out, name, title, buf = {}, None, "", []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        m = re.match(r"--\s*\[(\w+)\]\s*(.*)", line)
        if m:
            name, title = m.groups()
            continue
        if not buf and (line.strip().startswith("--") or not line.strip()):
            continue
        buf.append(line)
        if line.rstrip().endswith(";"):
            cur = conn.cursor()
            cur.execute("\n".join(buf))
            buf = []
            if cur.description:
                df = _num(pd.DataFrame(cur.fetchall(), columns=[d[0] for d in cur.description]))
                key = name or f"query_{len(out) + 1}"
                out[key] = (title, df)
                if save:
                    df.to_csv(RESULTS / f"{key}.csv", index=False)
            name, title = None, ""
    return out


def fmt(v):
    if v is None or (isinstance(v, float) and v != v):
        return "NULL"
    if isinstance(v, float):
        return f"{v:,.2f}" if abs(v) < 1000 and v != int(v) else f"{v:,.0f}"
    if isinstance(v, int):
        return f"{v:,}"
    return str(v)


def to_markdown(df):
    rows = [[fmt(v) for v in r] for r in df.itertuples(index=False)]
    head = "| " + " | ".join(df.columns) + " |"
    sep = "|" + "|".join("---" for _ in df.columns) + "|"
    return "\n".join([head, sep] + ["| " + " | ".join(r) + " |" for r in rows])


def table_png(df, title, filename, max_rows=15, col_widths=None):
    """Render a query result as an image (what a SQL client would show)."""
    d = df.head(max_rows)
    cells = [[fmt(v) for v in r] for r in d.itertuples(index=False)]
    ncol = len(d.columns)
    width = max(8, min(18, 1.5 * ncol + 2))
    fig, ax = plt.subplots(figsize=(width, 0.3 * (len(d) + 1) + 0.6))
    ax.axis("off")
    tbl = ax.table(cellText=cells, colLabels=list(d.columns), loc="upper center", cellLoc="center")
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(9)
    tbl.auto_set_column_width(list(range(ncol)))
    for (r, c), cell in tbl.get_celld().items():
        cell.set_edgecolor("#cccccc")
        if r == 0:
            cell.set_facecolor("#1f3b5c")
            cell.set_text_props(color="white", weight="bold")
        elif r % 2 == 0:
            cell.set_facecolor("#f1f5f9")
    ax.set_title(title, fontsize=11, weight="bold", loc="left", pad=8)
    fig.savefig(IMAGES / filename, dpi=140, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def write_tables_md(results, names):
    """Dump selected results as markdown for pasting into the README."""
    parts = []
    for n in names:
        title, df = results[n]
        parts.append(f"### {n} - {title}\n\n{to_markdown(df)}\n")
    (RESULTS / "readme_tables.md").write_text("\n".join(parts), encoding="utf-8")

# ---------------------------------------------------------------- project 04
DATA = HERE.parents[1] / "python" / "02_inventory_optimization" / "dataset_kaizen analytics.xlsx"


def load_data(conn):
    sheets = pd.read_excel(DATA, sheet_name=None)
    wh = sheets["Warehouse"].rename(columns={"Warehouse Code": "warehouse_id", "City": "city",
                                             "Province": "province", "Country": "country"})
    wh = wh[["warehouse_id", "city", "province", "country"]]
    sku = sheets["SKU Items"].rename(columns={"SKU ID": "sku_id", "SKU Name": "sku_name"})
    inv = sheets["Inventory Control"].rename(columns={
        "SKU ID": "sku_id", "Vendor Name": "vendor_name", "Warehouse ID": "warehouse_id",
        "Current Inventory Quantity": "on_hand_qty", "Cost per SKU": "unit_cost", "Total Value": "total_value",
        "Units (Nos/Kg)": "uom", "Average Lead Time (days)": "avg_lead_days",
        "Maximum Lead Time (days)": "max_lead_days", "Unit Price": "unit_price"})
    sal = sheets["Sales Data"].iloc[:, :8]
    sal.columns = [c.strip() for c in sal.columns]
    sal = sal.rename(columns={"Order Number": "order_number", "Order Date": "order_date", "SKU ID": "sku_id",
                              "Warehouse ID": "warehouse_id", "Customer Type": "customer_type",
                              "Order Quantity": "order_qty", "Unit Sale Price": "unit_sale_price",
                              "Revenue": "revenue"})
    sal["order_number"] = sal["order_number"].str.replace(" ", "", regex=False)
    sal["order_date"] = pd.to_datetime(sal["order_date"]).dt.date
    # vendor_name is loaded untouched: trimming is done in SQL (02_transform.sql)
    for name, df in [("warehouses", wh), ("sku_items", sku), ("stg_inventory", inv), ("sales", sal)]:
        copy_df(conn, name, df)
        print(f"loaded {name}: {len(df):,} rows")


def main():
    conn = connect("supply_chain_queries")
    run_script(conn, HERE / "01_schema.sql")
    load_data(conn)
    run_script(conn, HERE / "02_transform.sql")
    run_script(conn, HERE / "03_views.sql")
    res = run_queries(conn, HERE / "04_analysis.sql")
    for k, (t, df) in res.items():
        print(f"\n== {k}: {t}\n{df.head(40).to_string(index=False)}")
    write_tables_md(res, list(res))

    table_png(res["q03_vendor_scorecard"][1], "q03 - Vendor scorecard (ordered by revenue at risk)", "01_vendor_scorecard_table.png", max_rows=16)
    table_png(res["q04_vendor_ranking"][1], "q04 - Vendor performance index (RANK + NTILE)", "02_vendor_ranking_table.png", max_rows=16)
    table_png(res["q07_warehouse_comparison"][1], "q07 - Warehouse comparison", "03_warehouse_comparison_table.png")
    table_png(res["q06_late_skus_top"][1], "q06 - Top late-to-order SKUs by revenue at risk", "04_late_skus_table.png")

    sc = res["q03_vendor_scorecard"][1]
    cal = res["q05_order_by_calendar"][1]
    lt = res["q02_lead_time_buckets"][1]
    fig, ax = plt.subplots(1, 3, figsize=(18, 5.2))
    s = sc.sort_values("revenue_at_risk")
    ax[0].barh(s["vendor_name"], s["revenue_at_risk"] / 1e6, color="#c0392b")
    ax[0].set_title("Revenue at risk by vendor (millions)")
    ax[1].bar(lt["lead_time_bucket"], lt["skus"], color="#2980b9")
    ax[1].set_title("SKUs by average lead-time bucket")
    ax[1].tick_params(axis="x", rotation=20)
    for i, v in enumerate(lt["skus"]):
        ax[1].text(i, v, str(v), ha="center", va="bottom")
    ax[2].barh([w.split(") ")[1] for w in cal["order_window"]], cal["skus"], color="#e67e22")
    ax[2].invert_yaxis()
    ax[2].set_title("Replenishment calendar (SKUs by order window)")
    for i, v in enumerate(cal["skus"]):
        ax[2].text(v, i, f" {v}", va="center")
    fig.tight_layout()
    fig.savefig(IMAGES / "05_supply_chain_overview.png", dpi=130, facecolor="white")
    print("\nDone. CSVs in results/, PNGs in images/")


if __name__ == "__main__":
    main()
