"""SQL 02 - Sales Reporting on REAL data: UCI Online Retail II (main report) + Amazon India order lines (second report).

Builds two star schemas (retail, amazon) in an embedded PostgreSQL, runs the report queries and saves
results/*.csv and images/*.png.

Usage (from this folder):
    uv run --python 3.12 --with pgserver --with pandas --with python-calamine --with matplotlib --with psycopg2-binary python run_sales_reporting.py
"""
import os
import re
import tempfile
import time
from decimal import Decimal
from io import StringIO
from pathlib import Path

import matplotlib
import numpy as np
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


PLAIN_INT_COLS = {"fy", "year", "customer_id", "hour"}      # identifiers: no thousands separator


def fmt(v, col=None):
    if col in PLAIN_INT_COLS and isinstance(v, (int, np.integer)) and not isinstance(v, (bool, np.bool_)):
        return str(int(v))
    if v is None or (isinstance(v, float) and v != v) or v is pd.NaT:
        return "NULL"
    if isinstance(v, (bool, np.bool_)):
        return str(bool(v))
    if isinstance(v, (float, np.floating)):
        v = float(v)
        return f"{v:,.2f}" if abs(v) < 1000 and v != int(v) else f"{v:,.0f}"
    if isinstance(v, (int, np.integer)):
        return f"{int(v):,}"
    return str(v)


def to_markdown(df):
    rows = [[fmt(v, c) for v, c in zip(r, df.columns)] for r in df.itertuples(index=False)]
    head = "| " + " | ".join(df.columns) + " |"
    sep = "|" + "|".join("---" for _ in df.columns) + "|"
    return "\n".join([head, sep] + ["| " + " | ".join(r) + " |" for r in rows])


def table_png(df, title, filename, max_rows=15, col_widths=None):
    """Render a query result as an image (what a SQL client would show)."""
    d = df.head(max_rows)
    cells = [[fmt(v, c) for v, c in zip(r, d.columns)] for r in d.itertuples(index=False)]
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

# ---------------------------------------------------------------- project 02 (real data)
import urllib.request
import zipfile

DATA_DIR = HERE / "data" / "raw"          # git-ignored by the repo (**/data/raw/)
URL = "https://archive.ics.uci.edu/static/public/502/online+retail+ii.zip"
CSV = DATA_DIR / "online_retail_II.csv"
AMAZON_XLSX = HERE.parents[1] / "excel" / "01_inventory_control" / "01_inventory_control.xlsx"


def get_csv():
    """Download the UCI zip (45 MB, no login) and convert both sheets to one CSV (cached in data/raw)."""
    if CSV.exists():
        return CSV
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    zpath = DATA_DIR / "online_retail_II.zip"
    if not zpath.exists():
        print("downloading", URL)
        req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60) as resp, open(zpath, "wb") as out:
            while chunk := resp.read(1 << 20):
                out.write(chunk)
    with zipfile.ZipFile(zpath) as z:
        z.extract("online_retail_II.xlsx", DATA_DIR)
    print("converting xlsx -> csv (calamine engine, ~1 min)")
    sheets = pd.read_excel(DATA_DIR / "online_retail_II.xlsx", sheet_name=None, engine="calamine",
                           dtype={"Invoice": str, "StockCode": str})
    df = pd.concat(sheets.values(), ignore_index=True)
    df["Customer ID"] = df["Customer ID"].astype("Int64")
    df.to_csv(CSV, index=False)
    return CSV


def load_retail(conn, csv_path):
    with open(csv_path, "r", encoding="utf-8", newline="") as f:
        conn.cursor().copy_expert(
            "COPY retail.raw_transactions (invoice, stock_code, description, quantity, invoice_ts, unit_price, "
            "customer_id, country) FROM STDIN WITH (FORMAT csv, HEADER true)", f)
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM retail.raw_transactions")
    print(f"loaded retail.raw_transactions: {cur.fetchone()[0]:,} rows")


def load_amazon(conn):
    """'Clean Data' sheet, loaded exactly as stored: the day/month swap is repaired in SQL (02_model.sql)."""
    df = pd.read_excel(AMAZON_XLSX, sheet_name="Clean Data", header=1, engine="calamine")
    df = df.rename(columns={"SKU": "sku", "Category": "category", "Date": "stored_date", "Size": "size",
                            "Qty": "qty", "Amount": "amount"})
    df["stored_date"] = pd.to_datetime(df["stored_date"]).dt.date
    copy_df(conn, "amazon.raw_orders", df[["sku", "category", "stored_date", "size", "qty", "amount"]])
    print(f"loaded amazon.raw_orders: {len(df):,} rows")


def step(label, t0):
    print(f"[{time.time() - t0:7.1f}s] {label}", flush=True)


