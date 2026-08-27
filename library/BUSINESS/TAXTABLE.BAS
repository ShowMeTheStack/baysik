' ============================================================
' TITLE:    Sales Tax Bracket Table
' CATEGORY: Business & Finance
' LEVEL:    Beginner
' TAGS:     sales tax, rounding, tables, multi-column layout, LPRINT
' SUMMARY:  Print the old-fashioned shop-counter chart that shows exactly how much tax to charge on every small sale.
' ------------------------------------------------------------
' WHAT IT DOES
'   Before electronic cash registers, every shop had a printed
'   "sales tax schedule" taped to the counter. It lists the ranges
'   of sale amounts that get 1 cent of tax, 2 cents, 3 cents, and
'   so on. The program builds this table for any tax rate by
'   stepping through every price, one cent at a time, and noticing
'   where the rounded tax changes. It prints the brackets in three
'   columns to fit lots on one screen, and you can send the chart
'   to the printer. A quick-lookup mode tells you the tax on any
'   amount, showing the rounding step by step.
'
' HOW TO USE
'   Enter a tax rate in percent (e.g. 6.5). The chart appears.
'   Then type amounts to look up, or 0 to finish. Answer Y to
'   print the chart.
'
' CONCEPTS YOU WILL LEARN
'   * Rounding to the nearest cent: INT(x * 100 + .5) / 100
'   * Working in whole cents with LONG integers (no float errors)
'   * Detecting "where does the value change?" in a loop
'   * Printing a list in several columns with LOCATE
'
' THINGS TO TRY
'   * Use "always round up" (ceiling) instead of normal rounding
'   * Make the chart go up to $10.00
'   * Show two tax rates side by side (state and city)
' ============================================================

CONST MAXB = 200
DIM lo&(1 TO MAXB), hi&(1 TO MAXB), tx&(1 TO MAXB)

CLS
PRINT "SALES TAX BRACKET CHART"
PRINT
INPUT "Tax rate in percent (e.g. 6.5)"; rate#
IF rate# <= 0 OR rate# > 25 THEN rate# = 6.5
r# = rate# / 100

' ---- Find the brackets -------------------------------------------------
' Walk through every sale from 1 cent to $5.00. Tax in cents =
' amount * rate rounded to the nearest whole cent. Each time that
' number changes, a new bracket begins.
nb = 0
lastTax& = -1
FOR c& = 1 TO 500
    t& = INT(c& * r# + .5 + 1E-09)    ' tiny nudge avoids 0.4999999 errors
    IF t& <> lastTax& THEN
        IF nb > 0 THEN hi&(nb) = c& - 1    ' close the previous bracket
        nb = nb + 1
        IF nb > MAXB THEN nb = MAXB: EXIT FOR
        lo&(nb) = c&: tx&(nb) = t&
        lastTax& = t&
    END IF
NEXT c&
hi&(nb) = 500

' ---- Show the brackets in 3 columns -------------------------------------
CLS
PRINT USING "SALES TAX CHART  ##.###%   (sales $0.01 to $5.00)"; rate#
perCol = 20
FOR b = 1 TO nb
    ' Which column and row does bracket b go in?
    col = ((b - 1) \ perCol) MOD 3
    row = (b - 1) MOD perCol
    IF b > 1 AND (b - 1) MOD (perCol * 3) = 0 THEN
        LOCATE 24, 1: PRINT "-- more: press a key --";
        k$ = INPUT$(1)
        CLS
        PRINT USING "SALES TAX CHART  ##.###%   (continued)"; rate#
    END IF
    IF row = 0 THEN LOCATE 2, col * 26 + 1: PRINT " Sale amount      Tax";
    LOCATE row + 3, col * 26 + 1
    ' Amounts are in cents; divide by 100 for dollars.
    ' (We write "to" and not "-" between them: in PRINT USING a "-"
    ' right after a number field means "show a trailing minus sign".)
    PRINT USING "#.## to #.##  ... .##"; lo&(b) / 100; hi&(b) / 100; tx&(b) / 100;
NEXT b
LOCATE 24, 1: PRINT "Above $5.00: tax each $5.00 part and add.";
LOCATE 25, 1: PRINT "Press a key for look-up mode...";
k$ = INPUT$(1)

' ---- Look-up mode -------------------------------------------------------
CLS
PRINT "TAX LOOK-UP  (rate"; rate#; "%)   0 = finish"
DO
    PRINT
    INPUT "Sale amount $"; amt#
    IF amt# <= 0 THEN EXIT DO
    exact# = amt# * r#
    tax# = INT(exact# * 100 + .5 + 1E-09) / 100
    PRINT USING "  $$#,###.## x ##.###% = #,###.#### exact"; amt#; rate#; exact#
    PRINT USING "  rounded to the nearest cent:   $$#,###.##"; tax#
    PRINT USING "  customer pays:                 $$#,###.##"; amt# + tax#
LOOP

INPUT "Print the bracket chart (Y/N)"; a$
IF UCASE$(LEFT$(a$, 1)) = "Y" THEN
    LPRINT USING "SALES TAX CHART ##.###%"; rate#
    LPRINT "Sale amount          Tax"
    FOR b = 1 TO nb
        LPRINT USING "$#.## to $#.##       $.##"; lo&(b) / 100; hi&(b) / 100; tx&(b) / 100
    NEXT b
    PRINT "Sent"; nb; "lines to the printer."
END IF
END
