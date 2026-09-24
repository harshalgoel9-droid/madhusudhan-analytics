# Walkthrough

Every step of the project, what it does and why it was done that way.

## Contents

1. [The business](#1-the-business)
2. [How the questions were chosen](#2-how-the-questions-were-chosen)
3. [The data model](#3-the-data-model)
4. [Why three tools](#4-why-three-tools)
5. [Python](#5-python)
6. [MySQL](#6-mysql)
7. [Tableau](#7-tableau)
8. [Findings](#8-findings)
9. [Interview questions](#9-interview-questions)
10. [What was left out](#10-what-was-left-out)

---

## 1. The business

Before writing code you need to be able to describe the business in a few sentences. Without that you
cannot tell whether a number you calculate is good or bad.

A distributor of Madhusudan Ghee in western Uttar Pradesh. It buys from the manufacturer and sells to
143 kirana shops, dairies and retail accounts across ten towns. Five salesmen each own a territory and
the accounts in it.

Three pack sizes: 1 L, 500 ml, 200 ml. Every carton holds 15 litres regardless of pack size, so 15 x
1 L, 30 x 500 ml, or 75 x 200 ml. Cartons are the selling unit and litres are the volume measure.

Three financial years, April 2022 to March 2025.

The owner looks at one number each month: total revenue. It has gone up every year.

Two details shape everything that follows.

Ghee is close to a commodity. Customers buy on price and availability and there is not much brand
loyalty, so volume is the honest measure of demand.

Every carton is 15 litres. That means a 200 ml invoice and a 1 L invoice can be compared directly in
litres with no conversion. Details like that usually decide which metric becomes the spine of the
analysis, so they are worth noticing early.

---

## 2. How the questions were chosen

Anyone can write `GROUP BY city`. Knowing which questions are worth asking is the harder part, and it
is what gets probed in interviews.

### Work backwards from a decision

A question is worth asking if the answer would change what somebody does. If the owner would behave
the same way whatever the answer, the query is decoration.

So: who reads this, what do they decide, and what would they need to know?

| Who | Decides | Needs to know |
|---|---|---|
| Owner | Expand, hold, or fix something | Is the business growing |
| Owner | Whether to raise prices again | How much of growth is already price |
| Sales manager | Where to send the team | Which territories and salesmen are performing |
| Owner | Stock and cash levels, and timing | When demand peaks |
| Owner | How worried to be about losing an account | How concentrated revenue is |

### Start from the belief, not the data

The owner's belief was that revenue is up, so the business is fine. Break that into parts and each
part is a question.

Up compared to what? Up in volume as well as in rupees?

Fine for whom? Every customer, or is an average hiding movement underneath it?

That produced the first and most important question: is revenue rising because we sell more or because
we charge more? The two lead to opposite decisions.

### Let each answer produce the next question

Analysis is a chain, not a list. Each answer should make you ask something else.

```
Q1   Revenue +8.3%, volume +2.9%
       so most growth is price. Why is volume not growing?
Q3   Are we losing customers?  No, accounts up 18%
       more customers but flat volume means each buys less
Q4   Volume per account, down 13.1%
       but small new accounts could drag that average down harmlessly
Q5   Same 107 accounts across all three years, down 8.9%
       so it is real, not a mix effect
Q6   Is it a shift to smaller packs?  No, mix is stable
       so it is genuine demand loss
```

Q5 is the one that makes the project worth showing. Q4 alone has an obvious objection: isn't that just
because you added small new accounts? Q5 is the answer to that objection, prepared before it was
asked. Anticipating the attack on your own finding and testing it is most of the difference between an
analyst and someone who runs queries.

### The supporting questions

Q7 on seasonality exists because the owner compares each month with the previous month and sees a
collapse every December. Worth checking whether that is a problem. It is the calendar.

Q8 and Q9 cover cities and salesmen, which is where the team goes and who is doing well.

Q10 covers concentration, the standard distributor worry about a handful of accounts carrying
everything.

### Questions not asked

Profit margin by SKU, because there is no cost data and any margin would be invented.

Customer lifetime value, because it needs more history and a churn definition this data cannot
support.

Forecasting next year, because three annual points is not a time series. A trend line through three
dots looks sophisticated and means nothing.

Being able to say what the data cannot answer is worth as much as the answers. It also comes up
directly in interviews.

---

## 3. The data model

The source was one wide file with every column on every row: customer name, city, salesman, product
name, pack size, rates and taxes, repeated across all 2,742 lines.

That was split into four tables.

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

This is a star schema: one fact table in the middle holding the numbers you add up, surrounded by
dimension tables holding the labels you group by.

### Why split it

In the wide file, one shop name appeared on thirty rows. Fix a typo there and you fix it thirty times,
or twenty-nine and miss one. In `customers` it appears once.

The fact table also gets smaller, storing `ACC-112` instead of the name, city and salesman on every
row.

And it is what real warehouses look like, so recognising one is expected.

### Why four tables and not eight

An earlier version of this project also carried collections, targets and receivables. Those answer
cash flow and target setting questions. Real questions, but a different project. Including them would
have meant more joins for questions this analysis never asks.

Include a table if a question needs it. Otherwise leave it out.

### Why tax was removed

The source had `gst_pct`, `gst_amount` and `invoice_value`, which is taxable plus GST.

GST is collected on the government's behalf and passed straight through. It is not revenue. Including
it would inflate every figure by 12% and change nothing about the analysis, while adding three columns
and a permanent risk of someone picking the wrong one.

Everything here is ex-GST, which is what revenue means in any P&L.

### One deliberate redundancy

`sales.litres` is always `cartons * 15`, so strictly it could be dropped. It stays because litres is
the volume measure the whole analysis uses, and having it as a column means no query has to remember
the multiplication. That is a trade of normalisation for clarity, made on purpose.

---

## 4. Why three tools

Any one of them could do the whole job. Each is better at one stage.

| Stage | Tool | Why |
|---|---|---|
| Explore | Python | Fast and disposable. Try things, change your mind. |
| Answer | MySQL | Where the data lives, and the answers need to be reproducible by anyone who runs the file. |
| Present | Tableau | The owner will not read a notebook. |

That maps onto the three questions of any analysis: what is going on, what exactly is the answer, and
how do I get someone to act on it.

The notebook draws no charts. Having two places that produce visuals means two sets of numbers that
can drift apart, so all of it is in Tableau.

---

## 5. Python

`notebooks/01_exploratory_analysis.ipynb`

### Find the grain

The first question about any table is what one row represents.

```python
print('rows              :', len(sales))                  # 2742
print('unique invoice_no :', sales.invoice_no.nunique())   # 2536
```

They differ, so a row is one line on an invoice, not one invoice. An invoice with two pack sizes is
two rows.

This decides how you count from then on. `COUNT(*)` counts lines. Counting invoices needs
`COUNT(DISTINCT invoice_no)`. Getting it wrong overstates orders by 8% with no error message.

### Check the data

```python
sales.isnull().sum()
sales.duplicated().sum()
(sales.litres == sales.cartons * 15).all()
(sales.sales_amount == sales.cartons * sales.rate_per_carton).all()
```

The last two are business rules rather than generic checks. Every carton is 15 litres, and every line
is quantity times rate. If either broke, something upstream is wrong.

It is worth doing even when the data turns out clean, because it means anything surprising later is a
business surprise rather than a bug. That distinction saves time.

### Financial year

```python
fy_start = df.invoice_date.dt.year.where(df.invoice_date.dt.month >= 4,
                                         df.invoice_date.dt.year - 1)
```

April to March. January 2025 belongs to FY2024-25. Calendar years would split each festive season
across two years and give the owner numbers he does not recognise.

Use the calendar the business uses.

### Revenue and volume together

```python
yearly['rate_per_litre'] = yearly.revenue / yearly.litres
```

Total revenue divided by total litres, not the average of `rate_per_carton`.

A plain average treats a one-carton invoice and a fifty-carton invoice as equally important. Dividing
totals weights each sale by its size, which is what the price actually achieved means. This is a common
mistake and worth being able to explain.

### The cohort

```python
years_present = df.groupby('account_code')['fy'].nunique()
loyal = years_present[years_present == 3].index
```

Covered in section 2. Hold the customer list still and any change you see is behaviour rather than a
change in who is being averaged.

---

## 6. MySQL

Four files, run in order in Workbench.

### 01_create_tables.sql

Creates the database and the four tables with primary keys, foreign keys and types.

Declaring the keys is partly documentation. Someone reading the schema learns that an invoice can hold
several SKUs, from `PRIMARY KEY (invoice_no, sku)`, and that every sale must belong to a real
customer, without opening the data.

### 02_load_data.sql

`LOAD DATA LOCAL INFILE` for each CSV, dimensions first because `sales` has foreign keys pointing at
them.

Two things usually need setting up. The file paths have to be edited to match your machine, using
forward slashes even on Windows. And local file loading has to be enabled, either with
`SET GLOBAL local_infile = 1` or in Workbench under Manage Connections, Advanced, adding
`OPT_LOCAL_INFILE=1`. If it still refuses, the Table Data Import Wizard in the Navigator works with no
configuration, just more slowly.

The file ends with row counts against expected values and two checks that should return zero. Run
those before going further. Everything built on a bad load is also bad.

### 03_create_view.sql

A view is a saved query. It stores no data and runs underneath whatever reads from it.

Every question needs the same joins and the same financial year logic. Writing that into ten queries
is ten chances to get it slightly different, and the financial year logic is fiddly enough to get
wrong once. One home for it means fixing it fixes all ten answers.

Two MySQL details in there. `year_month` is a reserved word, so the column is called `month_key`. And
`RIGHT()` works on text, so the year is cast to `CHAR` first rather than relying on MySQL to convert
it.

### 04_business_questions.sql

Ten questions, each with a comment saying what is being asked and why, so the file reads as an
argument rather than a list.

| Technique | Where | What it does |
|---|---|---|
| `GROUP BY` with aggregates | all | the foundation |
| `COUNT(DISTINCT ...)` | Q3, Q4, Q9 | count accounts once, not once per invoice |
| CTE, `WITH ... AS` | Q2, Q5, Q10 | name an intermediate result so the query reads in steps |
| `LAG()` | Q2 | put last year's value on this year's row for growth percentages |
| `SUM() OVER (PARTITION BY)` | Q6, Q7, Q8 | percentage of a group total without a second query |
| `ROWS UNBOUNDED PRECEDING` | Q10 | running total down the customer list |
| `HAVING` | Q5 | filter after grouping |

`WHERE` versus `HAVING` comes up constantly in interviews. `WHERE` filters rows before grouping,
`HAVING` filters groups after. Q5 needs `HAVING COUNT(DISTINCT fy) = 3` because appearing in three
years is a property of the group, not of any single row.

Window functions need MySQL 8.0. On 5.7 they will not run.

---

## 7. Tableau

Build steps are in `tableau/TABLEAU_GUIDE.md`.

Tableau reads one flat extract rather than connecting to MySQL directly. The extract is written by
the notebook, from the CSVs in `data/`, in its last step.

Tableau can join tables itself, but then the joins live inside a binary workbook where they cannot be
reviewed or diffed. Doing them in code and handing Tableau one clean table keeps the logic in a file
you can read.

The extract is row level, all 2,742 invoice lines. Tableau aggregates it. Handing over pre-aggregated
results would be a mistake, because the year filter and the drill-downs would have nothing to work on.

The notebook and the MySQL view `v_sales` do the same joins and the same financial year logic,
written separately. Running both and comparing the totals is what confirmed neither had a bug in it.

Five sheets, one dashboard, one filter. Every extra control invites the viewer to wander off the
point.

Each chart title states a finding rather than describing the chart. `Revenue is growing faster than
volume`, not `Revenue by Year`. Descriptive titles waste the most valuable text on the page.

---

## 8. Findings

| # | Finding | Evidence |
|---|---|---|
| 1 | Growth is mostly price | Revenue +8.3%, volume +2.9%, price +5.3% |
| 2 | Volume fell in the latest year | -0.6% while revenue rose 2.0% |
| 3 | More customers, less from each | Accounts +18.4%, litres per account -13.1% |
| 4 | Established customers buying less | Same 107 accounts, -8.9%, mostly in the final year |
| 5 | Not a pack size shift | 1 L held 53.7% then 53.2% of litres |
| 6 | Sharp seasonality | Oct 11.4% vs Jul 6.5% of annual litres, Oct is 1.74x July |
| 7 | One salesman ahead | 522 L per account vs 291 to 365, at the same rate |
| 8 | Revenue not concentrated | Top 10 accounts 28.2%, 77 of 143 to reach 80% |

Revenue is up because prices are up. Underlying demand is shrinking and it is being covered by new
sign-ups and annual rate increases. Price rises cannot continue indefinitely, and when they stop,
revenue follows volume down.

### What to do

1. Ask the 107 established accounts why they are buying less. The data shows that they are, not why.
   About two weeks of field calls.
2. Stop treating new sign-ups as growth. Twenty-one new accounts added 2,130 litres while the existing
   base lost more than that.
3. Hold the next price rise until volume is understood. Five percent has already been taken, and
   another increase into falling volume risks accelerating it.
4. Ask Deepak Rana what he does differently. He gets 43% more per account at the same price. It may be
   his territory, but asking costs nothing.
5. Change the monthly review to month against the same month last year.

### What the data cannot say

Why volume is falling, since there is no competitor, complaint or stock-out data.

Whether any of it is profitable, since there is no cost data.

What happens next. Three annual points is not a forecast.

---

## 9. Interview questions

**Walk me through the project.**

A ghee distributor was judging the business on revenue, which rose every year. I split revenue into
volume and price and found most of the growth was price. Volume was flat. Customer count was up 18%
but volume per account was down 13%, so I ran a cohort check on the 107 accounts present in all three
years. They were down 8.9%, which meant real demand loss rather than new customer mix.

**Why three tools?**

Python to explore, because it is fast and disposable. MySQL to answer, because the answers have to be
reproducible by anyone who runs the file. Tableau to present, because the owner will not read a
notebook.

**How did you decide what to analyse?**

I started from what the owner believed, that revenue is up so things are fine, and broke it into parts
that could be tested. Each answer suggested the next question. I kept only the questions where the
answer would change a decision.

**What is the weakest part of this analysis?**

It shows volume is falling but not why, because there is no competitor, pricing or stock-out data.
With three annual points I can describe the trend but not forecast it. The cohort finding is the part
I trust most, because it controls for the obvious objection.

**Isn't the drop in volume per account just from adding small new accounts?**

That was my first concern, which is why I ran the cohort. Holding the customer list fixed at the 107
accounts present in all three years, volume still fell 8.9%.

**Why didn't you use the tax data?**

GST is collected for the government and passed through, so it is not revenue. Including it would
inflate every figure by 12% and change none of the conclusions.

**Why MySQL rather than something else?**

The data is relational and the questions are aggregations across joins, which is what SQL is for. The
window functions need 8.0.

The dataset is synthetic, which is stated in the README. Say so if asked. The method is what is being
demonstrated.

---

## 10. What was left out

| Left out | Why |
|---|---|
| Collections, receivables, targets | A cash flow project. Not needed for any question here. |
| GST and tax columns | Not revenue. Inflates every figure by 12% for nothing. |
| Forecasting | Three annual points. A trend line would look clever and mean nothing. |
| Profitability | No cost data. Any margin would be invented. |
| Machine learning | Nothing here needs prediction. Reaching for a model to look advanced is a common way portfolio projects lose credibility. |

Leaving things out is the harder discipline. A short project that answers its question beats a long
one that sprawls, and every extra section is another thing to defend.
