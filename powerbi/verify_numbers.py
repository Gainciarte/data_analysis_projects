"""Run: python verify_numbers.py (needs pandas and numpy). Independent pandas check of the headline numbers each Power BI dashboard should show (same definitions as the DAX measures)."""
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).parent
PROC = HERE / "02_procurement_analysis" / "data"
HRD = HERE / "04_hr_headcount" / "data"
KZ = HERE / "01_warehouse_kpis" / "data"
s = pd.read_csv(PROC / "scms_lines.csv", parse_dates=["ScheduledDate", "DeliveredDate"], keep_default_na=False, na_values=[""])
num = s[s.FreightType == "Numeric"]
direct = s[s.Sourcing == "Direct from vendor"]
top = direct.groupby("Vendor").LineValue.sum().sort_values(ascending=False)
print("P02 spend", round(s.LineValue.sum() / 1e6, 1), "M | direct", round(direct.LineValue.sum() / 1e6, 1), "| vendors", direct.Vendor.nunique(),
      "| top3 share", round(top.head(3).sum() / top.sum() * 100, 1), "| RDC share", round((1 - direct.LineValue.sum() / s.LineValue.sum()) * 100, 1))
print("P02 freight M", round(s.FreightUSD.sum() / 1e6, 1), "| freight % of priced value", round(s.FreightUSD.sum() / num.LineValue.sum() * 100, 1),
      "| late %", round((s.OnTime == "Late").sum() / s.OnTime.notna().sum() * 100, 1), "| avg days late", round(s[s.OnTime == "Late"].DaysLate.mean(), 1))
print("P02 late by route", (s[s.OnTime.notna()].assign(l=lambda d: d.OnTime == "Late").groupby("FulfillVia").l.mean() * 100).round(1).to_dict())

print("P03 projects", s.ProjectCode.nunique(), "| >30d late lines", int((s.DaysLate > 30).sum()), "| late lines", int((s.OnTime == "Late").sum()),
      "| value late M", round(s[s.OnTime == "Late"].LineValue.sum() / 1e6, 1), "| projects with late line", s[s.OnTime == "Late"].ProjectCode.nunique(),
      "| avg variance days", round(s.DaysLate.mean(), 2))
bands = pd.cut(s.DaysLate, [-1e9, -1, 0, 7, 30, 1e9], labels=["Early", "On schedule", "Late 1-7", "Late 8-30", "Late >30"]).value_counts().reindex(["Early", "On schedule", "Late 1-7", "Late 8-30", "Late >30"])
print("P03 status", bands.to_dict(), "| no date", int(s.DaysLate.isna().sum()))
pl = s[s.OnTime == "Late"].groupby("ProjectCode").size().sort_values(ascending=False)
print("P03 worst projects", pl.head(3).to_dict())

w = num[num.WeightKg.notna()]
print("P05 coverage", round(len(num) / len(s) * 100, 1), "| freight/kg", round(w.FreightUSD.sum() / w.WeightKg.sum(), 2), "| insurance M", round(s.InsuranceUSD.sum() / 1e6, 2),
      "| freight per priced line", round(num.FreightUSD.sum() / len(num)))
pk = w.groupby("ShipmentMode").apply(lambda d: d.FreightUSD.sum() / d.WeightKg.sum()).round(2).to_dict()
print("P05 per kg by mode", pk, "| air/truck", round(pk["Air"] / pk["Truck"], 2))
print("P05 freight by mode M", (s.groupby("ShipmentMode").FreightUSD.sum() / 1e6).round(1).to_dict())

h = pd.read_csv(HRD / "hr_employees.csv")
print("P04 headcount", len(h), "| attrition", round(h.LeftFlag.mean() * 100, 1), "| leavers", int(h.LeftFlag.sum()), "| avg age", round(h.Age.mean(), 1),
      "| avg tenure", round(h.YearsAtCompany.mean(), 1), "| avg income", round(h.MonthlyIncome.mean()), "| female", round((h.Gender == "Female").mean() * 100, 1),
      "| OT share", round((h.OverTime == "Yes").mean() * 100, 1))
print("P04 attrition by OT", (h.groupby("OverTime").LeftFlag.mean() * 100).round(1).to_dict(), "| by tenure", (h.groupby("TenureBand").LeftFlag.mean() * 100).round(1).to_dict())

inv = pd.read_csv(KZ / "kaizen_inventory.csv")
sa = pd.read_csv(KZ / "kaizen_sales.csv", parse_dates=["OrderDate"])
days = (sa.OrderDate.max() - sa.OrderDate.min()).days + 1
dd = sa.groupby("SKU").OrderQty.sum() / days
inv["cover"] = inv.OnHandQty / inv.SKU.map(dd)
b = np.select([inv.cover.isna(), inv.cover < inv.AvgLeadTimeDays, inv.cover <= 90, inv.cover <= 365], ["No sales", "Below lead time", "Healthy", "High"], "Overstock")
inv["bucket"] = b
print("P01 stock M", round(inv.StockValue.sum() / 1e6, 2), "| SKUs", len(inv), "| below LT", int((b == "Below lead time").sum()), "| overstock", int((b == "Overstock").sum()),
      "| overstock value share", round(inv[inv.bucket == "Overstock"].StockValue.sum() / inv.StockValue.sum() * 100, 1),
      "| turnover", round(sa.SalesCost.sum() * 365 / days / inv.StockValue.sum(), 2),
      "| days cover", round(inv.OnHandQty.sum() / (sa.OrderQty.sum() / days)))
print("P01 buckets", pd.Series(b).value_counts().to_dict(), "| revenue M", round(sa.Revenue.sum() / 1e6, 1), "| orders", sa.OrderNumber.nunique())
print("P05 air share of freight", round(s[s.ShipmentMode == "Air"].FreightUSD.sum() / s.FreightUSD.sum() * 100, 1))
print("P01 wholesale revenue share", round(sa[sa.CustomerType == "Wholesale"].Revenue.sum() / sa.Revenue.sum() * 100, 1))
