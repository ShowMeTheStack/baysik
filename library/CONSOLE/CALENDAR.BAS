' ============================================================
' TITLE:    Perpetual Calendar
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     calendar, date$, zeller, leap year, functions
' SUMMARY:  A boxed monthly calendar for any year that highlights today and flips with the arrow keys.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a neat calendar page for a month, with weekends in a
'   different colour and today's date highlighted.  You can flip
'   back and forward through months and years - all the way from
'   1583 to 9999 - because the program CALCULATES which weekday each
'   month starts on, using a famous formula (Zeller's congruence).
'
' HOW TO USE
'   Left / Right   previous / next month
'   Up / Down      next / previous year
'   T              jump back to today
'   Esc or Q       quit
'
' CONCEPTS YOU WILL LEARN
'   * Pulling numbers out of DATE$ ("MM-DD-YYYY") with VAL and MID$
'   * Leap year rules (every 4 years, except centuries, except 400s)
'   * Zeller's congruence for the day of the week
'   * Laying out a grid: column = weekday, row = week number
'
' THINGS TO TRY
'   * Mark birthdays: keep a list of month/day pairs and colour them.
'   * Show three months side by side.
'   * Print the day-of-year number for today (1..366).
' ============================================================

DEFINT A-Z
DECLARE FUNCTION DaysIn (m, y)
DECLARE FUNCTION DayOfWeek (d, m, y)
DECLARE SUB DrawMonth (m, y)

DIM SHARED mname$(1 TO 12)
DIM SHARED todayD, todayM, todayY
FOR i = 1 TO 12: READ mname$(i): NEXT i
DATA January,February,March,April,May,June
DATA July,August,September,October,November,December

' DATE$ looks like "10-15-2026": month, day, year.
todayM = VAL(LEFT$(DATE$, 2))
todayD = VAL(MID$(DATE$, 4, 2))
todayY = VAL(RIGHT$(DATE$, 4))

SCREEN 0: WIDTH 80, 25
m = todayM: y = todayY

DO
    DrawMonth m, y
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "K": m = m - 1           ' Left arrow
        CASE CHR$(0) + "M": m = m + 1           ' Right arrow
        CASE CHR$(0) + "H": y = y + 1           ' Up arrow
        CASE CHR$(0) + "P": y = y - 1           ' Down arrow
        CASE "T": m = todayM: y = todayY
        CASE CHR$(27), "Q": EXIT DO
    END SELECT
    ' Months wrap into the neighbouring year.
    IF m < 1 THEN m = 12: y = y - 1
    IF m > 12 THEN m = 1: y = y + 1
    ' The Gregorian calendar started in 1582, so stay after that.
    IF y < 1583 THEN y = 1583
    IF y > 9999 THEN y = 9999
LOOP
COLOR 7, 0: CLS
END

' Day of the week for a date.  Returns 0 = Sunday ... 6 = Saturday.
' Zeller's congruence treats January and February as months 13 and
' 14 of the PREVIOUS year (so the leap day falls at the END of the
' "year", which makes the maths simpler).
FUNCTION DayOfWeek (d, m, y)
    mm = m: yy = y
    IF mm < 3 THEN mm = mm + 12: yy = yy - 1
    k = yy MOD 100          ' year within the century
    j = yy \ 100            ' the century
    ' h: 0 = Saturday, 1 = Sunday, ... 6 = Friday
    ' (13 * (mm + 1)) \ 5 handles the uneven month lengths.
    h = (d + (13 * (mm + 1)) \ 5 + k + k \ 4 + j \ 4 + 5 * j) MOD 7
    ' Shift so that Sunday = 0.
    DayOfWeek = (h + 6) MOD 7
END FUNCTION

' How many days in month m of year y?
FUNCTION DaysIn (m, y)
    SELECT CASE m
        CASE 4, 6, 9, 11: DaysIn = 30
        CASE 2
            ' Leap year: divisible by 4, but not by 100 unless also by 400.
            IF (y MOD 4 = 0 AND y MOD 100 <> 0) OR y MOD 400 = 0 THEN
                DaysIn = 29
            ELSE
                DaysIn = 28
            END IF
        CASE ELSE: DaysIn = 31
    END SELECT
END FUNCTION

SUB DrawMonth (m, y)
    ' The calendar box: 7 columns x 5 chars = 35 wide, plus borders.
    CONST L = 22, T = 3         ' top-left corner of the box
    COLOR 7, 1: CLS
    COLOR 15, 1
    LOCATE 1, 1: PRINT SPACE$(80);
    LOCATE 1, 30: PRINT "PERPETUAL  CALENDAR";

    ' Frame (double line) and title strip.
    COLOR 14, 1
    LOCATE T, L: PRINT CHR$(201); STRING$(35, 205); CHR$(187)
    FOR r = T + 1 TO T + 15
        LOCATE r, L: PRINT CHR$(186); SPACE$(35); CHR$(186)
    NEXT r
    LOCATE T + 16, L: PRINT CHR$(200); STRING$(35, 205); CHR$(188)
    LOCATE T + 2, L: PRINT CHR$(199); STRING$(35, 196); CHR$(182)

    title$ = mname$(m) + STR$(y)
    COLOR 15, 1
    LOCATE T + 1, L + 1 + (35 - LEN(title$)) \ 2: PRINT title$

    ' Weekday headings.  Sunday and Saturday in light red.
    FOR d = 0 TO 6
        IF d = 0 OR d = 6 THEN COLOR 12, 1 ELSE COLOR 11, 1
        LOCATE T + 3, L + 2 + d * 5: PRINT MID$("SunMonTueWedThuFriSat", d * 3 + 1, 3)
    NEXT d

    ' Fill in the days.
    first = DayOfWeek(1, m, y)       ' weekday of the 1st
    n = DaysIn(m, y)
    FOR day = 1 TO n
        cell = first + day - 1       ' position in the 7-wide grid
        col = cell MOD 7             ' weekday column 0..6
        wk = cell \ 7                ' week row 0..5
        ' Leave a blank line between weeks.  A month can touch 6 weeks
        ' (e.g. 31 days starting on a Saturday), so we need 6 rows.
        LOCATE T + 5 + wk * 2, L + 2 + col * 5
        IF day = todayD AND m = todayM AND y = todayY THEN
            COLOR 0, 14              ' today: black on yellow
        ELSEIF col = 0 OR col = 6 THEN
            COLOR 12, 1
        ELSE
            COLOR 15, 1
        END IF
        PRINT USING "###"; day;
    NEXT day

    ' Footer: extra information and the keys.
    COLOR 7, 1
    LOCATE 21, L: PRINT USING "This month has ## days."; n
    leap$ = "is not": IF DaysIn(2, y) = 29 THEN leap$ = "is"
    LOCATE 22, L: PRINT y; leap$; " a leap year."
    COLOR 3, 1
    LOCATE 24, 8
    PRINT "Left/Right = month   Up/Down = year   T = today   Esc = quit";
END SUB
