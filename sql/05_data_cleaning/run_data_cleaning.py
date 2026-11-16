"""SQL 05 - Data Cleaning: loads the RAW Amazon India sheet as text into PostgreSQL, cleans it in SQL and validates the result.

Usage (from this folder):
    uv run --python 3.12 --with pgserver --with pandas --with openpyxl --with matplotlib --with psycopg2-binary python run_data_cleaning.py
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

# ---------------------------------------------------------------- project 05
DATA = HERE.parents[1] / "python" / "01_sales_eda" / "amazon.xlsx"
COLS = ["product_id", "product_name", "category", "discounted_price", "actual_price", "discount_percentage",
        "rating", "rating_count", "about_product", "user_id", "user_name", "review_id", "review_title",
        "review_content", "img_link", "product_link"] + [f"overflow_{i:02d}" for i in range(1, 17)]


def load_raw(conn):
    # dtype=str: nothing is converted by pandas - every cleaning decision is made in SQL
    df = pd.read_excel(DATA, dtype=str)
    assert df.shape[1] == len(COLS), df.shape
    df.columns = COLS
    copy_df(conn, "raw_amazon", df)
    print(f"loaded raw_amazon: {len(df):,} rows x {len(COLS)} columns")


def main():
    conn = connect("data_cleaning")
    run_script(conn, HERE / "01_schema.sql")
    load_raw(conn)
    before = run_queries(conn, HERE / "02_profile.sql")
    run_script(conn, HERE / "03_clean.sql")
    after = run_queries(conn, HERE / "04_validation.sql")
    res = {**before, **after}
    for k, (t, df) in res.items():
        print(f"\n== {k}: {t}\n{df.head(30).to_string(index=False)}")
    write_tables_md(res, list(res))

    table_png(res["p03_format_issues"][1], "p03 - Data quality issues found in the raw table (BEFORE)", "01_raw_issues_table.png")
    table_png(res["v01_before_after"][1], "v01 - Row-count audit per cleaning step", "02_before_after_table.png")
    table_png(res["v03_integrity_checks"][1], "v03 - Validation checks on the clean table (AFTER)", "03_validation_table.png")
    table_png(res["v06_sample_fixes"][1], "v06 - Raw vs clean values", "04_sample_fixes_table.png")

    ba = res["v01_before_after"][1]
    cat_before = res["p05_main_category_raw"][1]
    cat_after = res["v05_category_before_after"][1]
    fig, ax = plt.subplots(1, 2, figsize=(15, 5))
    labels = [s.split(". ", 1)[1] if ". " in s else s for s in ba["step"]]
    ax[0].barh(labels, ba["row_count"], color="#2980b9")
    ax[0].invert_yaxis()
    for i, v in enumerate(ba["row_count"]):
        ax[0].text(v, i, f" {v:,}", va="center")
    ax[0].set_xlim(0, ba["row_count"].max() * 1.15)
    ax[0].set_title("Rows after each cleaning step")
    ax[1].barh(cat_after["main_category"], cat_after["products"], color="#27ae60")
    ax[1].invert_yaxis()
    for i, v in enumerate(cat_after["products"]):
        ax[1].text(v, i, f" {v}", va="center")
    ax[1].set_xlim(0, cat_after["products"].max() * 1.12)
    ax[1].set_title("Clean layer: products by standardised main category")
    fig.tight_layout()
    fig.savefig(IMAGES / "05_cleaning_overview.png", dpi=130, facecolor="white")
    print("\nDone. CSVs in results/, PNGs in images/")


if __name__ == "__main__":
    main()
