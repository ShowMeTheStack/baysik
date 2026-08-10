' ============================================================
' TITLE:    Tip Calculator and Bill Splitter
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     money, percent, rounding, print using, input
' SUMMARY:  Work out the tip on a restaurant bill and split it fairly - so the pennies add up exactly.
' ------------------------------------------------------------
' WHAT IT DOES
'   Enter the bill, the tip percentage and how many people are
'   paying.  It shows a table of tips at 10/15/18/20/25 % and
'   then each person's share for the tip you chose.
'
'   Money trick: 100.00 split three ways is 33.333...  You can't
'   pay a third of a cent!  We work in WHOLE CENTS, give each
'   person the rounded-down share, and hand the few leftover
'   cents to the first people so the total is exactly right.
'
' HOW TO USE
'   Answer the three questions.  Then press any key to start
'   again, or Q / Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Percentages: tip = bill * percent / 100
'   * Working in integer cents to avoid rounding errors
'   * Integer division \ and remainder MOD
'   * PRINT USING "$$##.##" for money
'
' THINGS TO TRY
'   * Add tax before (or after) the tip.
'   * Round each share UP to the next whole dollar.
'   * Let each person enter what they ordered and split by item.
' ============================================================

DO
    CLS
    COLOR 14: PRINT "TIP CALCULATOR & BILL SPLITTER": COLOR 7
    PRINT
    INPUT "Bill total ($): ", bill#
    IF bill# <= 0 THEN bill# = 50: PRINT "(using $50.00 as an example)"

    ' ---- A quick table of common tip rates ----
    PRINT
    PRINT "  Tip %      Tip       Total"
    FOR i = 1 TO 5
        READ pct
        tip# = bill# * pct / 100
        PRINT USING "   ##%   $$###.##  $$####.##"; pct; tip#; bill# + tip#
    NEXT i
    RESTORE          ' so READ starts from the first DATA again next time
    PRINT

    INPUT "Tip percent to use: ", pct
    IF pct < 0 THEN pct = 0
    INPUT "Number of people: ", people
    people = INT(people)
    IF people < 1 THEN people = 1

    ' ---- Everything in whole cents (long integers) ----
    ' The & suffix makes a LONG integer: no fractions, no surprises.
    billC& = CLNG(bill# * 100)
    tipC& = CLNG(billC& * pct / 100)
    totalC& = billC& + tipC&

    share& = totalC& \ people          ' everyone pays at least this
    extra& = totalC& MOD people        ' cents left over

    PRINT
    PRINT USING "Bill $$####.##  +  tip $$###.##  =  $$####.##"; billC& / 100; tipC& / 100; totalC& / 100
    PRINT
    IF extra& = 0 THEN
        PRINT USING "Each of the ## people pays $$###.##"; people; share& / 100
    ELSE
        ' The first "extra" people pay one cent more.
        PRINT USING "## of you pay $$###.##"; extra&; (share& + 1) / 100
        PRINT USING "## of you pay $$###.##"; people - extra&; share& / 100
    END IF
    ' Check: does it add up?
    check& = share& * people + extra&
    PRINT USING "(check: shares add up to $$####.##)"; check& / 100

    PRINT
    PRINT "Any key = new bill,  Q / Esc = quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
LOOP UNTIL k$ = "Q" OR k$ = CHR$(27)
END

DATA 10, 15, 18, 20, 25
