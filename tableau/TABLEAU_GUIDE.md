# Building the dashboard in Tableau

`ghee_sales_dashboard.twb` in this folder has four sheets and a dashboard, all reading
`ghee_sales_extract.csv`. Open it from this folder so it finds the CSV beside it.

Two more sheets need calculated fields and are left for you to build. Steps are below under
"The two ratio sheets". They are the two charts that carry the finding, so they are worth doing.

The rest of this file builds everything from scratch, about 40 minutes.

## The data

One file: `ghee_sales_extract.csv`, 2,742 invoice lines, written by the last cell of
`notebooks/01_exploratory_analysis.ipynb`.

It is row level, so Tableau does its own summing and every filter works across every sheet.

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

## The two ratio sheets

These need calculated fields, because a ratio of two totals cannot be produced by `SUM`.

**Analysis > Create Calculated Field**, twice:

| Name | Formula |
|---|---|
| `Realised Rate per Litre` | `SUM([sales_amount]) / SUM([litres])` |
| `Litres per Account` | `SUM([litres]) / COUNTD([account_code])` |

The aggregation sits inside the formula. That is what makes them recalculate correctly wherever they
are dropped, so the same field works by year, by city or by salesman without being rewritten.

`COUNTD` counts each account once however many invoices it has. `COUNT` would count invoices.

**Price per Litre**

1. Columns: `Fy`
2. Rows: `Realised Rate per Litre`
3. Marks: Bar, and drag the same field onto Label
4. Click the axis, Edit Axis, set the range 540 to 590

Check the numbers read 552.62, 567.19, 581.65. If they do not, the calculated field is wrong.

On the truncated axis: bars normally start at zero because length encodes value. This is a trend in a
rate, and a zero-based axis flattens a real 5.3% rise into nothing. Worth being able to say why.

**Volume per Account**

1. Columns: `Fy`
2. Rows: `Litres per Account`, marks Bar, add a label
3. Drag `Account Code` to Rows, right-click it, Measure > Count (Distinct)
4. Right-click that second axis, Dual Axis, and set its mark type to Line

Check litres per account reads 152.4, 141.6, 132.4 and the account count reads 114, 127, 135.

Both series belong on one chart. Alone, "more customers" looks like good news and "less volume each"
looks like bad news. Together they are the finding.

**Add them to the dashboard**

Open the `Sales Review` dashboard and drag each new sheet in from the left panel. Tableau reflows the
layout as you drop them.

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
