import pandas as pd
D = "C:/Claude/Portafolio/repo/tableau/04_supply_chain_map/data/"
c = pd.read_csv(D + "scms_by_country.csv")
m = pd.read_csv(D + "scms_country_mode.csv")
print("countries", c.Country.nunique(), "lines", c.Lines.sum(), "value", round(c.LineValue.sum(), 2),
      "late lines", c.LateLines.sum(), "late %", round(c.LateLines.sum() / c.Lines.sum() * 100, 2))
c["late%"] = (c.LateLines / c.Lines * 100).round(1)
print("top 5 by value\n", c.sort_values("LineValue", ascending=False).head(5)[["Country", "Lines", "LineValue", "late%"]])
print("highest late % (>=100 lines)\n", c[c.Lines >= 100].sort_values("late%", ascending=False).head(5)[["Country", "Lines", "late%"]])
print("lowest late % (>=100 lines)\n", c[c.Lines >= 100].sort_values("late%").head(3)[["Country", "Lines", "late%"]])
g = m.groupby("ShipmentMode").agg(lines=("Lines", "sum"), value=("LineValue", "sum"), late=("LateLines", "sum"))
g["late%"] = (g.late / g.lines * 100).round(1)
print(g.sort_values("value", ascending=False))
print("mode totals match country totals:", round(m.LineValue.sum(), 2) == round(c.LineValue.sum(), 2), m.Lines.sum() == c.Lines.sum())
