' ============================================================
' TITLE:    Calendar Printer
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     dates, zeller, calendar, functions, leap year
' SUMMARY:  Prints a neat month calendar for any month and year using Zeller's congruence.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows a calendar page for any month of any year from 1583
'   onwards (the Gregorian calendar).  Today's date is
'   highlighted when you are looking at the current month.
'   Arrow keys flip through months and years.
'
'   The hard part is knowing which weekday the 1st falls on.
'   Zeller's congruence (1882) works it out with pure arithmetic:
'
'     h = ( q + INT(13*(m+1)/5) + K + INT(K/4) + INT(J/4) + 5*J ) MOD 7
'
'   q = day, m = month (March=3 ... with Jan/Feb counted as months
'   13 and 14 of the PREVIOUS year), K = year MOD 100, J = century.
'   h = 0 means Saturday, 1 Sunday, 2 Monday ... 6 Friday.
'
' HOW TO USE
'   Left/Right arrows = previous/next month
'   Up/Down arrows    = next/previous year
'   G = go to a month/year you type in, T = today
'   Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Zeller's congruence and the MOD operator
'   * Leap year rules (every 4 years, not 100s, but yes 400s)
'   * FUNCTIONs that return values
'   * Reading DATE$ ("mm-dd-yyyy") with MID$ and VAL
'   * Extended keys: INKEY$ gives CHR$(0) + scan code for arrows
'
' THINGS TO TRY
'   * Print a whole year (12 small months, 3 across).
'   * Mark weekends in a different colour.
'   * Add holidays from DATA statements.
' ============================================================

DECLARE FUNCTION Zeller% (d%, m%, y%)
DECLARE FUNCTION DaysIn% (m%, y%)
DECLARE SUB ShowMonth (m%, y%)

' Today, from DATE$ which looks like "10-15-2026".
DIM SHARED todayM%, todayD%, todayY%
todayM% = VAL(LEFT$(DATE$, 2))
todayD% = VAL(MID$(DATE$, 4, 2))
todayY% = VAL(RIGHT$(DATE$, 4))

m% = todayM%: y% = todayY%

DO
    ShowMonth m%, y%
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "K": m% = m% - 1          ' left arrow
        CASE CHR$(0) + "M": m% = m% + 1          ' right arrow
        CASE CHR$(0) + "H": y% = y% + 1          ' up arrow
        CASE CHR$(0) + "P": y% = y% - 1          ' down arrow
        CASE "T": m% = todayM%: y% = todayY%
        CASE "G"
            LOCATE 22, 5: INPUT "Month (1-12): ", nm%
            LOCATE 23, 5: INPUT "Year (1583-9999): ", ny%
            IF nm% >= 1 AND nm% <= 12 AND ny% >= 1583 AND ny% <= 9999 THEN m% = nm%: y% = ny%
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
    ' Wrap months round into the neighbouring year.
    IF m% < 1 THEN m% = 12: y% = y% - 1
    IF m% > 12 THEN m% = 1: y% = y% + 1
    IF y% < 1583 THEN y% = 1583
    IF y% > 9999 THEN y% = 9999
LOOP
CLS
END

' Number of days in month m of year y.
FUNCTION DaysIn% (m%, y%)
    SELECT CASE m%
        CASE 4, 6, 9, 11: DaysIn% = 30
        CASE 2
            ' Leap year: divisible by 4, except centuries, except
            ' every 400 years.  So 2000 was a leap year, 1900 not.
            IF (y% MOD 4 = 0 AND y% MOD 100 <> 0) OR y% MOD 400 = 0 THEN
                DaysIn% = 29
            ELSE
                DaysIn% = 28
            END IF
        CASE ELSE: DaysIn% = 31
    END SELECT
END FUNCTION

' Draw one calendar page.
SUB ShowMonth (m%, y%)
    CLS
    ' Month names stored in one string, 10 characters each.
    names$ = "January   February  March     April     May       June      "
    names$ = names$ + "July      August    September October   November  December  "
    title$ = RTRIM$(MID$(names$, (m% - 1) * 10 + 1, 10)) + STR$(y%)

    COLOR 15, 1
    LOCATE 3, 20: PRINT SPACE$(36);
    LOCATE 3, 20 + (36 - LEN(title$)) \ 2: PRINT title$;
    COLOR 14, 0
    LOCATE 5, 20: PRINT " Sun  Mon  Tue  Wed  Thu  Fri  Sat"
    COLOR 7, 0

    ' Zeller gives 0=Sat..6=Fri.  We want 0=Sun..6=Sat for the
    ' column, so shift by 6 and wrap: (h + 6) MOD 7.
    col% = (Zeller%(1, m%, y%) + 6) MOD 7
    row% = 7
    FOR d% = 1 TO DaysIn%(m%, y%)
        LOCATE row%, 20 + col% * 5
        IF d% = todayD% AND m% = todayM% AND y% = todayY% THEN COLOR 0, 14 ELSE COLOR 7, 0
        IF col% = 0 THEN IF NOT (d% = todayD% AND m% = todayM% AND y% = todayY%) THEN COLOR 12, 0
        PRINT USING " ## "; d%;
        COLOR 7, 0
        col% = col% + 1
        IF col% = 7 THEN col% = 0: row% = row% + 2    ' new week
    NEXT d%

    LOCATE 20, 5
    PRINT "<- -> month   Up/Down year   G = go to   T = today   Q = quit"
END SUB

' Zeller's congruence: weekday for day d of month m in year y.
' Returns 0 = Saturday, 1 = Sunday, ..., 6 = Friday.
FUNCTION Zeller% (d%, m%, y%)
    mm% = m%: yy% = y%
    ' January and February count as months 13 and 14 of the
    ' year before - this puts the awkward leap day at the END
    ' of the "year", so the formula stays simple.
    IF mm% < 3 THEN mm% = mm% + 12: yy% = yy% - 1
    k% = yy% MOD 100        ' year within the century
    j% = yy% \ 100          ' the century
    ' INT(13*(m+1)/5) adds the right number of days for the
    ' uneven month lengths (31,30,31,30,31,31...).
    h% = (d% + (13 * (mm% + 1)) \ 5 + k% + k% \ 4 + j% \ 4 + 5 * j%) MOD 7
    Zeller% = h%
END FUNCTION
