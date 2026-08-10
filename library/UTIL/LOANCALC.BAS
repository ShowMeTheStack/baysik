' ============================================================
' TITLE:    Loan and Mortgage Calculator
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     finance, interest, amortization, print using, formulas
' SUMMARY:  Works out monthly loan payments and prints a year-by-year amortization schedule.
' ------------------------------------------------------------
' WHAT IT DOES
'   Enter the amount borrowed, the yearly interest rate and the
'   number of years.  The program computes the fixed monthly
'   payment with the standard annuity formula:
'
'              P * r
'     M = -----------------       P = principal (amount borrowed)
'          1 - (1 + r)^(-n)       r = monthly rate (APR / 12 / 100)
'                                 n = number of monthly payments
'
'   Then it simulates every month: interest is charged on what
'   is still owed, and the rest of the payment reduces the debt.
'   Early payments are mostly interest; late ones mostly principal.
'   It also shows how much you save by paying extra each month.
'
' HOW TO USE
'   Answer the prompts.  The schedule is shown one year per line.
'   Afterwards press any key to do another, or Q/Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * The annuity (loan payment) formula and the ^ operator
'   * Simulating a process month by month in a loop
'   * PRINT USING with money formats like "$$###,###.##"
'   * Special case: a 0% loan (the formula divides by zero!)
'
' THINGS TO TRY
'   * Show the month-by-month table with paging.
'   * Draw a bar chart of interest vs principal for each year.
'   * Work backwards: given a payment, how much can you borrow?
' ============================================================

DO
    CLS
    COLOR 10: PRINT "LOAN / MORTGAGE CALCULATOR": COLOR 7
    PRINT STRING$(60, "-")
    INPUT "Amount borrowed ($): ", P#
    INPUT "Yearly interest rate (%), e.g. 6.5: ", apr#
    INPUT "Length of loan (years): ", yrs
    INPUT "Extra payment each month ($, 0 for none): ", extra#
    yrs = INT(yrs)
    IF P# <= 0 OR yrs < 1 OR yrs > 50 OR apr# < 0 OR extra# < 0 THEN
        PRINT "Please use a positive amount, 0+ % and 1-50 years."
    ELSE
        n = yrs * 12                   ' number of monthly payments
        r# = apr# / 100 / 12           ' monthly interest rate
        IF r# = 0 THEN
            M# = P# / n                ' no interest: just split it up
        ELSE
            M# = P# * r# / (1 - (1 + r#) ^ (-n))
        END IF
        ' Round to whole cents like a real bank would.
        M# = INT(M# * 100 + .5) / 100

        PRINT
        PRINT USING "Monthly payment:      $$###,###.##"; M#
        PRINT USING "Total of payments:    $$#,###,###.##"; M# * n
        PRINT USING "Total interest:       $$#,###,###.##"; M# * n - P#
        PRINT
        PRINT "Year    Interest   Principal     Balance"

        ' ---- Month-by-month simulation ----
        bal# = P#: totInt# = 0: month = 0
        yInt# = 0: yPrin# = 0
        DO WHILE bal# > .005 AND month < n
            month = month + 1
            interest# = INT(bal# * r# * 100 + .5) / 100   ' this month's interest
            pay# = M# + extra#
            IF pay# > bal# + interest# THEN pay# = bal# + interest#   ' last payment
            prin# = pay# - interest#
            bal# = bal# - prin#
            totInt# = totInt# + interest#
            yInt# = yInt# + interest#: yPrin# = yPrin# + prin#
            ' Print a line at the end of each year (or the last month).
            IF month MOD 12 = 0 OR bal# <= .005 THEN
                IF CSRLIN < 22 THEN
                    PRINT USING " ##   ###,###.##  ###,###.##  ###,###.##"; (month + 11) \ 12; yInt#; yPrin#; bal#
                END IF
                yInt# = 0: yPrin# = 0
            END IF
        LOOP
        IF CSRLIN >= 22 THEN PRINT " ... (schedule cut to fit the screen)"
        IF extra# > 0 THEN
            PRINT
            PRINT USING "With $$#,###.## extra, paid off in ### months, "; extra#; month;
            PRINT USING "saving $$###,###.##"; M# * n - P# - totInt#
        END IF
    END IF
    PRINT
    PRINT "Any key = another loan,  Q / Esc = quit";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
LOOP UNTIL k$ = "Q" OR k$ = CHR$(27)
CLS
END
