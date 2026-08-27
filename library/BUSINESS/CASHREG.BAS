' ============================================================
' TITLE:    Cash Register & Change Maker
' CATEGORY: Business & Finance
' LEVEL:    Beginner
' TAGS:     point of sale, change, integer math, MOD, PRINT USING
' SUMMARY:  Ring up a sale, take payment and work out the change in the fewest bills and coins.
' ------------------------------------------------------------
' WHAT IT DOES
'   A cashier scans items by typing a product code (or a price).
'   The register keeps a running total, adds tax, asks how much
'   the customer hands over and then counts out the change using
'   the biggest bills and coins first - the "greedy" method that
'   cashiers use every day. At the end of the shift it shows the
'   day's sales.
'
' HOW TO USE
'   Type a product code from the menu (A-H), or a price like 3.49
'   for something not on the list. Press Enter on an empty line to
'   finish the sale. Then type the cash the customer gives.
'   Answer N to "Another customer?" to close the register.
'
' CONCEPTS YOU WILL LEARN
'   * Working in whole CENTS (integers) to avoid rounding errors
'   * The greedy change-making algorithm with \ (integer divide)
'     and MOD
'   * Combining a lookup table with free-form input
'
' THINGS TO TRY
'   * Add the $50 and $100 bills to the DATA list
'   * Make the register refuse payment that is too small
'   * Keep count of how many of each coin the drawer has left
' ============================================================

CONST TAXRATE = .06
DIM code$(1 TO 8), item$(1 TO 8), price(1 TO 8)
FOR i = 1 TO 8: READ code$(i), item$(i), price(i): NEXT i

' Denominations in CENTS, biggest first, with their names.
CONST NDENOM = 8
DIM dval&(1 TO NDENOM), dname$(1 TO NDENOM)
FOR i = 1 TO NDENOM: READ dval&(i), dname$(i): NEXT i

customers = 0: daySales = 0

DO
    CLS
    PRINT "=========== CORNER CAFE REGISTER ==========="
    FOR i = 1 TO 8
        PRINT USING "  ! \             \ $$#.##"; code$(i); item$(i); price(i);
        IF i MOD 2 = 0 THEN PRINT ELSE PRINT "   ";
    NEXT i
    PRINT "============================================"
    PRINT "Code or price, Enter alone = total"
    subtotal = 0
    nItems = 0
    DO
        LINE INPUT "> "; t$
        t$ = UCASE$(LTRIM$(RTRIM$(t$)))
        IF t$ = "" THEN EXIT DO
        found = 0
        FOR i = 1 TO 8
            IF t$ = code$(i) THEN
                found = i
                EXIT FOR
            END IF
        NEXT i
        IF found THEN
            subtotal = subtotal + price(found)
            PRINT USING "     \             \      $$##.##"; item$(found); price(found)
            nItems = nItems + 1
        ELSEIF VAL(t$) > 0 THEN
            ' Not a code: treat it as a typed price (open department).
            subtotal = subtotal + VAL(t$)
            PRINT USING "     Misc. item           $$##.##"; VAL(t$)
            nItems = nItems + 1
        ELSE
            PRINT "     ?? unknown code"
        END IF
    LOOP
    IF nItems = 0 THEN EXIT DO

    tax = INT(subtotal * TAXRATE * 100 + .5) / 100
    total = subtotal + tax
    PRINT "     -----------------------------------"
    PRINT USING "     Subtotal                 $$##.##"; subtotal
    PRINT USING "     Tax 6%                   $$##.##"; tax
    PRINT USING "     TOTAL                    $$##.##"; total

    ' ---- Payment ---------------------------------------------------
    DO
        INPUT "     Cash tendered $"; paid
        IF paid >= total THEN EXIT DO
        PRINT USING "     That's not enough - still need $$##.##"; total - paid
    LOOP

    ' Convert money to whole cents FIRST. Floating point can store
    ' 0.1 only approximately, so 0.30 - 0.20 might be 0.0999999.
    ' Integers (long, &) are exact.
    changeC& = CLNG(paid * 100) - CLNG(total * 100)
    PRINT USING "     CHANGE DUE               $$##.##"; changeC& / 100
    PRINT

    ' ---- Greedy change: biggest denomination first ---------------
    ' count = change \ value  (how many fit)
    ' change = change MOD value (what is left over)
    left& = changeC&
    FOR i = 1 TO NDENOM
        cnt& = left& \ dval&(i)
        IF cnt& > 0 THEN
            PRINT USING "       ## x \          \"; cnt&; dname$(i)
            left& = left& MOD dval&(i)
        END IF
    NEXT i
    IF changeC& = 0 THEN PRINT "       Exact change - thank you!"

    customers = customers + 1
    daySales = daySales + total
    PRINT
    INPUT "Another customer (Y/N)"; a$
LOOP UNTIL UCASE$(LEFT$(a$, 1)) = "N"

CLS
PRINT "END OF SHIFT REPORT"
PRINT "-------------------"
PRINT USING "Customers served:  ####"; customers
PRINT USING "Total sales:      $$#,###.##"; daySales
IF customers > 0 THEN PRINT USING "Average sale:     $$#,###.##"; daySales / customers
END

' ---- Menu: code, item, price -----------------------------------------
DATA A, "Coffee", 2.25, B, "Latte", 3.75, C, "Tea", 1.95, D, "Muffin", 2.89
DATA E, "Bagel", 1.79, F, "Sandwich", 6.49, G, "Juice", 3.10, H, "Cookie", 1.25
' ---- Denominations in cents ------------------------------------------
DATA 2000, "$20 bill", 1000, "$10 bill", 500, "$5 bill", 100, "$1 bill"
DATA 25, "quarter", 10, "dime", 5, "nickel", 1, "penny"
