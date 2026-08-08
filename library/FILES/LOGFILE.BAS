' ============================================================
' TITLE:    Log File with Timestamps & Rotation
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, append, logging, TIME$, DATE$, NAME, KILL
' SUMMARY:  A greenhouse simulator writes timestamped events to a log file, which rotates when it gets big.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pretends to be a greenhouse controller. Every tick it reads a
'   (random) temperature and writes a line to GREEN.LOG like
'       10-15-2026 14:03:22 WARN  Temp 31.4C - opening vents
'   When GREEN.LOG grows past MAXLOG bytes it is "rotated": renamed to
'   GREEN.OLD (the previous old log is deleted) and a fresh log starts.
'   Afterwards a viewer lets you filter the log by level.
'
' HOW TO USE
'   Watch the events scroll by (any key stops the simulation early).
'   Then pick a filter: A=all  I=INFO  W=WARN  E=ERROR  Q=quit.
'
' CONCEPTS YOU WILL LEARN
'   * One small SUB that every part of the program uses for logging
'   * OPEN ... FOR APPEND, which adds to the end of a file
'   * Checking a file's size with LOF before writing
'   * Rotating logs with KILL and NAME ... AS ...
'   * Fixed-width log lines that are easy to filter with MID$
'
' THINGS TO TRY
'   * Keep three generations: .LOG, .OLD and .OL2.
'   * Add a DEBUG level that is only written when a flag is on.
' ============================================================

DECLARE SUB LogMsg (level$, msg$)
DECLARE SUB ShowLog (f$, want$)

CONST LOGF = "GREEN.LOG"
CONST OLDF = "GREEN.OLD"
CONST MAXLOG = 1200            ' bytes before we rotate
DIM SHARED rotations, errFlag

' Start with a clean slate each run: create an empty log and remove
' any old one. ON ERROR protects KILL if the file is not there.
ON ERROR GOTO Ignore
KILL OLDF
ON ERROR GOTO 0
OPEN LOGF FOR OUTPUT AS #1: CLOSE #1

CLS
PRINT "GREENHOUSE CONTROLLER - press any key to stop"
PRINT STRING$(60, "=")
RANDOMIZE TIMER
LogMsg "INFO", "Controller started"
temp = 22: vents = 0: heater = 0

FOR tick = 1 TO 60
    ' The sun warms and cools the greenhouse in a slow wave (SIN), plus
    ' some random noise; open vents cool it, the heater warms it.
    temp = temp + SIN(tick / 5) * 1.5 + (RND - .5) * 2 - vents * .8 + heater * .8
    t$ = "Temp " + LTRIM$(STR$(INT(temp * 10) / 10)) + "C"
    IF temp > 30 AND vents = 0 THEN
        vents = 1: LogMsg "WARN", t$ + " - opening vents"
    ELSEIF temp < 25 AND vents = 1 THEN
        vents = 0: LogMsg "INFO", t$ + " - closing vents"
    ELSEIF temp < 12 AND heater = 0 THEN
        heater = 1: LogMsg "WARN", t$ + " - heater ON"
    ELSEIF temp > 18 AND heater = 1 THEN
        heater = 0: LogMsg "INFO", t$ + " - heater off"
    ELSE
        LogMsg "INFO", t$
    END IF
    ' Rare random faults, so there is something to find later.
    IF RND < .06 THEN LogMsg "ERROR", "Sensor " + CHR$(65 + INT(RND * 4)) + " not responding"
    IF INKEY$ <> "" THEN EXIT FOR
    ' A short pause so you can watch it happen.
    t0! = TIMER: DO WHILE TIMER - t0! < .05 AND TIMER >= t0!: LOOP
NEXT
LogMsg "INFO", "Controller stopped"
PRINT STRING$(60, "=")
PRINT "Log rotated"; rotations; "time(s). Press a key for the viewer."
k$ = INPUT$(1)

' ---- the viewer ------------------------------------------------
DO
    CLS
    PRINT "LOG VIEWER   A=all  I=INFO  W=WARN  E=ERROR  O=old log  Q=quit"
    k$ = UCASE$(INPUT$(1))
    SELECT CASE k$
    CASE "A": ShowLog LOGF, ""
    CASE "I": ShowLog LOGF, "INFO"
    CASE "W": ShowLog LOGF, "WARN"
    CASE "E": ShowLog LOGF, "ERROR"
    CASE "O": ShowLog OLDF, ""
    CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
END

' Shared error handler: remember the error number, then carry on
' with the statement after the one that failed.
Ignore:
    errFlag = ERR
    RESUME NEXT

' Write one log line: date, time, level padded to 5, message.
' The file is opened and closed every time, so even if the program
' crashes, everything logged so far is safely on disk.
SUB LogMsg (level$, msg$)
    OPEN LOGF FOR APPEND AS #1
    ' Time to rotate? (LOF works on APPEND files too.)
    IF LOF(1) > MAXLOG THEN
        CLOSE #1
        ON ERROR GOTO Ignore      ' the first time there is no .OLD yet
        KILL OLDF
        ON ERROR GOTO 0
        NAME LOGF AS OLDF
        rotations = rotations + 1
        OPEN LOGF FOR APPEND AS #1
        PRINT #1, DATE$; " "; TIME$; " INFO  --- log rotated ---"
    END IF
    l$ = DATE$ + " " + TIME$ + " " + LEFT$(level$ + "     ", 5) + " " + msg$
    PRINT #1, l$
    CLOSE #1
    ' Echo to the screen in a colour that matches the level.
    SELECT CASE level$
    CASE "WARN": COLOR 14
    CASE "ERROR": COLOR 12
    CASE ELSE: COLOR 7
    END SELECT
    PRINT l$
    COLOR 7
END SUB

' Show lines whose level column (characters 21-25) matches want$.
SUB ShowLog (f$, want$)
    errFlag = 0
    ON ERROR GOTO Ignore
    OPEN f$ FOR INPUT AS #2
    ON ERROR GOTO 0
    IF errFlag = 53 THEN PRINT f$; " does not exist yet.": k$ = INPUT$(1): EXIT SUB
    n = 0
    DO WHILE NOT EOF(2)
        LINE INPUT #2, l$
        IF want$ = "" OR RTRIM$(MID$(l$, 21, 5)) = want$ THEN
            PRINT l$: n = n + 1
            IF n MOD 20 = 0 THEN PRINT "-- more --": k$ = INPUT$(1)
        END IF
    LOOP
    CLOSE #2
    PRINT n; "line(s). Press a key."
    k$ = INPUT$(1)
END SUB
