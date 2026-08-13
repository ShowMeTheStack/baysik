' ============================================================
' TITLE:    Time Machine (Setting DATE$ and TIME$)
' CATEGORY: System, Events & Hardware
' LEVEL:    Beginner
' TAGS:     date$, time$, clock, y2k, day of week, on error
' SUMMARY:  Read and SET the system clock with DATE$ and TIME$, find the weekday, and watch the Year 2000 roll over.
' ------------------------------------------------------------
' WHAT IT DOES
'   DATE$ and TIME$ are not just functions - they are also statements
'   that SET the PC's clock:
'       DATE$ = "12-31-1999"      (month-day-year)
'       TIME$ = "23:59:55"        (hours:minutes:seconds, 24-hour)
'   This "time machine" lets you travel to any date, works out what
'   weekday it falls on, and has a special trip to the last seconds of
'   1999 so you can watch the famous Y2K rollover happen live.
'   Before quitting it puts the clock back where it was.
'
' HOW TO USE
'   1 = set the date   2 = set the time   3 = Y2K rollover show
'   Q = quit (restores the real date and time)
'
' CONCEPTS YOU WILL LEARN
'   * DATE$ / TIME$ as functions and as statements
'   * Pulling numbers out of "mm-dd-yyyy" with MID$ and VAL
'   * Zeller's congruence to compute the day of the week
'   * ON ERROR to catch an invalid date (error 5)
'
' THINGS TO TRY
'   * Show how many days are left until your birthday
'   * Display a 12-hour clock with AM / PM
'   * Find the weekday you were born on
' ============================================================

DEFINT A-Z
DECLARE FUNCTION WeekDay$ (d$)

realDate$ = DATE$: realTime$ = TIME$   ' remember the real clock
startT! = TIMER
ON ERROR GOTO BadInput

DO
    CLS
    PRINT "T I M E   M A C H I N E"
    PRINT STRING$(40, 196)
    PRINT "Now it is  "; DATE$; "  "; TIME$; "  ("; WeekDay$(DATE$); ")"
    PRINT
    PRINT "1  Travel to a date"
    PRINT "2  Set the time"
    PRINT "3  Watch the Year 2000 arrive"
    PRINT "Q  Quit (back to the present)"
    PRINT
    bad = 0                             ' the error handler sets this
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
        CASE "1"
            LINE INPUT "Date (mm-dd-yyyy): "; d$
            DATE$ = d$                  ' error 5 if it is not a real date
            IF bad = 0 THEN PRINT "Arrived!  It is a "; WeekDay$(DATE$); "."
        CASE "2"
            LINE INPUT "Time (hh:mm:ss): "; t$
            TIME$ = t$
            IF bad = 0 THEN PRINT "Clock set to "; TIME$
        CASE "3"
            DATE$ = "12-31-1999"
            TIME$ = "23:59:55"
            PRINT : PRINT "Countdown to the new millennium!"
            row = CSRLIN
            FOR i = 1 TO 8              ' about 8 seconds
                t0$ = TIME$
                DO WHILE TIME$ = t0$: LOOP      ' wait for the next second
                LOCATE row, 1
                PRINT DATE$; "  "; TIME$; "  "; WeekDay$(DATE$); "     ";
                IF LEFT$(TIME$, 2) = "00" THEN PRINT "HAPPY NEW YEAR 2000!"; : SOUND 880, 2
                PRINT
            NEXT i
        CASE "Q", CHR$(27)
            EXIT DO
    END SELECT
    PRINT : PRINT "(press a key)"
    DO: LOOP WHILE INKEY$ = ""
LOOP

' ---- return to the present: real time + the seconds we spent here ---
DATE$ = realDate$
el& = TIMER - startT!
IF el& < 0 THEN el& = 0
s& = VAL(LEFT$(realTime$, 2)) * 3600& + VAL(MID$(realTime$, 4, 2)) * 60 + VAL(RIGHT$(realTime$, 2)) + el&
s& = s& MOD 86400
TIME$ = RIGHT$("0" + LTRIM$(STR$(s& \ 3600)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$((s& \ 60) MOD 60)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(s& MOD 60)), 2)
CLS
PRINT "Back in the present: "; DATE$; " "; TIME$
END

BadInput:
    PRINT "That is not a valid date/time (error"; ERR; ") - nothing changed."
    bad = 1
    RESUME NEXT

' Day of the week for a "mm-dd-yyyy" string, using Zeller's congruence.
FUNCTION WeekDay$ (d$)
    m = VAL(LEFT$(d$, 2)): dd = VAL(MID$(d$, 4, 2)): y = VAL(MID$(d$, 7, 4))
    IF m < 3 THEN m = m + 12: y = y - 1   ' Jan/Feb count as months 13/14
    k = y MOD 100: j = y \ 100
    h = (dd + (13 * (m + 1)) \ 5 + k + k \ 4 + j \ 4 + 5 * j) MOD 7
    ' h: 0 = Saturday, 1 = Sunday, ... 6 = Friday
    WeekDay$ = RTRIM$(MID$("Saturday Sunday   Monday   Tuesday  WednesdayThursday Friday   ", h * 9 + 1, 9))
END FUNCTION
