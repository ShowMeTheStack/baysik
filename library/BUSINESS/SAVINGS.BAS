' ============================================================
' TITLE:    Compound Interest & Savings Goal
' CATEGORY: Business & Finance
' LEVEL:    Beginner
' TAGS:     compound interest, savings, menus, PRINT USING, loops
' SUMMARY:  See money grow with compound interest, and find out how much to save each month to reach a goal.
' ------------------------------------------------------------
' WHAT IT DOES
'   Option 1 grows a starting deposit plus monthly savings year by
'   year and shows how much of the final amount is YOUR money and
'   how much is interest earned ("money making money").
'   Option 2 works backwards: you name a goal (say $10,000 for a
'   car) and a deadline, and it tells you the monthly deposit you
'   need. Option 3 shows the famous "Rule of 72".
'
' HOW TO USE
'   Pick 1, 2 or 3 from the menu and answer the questions.
'   Pick 4 (or press Q) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Compound interest: interest is added to the balance, then
'     next month's interest is computed on the bigger balance
'   * Future value of a series of deposits (an annuity)
'   * Solving the formula "backwards" to find the deposit needed
'   * A simple SELECT CASE menu loop
'
' THINGS TO TRY
'   * Compare saving $100/month from age 20 vs from age 30
'   * Change compounding to daily (365 periods) - does it matter much?
'   * Draw a bar for each year with STRING$(n, 219)
' ============================================================

DEFDBL A-Z

DO
    CLS
    PRINT "SAVINGS PLANNER"
    PRINT "==============="
    PRINT "1. Grow my savings (compound interest)"
    PRINT "2. How much must I save for a goal?"
    PRINT "3. Rule of 72 - doubling time table"
    PRINT "4. Quit"
    PRINT
    INPUT "Choice"; c$
    SELECT CASE UCASE$(LEFT$(c$, 1))
        CASE "1": GOSUB Grow
        CASE "2": GOSUB Goal
        CASE "3": GOSUB Rule72
        CASE "4", "Q", "": EXIT DO
    END SELECT
    PRINT
    PRINT "Press a key for the menu...";
    k$ = INPUT$(1)
LOOP
PRINT "Happy saving!"
END

' ------------------------------------------------------------
' Grow: simulate month by month. Each month:
'   1. add interest:   balance = balance * (1 + yearlyRate/12)
'   2. add the deposit
' We print one row per year.
' ------------------------------------------------------------
Grow:
    INPUT "Starting amount ($)"; start
    INPUT "Monthly deposit ($)"; dep
    INPUT "Yearly interest rate (%)"; rate
    INPUT "Number of years"; yrs
    IF yrs < 1 OR yrs > 50 THEN yrs = 10
    r = rate / 100 / 12
    bal = start: paidIn = start
    CLS
    PRINT "Year    You paid in     Interest so far      Balance"
    PRINT STRING$(54, "-")
    FOR y = 1 TO yrs
        FOR m = 1 TO 12
            bal = bal * (1 + r) + dep
            paidIn = paidIn + dep
        NEXT m
        ' Interest earned = what we have minus what we put in.
        PRINT USING " ##     $$###,###.##     $$###,###.##    $$#,###,###.##"; y; paidIn; bal - paidIn; bal
        IF y MOD 20 = 0 AND y < yrs THEN PRINT "(more...)": k$ = INPUT$(1)
    NEXT y
    PRINT
    IF bal > 0 THEN PRINT USING "Interest makes up ##.#% of your final balance."; (bal - paidIn) / bal * 100
RETURN

' ------------------------------------------------------------
' Goal: the future value of saving D per month for n months at
' monthly rate r is
'     FV = start*(1+r)^n + D * ((1+r)^n - 1) / r
' We know FV (the goal), so solve for D:
'     D = (FV - start*(1+r)^n) * r / ((1+r)^n - 1)
' ------------------------------------------------------------
Goal:
    INPUT "Savings goal ($)"; goalAmt
    INPUT "Already saved ($)"; start
    INPUT "Months until you need it"; n
    INPUT "Yearly interest rate (%)"; rate
    IF n < 1 THEN n = 12
    r = rate / 100 / 12
    growth = (1 + r) ^ n          ' how much $1 grows to in n months
    IF r = 0 THEN
        need = (goalAmt - start) / n
    ELSE
        need = (goalAmt - start * growth) * r / (growth - 1)
    END IF
    PRINT
    IF need <= 0 THEN
        PRINT "Good news: your current savings will reach the goal on their own!"
    ELSE
        PRINT USING "Save $$##,###.## every month for ### months."; need; n
        PRINT USING "You deposit $$###,###.## in total;"; need * n
        PRINT USING "interest adds about $$###,###.##."; goalAmt - start - need * n
    END IF
RETURN

' ------------------------------------------------------------
' Rule72: a handy mental shortcut. Money doubles in about
' 72 / rate years. We compare it with the exact answer
'     years = LOG(2) / LOG(1 + rate/100)
' ------------------------------------------------------------
Rule72:
    CLS
    PRINT "Rate %   Rule of 72   Exact years"
    PRINT "------   ----------   -----------"
    FOR rate = 1 TO 12
        exact = LOG(2) / LOG(1 + rate / 100)
        PRINT USING " ##.0      ###.#         ###.#"; rate; 72 / rate; exact
    NEXT rate
    PRINT
    PRINT "The shortcut is very close for normal interest rates!"
RETURN
