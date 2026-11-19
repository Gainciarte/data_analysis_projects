import pandas as pd
d = pd.read_csv("C:/Claude/Portafolio/repo/tableau/03_customer_segmentation/data/customer_segments.csv")
print(d.columns.tolist(), len(d), d.CustomerID.nunique())
print("revenue", round(d.Monetary.sum(), 2), "avg", round(d.Monetary.mean(), 2))
g = d.groupby("Segment").agg(n=("CustomerID", "count"), rev=("Monetary", "sum"), rec=("Recency", "mean"),
                              fre=("Frequency", "mean"), mon=("Monetary", "mean"))
g["cust%"] = (g.n / g.n.sum() * 100).round(1)
g["rev%"] = (g.rev / g.rev.sum() * 100).round(1)
print(g.round(2).sort_values("rev", ascending=False))
print("champions share", round(g.loc["Champions", "rev"] / g.rev.sum() * 100, 1))
