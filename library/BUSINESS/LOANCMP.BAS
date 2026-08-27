' ============================================================
' TITLE:    Loan Offer Comparison
' CATEGORY: Business & Finance
' LEVEL:    Advanced
' TAGS:     loans, APR, bisection, FUNCTION, comparison table
' SUMMARY:  Compare loan offers with different rates, terms and fees - and find each one's true APR by bisection.
' ------------------------------------------------------------
' WHAT IT DOES
'   Banks advertise loans in confusing ways: "low 5.9% rate!" (but
'   a $900 fee), "no fees!" (but 7.2%), "small payments!" (because
'   it lasts 7 years). To compare fairly you need:
'     * the monthly payment
'     * the TOTAL you will pay back, and the total cost of borrowing
'     * the APR - the "annual percentage rate" that includes fees.
'   Fees are taken from the money you receive, so you get less cash
'   but pay as if you borrowed the full amount. The APR is the rate
'   at which the payments exactly pay off the cash you RECEIVED.
'   There is no simple formula for that, so we SEARCH for it with
'   the bisection method: guess, check, halve the range, repeat.
'
' HOW TO USE
'   Enter the amount you want to borrow, then press Enter to use
'   the four sample offers, or type M to enter your own (up to 4).
'
' CONCEPTS YOU WILL LEARN
'   * The annuity payment formula as a reusable FUNCTION
'   * Solving an equation numerically with bisection
'   * Marking the best value in each column of a table
'
' THINGS TO TRY
'   * Add a "balloon payment" at the end of a loan
'   * Show how much you save by paying $50 extra each month
'   * Draw the remaining balance of each offer on one graph
' ============================================================

DECLARE FUNCTION Payment# (principal#, yearRate#, months%)
DECLARE FUNCTION FindAPR# (cashGot#, pay#, months%)

CONST MAXO = 4
DIM lender$(1 TO MAXO), rate#(1 TO MAXO), term%(1 TO MAXO), fee#(1 TO MAXO)
DIM pay#(1 TO MAXO), total#(1 TO MAXO), cost#(1 TO MAXO), apr#(1 TO MAXO)

CLS
PRINT "LOAN OFFER COMPARISON"
PRINT
INPUT "How much do you want to borrow ($)"; amt#
IF amt# <= 0 THEN amt# = 15000
LINE INPUT "Enter = sample offers, M = type my own: "; m$

IF UCASE$(LEFT$(m$, 1)) = "M" THEN
    n = 0
    DO WHILE n < MAXO
        PRINT
        LINE INPUT "Lender name (Enter to stop): "; t$
        IF t$ = "" THEN EXIT DO
        n = n + 1
        lender$(n) = LEFT$(t$, 16)
        INPUT "  Interest rate % per year"; rate#(n)
        INPUT "  Length in months"; term%(n)
        INPUT "  Up-front fees $"; fee#(n)
        IF term%(n) < 1 THEN term%(n) = 12
        IF rate#(n) < 0 THEN rate#(n) = 0
        IF fee#(n) < 0 OR fee#(n) >= amt# THEN fee#(n) = 0
    LOOP
    IF n = 0 THEN PRINT "No offers entered.": END
ELSE
    n = MAXO
    FOR i = 1 TO n: READ lender$(i), rate#(i), term%(i), fee#(i): NEXT i
END IF

' ---- Work out every offer -----------------------------------------
FOR i = 1 TO n
    pay#(i) = Payment#(amt#, rate#(i), term%(i))
    total#(i) = pay#(i) * term%(i) + fee#(i)        ' all money you hand over
    cost#(i) = total#(i) - amt#                     ' price of borrowing
    apr#(i) = FindAPR#(amt# - fee#(i), pay#(i), term%(i))
NEXT i

' Which offer is best in each column? (lowest number wins)
bestPay = 1: bestCost = 1: bestApr = 1
FOR i = 2 TO n
    IF pay#(i) < pay#(bestPay) THEN bestPay = i
    IF cost#(i) < cost#(bestCost) THEN bestCost = i
    IF apr#(i) < apr#(bestApr) THEN bestApr = i
NEXT i

CLS
PRINT USING "Borrowing $$###,###.##"; amt#
PRINT
PRINT "Lender             Rate Months  Fees    Payment  Total cost    APR"
PRINT STRING$(72, "-")
FOR i = 1 TO n
    PRINT USING "\              \ ##.##%   ###  #,###  "; lender$(i); rate#(i); term%(i); fee#(i);
    ' Highlight the best value of each column in bright green.
    IF i = bestPay THEN COLOR 10 ELSE COLOR 7
    PRINT USING "##,###.##  "; pay#(i);
    IF i = bestCost THEN COLOR 10 ELSE COLOR 7
    PRINT USING "###,###.##  "; cost#(i);
    IF i = bestApr THEN COLOR 10 ELSE COLOR 7
    PRINT USING "##.##%"; apr#(i)
    COLOR 7
NEXT i
PRINT STRING$(72, "-")
PRINT "Green = best in that column."
PRINT
PRINT "Cheapest overall: "; lender$(bestCost)
' Find the most expensive offer to show how much choosing well saves.
worst = 1
FOR i = 2 TO n
    IF cost#(i) > cost#(worst) THEN worst = i
NEXT i
PRINT USING "It saves $$##,###.## compared with the most expensive offer."; cost#(worst) - cost#(bestCost)
PRINT
PRINT "Notice: the lowest PAYMENT is often NOT the cheapest loan -"
PRINT "longer loans have small payments but cost more in interest."
END

' code: lender, yearly rate %, months, up-front fees
DATA "Big City Bank", 5.9, 60, 900
DATA "Credit Union", 6.4, 48, 0
DATA "QuickCash Online", 7.2, 84, 250
DATA "Dealer Finance", 4.5, 36, 1200

' ------------------------------------------------------------
' Payment#: fixed monthly payment for a loan.
'     P = L * r / (1 - (1 + r) ^ -n),  r = monthly rate
' ------------------------------------------------------------
FUNCTION Payment# (principal#, yearRate#, months%)
    r# = yearRate# / 1200
    IF r# = 0 THEN
        Payment# = principal# / months%
    ELSE
        Payment# = principal# * r# / (1 - (1 + r#) ^ (-months%))
    END IF
END FUNCTION

' ------------------------------------------------------------
' FindAPR#: which yearly rate makes "pay# per month for months%"
' exactly repay cashGot#?
' Bisection: the right rate lies between lo and hi. Try the middle.
' If its payment is too BIG the rate is too high -> hi = mid,
' otherwise lo = mid. Each step halves the range; 60 steps give
' far more precision than we need.
' ------------------------------------------------------------
FUNCTION FindAPR# (cashGot#, pay#, months%)
    lo# = 0: hi# = 100
    FOR k = 1 TO 60
        mid# = (lo# + hi#) / 2
        IF Payment#(cashGot#, mid#, months%) > pay# THEN hi# = mid# ELSE lo# = mid#
    NEXT k
    FindAPR# = (lo# + hi#) / 2
END FUNCTION
