' ============================================================
' TITLE:    NPV & IRR Investment Calculator
' CATEGORY: Business & Finance
' LEVEL:    Advanced
' TAGS:     NPV, IRR, Newton's method, time value of money, FUNCTION
' SUMMARY:  Decide whether a project is worth it: net present value, internal rate of return, payback and an NPV profile.
' ------------------------------------------------------------
' WHAT IT DOES
'   "A dollar today is worth more than a dollar next year" - because
'   today's dollar could be invested and earn interest. So money a
'   project returns in the future must be DISCOUNTED back to today:
'       present value = cash / (1 + rate) ^ year
'   Adding up the present values of all cash flows (the first one
'   is usually a big negative investment) gives the NET PRESENT
'   VALUE. NPV > 0 means the project beats your required return.
'   The INTERNAL RATE OF RETURN is the rate that makes NPV exactly
'   zero. We find it with NEWTON'S METHOD, which uses the slope
'   (derivative) of the NPV curve to jump towards the zero.
'   The program also finds the PAYBACK period and draws an "NPV
'   profile" - NPV at rates from 0% to 30% - as a text chart.
'
' HOW TO USE
'   Press Enter to analyse the sample project, or type M to enter
'   your own cash flows (year 0 = the investment, as a negative).
'   Then enter your required rate of return (discount rate).
'
' CONCEPTS YOU WILL LEARN
'   * Discounting and present value
'   * Newton's method:  x(new) = x - f(x) / f'(x)
'   * Writing f and f' as FUNCTIONs that read a SHARED array
'   * Plotting positive and negative values around a zero axis
'
' THINGS TO TRY
'   * Compare two projects: which has the higher NPV at 10%?
'   * Find a project with TWO IRRs (cash flows -, +, -) and watch
'     what Newton's method does with different starting guesses
'   * Add the "profitability index" = PV of inflows / investment
' ============================================================

DECLARE FUNCTION NPV# (rate#)
DECLARE FUNCTION dNPV# (rate#)

CONST MAXY = 30
DIM SHARED cf#(0 TO MAXY), nYears AS INTEGER

CLS
PRINT "NPV & IRR CALCULATOR"
PRINT
LINE INPUT "Enter = sample project, M = my own cash flows: "; m$
IF UCASE$(LEFT$(m$, 1)) = "M" THEN
    INPUT "Number of years after the investment (1-30)"; nYears
    IF nYears < 1 OR nYears > MAXY THEN nYears = 5
    INPUT "Year 0 investment (type as a negative number)"; cf#(0)
    IF cf#(0) > 0 THEN cf#(0) = -cf#(0)
    FOR y = 1 TO nYears
        PRINT "Year"; y; "cash flow";
        INPUT cf#(y)
    NEXT y
ELSE
    ' Sample: buy a $50,000 machine that saves money for 6 years,
    ' then sell it for scrap (bigger last-year cash flow).
    READ nYears
    FOR y = 0 TO nYears: READ cf#(y): NEXT y
END IF
INPUT "Required rate of return % (e.g. 10)"; req#
IF req# <= 0 THEN req# = 10

' ---- Table of discounted cash flows --------------------------------
CLS
PRINT USING "DISCOUNTED CASH FLOWS at ##.##%"; req#
PRINT "Year    Cash flow   Discount factor   Present value   Cumulative cash"
PRINT STRING$(72, "-")
cum# = 0: payback# = -1
FOR y = 0 TO nYears
    f# = 1 / (1 + req# / 100) ^ y          ' discount factor
    pv# = cf#(y) * f#
    prevCum# = cum#
    cum# = cum# + cf#(y)
    ' Payback: the year in which the running total turns positive.
    ' We estimate the part-year by straight-line interpolation.
    IF payback# < 0 AND cum# >= 0 AND y > 0 THEN payback# = y - 1 + (-prevCum#) / cf#(y)
    PRINT USING " ##   ####,###.##      #.######     ####,###.##     ####,###.##"; y; cf#(y); f#; pv#; cum#
