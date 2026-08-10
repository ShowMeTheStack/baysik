' ============================================================
' TITLE:    Alarm Clock with ON TIMER
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     on timer, events, time$, alarm, sound, clock
' SUMMARY:  A desk clock that updates itself with ON TIMER events and rings an alarm at the time you set.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows a live clock.  You can set an alarm time (HH:MM:SS) or
'   a quick "snooze" alarm a number of minutes from now.  When the
'   clock reaches the alarm time it flashes and plays a tune.
'
'   The clock is NOT redrawn by the main loop.  Instead we use
'   EVENT TRAPPING:  ON TIMER(1) GOSUB Tick  asks BASIC to jump to
'   the Tick routine once every second, all by itself, whatever
'   the main program is doing (here: waiting for keys).  When
'   Tick finishes, RETURN goes back to exactly where we were.
'
' HOW TO USE
'   A = set alarm time    M = alarm in N minutes
'   O = turn alarm off    Q or Esc = quit
'   While ringing, press any key to stop it.
'
' CONCEPTS YOU WILL LEARN
'   * ON TIMER(n) GOSUB, TIMER ON / TIMER OFF / TIMER STOP
'   * TIME$ as "HH:MM:SS" text, and converting to seconds
'   * Comparing times as numbers of seconds since midnight
'   * PLAY for a short melody
'
' THINGS TO TRY
'   * Allow several alarms stored in an array.
'   * Show the time remaining until the alarm.
'   * Add a 12-hour AM/PM display option.
' ============================================================

DECLARE FUNCTION ToSecs& (t$)
DECLARE FUNCTION ToHMS$ (s&)

alarmOn = 0          ' is an alarm set?
alarmAt& = 0         ' alarm time, in seconds since midnight
ringing = 0

CLS
COLOR 15, 5: PRINT SPACE$(80);: LOCATE 1, 33: PRINT "ALARM CLOCK": COLOR 7, 0
LOCATE 20, 10: PRINT "A = set alarm   M = alarm in N minutes   O = off   Q = quit"

' ---- Set up the event trap ----
' Every 1 second BASIC will run the code at label Tick.
ON TIMER(1) GOSUB Tick
TIMER ON
GOSUB Tick                     ' draw the clock right away

DO
    k$ = UCASE$(INKEY$)
    IF ringing AND k$ <> "" THEN
        ' Any key silences the alarm.
        ringing = 0: alarmOn = 0
        LOCATE 12, 30: PRINT SPACE$(25)
        k$ = ""
    END IF
    SELECT CASE k$
        CASE "A"
            ' TIMER STOP: events are remembered but not run while we
            ' use INPUT, so the clock doesn't print over our typing.
            TIMER STOP
            LOCATE 16, 10: LINE INPUT "Alarm time (HH:MM or HH:MM:SS): "; t$
            s& = ToSecs&(t$)
            IF s& >= 0 THEN alarmAt& = s&: alarmOn = -1
            LOCATE 16, 10: PRINT SPACE$(60)
            TIMER ON
        CASE "M"
            TIMER STOP
            LOCATE 16, 10: INPUT "Ring in how many minutes"; n
            IF n > 0 THEN
                ' MOD 86400 wraps past midnight back to 00:00:00.
                alarmAt& = (ToSecs&(TIME$) + INT(n * 60)) MOD 86400
                alarmOn = -1
            END IF
            LOCATE 16, 10: PRINT SPACE$(60)
            TIMER ON
        CASE "O": alarmOn = 0
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP

TIMER OFF                      ' always switch the trap off when done
CLS
PRINT "Alarm clock closed."
END

' ===== Event handler: runs once per second =====
Tick:
    now$ = TIME$
    COLOR 14, 0
    LOCATE 6, 34: PRINT now$
    COLOR 7, 0
    LOCATE 8, 30
    IF alarmOn THEN PRINT "Alarm set for "; ToHMS$(alarmAt&) ELSE PRINT "No alarm set          "
    ' Has the alarm time arrived?  We don't test for EXACTLY equal:
    ' while you type at an INPUT the trap is paused (TIMER STOP), so
    ' a second could be skipped.  Instead we ring if we are 0-9
    ' seconds past the alarm.  "+ 86400 ... MOD 86400" makes this
    ' work across midnight too (23:59:58 -> 00:00:03 is 5 seconds).
    late& = (ToSecs&(now$) - alarmAt& + 86400) MOD 86400
    IF alarmOn AND NOT ringing AND late& < 10 THEN ringing = -1
    IF ringing THEN
        ' Flash by swapping colours on odd/even seconds.
        IF ToSecs&(now$) MOD 2 THEN COLOR 15, 4 ELSE COLOR 4, 15
        LOCATE 12, 30: PRINT "  WAKE UP! (any key)  "
        COLOR 7, 0
        PLAY "MBT200L16O4CEGO5C"     ' MB = play in background
    END IF
    RETURN

' "HH:MM:SS" or "HH:MM" -> seconds since midnight (-1 if bad).
FUNCTION ToSecs& (t$)
    t$ = LTRIM$(RTRIM$(t$))
    p1 = INSTR(t$, ":")
    IF p1 = 0 THEN ToSecs& = -1: EXIT FUNCTION
    h = VAL(LEFT$(t$, p1 - 1))
    rest$ = MID$(t$, p1 + 1)
    p2 = INSTR(rest$, ":")
    IF p2 THEN m = VAL(LEFT$(rest$, p2 - 1)): s = VAL(MID$(rest$, p2 + 1)) ELSE m = VAL(rest$): s = 0
    IF h < 0 OR h > 23 OR m < 0 OR m > 59 OR s < 0 OR s > 59 THEN ToSecs& = -1: EXIT FUNCTION
    ToSecs& = h * 3600& + m * 60 + s
END FUNCTION

' Seconds since midnight -> "HH:MM:SS".
FUNCTION ToHMS$ (s&)
    h = s& \ 3600: m = (s& \ 60) MOD 60: sec = s& MOD 60
    ToHMS$ = RIGHT$("0" + LTRIM$(STR$(h)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(m)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(sec)), 2)
END FUNCTION
