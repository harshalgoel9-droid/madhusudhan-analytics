# Building the dashboard in Tableau

There is a ready-made workbook in this folder: `ghee_sales_dashboard.twb`. Open it from here, so it
finds `ghee_sales_extract.csv` sitting beside it. It has the five sheets and the dashboard already
laid out.

The rest of this file is the build from scratch, which takes about 40 minutes. Worth doing even with
the workbook in hand, because in an interview you get asked how you made it, and you can only answer
that about something you built.

Two things the workbook leaves for you, both two clicks each:

- **Revenue vs Volume** shows the two measures as stacked charts on a shared year axis. To make it a
  dual axis, right-click the `Litres` axis and choose **Dual Axis**.
- **Volume per Account** does the same with litres per account and the account count. Right-click the
  `CNTD(account_code)` axis, choose **Dual Axis**, then set that mark type to **Line**.

Everything visual in this project is built here. The Python notebook does the data preparation and
exploration but draws no charts, so there is one place to look for visuals and one set of numbers
behind them.

---

## Connect to the data

1. Tableau Desktop, **Connect > To a File > Text file**
2. Choose `tableau/ghee_sales_extract.csv`
3. Check `invoice_date` has a calendar icon. If it shows `Abc`, click the icon and change the type to
   **Date**.

That file is the four tables already joined, with the financial year and month added. It is written
by the notebook, in the last step of `notebooks/01_exploratory_analysis.ipynb`, straight from the CSVs
in `data/`.

It is row level, not aggregated. All 2,742 invoice lines are in it, so Tableau does its own summing.
Nothing has been pre-calculated except the joins and the two date columns. That matters: if the
extract held aggregated results, the year filter on the dashboard could not work.

The MySQL view `v_sales` does exactly the same joins and the same financial year logic. The two were
written separately and checked against each other, which is a useful thing to have done.

## Two calculated fields

Both are used by more than one sheet, so make them now. **Analysis > Create Calculated Field**.

**Realised Rate per Litre**

```
SUM([Sales Amount]) / SUM([Litres])
```

The price actually achieved. It has to be a ratio of two sums. Averaging `rate_per_carton` instead
would give a one-carton invoice the same weight as a fifty-carton one.

**Litres per Account**

```
SUM([Litres]) / COUNTD([Account Code])
```

Volume per customer. `COUNTD` counts each account once no matter how many invoices it has.

Because both have the aggregation inside the formula, they recalculate correctly wherever you drop
them: by year, by city, by salesman.

---

## Sheet 1: Revenue vs Volume

Shows that revenue and volume have come apart. This is the main chart.

1. **Columns:** `Fy`
2. **Rows:** `Sales Amount`, then drag `Litres` below it so there are two rows
3. Right-click the `Litres` axis, choose **Dual Axis**
4. Set both marks to **Line**
5. Click each axis, **Edit Axis**, untick *Include zero*
6. Colour `Sales Amount` dark green and `Litres` grey
7. Title: `Revenue is growing faster than volume`

Lines rather than bars because the point is the gap opening up between two series. Side by side bars
hide that.

---

## Sheet 2: Price per Litre

Quantifies how much of the growth is price.

1. **Columns:** `Fy`
2. **Rows:** `Realised Rate per Litre`
3. Marks: **Bar**, and drag the same field onto **Label**
4. Click the axis, **Edit Axis**, set the range to **540 to 590**

Title: `Price per litre rose 5.3% over three years`

On the truncated axis: the rule that bars start at zero exists because bar length encodes value, and
it is right for comparing sizes. This is a trend in a rate, and a zero-based axis turns a real 5.3%
rise into a flat line. If someone asks, that is the answer.

---

## Sheet 3: Volume per Account

The main finding.

1. **Columns:** `Fy`
2. **Rows:** `Litres per Account`, marks **Bar**, add a label
3. Drag `Account Code` to **Rows**, right-click it, **Measure > Count (Distinct)**
4. Right-click that axis, **Dual Axis**, set its mark type to **Line**

Title: `Accounts up 18%, litres per account down 13%`

Both series belong on one chart. Alone, "more customers" reads as good news and "less volume each"
reads as bad news. Together they are the finding.

---

## Sheet 4: Seasonality

1. **Columns:** `Month No`, right-click it and choose **Discrete**
2. **Rows:** `Litres`, marks **Bar**
3. **Analytics** pane, drag **Average Line** onto the view

Title: `October is 1.7x July`

All three years combined, so one odd month cannot set the pattern.

---

## Sheet 5: Salesman Productivity

1. **Rows:** `Salesman Name`
2. **Columns:** `Litres per Account`
3. Sort descending
4. Drag `Realised Rate per Litre` onto **Tooltip**
5. Marks **Bar**, label with `Litres per Account`

Title: `Deepak Rana: 43% more per account, at the same price`

Per account rather than total litres, because a salesman with more accounts should sell more.
Comparing totals would reward territory size. The rate in the tooltip shows he is not discounting to
get there.

---

## The dashboard

1. **New Dashboard**, size **1200 x 900** fixed
2. Layout:

```
+---------------------------------------------+
|  Madhusudan Ghee - Sales Review             |
+----------------------+----------------------+
|  Sheet 1             |  Sheet 2             |
|  Revenue vs Volume   |  Price per Litre     |
+----------------------+----------------------+
|  Sheet 3  -  Volume per Account             |
+----------------------+----------------------+
|  Sheet 4             |  Sheet 5             |
|  Seasonality         |  Salesman            |
+----------------------+----------------------+
```

3. One filter only. Drag `Fy` onto the dashboard, then on its dropdown choose **Apply to Worksheets >
   All Using This Data Source**. Sheets 1 to 3 are the year comparison, so right-click the filter card
   on those and choose **Ignore**.
4. Add a text object at the top with the conclusion:
   *Revenue is up 8.3%. Volume is up 2.9%. The difference is price, and established customers are
   buying 8.9% less.*

One filter is enough. Every extra control is an invitation to stop reading the point.

---

## Saving and publishing

**File > Save As** to `tableau/ghee_sales_dashboard.twbx`. Use `.twbx` rather than `.twb`, since it
packages the data inside the file and will open on any machine.

To publish, **File > Save to Tableau Public**. That makes the workbook and its data publicly visible,
which is fine here because the data is synthetic. Never publish real customer data this way.

Put the published link in the main `README.md`.

## Screenshots for the README

The README has a section for dashboard images. After building:

1. In Tableau, **Dashboard > Export Image**, save as PNG
2. Save it into `docs/images/` as `dashboard.png`

The README already links to that filename, so the image appears once the file exists. If you want
individual charts in the README too, export those sheets the same way and add the links yourself.

---

## Before calling it done

- Every sheet title states a finding, not a description. `Revenue is growing faster than volume`, not
  `Revenue by Year`.
- No axis left unlabelled.
- Rupee figures formatted with thousands separators. Right-click the measure, **Format > Numbers >
  Number (Custom)**, 0 decimals.
- The dashboard answers the original question without anyone needing to ask a follow-up.
- You can say out loud why each chart type was chosen.
