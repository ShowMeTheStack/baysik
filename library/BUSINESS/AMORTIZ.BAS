' ============================================================
' TITLE:    Loan Amortization Schedule
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     loans, interest, PRINT USING, formulas, paging
' SUMMARY:  Work out a monthly loan payment and print the full month-by-month schedule of interest and principal.
' ------------------------------------------------------------
' WHAT IT DOES
'   When you borrow money for a car or a house you pay back the same
'   amount every month. Early on most of each payment is INTEREST;
'   later most of it pays down the PRINCIPAL (the amount borrowed).
'   This program computes the fixed payment with the standard
'   annuity formula and then shows every month: payment, interest
'   part, principal part and remaining balance. It pauses after
'   each screenful and finishes with yearly totals.
'
' HOW TO USE
'   Enter the loan amount, the yearly interest rate in percent
'   (e.g. 6.5) and the number of years. Press a key to page through
'   the schedule, or Esc to jump to the summary.
'
' CONCEPTS YOU WILL LEARN
'   * The loan payment formula  P = L * r / (1 - (1 + r) ^ -n)
'   * Rounding money to cents so the schedule balances exactly
'   * PRINT USING with commas: "###,###.##"
'   * Paging long output and waiting for a key
'
' THINGS TO TRY
'   * Add an "extra payment per month" and see how many months it saves
'   * Compare a 15-year and a 30-year mortgage: total interest?
'   * Print the schedule to a file instead of the screen
' ============================================================

DEFDBL A-Z                 ' double precision: money needs accuracy

CLS
PRINT "LOAN AMORTIZATION SCHEDULE"
PRINT "=========================="
PRINT
INPUT "Loan amount ($)        "; loan
INPUT "Yearly interest rate %"; rate
INPUT "Length in years        "; years
' Sensible defaults if the input is missing or silly.
IF loan <= 0 THEN loan = 20000
IF rate < 0 THEN rate = 0
IF years <= 0 OR years > 40 THEN years = 5

n = INT(years * 12)        ' number of monthly payments
r = rate / 100 / 12        ' MONTHLY interest rate as a fraction

' ---- The payment formula ---------------------------------------
' If you owe L and pay P each month, the balance after month k is
'   B(k) = L(1+r)^k - P((1+r)^k - 1)/r
' Setting B(n) = 0 and solving gives P = L*r / (1 - (1+r)^-n).
' With 0% interest the formula divides by zero, so treat it apart.
IF r = 0 THEN
    pay = loan / n
ELSE
    pay = loan * r / (1 - (1 + r) ^ (-n))
END IF
pay = INT(pay * 100 + .5) / 100          ' round to whole cents

PRINT
PRINT USING "Monthly payment: $$###,###.##  for ### months"; pay; n
PRINT "Press a key to see the schedule..."
k$ = INPUT$(1)

' ---- The schedule ----------------------------------------------
bal = loan
totInt = 0
yrInt = 0: yrPrin = 0
DIM yInt(1 TO 40), yPrin(1 TO 40)
skip = 0                          ' set to 1 if the user presses Esc
GOSUB Header
FOR m = 1 TO n
    ' Interest for this month is charged on what you still owe.
    interest = INT(bal * r * 100 + .5) / 100
    principal = pay - interest
    ' The last payment is adjusted so the balance hits exactly 0
    ' (rounding to cents each month leaves a few pennies over).
    IF m = n OR principal > bal THEN
        principal = bal
        thisPay = principal + interest
    ELSE
        thisPay = pay
    END IF
    bal = bal - principal
    totInt = totInt + interest

    ' Add to this year's totals (month 1-12 = year 1, etc.)
    y = INT((m - 1) / 12) + 1
    yInt(y) = yInt(y) + interest
    yPrin(y) = yPrin(y) + principal

    IF skip = 0 THEN
        PRINT USING " ###   ##,###.##   ##,###.##   ###,###.##   ###,###.##"; m; thisPay; interest; principal; bal
        ' After 18 rows, wait for a key, then clear and repeat header.
        IF m MOD 18 = 0 AND m < n THEN
            PRINT "-- more (any key, Esc = summary) --";
            k$ = INPUT$(1)
            IF k$ = CHR$(27) THEN skip = 1 ELSE GOSUB Header
        END IF
    END IF
NEXT m

' ---- Yearly summary ---------------------------------------------
PRINT
PRINT "-- any key for the yearly summary --";
k$ = INPUT$(1)
CLS
PRINT "YEARLY SUMMARY"
PRINT "Year     Interest     Principal"
FOR y = 1 TO INT((n + 11) / 12)
    PRINT USING " ##   ###,###.##    ###,###.##"; y; yInt(y); yPrin(y)
NEXT y
PRINT
PRINT USING "Total paid:      $$#,###,###.##"; loan + totInt
PRINT USING "Total interest:  $$#,###,###.##"; totInt
IF loan > 0 THEN PRINT USING "Interest is ###.#% of the amount borrowed."; totInt / loan * 100
END

Header:
    CLS
    PRINT "Month   Payment     Interest    Principal     Balance"
    PRINT STRING$(56, "-")
RETURN
