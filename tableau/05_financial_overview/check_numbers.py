import pandas as pd
D = "C:/Claude/Portafolio/repo/tableau/05_financial_overview/data/"
w = pd.read_csv(D + "budget_vs_actual.csv")
l = pd.read_csv(D + "budget_vs_actual_long.csv")
print("rows", len(w), "months", w.Month.nunique(), w.Month.min(), w.Month.max(), "categories", w.Category.nunique())
B, A = w.Budget.sum(), w.Actual.sum()
print("budget", B, "actual", A, "variance", A - B, "variance %", round((A - B) / B * 100, 2))
print("long totals", l.groupby("Type").Amount.sum().to_dict(), "match:", l[l.Type=="Budget"].Amount.sum() == B and l[l.Type=="Actual"].Amount.sum() == A)
c = w.groupby("Category").agg(budget=("Budget","sum"), actual=("Actual","sum"), var=("Variance","sum"))
c["var%"] = (c["var"] / c.budget * 100).round(1)
print(c.sort_values("var", ascending=False))
print(w.groupby(["Category","Status"]).size().unstack(fill_value=0))
print(w.Status.value_counts())
m = l.groupby(["Month","Type"]).Amount.sum().unstack()
m["var"] = m.Actual - m.Budget
print(m)
