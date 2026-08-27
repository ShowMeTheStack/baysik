' ============================================================
' TITLE:    Profit & Loss Statement
' CATEGORY: Business & Finance
' LEVEL:    Beginner
' TAGS:     income statement, accounting, DATA, PRINT USING, percentages
' SUMMARY:  Turn a year of revenue and expense figures into a classic two-year income statement with margins.
' ------------------------------------------------------------
' WHAT IT DOES
'   A Profit & Loss statement (also called an income statement)
'   answers: "did the business make money?" It goes top to bottom:
'       Revenue
'     - Cost of goods sold         = GROSS PROFIT
'     - Operating expenses         = OPERATING PROFIT
'     - Interest and tax           = NET PROFIT ("the bottom line")
'   The program reads two years of figures from DATA, prints them
'   side by side with the change in dollars and percent, and shows
'   each line as a percentage of revenue (a "common-size" view),
'   which makes it easy to spot costs that are growing too fast.
'   Losses are shown in brackets, as accountants do.
'
' HOW TO USE
'   Just run it and read the statement. Press a key to finish.
'
' CONCEPTS YOU WILL LEARN
'   * The structure of an income statement
'   * Gross margin, operating margin and net margin
'   * Using a "type" code in DATA to control how each line prints
'   * Showing negative numbers in (brackets) with a custom routine
'
' THINGS TO TRY
'   * Change the figures to a business you know
'   * Add a third year and an average column
'   * Flag in red any expense that grew faster than revenue
' ============================================================

DECLARE FUNCTION Acct$ (v#)

' ---- First pass: total revenue for each year ------------------------
' We need it BEFORE printing, because every line shows "% of revenue".
DIM tot#(1 TO 2), rev#(1 TO 2)
RESTORE Figures
DO
    READ code$, label$, y1#, y2#
    IF code$ = "END" THEN EXIT DO
    IF code$ = "R" THEN rev#(1) = rev#(1) + y1#: rev#(2) = rev#(2) + y2#
LOOP

CLS
COLOR 15
PRINT "     GREEN LEAF GARDEN CENTRE - PROFIT & LOSS STATEMENT"
COLOR 7
PRINT "                                     2024        2025      Change  % rev"
PRINT STRING$(75, "-")

' Running totals for both years.
' Codes in DATA:  R = revenue line, C = cost of sales, X = operating
' expense, I = interest/tax, S = subtotal to print, H = heading.
RESTORE Figures
DO
    READ code$, label$, y1#, y2#
    SELECT CASE code$
    CASE "H"
        COLOR 11: PRINT label$: COLOR 7
    CASE "R", "C", "X", "I"
        ' Revenue adds to the running total; every cost subtracts.
        IF code$ = "R" THEN sign = 1 ELSE sign = -1
        tot#(1) = tot#(1) + sign * y1#
        tot#(2) = tot#(2) + sign * y2#
        GOSUB PrintLine
    CASE "S"
        ' A subtotal line shows the running total so far (in yellow).
        y1# = tot#(1): y2# = tot#(2)
        COLOR 14: GOSUB PrintLine: COLOR 7
    CASE "END"
        EXIT DO
    END SELECT
LOOP
PRINT STRING$(75, "=")
PRINT "Press a key for the key ratios...";
k$ = INPUT$(1)

' ---- Key ratios -----------------------------------------------------
' Margins = profit as a percentage of revenue. Higher is better.
CLS
PRINT "KEY RATIOS                              2024        2025"
RESTORE Figures
FOR yr = 1 TO 2: tot#(yr) = 0: NEXT yr
DO
    READ code$, label$, y1#, y2#
    IF code$ = "END" THEN EXIT DO
    IF code$ = "R" THEN tot#(1) = tot#(1) + y1#: tot#(2) = tot#(2) + y2#
    IF code$ = "C" OR code$ = "X" OR code$ = "I" THEN tot#(1) = tot#(1) - y1#: tot#(2) = tot#(2) - y2#
    IF code$ = "S" AND label$ <> "Total revenue" THEN
        PRINT USING "  \                    \ margin   ###.#%      ###.#%"; label$; tot#(1) / rev#(1) * 100; tot#(2) / rev#(2) * 100
    END IF
LOOP
PRINT
IF tot#(2) > tot#(1) THEN PRINT "Net profit improved this year." ELSE PRINT "Net profit fell this year - check the costs!"
k$ = INPUT$(1)
END

' ------------------------------------------------------------
' PrintLine: label, two years, change, and % of revenue (year 2).
' Costs are shown as positive numbers but subtracted in the totals.
' ------------------------------------------------------------
PrintLine:
    PRINT USING "  \                            \"; label$;
    PRINT Acct$(y1#); Acct$(y2#); Acct$(y2# - y1#);
    IF rev#(2) <> 0 THEN PRINT USING "  ###.#"; y2# / rev#(2) * 100 ELSE PRINT
RETURN

Figures:
DATA H, "REVENUE", 0, 0
DATA R, "Plant sales", 412500, 455300
DATA R, "Landscaping services", 128900, 151200
DATA S, "Total revenue", 0, 0
DATA H, "COST OF SALES", 0, 0
DATA C, "Plants & materials bought", 221400, 248900
DATA C, "Direct labour", 64300, 70150
DATA S, "Gross profit", 0, 0
DATA H, "OPERATING EXPENSES", 0, 0
DATA X, "Rent", 48000, 49500
DATA X, "Salaries (office)", 71200, 74800
DATA X, "Marketing", 15800, 22400
DATA X, "Utilities & insurance", 19650, 21300
DATA X, "Depreciation", 12000, 12000
DATA S, "Operating profit", 0, 0
DATA I, "Interest on loans", 9100, 7600
DATA I, "Income tax", 18200, 24100
DATA S, "NET PROFIT", 0, 0
DATA END, "", 0, 0

' ------------------------------------------------------------
' Acct$: format whole dollars accountant-style in a 12-char column:
'    1234.5  ->  "      1,235 "      -500 -> "       (500)"
' PRINT USING can't put negatives in brackets, and QBasic has no
' way to PRINT USING into a string, so we build the text ourselves:
' take the digits from STR$, then insert a comma every 3 digits
' working from the right.
' ------------------------------------------------------------
FUNCTION Acct$ (v#)
    a# = ABS(v#)
    ' whole dollars with thousands commas
    w$ = LTRIM$(STR$(INT(a# + .5)))
    out$ = ""
    DO WHILE LEN(w$) > 3
        out$ = "," + RIGHT$(w$, 3) + out$
        w$ = LEFT$(w$, LEN(w$) - 3)
    LOOP
    out$ = w$ + out$
    IF v# < -.5 THEN out$ = "(" + out$ + ")" ELSE out$ = out$ + " "
    Acct$ = RIGHT$(SPACE$(12) + out$, 12)
END FUNCTION
