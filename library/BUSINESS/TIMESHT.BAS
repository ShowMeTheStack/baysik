' ============================================================
' TITLE:    Weekly Time Sheet
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     time math, string parsing, APPEND files, validation, overtime
' SUMMARY:  Enter clock-in and clock-out times for each day, subtract breaks, and total the week's hours and pay.
' ------------------------------------------------------------
' WHAT IT DOES
'   Workers who are paid by the hour fill in a time sheet. This
'   program asks for each day's start time, finish time and unpaid
'   break, works out the hours worked (even for night shifts that
'   go past midnight!), and adds up the week. Hours over 40 are
'   paid as overtime. Each finished sheet is APPENDED to the file
'   TIMESHT.LOG, so the log keeps growing week after week; the last
'   few entries are shown at the end.
'
' HOW TO USE
'   Type times as HH:MM in 24-hour style (e.g. 08:30 or 17:15).
'   Press Enter with no start time for a day off. Break is in
'   minutes. You can also type a time like 9 or 930 - the program
'   understands it.
'
' CONCEPTS YOU WILL LEARN
'   * Turning "HH:MM" text into minutes since midnight
'   * Validating input and asking again when it is wrong
'   * Handling the midnight wrap-around with + 24 * 60
'   * OPEN ... FOR APPEND to add to the end of a log file
'
' THINGS TO TRY
'   * Pay Sunday hours at double time
'   * Accept "5:30pm" style times with AM/PM
'   * Read the log back and total a whole month
' ============================================================

DECLARE FUNCTION ParseTime% (t$)
DECLARE FUNCTION Hm$ (mins%)

DIM day$(1 TO 7), worked%(1 TO 7), inT$(1 TO 7), outT$(1 TO 7), brk%(1 TO 7)
FOR d = 1 TO 7: READ day$(d): NEXT d

CLS
PRINT "WEEKLY TIME SHEET"
PRINT "================="
LINE INPUT "Employee name: "; emp$
IF emp$ = "" THEN emp$ = "Anonymous"
INPUT "Hourly rate $"; rate
IF rate <= 0 THEN rate = 15
PRINT
PRINT "Times as HH:MM (24 h). Enter with no start = day off."

FOR d = 1 TO 7
    PRINT
    PRINT day$(d)
    ' ---- Start time -------------------------------------------------
    DO
        LINE INPUT "  Start: "; t$
        IF t$ = "" THEN EXIT DO
        s% = ParseTime%(t$)
        IF s% >= 0 THEN EXIT DO
        PRINT "  ?? use HH:MM, e.g. 08:30"
    LOOP
    IF t$ = "" THEN
        worked%(d) = 0: inT$(d) = "--": outT$(d) = "--"
    ELSE
        ' ---- Finish time ----------------------------------------------
        DO
            LINE INPUT "  Finish: "; t$
            e% = ParseTime%(t$)
            IF e% >= 0 THEN EXIT DO
            PRINT "  ?? use HH:MM, e.g. 17:00"
        LOOP
        INPUT "  Unpaid break (minutes)"; b%
        IF b% < 0 THEN b% = 0
        ' If finish is earlier than start, the shift went past midnight.
        span% = e% - s%
        IF span% <= 0 THEN span% = span% + 24 * 60
        IF b% > span% THEN b% = span%
        worked%(d) = span% - b%
        inT$(d) = Hm$(s%): outT$(d) = Hm$(e%): brk%(d) = b%
        PRINT "  = "; Hm$(worked%(d)); " worked"
    END IF
NEXT d

' ---- Summary ------------------------------------------------------------
CLS
PRINT "TIME SHEET: "; emp$; "    Week ending "; DATE$
PRINT
PRINT "Day          In     Out    Break   Worked   Hours"
PRINT STRING$(50, "-")
total% = 0
FOR d = 1 TO 7
    PRINT USING "\         \  \   \  \   \  ###     \   \  ##.##"; day$(d); inT$(d); outT$(d); brk%(d); Hm$(worked%(d)); worked%(d) / 60
    total% = total% + worked%(d)
NEXT d
PRINT STRING$(50, "-")
hours = total% / 60
PRINT USING "TOTAL                              \   \  ##.##"; Hm$(total%); hours

' Overtime: everything over 40 hours at 1.5 x the rate.
reg = hours: ot = 0
IF hours > 40 THEN reg = 40: ot = hours - 40
pay = reg * rate + ot * rate * 1.5
pay = INT(pay * 100 + .5) / 100          ' round to whole cents
PRINT
PRINT USING "Regular  ##.## h x $$##.##        = $$#,###.##"; reg; rate; reg * rate
PRINT USING "Overtime ##.## h x $$##.## x 1.5  = $$#,###.##"; ot; rate; ot * rate * 1.5
PRINT USING "GROSS PAY                         $$##,###.##"; pay

' ---- Append to the log and show the latest entries ----------------------
OPEN "TIMESHT.LOG" FOR APPEND AS #1
WRITE #1, DATE$, emp$, hours, pay
CLOSE #1

PRINT
PRINT "Recent log entries (TIMESHT.LOG):"
OPEN "TIMESHT.LOG" FOR INPUT AS #1
n = 0
DIM logLine$(1 TO 5)
DO WHILE NOT EOF(1)
    LINE INPUT #1, l$
    ' Keep only the last 5 lines: shift up, add at the bottom.
    n = n + 1
    IF n > 5 THEN
        FOR i = 1 TO 4: logLine$(i) = logLine$(i + 1): NEXT i
        logLine$(5) = l$
    ELSE
        logLine$(n) = l$
    END IF
LOOP
CLOSE #1
IF n > 5 THEN n = 5
FOR i = 1 TO n: PRINT "  "; logLine$(i): NEXT i
END

DATA Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday

' ------------------------------------------------------------
' ParseTime%: "8:30", "08:30", "830", "17" -> minutes since
' midnight (8*60+30 = 510). Returns -1 if it makes no sense.
' ------------------------------------------------------------
FUNCTION ParseTime% (t$)
    t$ = LTRIM$(RTRIM$(t$))
    p = INSTR(t$, ":")
    IF p > 0 THEN
        h$ = LEFT$(t$, p - 1): m$ = MID$(t$, p + 1)
    ELSEIF LEN(t$) <= 2 THEN
        h$ = t$: m$ = "0"                       ' "9" -> 9:00
    ELSE
        h$ = LEFT$(t$, LEN(t$) - 2): m$ = RIGHT$(t$, 2)   ' "930" -> 9:30
    END IF
    ' Every character must be a digit.
    ok = (LEN(h$) > 0 AND LEN(m$) > 0)
    FOR i = 1 TO LEN(h$ + m$)
        ch$ = MID$(h$ + m$, i, 1)
        IF ch$ < "0" OR ch$ > "9" THEN ok = 0
    NEXT i
    h = VAL(h$): m = VAL(m$)
    IF ok AND h >= 0 AND h <= 23 AND m >= 0 AND m <= 59 THEN
        ParseTime% = h * 60 + m
    ELSE
        ParseTime% = -1
    END IF
END FUNCTION

' Hm$: minutes -> "H:MM" text, e.g. 465 -> "7:45"
FUNCTION Hm$ (mins%)
    h = mins% \ 60: m = mins% MOD 60
    Hm$ = LTRIM$(STR$(h)) + ":" + RIGHT$("0" + LTRIM$(STR$(m)), 2)
END FUNCTION
