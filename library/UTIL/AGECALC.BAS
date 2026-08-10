' ============================================================
' TITLE:    Exact Age Calculator
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     dates, julian day number, functions, date$, birthdays
' SUMMARY:  Your exact age in years, months and days, plus total days lived and days to your next birthday.
' ------------------------------------------------------------
' WHAT IT DOES
'   Type a birth date (and optionally a second date - it uses
'   today's DATE$ if you leave it blank).  It prints:
'     * age as years, months and days
'     * total days, weeks, hours lived
'     * how many days until the next birthday, and its weekday
'     * when you will be / were 10,000 days old
'
'   The trick for counting days between two dates is the JULIAN
'   DAY NUMBER (JDN): a count of days from a fixed point long
'   ago.  Convert both dates to JDN and subtract!  The formula
'   below is the well-known Fliegel & Van Flandern version.
'
' HOW TO USE
'   Enter dates as MM/DD/YYYY (e.g. 03/14/2010).  Blank "to"
'   date means today.  Type Q at the first prompt to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Julian Day Numbers: dates -> integers -> dates
'   * Borrowing days/months, just like subtraction with carries
'   * Parsing "MM/DD/YYYY" text with INSTR and VAL
'   * LONG integers (&) for big numbers
'
' THINGS TO TRY
'   * Print your age on other planets (Mars year = 686.98 days).
'   * Count how many full moons you have seen (29.53 days each).
'   * Show the date you will be 1,000,000,000 seconds old.
' ============================================================

DECLARE FUNCTION JDN& (d%, m%, y%)
DECLARE SUB FromJDN (j&, d%, m%, y%)
DECLARE FUNCTION ParseDate% (s$, d%, m%, y%)
DECLARE FUNCTION MonthLen% (m%, y%)

DIM dayName$(0 TO 6)
FOR i = 0 TO 6: READ dayName$(i): NEXT i
' JDN MOD 7: 0 = Monday ... 6 = Sunday
DATA Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday

CLS
COLOR 13: PRINT "EXACT AGE CALCULATOR": COLOR 7
DO
    PRINT
    LINE INPUT "Birth date MM/DD/YYYY (Q to quit): "; a$
    IF UCASE$(LTRIM$(a$)) = "Q" THEN EXIT DO
    IF NOT ParseDate%(a$, bd%, bm%, by%) THEN
        PRINT "  Sorry, I can't read that date."
    ELSE
        LINE INPUT "Age on date (blank = today): "; b$
        IF LTRIM$(b$) = "" THEN b$ = DATE$        ' DATE$ = "MM-DD-YYYY"
        IF NOT ParseDate%(b$, td%, tm%, ty%) THEN
            PRINT "  Sorry, I can't read that date."
        ELSE
            j1& = JDN&(bd%, bm%, by%)
            j2& = JDN&(td%, tm%, ty%)
            IF j2& < j1& THEN
                PRINT "  That person isn't born yet!"
            ELSE
                ' ---- Years, months, days: subtract with borrowing ----
                yy% = ty% - by%: mm% = tm% - bm%: dd% = td% - bd%
                IF dd% < 0 THEN
                    ' borrow the length of the month BEFORE the "to" month
                    pm% = tm% - 1: py% = ty%
                    IF pm% = 0 THEN pm% = 12: py% = py% - 1
                    dd% = dd% + MonthLen%(pm%, py%)
                    mm% = mm% - 1
                END IF
                IF mm% < 0 THEN mm% = mm% + 12: yy% = yy% - 1

                days& = j2& - j1&
                COLOR 14
                PRINT USING "  Age: ### years, ## months, ## days"; yy%; mm%; dd%
                COLOR 7
                PRINT USING "  That is ###,### days  = ##,### weeks  = ##,###,### hours"; days&; days& \ 7; days& * 24#
                PRINT "  Born on a "; dayName$(j1& MOD 7)

                ' ---- Next birthday ----
                ny% = ty%
                nd% = bd%
                ' Feb 29 birthdays fall on Feb 28 in non-leap years.
                IF bm% = 2 AND bd% = 29 AND MonthLen%(2, ny%) = 28 THEN nd% = 28
                IF JDN&(nd%, bm%, ny%) < j2& THEN
                    ny% = ny% + 1: nd% = bd%
                    IF bm% = 2 AND bd% = 29 AND MonthLen%(2, ny%) = 28 THEN nd% = 28
                END IF
                jb& = JDN&(nd%, bm%, ny%)
                IF jb& = j2& THEN
                    COLOR 12: PRINT "  HAPPY BIRTHDAY!": COLOR 7
                ELSE
                    PRINT "  Next birthday in"; jb& - j2&; "days, on a "; dayName$(jb& MOD 7)
                END IF

                ' ---- 10,000 days old ----
                FromJDN j1& + 10000, d%, m%, y%
                PRINT USING "  10,000 days old on ##/##/####"; m%; d%; y%
            END IF
        END IF
    END IF
