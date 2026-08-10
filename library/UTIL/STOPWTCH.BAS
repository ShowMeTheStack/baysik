' ============================================================
' TITLE:    Stopwatch and Countdown Timer
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     timer, time, stopwatch, countdown, laps, big digits
' SUMMARY:  A lap stopwatch and a countdown timer with big block digits, driven by the TIMER function.
' ------------------------------------------------------------
' WHAT IT DOES
'   Two tools in one:
'   * STOPWATCH - start/stop/reset, records up to 8 lap times.
'   * COUNTDOWN - type minutes and seconds, it counts down and
'     beeps when it reaches zero.  You can pause it.
'   The time is drawn in big digits made of block characters.
'
'   TIMER returns the number of seconds since midnight (with
'   fractions).  We never "count" seconds ourselves - we remember
'   the TIMER value when we started and subtract.  That way the
'   time stays accurate even if the screen drawing is slow.
'
' HOW TO USE
'   Main menu: S = stopwatch, C = countdown, Q/Esc = quit.
'   Stopwatch: Space = start/stop, L = lap, R = reset, Esc = back
'   Countdown: Space = pause/resume, Esc = back
'
' CONCEPTS YOU WILL LEARN
'   * TIMER and elapsed time = now - start
'   * Handling the midnight wrap-around (TIMER goes back to 0)
'   * Drawing big digits from a font stored in DATA
'   * A main loop that never waits: INKEY$ polling
'
' THINGS TO TRY
'   * Show the fastest and slowest lap in different colours.
'   * Play a tune with PLAY when the countdown ends.
'   * Add an "interval" mode: 30s work, 10s rest, repeat.
' ============================================================

