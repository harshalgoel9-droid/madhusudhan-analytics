# Madhusudan Ghee - Sales Performance Analysis

Python · MySQL · Tableau

A three year sales review for a ghee distributorship in western Uttar Pradesh, covering FY2022-23 to
FY2024-25.

---

## Problem statement

Madhusudan Ghee is distributed across ten towns in western Uttar Pradesh through 143 dealer and retail
accounts, served by five salesmen who each own a territory. The product comes in three pack sizes:
1 litre, 500 ml and 200 ml. Every carton holds 15 litres whatever the pack size.

The owner reviews one number each month: total revenue. Over the three years in this dataset it has
risen every year, from ₹96.0 lakh to ₹104.0 lakh. On that basis the business is treated as growing,
and decisions about pricing, stock and hiring are made accordingly.

Revenue on its own cannot support those decisions. It moves for two very different reasons. Selling
more product and charging more for the same product both push revenue up, but they point to opposite
responses. If demand is growing, invest in it. If the rate is doing the work, the business is
harvesting an existing customer base, and that stops working as soon as customers resist the next
increase.

The monthly review has a second problem. It compares each month with the month before it. For a
product with a festive season peak, that reports a crisis every December that is just the calendar.

**The question this project answers: is the business actually growing, and if so, on what?**

Four decisions depend on the answer:

| Decision | What it needs |
|---|---|
| Whether to raise prices again next year | How much of current growth is already price |
| Whether to invest in expansion or fix retention | Whether demand is rising or falling |
| How much stock and cash to hold, and when | The real shape of the season |
| Where to put field effort | Which territories and salesmen are performing |

### Scope

Three financial years of invoice data, 2,742 invoice lines. All amounts are ex-GST. Tax is collected
on the government's behalf and is not revenue, so it is excluded.

The data covers sales only. There is no cost, competitor, complaint or stock-out data, so the analysis
can establish what is happening but not always why, and cannot speak to profitability.

---

## Overview

The project runs in three stages, one tool each.

**Python** handles data preparation and exploration. It loads the four CSVs, establishes the grain,
checks the data against two business rules, joins the tables, derives the financial year, and works
through the questions with summary tables. It draws no charts.

**MySQL** holds the formal analysis. Four files build the database, load it, create a view, and answer
ten business questions. Anyone can run them and get the same numbers.

**Tableau** builds the dashboard. Five sheets and one dashboard, from a flat extract written by the
notebook.

The questions are ordered as an argument rather than a list. Q1 and Q2 ask whether the business is
growing and on what. Q3 to Q5 follow up on what the customers are doing. Q6 and Q7 cover what sells
and when. Q8 to Q10 cover who sells it and how concentrated the revenue is.

---

## Findings

| # | Finding | Evidence |
|---|---|---|
| 1 | Growth is mostly price, not volume | Revenue +8.3%, volume +2.9%, price +5.3% over three years |
| 2 | Volume fell in the most recent year | -0.6%, while revenue still rose 2.0% |
| 3 | More customers, less from each | Accounts +18.4% (114 to 135), litres per account -13.1% |
| 4 | Established customers are buying less | Same 107 accounts, -8.9% volume |
| 5 | Not explained by a pack size shift | 1 L held 53.7% of litres, then 53.2% |
| 6 | Sharp seasonality | October is 1.74x July |
| 7 | One salesman well ahead | 522 litres per account vs 291 to 365, at the same price |
| 8 | Revenue is not concentrated | Top 10 accounts hold 28.2%; it takes 77 of 143 to reach 80% |

Finding 4 is the one that matters. Finding 3 on its own has an obvious objection: adding small new
accounts would pull the average down even if nobody changed their behaviour. Holding the customer list
fixed at the 107 accounts present in all three years removes that possibility, and volume still falls.

### Answer

Revenue is up because prices are up. Underlying demand is shrinking, and it is being covered by new
account sign-ups and annual rate increases. Price rises cannot continue indefinitely. When they stop,
revenue follows volume down.