def main():
    t0 = time.time()
    csv_path = get_csv()
    step("Online Retail II csv ready", t0)
    conn = connect("sales_reporting")
    run_script(conn, HERE / "01_schema.sql")
    load_retail(conn, csv_path)
    load_amazon(conn)
    step("raw tables loaded", t0)
    run_script(conn, HERE / "02_model.sql")
    step("star schemas built (02_model.sql)", t0)
    run_script(conn, HERE / "03_views.sql")
    step("views + materialized views built (03_views.sql)", t0)
    res = run_queries(conn, HERE / "04_reports_retail.sql")
    res.update(run_queries(conn, HERE / "05_reports_amazon.sql"))
    step(f"{len(res)} report queries run", t0)
    for k, (t, df) in res.items():
        print(f"\n== {k}: {t}\n{df.head(40).to_string(index=False)}")
    write_tables_md(res, list(res))

    # ---- table renders (what a SQL client would show)
    table_png(res["q04_yearly_yoy"][1], "q04 - Online Retail II: revenue per business year (Dec-Nov) and YoY (GBP)", "01_retail_yearly_yoy_table.png")
    table_png(res["q05_monthly_mom"][1], "q05 - Monthly revenue: MoM, YoY, YTD running total, 3-month moving average (GBP)", "02_retail_monthly_mom_table.png", max_rows=25)
    table_png(res["q06_quarterly_yoy"][1], "q06 - Quarterly revenue vs same quarter last year (only complete quarters)", "03_retail_quarterly_yoy_table.png")
    table_png(res["q08_top_products"][1], "q08 - Top 15 products: RANK by revenue, DENSE_RANK by units", "04_retail_top_products_table.png")
    table_png(res["q12_top_countries"][1], "q12 - Top 10 countries: RANK by revenue, DENSE_RANK by orders", "05_retail_top_countries_table.png")
    table_png(res["q11_pareto_curve"][1], "q11 - Product contribution (Pareto)", "06_retail_pareto_table.png")
    table_png(res["q19_outlier_orders"][1], "q19 - Biggest single sale lines and the cancellations of the same product by the same customer", "07_retail_outlier_orders_table.png")
    table_png(res["a04_weekly_growth"][1], "a04 - Amazon India: weekly revenue and growth on average daily revenue (INR)", "09_amazon_weekly_table.png", max_rows=15)
    table_png(res["a09_top_skus"][1], "a09 - Amazon India: top 15 SKUs (RANK / DENSE_RANK)", "10_amazon_top_skus_table.png")
    table_png(res["a06_category_mix"][1], "a06 - Amazon India: category mix", "11_amazon_category_mix_table.png")

    # ---- retail dashboard
    m = res["q05_monthly_mom"][1]
    nv = res["q17_new_vs_returning"][1]
    co = res["q12_top_countries"][1]
    co = co[co["country"] != "United Kingdom"].sort_values("revenue")
    wd = res["q14_weekday"][1]
    hr = res["q15_hour"][1]
    fig, ax = plt.subplots(2, 3, figsize=(20, 10))
    cols = ["#bdc3c7" if p else "#2980b9" for p in m["is_partial"]]
    ax[0, 0].bar(m["year_month"], m["revenue"] / 1e6, color=cols)
    ax[0, 0].plot(m["year_month"], m["moving_avg_3m"] / 1e6, color="#c0392b", lw=2, label="3-month moving avg")
    ax[0, 0].set_xticks(range(0, len(m), 2))
    ax[0, 0].set_xticklabels(m["year_month"][::2], rotation=60, fontsize=8)
    ax[0, 0].set_title("Monthly revenue, GBP millions (grey = partial month)")
    ax[0, 0].legend()
    y = m.dropna(subset=["yoy_pct"])
    ax[0, 1].bar(y["year_month"], y["yoy_pct"], color=["#27ae60" if v >= 0 else "#c0392b" for v in y["yoy_pct"]])
    ax[0, 1].set_xticks(range(len(y)))
    ax[0, 1].set_xticklabels(y["year_month"], rotation=60, fontsize=8)
    ax[0, 1].axhline(0, color="black", lw=0.8)
    ax[0, 1].set_title("Year-over-year growth by month, % (LAG 12)")
    x = range(len(nv))
    ax[0, 2].bar(x, nv["revenue_new"] / 1e6, color="#27ae60", label="New customers")
    ax[0, 2].bar(x, nv["revenue_returning"] / 1e6, bottom=nv["revenue_new"] / 1e6, color="#2980b9", label="Returning customers")
    ax[0, 2].bar(x, nv["revenue_guest"] / 1e6, bottom=(nv["revenue_new"] + nv["revenue_returning"]) / 1e6, color="#bdc3c7", label="Guest checkout")
    ax[0, 2].set_xticks(list(x)[::2])
    ax[0, 2].set_xticklabels(nv["year_month"][::2], rotation=60, fontsize=8)
    ax[0, 2].set_title("Revenue by customer type, GBP millions")
    ax[0, 2].legend(fontsize=8)
    ax[1, 0].barh(co["country"], co["revenue"] / 1e3, color="#8e44ad")
    for i, (v, p) in enumerate(zip(co["revenue"] / 1e3, co["pct_revenue"])):
        ax[1, 0].text(v, i, f" {v:,.0f}k ({p}%)", va="center", fontsize=8)
    ax[1, 0].set_xlim(0, (co["revenue"] / 1e3).max() * 1.3)
    ax[1, 0].set_title("Countries ranked 2-10 (UK excluded), GBP thousands")
    ax[1, 1].bar(wd["weekday"], wd["revenue"] / 1e6, color="#16a085")
    for i, (v, p) in enumerate(zip(wd["revenue"] / 1e6, wd["pct_revenue"])):
        ax[1, 1].text(i, v, f"{p}%", ha="center", va="bottom", fontsize=9)
    ax[1, 1].set_title("Revenue by weekday, GBP millions")
    ax[1, 2].bar(hr["hour"], hr["revenue"] / 1e6, color="#d35400")
    ax[1, 2].set_xticks(hr["hour"])
    ax[1, 2].set_title("Revenue by hour of the day, GBP millions")
    fig.suptitle("Online Retail II (UK gift retailer, Dec-2009 .. 9-Dec-2011) - valid product sales", fontsize=13, weight="bold")
    fig.tight_layout()
    fig.savefig(IMAGES / "08_retail_dashboard.png", dpi=110, facecolor="white")
    plt.close(fig)

    # ---- amazon dashboard
    d = res["a03_daily"][1]
    w = res["a04_weekly_growth"][1]
    cat = res["a06_category_mix"][1].sort_values("revenue")
    sz = res["a07_size_mix"][1]
    fig, ax = plt.subplots(2, 2, figsize=(16, 10))
    ax[0, 0].bar(d["order_date"].astype(str), d["revenue"] / 1e6, color="#e67e22", label="Daily revenue")
    ax[0, 0].plot(d["order_date"].astype(str), d["moving_avg_7d"] / 1e6, color="#1f3b5c", lw=2, label="7-day moving avg")
    ax[0, 0].set_xticks(range(0, len(d), 7))
    ax[0, 0].set_xticklabels(d["order_date"].astype(str)[::7], rotation=60, fontsize=8)
    ax[0, 0].set_title("Daily revenue, INR millions (repaired dates)")
    ax[0, 0].legend()
    ax[0, 1].bar(w["week_start"].astype(str), w["avg_daily_revenue"] / 1e6, color=["#bdc3c7" if p else "#2980b9" for p in w["is_partial"]])
    for i, g in enumerate(w["wow_pct"]):
        if g == g:
            ax[0, 1].text(i, w["avg_daily_revenue"].iloc[i] / 1e6, f"{g:+.1f}%", ha="center", va="bottom", fontsize=8)
    ax[0, 1].set_xticks(range(len(w)))
    ax[0, 1].set_xticklabels(w["week_start"].astype(str), rotation=60, fontsize=8)
    ax[0, 1].set_title("Average daily revenue per week, INR millions (grey = partial week; label = WoW)")
    ax[1, 0].barh(cat["category"], cat["revenue"] / 1e6, color="#8e44ad")
    for i, (v, p) in enumerate(zip(cat["revenue"] / 1e6, cat["pct_revenue"])):
        ax[1, 0].text(v, i, f" {v:,.1f}M ({p}%)", va="center", fontsize=8)
    ax[1, 0].set_xlim(0, (cat["revenue"] / 1e6).max() * 1.25)
    ax[1, 0].set_title("Revenue by category, INR millions")
    ax[1, 1].bar(sz["size"], sz["pct_revenue"], color="#16a085")
    for i, v in enumerate(sz["pct_revenue"]):
        ax[1, 1].text(i, v, f"{v}%", ha="center", va="bottom", fontsize=8)
    ax[1, 1].set_title("Revenue share by size, %")
    fig.suptitle("Amazon India shipped order lines, 31-Mar-2022 .. 29-Jun-2022", fontsize=13, weight="bold")
    fig.tight_layout()
    fig.savefig(IMAGES / "12_amazon_dashboard.png", dpi=110, facecolor="white")
    plt.close(fig)
    step("Done. CSVs in results/, PNGs in images/", t0)


if __name__ == "__main__":
    main()
