' ============================================================
' TITLE:    Payroll with Tax Brackets
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     payroll, tax brackets, DATA, overtime, FUNCTION, PRINT USING
' SUMMARY:  Compute gross pay with overtime, progressive income tax from a bracket table, and print pay stubs.
' ------------------------------------------------------------
' WHAT IT DOES
'   A company pays its staff by the hour. Hours over 40 in a week
'   are overtime at "time and a half". From the gross pay we take:
'     * income tax using PROGRESSIVE BRACKETS - each slice of the
'       income is taxed at its own rate (not the whole amount!)
'     * a flat 7.65% social insurance (FICA-style) deduction
'     * a retirement contribution chosen by each employee
'   The bracket table lives in DATA lines, so changing tax law
'   means editing data, not code. Finally a payroll register
'   summarises the whole company.
'
' HOW TO USE
'   Just run it. Press a key after each pay stub, Esc to skip to
'   the register.
'
' CONCEPTS YOU WILL LEARN
'   * Progressive (marginal) tax calculation with a loop
'   * Keeping rules (brackets) in DATA, separate from the logic
'   * FUNCTION procedures that return a value
'   * Effective vs marginal tax rate
'
' THINGS TO TRY
'   * Add a new bracket at 37% above $10,000 per week
'   * Let the user type in hours for each employee
'   * Add a double-time rate for hours over 60
' ============================================================

DECLARE FUNCTION IncomeTax# (gross#)
DECLARE FUNCTION Cents# (x#)

' Bracket table (weekly amounts, so the numbers are small).
' Each bracket: the income where it STARTS, and its rate.
CONST NBRACK = 5
DIM SHARED bStart#(1 TO NBRACK), bRate#(1 TO NBRACK)
RESTORE Brackets
FOR i = 1 TO NBRACK
    READ bStart#(i), bRate#(i)
NEXT i

CONST NEMP = 6
DIM nm$(NEMP), rate#(NEMP), hours#(NEMP), ret#(NEMP)
RESTORE Staff
FOR i = 1 TO NEMP
    READ nm$(i), rate#(i), hours#(i), ret#(i)
NEXT i

' Totals for the register at the end.
DIM g#(NEMP), t#(NEMP), f#(NEMP), r#(NEMP), net#(NEMP)

showStubs = -1
FOR i = 1 TO NEMP
    ' ---- Gross pay ------------------------------------------------
    regH# = hours#(i): otH# = 0
    IF regH# > 40 THEN otH# = regH# - 40: regH# = 40
    regPay# = Cents#(regH# * rate#(i))
    otPay# = Cents#(otH# * rate#(i) * 1.5)
    g#(i) = regPay# + otPay#

    ' ---- Deductions ------------------------------------------------
    r#(i) = Cents#(g#(i) * ret#(i) / 100)   ' retirement (pre-tax)
    taxable# = g#(i) - r#(i)
    t#(i) = Cents#(IncomeTax#(taxable#))
    f#(i) = Cents#(g#(i) * .0765)
    net#(i) = g#(i) - r#(i) - t#(i) - f#(i)

    IF showStubs THEN
        CLS
        PRINT "+----------------------------------------------+"
        PRINT USING "| PAY STUB   \                  \  Week 42     |"; nm$(i)
        PRINT "+----------------------------------------------+"
        PRINT USING "| Regular   ##.# h x $$#.## =        ##,###.## |"; regH#; rate#(i); regPay#
        PRINT USING "| Overtime  ##.# h x $$#.## x1.5 =   ##,###.## |"; otH#; rate#(i); otPay#
        PRINT USING "| GROSS PAY                          ##,###.## |"; g#(i)
        PRINT USING "|   Retirement ##%                   ##,###.##-|"; ret#(i); r#(i)
        PRINT USING "|   Income tax                       ##,###.##-|"; t#(i)
        PRINT USING "|   Social insurance 7.65%           ##,###.##-|"; f#(i)
        PRINT "|                                   ---------- |"
        PRINT USING "| NET PAY                          $$##,###.## |"; net#(i)
        PRINT "+----------------------------------------------+"
        IF taxable# > 0 THEN
            PRINT USING "Effective income-tax rate: ##.#%"; t#(i) / taxable# * 100
        END IF
        ' The marginal rate is the rate of the highest bracket reached.
        FOR b = NBRACK TO 1 STEP -1
            IF taxable# > bStart#(b) THEN PRINT USING "Marginal (top) bracket:    ##.#%"; bRate#(b) * 100: EXIT FOR
        NEXT b
        PRINT
        PRINT "Any key for next stub, Esc for the register"
        k$ = INPUT$(1)
        IF k$ = CHR$(27) THEN showStubs = 0
    END IF
NEXT i

' ---- Payroll register --------------------------------------------
CLS
PRINT "PAYROLL REGISTER - WEEK 42"
PRINT "Employee                Gross    Retire       Tax      FICA        Net"
PRINT STRING$(73, "=")
FOR i = 1 TO NEMP
    PRINT USING "\                \ ###,###.## ##,###.## ##,###.## ##,###.## ###,###.##"; nm$(i); g#(i); r#(i); t#(i); f#(i); net#(i)
    tg# = tg# + g#(i): tr# = tr# + r#(i): tt# = tt# + t#(i): tf# = tf# + f#(i): tn# = tn# + net#(i)
NEXT i
PRINT STRING$(73, "-")
PRINT USING "TOTALS             ###,###.## ##,###.## ##,###.## ##,###.## ###,###.##"; tg#; tr#; tt#; tf#; tn#
PRINT
PRINT USING "Employer also pays matching FICA of $$##,###.##"; tf#
END

' ---- Weekly tax brackets: start of bracket, rate -------------------
Brackets:
DATA 0, 0.00
DATA 250, 0.10
DATA 1000, 0.15
DATA 2500, 0.25
DATA 5000, 0.33

' ---- Staff: name, hourly rate, hours this week, retirement % -------
Staff:
DATA "Ana Lopez", 18.50, 40, 5
DATA "Ben Okafor", 22.00, 46.5, 3
DATA "Chen Wei", 41.25, 52, 10
DATA "Dana Fox", 15.75, 28, 0
DATA "Eli Brandt", 63.00, 44, 6
DATA "Fatima Noor", 120.00, 50, 12

' ------------------------------------------------------------
' IncomeTax: progressive tax. Walk through the brackets; for each
' one, tax only the slice of income that falls INSIDE it.
' Example with income 1200:
'   0..250     at 0%   -> 0
'   250..1000  at 10%  -> 75
'   1000..1200 at 15%  -> 30      total = 105
' ------------------------------------------------------------
FUNCTION IncomeTax# (gross#)
    tax# = 0
    FOR b = 1 TO NBRACK
        lo# = bStart#(b)
        IF b < NBRACK THEN hi# = bStart#(b + 1) ELSE hi# = 1E+30
        IF gross# > lo# THEN
            ' The slice is from lo up to the smaller of income and hi.
            IF gross# < hi# THEN top# = gross# ELSE top# = hi#
            tax# = tax# + (top# - lo#) * bRate#(b)
        END IF
    NEXT b
    IncomeTax# = tax#
END FUNCTION

' Cents: round a money value to the nearest cent.
FUNCTION Cents# (x#)
    Cents# = INT(x# * 100 + .5) / 100
END FUNCTION
