"""SQL 03 - Customer Analysis: RFM, repeat purchase, CLV and cohort retention on UCI Online Retail II in PostgreSQL.

Usage (from this folder):
    uv run --python 3.12 --with pgserver --with pandas --with python-calamine --with matplotlib --with psycopg2-binary python run_customer_analysis.py
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

# ---------------------------------------------------------------- project 03
import urllib.request
import zipfile

DATA_DIR = HERE / "data" / "raw"          # git-ignored by the repo (**/data/raw/)
URL = "https://archive.ics.uci.edu/static/public/502/online+retail+ii.zip"
CSV = DATA_DIR / "online_retail_II.csv"


def get_csv():
    """Download the UCI zip (45 MB, no login) and convert both sheets to one CSV (cached)."""
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


def load_raw(conn, csv_path):
    with open(csv_path, "r", encoding="utf-8", newline="") as f:
        conn.cursor().copy_expert(
            "COPY raw_transactions (invoice, stock_code, description, quantity, invoice_ts, unit_price, "
            "customer_id, country) FROM STDIN WITH (FORMAT csv, HEADER true)", f)
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM raw_transactions")
    print(f"loaded raw_transactions: {cur.fetchone()[0]:,} rows")


def main():
    csv_path = get_csv()
    conn = connect("customer_analysis")
    run_script(conn, HERE / "01_schema.sql")
    load_raw(conn, csv_path)
    run_script(conn, HERE / "02_prepare.sql")
    res = run_queries(conn, HERE / "03_analysis.sql")
    for k, (t, df) in res.items():
        print(f"\n== {k}: {t}\n{df.head(30).to_string(index=False)}")
    write_tables_md(res, list(res))

    table_png(res["q04_rfm_segments"][1], "q04 - RFM segments (NTILE(5) scores)", "01_rfm_segments_table.png")
    table_png(res["q06_revenue_deciles"][1], "q06 - Customer value deciles (NTILE(10))", "02_revenue_deciles_table.png")
    table_png(res["q11_cohort_retention"][1], "q11 - Monthly cohort retention (first 12 cohorts)", "03_cohort_retention_table.png")
    table_png(res["q07_repeat_purchase"][1], "q07 - Repeat purchase rate", "04_repeat_purchase_table.png")
    table_png(res["q14_top_customers"][1], "q14 - Top 10 customers (RANK) with RFM segment", "05_top_customers_table.png")

    seg = res["q04_rfm_segments"][1]
    dec = res["q06_revenue_deciles"][1]
    mo = res["q03_monthly_new_vs_returning"][1]
    mx = res["q12_cohort_matrix"][1]
    piv = mx.pivot(index="cohort", columns="month_offset", values="retention_pct")

    fig, ax = plt.subplots(2, 2, figsize=(16, 10))
    s = seg.sort_values("revenue")
    ax[0, 0].barh(s["segment"], s["revenue"] / 1e6, color="#2980b9")
    for i, (v, p, c) in enumerate(zip(s["revenue"] / 1e6, s["pct_revenue"], s["customers"])):
        ax[0, 0].text(v, i, f" {v:,.1f}M ({p}%), {c:,} cust.", va="center", fontsize=8)
    ax[0, 0].set_xlim(0, (s["revenue"] / 1e6).max() * 1.45)
    ax[0, 0].set_title("Revenue by RFM segment (millions)")
    ax[0, 1].bar(dec["decile"].astype(str), dec["pct_revenue"], color="#8e44ad")
    ax[0, 1].plot(dec["decile"].astype(str), dec["cum_pct_revenue"], color="#c0392b", marker="o")
    ax[0, 1].set_title("Share of revenue by customer decile (bars) and cumulative % (line)")
    ax[0, 1].set_xlabel("Decile (1 = best customers)")
    x = range(len(mo))
    ax[1, 0].bar(x, mo["new_customers"], color="#27ae60", label="New")
    ax[1, 0].bar(x, mo["returning_customers"], bottom=mo["new_customers"], color="#2980b9", label="Returning")
    ax[1, 0].set_xticks(list(x)[::2])
    ax[1, 0].set_xticklabels(mo["month"][::2], rotation=60, fontsize=8)
    ax[1, 0].set_title("Active customers per month: new vs returning")
    ax[1, 0].legend()
    im = ax[1, 1].imshow(piv.values, cmap="Blues", aspect="auto", vmin=0, vmax=60)
    ax[1, 1].set_yticks(range(len(piv)))
    ax[1, 1].set_yticklabels(piv.index, fontsize=7)
    ax[1, 1].set_xticks(range(piv.shape[1]))
    ax[1, 1].set_xticklabels(piv.columns, fontsize=8)
    ax[1, 1].set_xlabel("Months since first purchase")
    ax[1, 1].set_title("Cohort retention % (cohort = month of first order)")
    fig.colorbar(im, ax=ax[1, 1], shrink=0.8)
    fig.tight_layout()
    fig.savefig(IMAGES / "06_customer_dashboard.png", dpi=120, facecolor="white")
    print("\nDone. CSVs in results/, PNGs in images/")


if __name__ == "__main__":
    main()