DECLARE SUB BigTime (t#, row%)
DECLARE FUNCTION Elapsed# (start#)
DECLARE FUNCTION Fmt$ (t#)

' ---- Load a 3x5 "font" for the digits 0-9 and ":" "." ----
' Each character is 5 rows of 3 pixels; "#" = block, "." = blank.
DIM SHARED font$(0 TO 11, 1 TO 5)
FOR c = 0 TO 11
    FOR r = 1 TO 5: READ font$(c, r): NEXT r
NEXT c
DATA "###","#.#","#.#","#.#","###"
DATA "..#","..#","..#","..#","..#"
DATA "###","..#","###","#..","###"
DATA "###","..#","###","..#","###"
DATA "#.#","#.#","###","..#","..#"
DATA "###","#..","###","..#","###"
DATA "###","#..","###","#.#","###"
DATA "###","..#","..#","..#","..#"
DATA "###","#.#","###","#.#","###"
DATA "###","#.#","###","..#","###"
DATA "...",".#.","...",".#.","..."
DATA "...","...","...","...",".#."

DO
    CLS
    COLOR 15, 2: PRINT SPACE$(80);: LOCATE 1, 27: PRINT "STOPWATCH & COUNTDOWN": COLOR 7, 0
    LOCATE 5, 30: PRINT "S  Stopwatch"
    LOCATE 6, 30: PRINT "C  Countdown timer"
    LOCATE 7, 30: PRINT "Q  Quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO

    IF k$ = "S" THEN
        ' ================= STOPWATCH =================
        ' total# = time banked from previous runs; start# = TIMER
        ' when the current run began.  running = are we counting?
        CLS
        LOCATE 2, 25: PRINT "STOPWATCH   Space=start/stop  L=lap  R=reset  Esc=back"
        total# = 0: running = 0: laps = 0: lastLap# = 0
        DO
            IF running THEN t# = total# + Elapsed#(start#) ELSE t# = total#
            BigTime t#, 5
            k$ = UCASE$(INKEY$)
            SELECT CASE k$
                CASE " "
                    IF running THEN
                        total# = total# + Elapsed#(start#)   ' bank the run
                        running = 0
                    ELSE
                        start# = TIMER: running = -1
                    END IF
                CASE "L"
                    IF running AND laps < 8 THEN
                        laps = laps + 1
                        ' lap time = now - time of previous lap
                        LOCATE 12 + laps, 25
                        PRINT USING "Lap #:  "; laps;
                        PRINT Fmt$(t# - lastLap#); "   total "; Fmt$(t#)
                        lastLap# = t#
                    END IF
                CASE "R"
                    total# = 0: running = 0: laps = 0: lastLap# = 0
                    FOR i = 13 TO 21: LOCATE i, 1: PRINT SPACE$(79);: NEXT i
                CASE CHR$(27): EXIT DO
            END SELECT
        LOOP
    ELSEIF k$ = "C" THEN
        ' ================= COUNTDOWN =================
        CLS
        LOCATE 3, 10: INPUT "Minutes: ", mins
        LOCATE 4, 10: INPUT "Seconds: ", secs
        dur# = ABS(mins) * 60 + ABS(secs)
        IF dur# = 0 THEN dur# = 10           ' sensible default
        CLS
        LOCATE 2, 30: PRINT "COUNTDOWN   Space=pause  Esc=back"
        start# = TIMER: banked# = 0: paused = 0
        DO
            IF paused THEN used# = banked# ELSE used# = banked# + Elapsed#(start#)
            left# = dur# - used#
            IF left# <= 0 THEN
                BigTime 0, 5
                LOCATE 14, 10: PRINT STRING$(60, 219)     ' full bar
                LOCATE 16, 34: COLOR 28: PRINT "TIME IS UP!": COLOR 7
                FOR b = 1 TO 3: SOUND 880, 3: SOUND 32767, 3: NEXT b
                LOCATE 18, 32: PRINT "Press any key..."
                DO: LOOP WHILE INKEY$ = ""
                EXIT DO
            END IF
            BigTime left#, 5
            ' A progress bar: how much of the time has gone.
            w = INT(60 * used# / dur#)
            LOCATE 14, 10: PRINT STRING$(w, 219); STRING$(60 - w, 176)
            k$ = INKEY$
            IF k$ = " " THEN
                IF paused THEN
                    start# = TIMER: paused = 0
                ELSE
                    banked# = banked# + Elapsed#(start#): paused = -1
                END IF
            END IF
            IF k$ = CHR$(27) THEN EXIT DO
        LOOP
    END IF
LOOP
CLS
END

' Draw t# seconds as MM:SS.t in big digits starting at row%.
SUB BigTime (t#, row%)
    s$ = Fmt$(t#)               ' e.g. "03:07.4"
    x = 20
    FOR i = 1 TO LEN(s$)
        ch$ = MID$(s$, i, 1)
        IF ch$ = ":" THEN c = 10 ELSE IF ch$ = "." THEN c = 11 ELSE c = VAL(ch$)
        FOR r = 1 TO 5
            LOCATE row% + r - 1, x
            ' Each font pixel becomes two screen characters wide so
            ' the digits look roughly square.
            FOR p = 1 TO 3
                IF MID$(font$(c, r), p, 1) = "#" THEN PRINT CHR$(219); CHR$(219); ELSE PRINT "  ";
            NEXT p
        NEXT r
        x = x + 7
    NEXT i
END SUB

' Seconds since start#, correct even if midnight has passed.
FUNCTION Elapsed# (start#)
    e# = TIMER - start#
    ' After midnight TIMER restarts at 0, so the difference goes
    ' negative.  Adding one day (86400 s) fixes it.
    IF e# < 0 THEN e# = e# + 86400
    Elapsed# = e#
END FUNCTION

' Turn seconds into "MM:SS.t" text.
FUNCTION Fmt$ (t#)
    IF t# < 0 THEN t# = 0
    tenths& = INT(t# * 10)
    m& = tenths& \ 600
    s& = (tenths& \ 10) MOD 60
    f& = tenths& MOD 10
    ' RIGHT$("0" + ...) adds a leading zero to single digits.
    Fmt$ = RIGHT$("0" + LTRIM$(STR$(m& MOD 100)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(s&)), 2) + "." + LTRIM$(STR$(f&))
END FUNCTION
