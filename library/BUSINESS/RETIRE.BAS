' ============================================================
' TITLE:    Retirement Projection Chart
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     retirement, graphics, SCREEN 12, WINDOW, LINE, compound growth
' SUMMARY:  Project a retirement nest egg through saving and spending years and draw it as a colourful chart.
' ------------------------------------------------------------
' WHAT IT DOES
'   You save a percentage of your salary every year until you retire.
'   The savings grow with investment returns, and your salary grows
'   with raises. After retirement you withdraw money every year
'   (adjusted for inflation) and the pot slowly shrinks. The program
'   draws a bar chart of the balance for every year of your life from
'   now to age 95, green while working and orange while retired,
'   and tells you whether the money lasts.
'
' HOW TO USE
'   Answer the questions (just press Enter to accept the default
'   shown in brackets). Look at the chart, then press any key.
'
' CONCEPTS YOU WILL LEARN
'   * Year-by-year financial simulation with several growth rates
'   * SCREEN 12 graphics, WINDOW to use "real" units on the axes
'   * LINE ... BF for filled bars, gridlines and labels with LOCATE
'   * A helper FUNCTION that reads a number with a default value
'
' THINGS TO TRY
'   * Retire 5 years earlier: how much bigger must savings be?
'   * Lower the return from 6% to 4%: does the money still last?
'   * Add Social Security / pension income after age 67
' ============================================================

DECLARE FUNCTION AskNum# (prompt$, default#)

DEFDBL A-Z
CLS
PRINT "RETIREMENT PROJECTION"
PRINT "(press Enter to keep the value in brackets)"
PRINT
age = AskNum("Your age now", 30)
retAge = AskNum("Retirement age", 65)
salary = AskNum("Yearly salary ($)", 50000)
savePct = AskNum("Percent of salary saved", 10)
have = AskNum("Savings so far ($)", 10000)
ret = AskNum("Investment return %/yr", 6)
raise = AskNum("Salary raise %/yr", 2.5)
spend = AskNum("Yearly spending in retirement (today's $)", 40000)
infl = AskNum("Inflation %/yr", 2.5)
IF age < 15 OR age > 90 THEN age = 30
IF retAge <= age THEN retAge = age + 1
IF retAge > 94 THEN retAge = 94
' Keep the rates in a sensible range so silly typing can't break the maths.
IF ret < -10 OR ret > 30 THEN ret = 6
IF raise < -10 OR raise > 20 THEN raise = 2.5
IF infl < 0 OR infl > 20 THEN infl = 2.5
IF savePct < 0 OR savePct > 100 THEN savePct = 10
IF salary < 0 THEN salary = 0
IF have < 0 THEN have = 0

' ---- Simulate every year up to age 95 ---------------------------
LASTAGE = 95
DIM bal(0 TO 120)
b = have
peak = b
ranOutAge = 0
FOR a = age TO LASTAGE
    bal(a) = b
    IF b > peak THEN peak = b
    yearsFromNow = a - age
    IF a < retAge THEN
        ' Working year: money grows, then we add this year's savings.
        b = b * (1 + ret / 100) + salary * savePct / 100
        salary = salary * (1 + raise / 100)
    ELSE
        ' Retired: withdraw spending, grown by inflation since today.
        need = spend * (1 + infl / 100) ^ yearsFromNow
        b = b * (1 + ret / 100) - need
        IF b < 0 THEN
            b = 0
            IF ranOutAge = 0 THEN ranOutAge = a + 1
        END IF
    END IF
NEXT a
IF peak < 1 THEN peak = 1

' ---- Draw the chart -----------------------------------------------
SCREEN 12
CLS
' WINDOW lets us draw in "ages" across and "dollars" up the screen
' instead of pixels. Extra margins leave room for labels.
' Screen y goes DOWN, but WINDOW (without SCREEN) makes y go UP.
WINDOW (age - (LASTAGE - age) * .12, -peak * .12)-(LASTAGE + 1, peak * 1.08)

' Horizontal grid lines at every 1/4 of the peak
FOR g = 0 TO 4
    gy = peak * g / 4
    LINE (age, gy)-(LASTAGE + 1, gy), 8
NEXT g

' One bar per year.
FOR a = age TO LASTAGE
    IF a < retAge THEN c = 10 ELSE c = 6     ' green / brown-orange
    IF bal(a) > 0 THEN LINE (a + .1, 0)-(a + .9, bal(a)), c, BF
NEXT a
' A white line marks retirement.
LINE (retAge, 0)-(retAge, peak * 1.05), 15

' Axis labels are text, so we use LOCATE (rows 1-30, cols 1-80).
COLOR 15
LOCATE 1, 20: PRINT "Projected savings balance by age"
FOR g = 0 TO 4
    ' Convert the dollar value of each grid line into a text row.
    ' PMAP converts world -> pixel coordinates (function 1 = y).
    py = PMAP(peak * g / 4, 1)
    row = INT(py / 16) + 1
    IF row >= 1 AND row <= 28 THEN LOCATE row, 1: PRINT USING "$$##,###,###"; peak * g / 4;
NEXT g
FOR a = age TO LASTAGE STEP 10
    col = INT(PMAP(a, 0) / 8) + 1
    IF col < 79 THEN LOCATE 28, col: PRINT USING "##"; a;
NEXT a
LOCATE 29, 1
COLOR 10: PRINT "Saving  ";
COLOR 6: PRINT "Retired  ";
COLOR 15
IF ranOutAge > 0 THEN
    PRINT USING "Money runs out at age ###_!"; ranOutAge;
ELSE
    PRINT USING "Money lasts_! Left at 95: $$##,###,###"; bal(LASTAGE);
END IF
LOCATE 30, 1: PRINT USING "Balance at retirement (age ##): $$#,###,###"; retAge; bal(retAge);
k$ = INPUT$(1)
SCREEN 0
WIDTH 80
END

' ------------------------------------------------------------
' AskNum: shows "prompt [default]?" and returns the number typed,
' or the default if the user just presses Enter.
' LINE INPUT reads text, so we can tell "nothing" from "0".
' ------------------------------------------------------------
FUNCTION AskNum# (prompt$, default#)
    PRINT prompt$; " ["; LTRIM$(STR$(default#)); "]";
    LINE INPUT "? "; t$
    IF LTRIM$(t$) = "" THEN AskNum# = default# ELSE AskNum# = VAL(t$)
END FUNCTION
