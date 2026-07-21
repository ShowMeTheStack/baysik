' ============================================================
' TITLE:    Compound Interest & Growth
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     finance, exponential growth, compound interest, e, graphics
' SUMMARY:  Compares simple and compound interest year by year, discovers e, and graphs exponential growth.
' ------------------------------------------------------------
' WHAT IT DOES
'   SIMPLE interest pays the same amount every year:
'        A = P * (1 + r * t)               (a straight line)
'   COMPOUND interest pays interest on the interest too:
'        A = P * (1 + r / n) ^ (n * t)     (an exponential curve)
'   where P = starting amount, r = yearly rate (5% = 0.05), t = years
'   and n = how many times per year interest is added.
'   As n grows (yearly, monthly, daily ... every instant) the answer
'   approaches  P * e ^ (r * t),  where e = 2.71828... is the same
'   famous constant you get from (1 + 1/n)^n for huge n.
'   The program shows a table, the "rule of 72" for doubling time,
'   and a graph of both kinds of growth.
'
' HOW TO USE
'   Enter the starting amount, the yearly interest rate in percent
'   and the number of years.  Press a key to move on.  At the end
'   press Y to try again.
'
' CONCEPTS YOU WILL LEARN
'   * Linear vs exponential growth
'   * The ^ operator, EXP and LOG
'   * The number e as a limit
'   * Solving for time with logarithms:  t = LOG(2) / LOG(1 + r)
'
' THINGS TO TRY
'   * Compare 5% for 40 years with 10% for 20 years
'   * Add a monthly deposit to the savings
'   * Model a loan: how long to pay off a debt with fixed payments?
' ============================================================

DEFDBL A-Z

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "COMPOUND INTEREST & GROWTH": COLOR 7
    PRINT
    INPUT "Starting amount (e.g. 1000)"; p
    IF p <= 0 THEN p = 1000
    INPUT "Yearly interest rate in % (e.g. 7)"; pct
    IF pct <= 0 OR pct > 100 THEN pct = 7
    INPUT "Number of years (1-60)"; yrs
    yrs = INT(yrs): IF yrs < 1 OR yrs > 60 THEN yrs = 30
    r = pct / 100

    CLS
    PRINT USING "P = #########.##   rate = ##.##%   years = ##"; p; pct; yrs
    PRINT
    PRINT " Year        Simple        Compound      Interest earned that year"
    stp = 1: IF yrs > 20 THEN stp = INT(yrs / 15) + 1   ' keep the table short
    FOR t = 0 TO yrs
        IF t MOD stp = 0 OR t = yrs THEN
            simple = p * (1 + r * t)
            comp = p * (1 + r) ^ t
            earned = 0: IF t > 0 THEN earned = comp - p * (1 + r) ^ (t - 1)
            PRINT USING " ###   ###########.##  ###########.##    #########.##"; t; simple; comp; earned
        END IF
    NEXT t
    PRINT
    ' Rule of 72: money doubles in about 72 / (rate in %) years.
    exactDouble = LOG(2) / LOG(1 + r)
    PRINT USING "Doubling time: exact ###.## years, rule of 72 says ###.## years"; exactDouble; 72 / pct
    PRINT "Press a key...": k$ = INPUT$(1)

    ' ---- How often is interest added?  Approaching e ----
    CLS
    COLOR 11: PRINT "Same rate, different compounding (n times per year), after"; yrs; "years:": COLOR 7
    PRINT
    RESTORE Freq
    FOR i = 1 TO 6
        READ n, nm$
        a = p * (1 + r / n) ^ (n * yrs)
        PRINT USING "  \          \ n = ########   ###########.##"; nm$; n; a
    NEXT i
    PRINT USING "  continuous     P*e^(rt)     ###########.##"; p * EXP(r * yrs)
    PRINT
    COLOR 11: PRINT "Where e comes from:  (1 + 1/n)^n": COLOR 7
    n = 1
    FOR i = 1 TO 7
        PRINT USING "  n = ########   (1 + 1/n)^n = #.#########"; n; (1 + 1 / n) ^ n
        n = n * 10
    NEXT i
    PRINT USING "  e = EXP(1)                  = #.#########"; EXP(1#)
    PRINT "Press a key for the graph...": k$ = INPUT$(1)

    ' ---- Graph ----
    SCREEN 12: CLS
    top = p * (1 + r) ^ yrs                 ' compound is the biggest value
    ' WINDOW maps (years, money) straight onto the screen.
    WINDOW (-yrs * .08, -top * .08)-(yrs * 1.05, top * 1.1)
    LINE (0, 0)-(yrs, 0), 8: LINE (0, 0)-(0, top), 8
    FOR t = 0 TO yrs STEP 5: LINE (t, 0)-(t, -top * .02), 8: NEXT t
    FOR i = 1 TO 200
        t = yrs * i / 200
        ' Each curve is 200 short straight segments from the previous
        ' time (t - yrs/200) to the current time t.
        LINE (t - yrs / 200, p * (1 + r * (t - yrs / 200)))-(t, p * (1 + r * t)), 10
        LINE (t - yrs / 200, p * (1 + r) ^ (t - yrs / 200))-(t, p * (1 + r) ^ t), 14
    NEXT i
    ' Mark each doubling of the compound curve.
    d = p
    DO WHILE d * 2 <= top
        d = d * 2
        tt = LOG(d / p) / LOG(1 + r)
        CIRCLE (tt, d), yrs / 100, 12
    LOOP
    COLOR 14: LOCATE 1, 1: PRINT "Yellow: compound (exponential curve)"
    COLOR 10: LOCATE 2, 1: PRINT "Green:  simple (straight line)"
    COLOR 12: LOCATE 3, 1: PRINT "Red circles: each time the money doubles"
    COLOR 7: LOCATE 30, 1: PRINT "Tick marks every 5 years.  Again (Y/N)?";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
LOOP WHILE k$ = "Y"
SCREEN 0: WIDTH 80
END

Freq:
DATA 1, yearly, 4, quarterly, 12, monthly, 52, weekly, 365, daily, 8760, hourly