NEXT y
PRINT STRING$(72, "-")
npvReq# = NPV#(req# / 100)
PRINT USING "NET PRESENT VALUE:  $$#,###,###.##-"; npvReq#
IF npvReq# >= 0 THEN
    COLOR 10: PRINT "  NPV is positive -> the project earns MORE than"; req#; "% - accept."
ELSE
    COLOR 12: PRINT "  NPV is negative -> the project earns LESS than"; req#; "% - reject."
END IF
COLOR 7
IF payback# >= 0 THEN PRINT USING "Payback period:     ##.# years"; payback# ELSE PRINT "Payback: never (the money doesn't come back)."

' ---- IRR by Newton's method ----------------------------------------
' Start with a guess of 10% and improve it. Each step follows the
' tangent line of the NPV curve down to where it crosses zero.
r# = .1
ok = 0
FOR it = 1 TO 50
    d# = dNPV#(r#)
    IF d# = 0 THEN EXIT FOR
    newR# = r# - NPV#(r#) / d#
    IF newR# <= -.99 THEN newR# = -.5      ' keep (1 + r) positive
    IF ABS(newR# - r#) < 1E-10 THEN ok = -1: r# = newR#: EXIT FOR
    r# = newR#
NEXT it
IF ok THEN
    PRINT USING "IRR:                ##.###%   (found in ## Newton steps)"; r# * 100; it
ELSE
    PRINT "IRR: could not be found (cash flows may never break even)."
END IF
PRINT
PRINT "Press a key for the NPV profile...";
k$ = INPUT$(1)

' ---- NPV profile chart -----------------------------------------------
' One row per rate. The zero axis is in the middle column; bars go
' right for positive NPV (green) and left for negative (red).
CLS
PRINT "NPV PROFILE: how NPV changes with the discount rate"
PRINT
big# = 1
FOR pct = 0 TO 30 STEP 2
    v# = ABS(NPV#(pct / 100)): IF v# > big# THEN big# = v#
NEXT pct
mid = 45                                  ' screen column of NPV = 0
FOR pct = 0 TO 30 STEP 2
    v# = NPV#(pct / 100)
    n = INT(ABS(v#) / big# * 30 + .5)      ' bar length up to 30
    PRINT USING "##% #,###,###-"; pct; v#;
    LOCATE , mid: PRINT CHR$(179);         ' the zero axis
    IF v# >= 0 THEN
        COLOR 10: LOCATE , mid + 1: PRINT STRING$(n, 219);
    ELSE
        COLOR 12: LOCATE , mid - n: PRINT STRING$(n, 219);
    END IF
    COLOR 7: PRINT
NEXT pct
PRINT
IF ok THEN PRINT USING "The bars cross zero near the IRR of ##.#%"; r# * 100
END

' Sample project: years, then cash flows for year 0..6
DATA 6
DATA -50000, 12000, 14000, 15000, 13000, 11000, 16000

' ------------------------------------------------------------
' NPV#: sum of cash / (1 + rate)^year over all years.
' ------------------------------------------------------------
FUNCTION NPV# (rate#)
    s# = 0
    FOR y = 0 TO nYears
        s# = s# + cf#(y) / (1 + rate#) ^ y
    NEXT y
    NPV# = s#
END FUNCTION

' ------------------------------------------------------------
' dNPV#: the derivative (slope) of NPV with respect to rate.
' d/dr [ c * (1+r)^-y ] = -y * c * (1+r)^-(y+1)
' ------------------------------------------------------------
FUNCTION dNPV# (rate#)
    s# = 0
    FOR y = 1 TO nYears
        s# = s# - y * cf#(y) / (1 + rate#) ^ (y + 1)
    NEXT y
    dNPV# = s#
END FUNCTION
