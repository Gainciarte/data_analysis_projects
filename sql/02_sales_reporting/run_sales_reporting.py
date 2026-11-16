"""SQL 02 - Sales Reporting: loads Kaizen sales orders into PostgreSQL, runs the report queries and saves results/images.

Usage (from this folder):
    uv run --python 3.12 --with pgserver --with pandas --with openpyxl --with matplotlib --with psycopg2-binary python run_sales_reporting.py
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

# ---------------------------------------------------------------- project 02
DATA = HERE.parents[1] / "python" / "02_inventory_optimization" / "dataset_kaizen analytics.xlsx"


def load_data(conn):
    sheets = pd.read_excel(DATA, sheet_name=None)
    wh = sheets["Warehouse"].rename(columns={"Warehouse Code": "warehouse_id", "City": "city",
                                             "Province": "province", "Country": "country"})
    wh = wh[["warehouse_id", "city", "province", "country"]]
    sku = sheets["SKU Items"].rename(columns={"SKU ID": "sku_id", "SKU Name": "sku_name"})
    sal = sheets["Sales Data"].iloc[:, :8]
    sal.columns = [c.strip() for c in sal.columns]
    sal = sal.rename(columns={"Order Number": "order_number", "Order Date": "order_date", "SKU ID": "sku_id",
                              "Warehouse ID": "warehouse_id", "Customer Type": "customer_type",
                              "Order Quantity": "order_qty", "Unit Sale Price": "unit_sale_price",
                              "Revenue": "revenue"})
    sal["order_number"] = sal["order_number"].str.replace(" ", "", regex=False)
    sal["order_date"] = pd.to_datetime(sal["order_date"]).dt.date
    for name, df in [("warehouses", wh), ("sku_items", sku), ("sales", sal)]:
        copy_df(conn, name, df)
        print(f"loaded {name}: {len(df):,} rows")


def main():
    conn = connect("sales_reporting")
    run_script(conn, HERE / "01_schema.sql")
    load_data(conn)
    run_script(conn, HERE / "02_views.sql")
    res = run_queries(conn, HERE / "03_reports.sql")
    for k, (t, df) in res.items():
        print(f"\n== {k}: {t}\n{df.head(40).to_string(index=False)}")
    write_tables_md(res, list(res))

    table_png(res["q02_yearly_yoy"][1], "q02 - Yearly revenue and YoY growth", "01_yearly_yoy_table.png")
    table_png(res["q04_monthly_mom"][1], "q04 - Monthly revenue: MoM, YTD running total, 3-month moving average",
              "02_monthly_mom_table.png", max_rows=14)
    table_png(res["q05_quarterly_yoy"][1], "q05 - Quarterly revenue vs same quarter last year", "03_quarterly_yoy_table.png")
    table_png(res["q09_top10_skus"][1], "q09 - Top 10 SKUs by revenue", "04_top10_skus_table.png")
    table_png(res["q10_top3_per_warehouse"][1], "q10 - Top 3 SKUs per warehouse (RANK OVER PARTITION)",
              "05_top3_per_warehouse_table.png")

    m = res["q04_monthly_mom"][1]
    ct = res["q06_customer_type"][1]
    sk = res["q09_top10_skus"][1]
    fig, ax = plt.subplots(2, 2, figsize=(15, 9))
    ax[0, 0].bar(m["year_month"], m["revenue"] / 1e6, color="#2980b9", label="Monthly revenue")
    ax[0, 0].plot(m["year_month"], m["moving_avg_3m"] / 1e6, color="#c0392b", lw=2, label="3-month moving avg")
    ax[0, 0].set_xticks(range(0, len(m), 3))
    ax[0, 0].set_xticklabels(m["year_month"][::3], rotation=60, fontsize=8)
    ax[0, 0].set_title("Monthly revenue (millions)")
    ax[0, 0].legend()
    ax[0, 1].bar(m["year_month"], m["mom_pct"].fillna(0), color=["#27ae60" if v >= 0 else "#c0392b" for v in m["mom_pct"].fillna(0)])
    ax[0, 1].set_xticks(range(0, len(m), 3))
    ax[0, 1].set_xticklabels(m["year_month"][::3], rotation=60, fontsize=8)
    ax[0, 1].set_title("Month-over-month growth (%) - LAG window")
    ax[1, 0].bar(ct["customer_type"], ct["revenue"] / 1e6, color=["#1f3b5c", "#2980b9", "#85c1e9"])
    for i, (v, p) in enumerate(zip(ct["revenue"] / 1e6, ct["pct_revenue"])):
        ax[1, 0].text(i, v, f"{v:,.0f}M ({p}%)", ha="center", va="bottom")
    ax[1, 0].set_title("Revenue by customer type (millions)")
    ax[1, 1].barh(sk["sku_id"], sk["revenue"] / 1e6, color="#8e44ad")
    ax[1, 1].invert_yaxis()
    ax[1, 1].set_title("Top 10 SKUs by revenue (millions)")
    fig.tight_layout()
    fig.savefig(IMAGES / "06_sales_dashboard.png", dpi=130, facecolor="white")
    print("\nDone. CSVs in results/, PNGs in images/")


if __name__ == "__main__":
    main()