LOOP
END

' Convert a JDN back to a calendar date (inverse of JDN&).
SUB FromJDN (j&, d%, m%, y%)
    l& = j& + 68569
    n& = (4 * l&) \ 146097
    l& = l& - (146097 * n& + 3) \ 4
    i& = (4000 * (l& + 1)) \ 1461001
    l& = l& - (1461 * i&) \ 4 + 31
    k& = (80 * l&) \ 2447
    d% = l& - (2447 * k&) \ 80
    l& = k& \ 11
    m% = k& + 2 - 12 * l&
    y% = 100 * (n& - 49) + i& + l&
END SUB

' Gregorian date -> Julian Day Number (Fliegel & Van Flandern).
' All divisions are INTEGER divisions (\).  The "a" term is -1
' for January/February and 0 otherwise, which treats Jan and Feb
' as the end of the previous year (like Zeller's method).
FUNCTION JDN& (d%, m%, y%)
    a& = (m% - 14) \ 12
    JDN& = (1461 * (y% + 4800& + a&)) \ 4 + (367 * (m% - 2 - 12 * a&)) \ 12 - (3 * ((y% + 4900& + a&) \ 100)) \ 4 + d% - 32075
END FUNCTION

FUNCTION MonthLen% (m%, y%)
    SELECT CASE m%
        CASE 4, 6, 9, 11: MonthLen% = 30
        CASE 2
            IF (y% MOD 4 = 0 AND y% MOD 100 <> 0) OR y% MOD 400 = 0 THEN MonthLen% = 29 ELSE MonthLen% = 28
        CASE ELSE: MonthLen% = 31
    END SELECT
END FUNCTION

' Read "MM/DD/YYYY" (or with "-" separators).  Returns -1 if OK.
FUNCTION ParseDate% (s$, d%, m%, y%)
    ParseDate% = 0
    t$ = LTRIM$(RTRIM$(s$))
    ' turn "-" into "/" so both styles work
    FOR i = 1 TO LEN(t$)
        IF MID$(t$, i, 1) = "-" THEN MID$(t$, i, 1) = "/"
    NEXT i
    p1 = INSTR(t$, "/"): IF p1 = 0 THEN EXIT FUNCTION
    p2 = INSTR(p1 + 1, t$, "/"): IF p2 = 0 THEN EXIT FUNCTION
    mv = VAL(LEFT$(t$, p1 - 1))
    dv = VAL(MID$(t$, p1 + 1, p2 - p1 - 1))
    yv = VAL(MID$(t$, p2 + 1))
    IF yv < 1583 OR yv > 9999 OR mv < 1 OR mv > 12 THEN EXIT FUNCTION
    m% = mv: y% = yv
    IF dv < 1 OR dv > MonthLen%(m%, y%) THEN EXIT FUNCTION
    d% = dv
    ParseDate% = -1
END FUNCTION
