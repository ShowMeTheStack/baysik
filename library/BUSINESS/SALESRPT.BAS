' ============================================================
' TITLE:    Quarterly Sales Report
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     reports, 2D arrays, bar chart, SCREEN 12, PRINT USING, DATA
' SUMMARY:  Crunch a table of regional sales into a formatted report with totals, then draw a grouped bar chart.
' ------------------------------------------------------------
' WHAT IT DOES
'   A company sells in five regions. The monthly figures for one
'   quarter are stored in DATA. The program builds a classic
'   spreadsheet-style report: rows = regions, columns = months,
'   with row totals, column totals, each region's share of sales
'   and growth from the first month to the last. Then it switches
'   to graphics and draws a grouped bar chart (three bars per
'   region, one colour per month) with a legend.
'
' HOW TO USE
'   Read the report, press a key to see the chart, and press a key
'   again to finish.
'
' CONCEPTS YOU WILL LEARN
'   * Two-dimensional arrays: sales(region, month)
'   * Row totals, column totals and a grand total
'   * Percentages and growth rates
'   * Scaling numbers into pixels for a bar chart
'
' THINGS TO TRY
'   * Add a fourth month (change NMON and the DATA)
'   * Sort the regions from best to worst before printing
'   * Draw a pie chart of each region's share with CIRCLE and PAINT
' ============================================================

CONST NREG = 5, NMON = 3
DIM region$(1 TO NREG), mon$(1 TO NMON)
DIM sales(1 TO NREG, 1 TO NMON)
DIM rowTot(1 TO NREG), colTot(1 TO NMON)

FOR m = 1 TO NMON: READ mon$(m): NEXT m
FOR r = 1 TO NREG
    READ region$(r)
    FOR m = 1 TO NMON
        READ sales(r, m)
    NEXT m
NEXT r

' ---- Totals --------------------------------------------------------
' Each number is added to its row total AND its column total.
grand = 0: best = 0: maxVal = 0
FOR r = 1 TO NREG
    FOR m = 1 TO NMON
        rowTot(r) = rowTot(r) + sales(r, m)
        colTot(m) = colTot(m) + sales(r, m)
        IF sales(r, m) > maxVal THEN maxVal = sales(r, m)
    NEXT m
    grand = grand + rowTot(r)
    ' Remember the best region seen so far (r = 1 is best at first).
    IF r = 1 THEN best = 1 ELSE IF rowTot(r) > rowTot(best) THEN best = r
NEXT r

' ---- Text report ----------------------------------------------------
CLS
PRINT "NORTHWIND TRADING - Q3 SALES REPORT"
PRINT
PRINT "Region       ";
FOR m = 1 TO NMON: PRINT USING "     \ \   "; mon$(m); : NEXT m
PRINT "       Total  Share  Growth"
PRINT STRING$(77, "-")
FOR r = 1 TO NREG
    PRINT USING "\          \ "; region$(r);
    FOR m = 1 TO NMON
        PRINT USING " ###,###.##"; sales(r, m);
    NEXT m
    ' share = this region / everything; growth = (last - first)/first
    share = rowTot(r) / grand * 100
    growth = (sales(r, NMON) - sales(r, 1)) / sales(r, 1) * 100
    PRINT USING " ####,###.## ###.#% +##.#%"; rowTot(r); share; growth
NEXT r
PRINT STRING$(77, "-")
PRINT "TOTAL        ";
FOR m = 1 TO NMON: PRINT USING " ###,###.##"; colTot(m); : NEXT m
PRINT USING " ####,###.## 100.0%"; grand
PRINT
PRINT USING "Average per region per month: $$###,###.##"; grand / (NREG * NMON)
PRINT "Top region: "; region$(best)
PRINT
PRINT "Press a key for the chart..."
k$ = INPUT$(1)

' ---- Grouped bar chart -----------------------------------------------
SCREEN 12
CLS
x0 = 70: y0 = 400            ' chart origin (bottom-left), in pixels
chartH = 330: chartW = 540
groupW = chartW / NREG       ' horizontal space for each region
barW = (groupW - 20) / NMON  ' leave a 20 pixel gap between groups

' Gridlines and dollar labels every 1/5 of the top value.
top = INT(maxVal / 10000 + 1) * 10000   ' round up to next 10,000
FOR g = 0 TO 5
    y = y0 - chartH * g / 5
    LINE (x0, y)-(x0 + chartW, y), 8
    LOCATE INT(y / 16) + 1, 1: PRINT USING "###,###"; top * g / 5;
NEXT g

FOR r = 1 TO NREG
    gx = x0 + (r - 1) * groupW + 10
    FOR m = 1 TO NMON
        h = sales(r, m) / top * chartH          ' scale dollars to pixels
        bx = gx + (m - 1) * barW
        LINE (bx, y0 - h)-(bx + barW - 2, y0), 8 + m, BF   ' filled bar
        LINE (bx, y0 - h)-(bx + barW - 2, y0), 15, B       ' white outline
    NEXT m
    ' Region name centred under its group.
    LOCATE 27, INT((gx + groupW / 2 - 10) / 8) + 1 - LEN(region$(r)) \ 2
    PRINT region$(r);
NEXT r
LINE (x0, y0)-(x0, y0 - chartH), 15
LINE (x0, y0)-(x0 + chartW, y0), 15

' Legend
LOCATE 1, 22: PRINT "Q3 sales by region and month"
FOR m = 1 TO NMON
    LINE (420 + (m - 1) * 70, 434)-(434 + (m - 1) * 70, 446), 8 + m, BF
    LOCATE 28, 56 + (m - 1) * 9: PRINT mon$(m);
NEXT m
k$ = INPUT$(1)
SCREEN 0
END

' ---- Data: month names, then each region with 3 months -----------------
DATA "Jul", "Aug", "Sep"
DATA "North", 48250.00, 51900.50, 55100.75
DATA "South", 39875.25, 37210.00, 41980.10
DATA "East", 61200.00, 64450.40, 70325.00
DATA "West", 52780.90, 49900.00, 47215.60
DATA "Central", 28400.00, 33150.25, 39020.00
