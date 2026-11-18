"""Independent pandas check of the numbers shown in Tableau 02."""
import pandas as pd
d = pd.read_csv('data/walmart_weekly_sales.csv')
s = d.Weekly_Sales
print('total', s.sum(), 'avg', s.mean(), 'stores', d.Store.nunique(), 'rows', len(d))
h = d[d.Holiday == 'Holiday week'].Weekly_Sales.mean()
n = d[d.Holiday != 'Holiday week'].Weekly_Sales.mean()
print('hol', h, 'non', n, 'uplift', h / n - 1, (d.Holiday == 'Holiday week').sum())
t = d.groupby('Store').Weekly_Sales.sum().sort_values()
print(t.head(10).round(0).to_string())
print(t.tail(10).round(0).to_string())


def band(c, bins):
    print(d.groupby(pd.cut(d[c], bins, right=False, labels=list('1234')), observed=True).Weekly_Sales.agg(['mean', 'count']).round(0))


band('Temperature', [-99, 40, 60, 80, 999])
band('Fuel_Price', [0, 3, 3.5, 4, 99])
band('Unemployment', [0, 7, 8, 9, 99])
print(d.groupby('Year').Weekly_Sales.mean().round(0))
m = d.groupby(['Year', 'Month']).Weekly_Sales.mean()
print(m.round(0).to_string())