### Recommendations

1. Ask the 107 established accounts why they are buying less. The data shows that they are, not why.
   That is about two weeks of field calls.
2. Stop counting new sign-ups as growth. Twenty-one new accounts added 2,130 litres while the existing
   base lost more than that.
3. Hold the next price rise until volume is understood. Five percent has already been taken.
4. Ask Deepak Rana what he does differently. It may be his territory rather than his method, but
   asking costs nothing.
5. Change the monthly review to compare each month with the same month last year.

---

## Dashboard

<!-- Add after building in Tableau - see tableau/TABLEAU_GUIDE.md -->

![Dashboard](docs/images/dashboard.png)

---

## Repository

```
data/                          the four source tables
  sales.csv                    2,742 invoice lines
  customers.csv                143 accounts
  products.csv                 3 pack sizes
  salesmen.csv                 5 salesmen

notebooks/
  01_exploratory_analysis.ipynb    data preparation and exploration

sql/
  01_create_tables.sql         database and four tables
  02_load_data.sql             load the CSVs, with checks
  03_create_view.sql           the view the questions read from
  04_business_questions.sql    ten questions

tableau/
  ghee_sales_extract.csv       flat extract, written by the notebook
  TABLEAU_GUIDE.md             step by step dashboard build

WALKTHROUGH.md                 every step explained, and why
```

---

## Data model

```
    products                salesmen
    (3 rows)                (5 rows)
        |                       |  owns
        |                       v
        |                   customers
        |                   (143 rows)
        +---------+   +---------+
                  v   v
                 sales
              (2,742 rows)
```

A star schema. One fact table holding the numbers, three dimension tables holding the labels.

Names and cities are kept out of the fact table so each is stored once. A shop that changes its name
is corrected in one row rather than in thirty.

---

## Running it

**Requirements:** MySQL 8.0 with Workbench, Tableau Desktop, Python 3.9+.

MySQL 8.0 or later is needed. The queries use window functions, which MySQL 5.7 does not support.

### 1. Database

In MySQL Workbench, run in order:

```
sql/01_create_tables.sql     creates the ghee_analytics database and four tables
sql/02_load_data.sql         loads the CSVs - edit the file paths first
sql/03_create_view.sql       creates v_sales
sql/04_business_questions.sql    the ten questions
```

`02_load_data.sql` needs the four file paths changed to point at the `data` folder on your machine,
and local file loading enabled. Both are explained in comments at the top of that file.

### 2. Notebook

```bash
pip install -r requirements.txt
jupyter notebook notebooks/01_exploratory_analysis.ipynb
```

Runs from the CSVs. No database needed.

### 3. Dashboard

Follow `tableau/TABLEAU_GUIDE.md` using `tableau/ghee_sales_extract.csv`.

---

## Techniques

**MySQL** - joins, `GROUP BY`, `COUNT(DISTINCT)`, CTEs, `HAVING`, views, window functions (`LAG`,
`SUM() OVER (PARTITION BY)`, running totals with `ROWS UNBOUNDED PRECEDING`)

**Python** - pandas: merge, groupby, pivot_table, cohort construction, data quality checks

**Tableau** - dual axis charts, level of detail in calculated fields, dashboard actions and filtering

**Analysis** - growth decomposition into price and volume, cohort analysis, seasonality indexing,
per-unit normalisation for fair comparison, revenue concentration

---

## About the data

The dataset is synthetic. It is modelled on the operating profile of a real ghee distributorship,
including pack sizes, carton economics, territory structure, price levels and the seasonal shape of
the Indian ghee trade, but contains no real customer or commercial information.

It was generated so the analysis could be published openly.

---

## Author

Harshal Goel

[LinkedIn](https://www.linkedin.com/in/harshal-goel-11265b266) · harshalgoel9@gmail.com

## Licence

[MIT](LICENSE)
