"""Re-computes the ABC/XYZ classification from the 'Clean Data' sheet after repairing the dates.

Why: in the workbook, day and month were swapped for every date whose day is <= 12
(the text 'MM-DD-YY' was read with a day-first locale), which spread 3 months of sales over
12 calendar months and inflated the coefficient of variation. Undoing the swap gives the true
range, 31 Mar 2022 - 29 Jun 2022, which matches the source file.

Run from this folder:  python verify_xyz.py
Needs: pandas, openpyxl, matplotlib
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

HERE = Path(__file__).parent
XLSX = HERE / "01_inventory_control.xlsx"
OUT = HERE / "results"
OUT.mkdir(exist_ok=True)

clean = pd.read_excel(XLSX, sheet_name="Clean Data", header=1)
abc = pd.read_excel(XLSX, sheet_name="ABC Analysis", header=1).dropna(subset=["ABC Class"])

# 1) repair dates: swap day and month where the stored day is <= 12
d = clean["Date"]
# The delivered workbook already holds the repaired dates (range 31 Mar - 29 Jun 2022). Only an older copy
# (dates spread over 2022-01..2022-12) still needs the day/month swap.
needs_swap = d.max() > pd.Timestamp("2022-06-30")
swap = (d.dt.day <= 12) if needs_swap else pd.Series(False, index=d.index)
fixed = d.copy()
if needs_swap:
    fixed[swap] = pd.to_datetime({"year": d[swap].dt.year, "month": d[swap].dt.day, "day": d[swap].dt.month})
clean["Date_fixed"] = fixed
print("Date range in workbook :", d.min().date(), "->", d.max().date())
print("Date range after repair:", fixed.min().date(), "->", fixed.max().date())

# 2) monthly demand per SKU on full months only (April-June 2022); March has 152 rows (31 Mar only)
full = clean[clean["Date_fixed"] >= "2022-04-01"]
monthly = full.pivot_table(index="SKU", columns=full["Date_fixed"].dt.month, values="Qty", aggfunc="sum", fill_value=0)
monthly.columns = ["Apr", "May", "Jun"]
cv = monthly.std(axis=1, ddof=1) / monthly.mean(axis=1)
xyz = pd.cut(cv, [-1, 0.5, 1.0, 1e9], right=False, labels=["X", "Y", "Z"])
res = pd.DataFrame({"SKU": monthly.index, "Apr": monthly["Apr"].values, "May": monthly["May"].values,
                    "Jun": monthly["Jun"].values, "CV": cv.values.round(3), "XYZ": xyz.values})
res = res.merge(abc[["SKU", "ABC Class"]], on="SKU", how="left")
res.to_csv(OUT / "xyz_recomputed.csv", index=False)

counts = res["XYZ"].value_counts().reindex(["X", "Y", "Z"])
print("XYZ (Apr-Jun, CV with n=3 months):", counts.to_dict(), "of", len(res), "SKUs with sales in Apr-Jun")
mat = pd.crosstab(res["ABC Class"], res["XYZ"]).reindex(index=["A", "B", "C"], columns=["X", "Y", "Z"]).fillna(0).astype(int)
print(mat)
mat.to_csv(OUT / "abc_xyz_matrix.csv")

# 3) matrix figure
fig, ax = plt.subplots(figsize=(5.4, 4))
ax.imshow(mat.values, cmap="Blues")
ax.set_xticks(range(3), mat.columns)
ax.set_yticks(range(3), mat.index)
for i in range(3):
    for j in range(3):
        v = mat.values[i, j]
        ax.text(j, i, f"{v:,}", ha="center", va="center", color="white" if v > mat.values.max() * 0.6 else "black")
ax.set_title("ABC x XYZ matrix (SKUs, Apr-Jun 2022)")
ax.set_xlabel("XYZ (CV of monthly demand)")
ax.set_ylabel("ABC (annual sales value)")
fig.tight_layout()
(HERE / "images").mkdir(exist_ok=True)
fig.savefig(HERE / "images" / "02_abc_xyz_matrix.png", dpi=130)
