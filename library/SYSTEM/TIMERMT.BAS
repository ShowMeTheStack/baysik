' ============================================================
' TITLE:    ON TIMER Multitasking
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     on timer, events, multitasking, clock, gosub
' SUMMARY:  A live clock and a spinning worker run "in the background" while you type a note.
' ------------------------------------------------------------
' WHAT IT DOES
'   DOS had no threads, but BASIC could still do two jobs at once
'   using EVENT TRAPPING.  ON TIMER(1) GOSUB asks BASIC to interrupt
'   the main program once every second and run a little subroutine.
'   Here that subroutine updates a clock and an "uptime" counter in
'   the top bar, while the main loop lets you type a line of text and
'   also animates a spinner and a progress bar.
'
' HOW TO USE
'   Type letters to write a note.  Backspace deletes, Enter clears.
'   Press P to pause/resume the clock (TIMER STOP / TIMER ON).
'   Press Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * ON TIMER(n) GOSUB label  +  TIMER ON / TIMER OFF / TIMER STOP
'   * How BASIC checks for events between statements
'   * Why a trap handler must be short and must end with RETURN
'   * Saving and restoring the cursor (CSRLIN / POS) inside a handler
'
' THINGS TO TRY
'   * Change the interval to 0.5 seconds (ON TIMER(.5) does not work in
'     GW-BASIC: the interval is whole seconds 1..86400)
'   * Add a second "task" that beeps every 10 seconds
'   * With TIMER STOP, events are remembered: watch the clock jump
'     forward the instant you press P again
' ============================================================

DEFINT A-Z
DIM SHARED ticks AS LONG          ' how many timer events have happened

CLS
COLOR 15, 1
LOCATE 1, 1: PRINT SPACE$(80);    ' a blue status bar across the top
LOCATE 1, 2: PRINT "ON TIMER demo";
COLOR 7, 0

LOCATE 4, 1
PRINT "Main task: type a note below.  P = pause clock, Esc = quit."
PRINT
PRINT "Note> ";

' ---- set up the event trap ------------------------------------------
' From now on, once per second, BASIC will "GOSUB ClockTick" all by
' itself - in between whatever statements the main loop is running.
ON TIMER(1) GOSUB ClockTick
TIMER ON
paused = 0

note$ = ""
spin$ = "|/-\"                       ' four frames of a spinner
frame = 0
work = 0

' ---- the main task ------------------------------------------------------
DO
    k$ = INKEY$
    SELECT CASE k$
        CASE CHR$(27)
            EXIT DO
        CASE "p", "P"
            IF paused THEN
                TIMER ON                  ' resume: a STOPped event fires now
                paused = 0
            ELSE
                TIMER STOP                ' events are remembered, not lost
                paused = 1
            END IF
            LOCATE 10, 1
            IF paused THEN PRINT "Clock: PAUSED (TIMER STOP) "; ELSE PRINT "Clock: running (TIMER ON) ";
        CASE CHR$(8)
            IF LEN(note$) > 0 THEN note$ = LEFT$(note$, LEN(note$) - 1)
        CASE CHR$(13)
            note$ = ""
        CASE " " TO "~"
            IF LEN(note$) < 70 THEN note$ = note$ + k$
    END SELECT

    ' redraw the note line (pad with a space to erase a deleted char)
    LOCATE 6, 7: PRINT note$; " ";

    ' a second "job": a spinner and a fake progress bar
    frame = (frame + 1) MOD 4
    LOCATE 8, 1: PRINT "Worker "; MID$(spin$, frame + 1, 1);
    work = (work + 1) MOD 400
    LOCATE 8, 10: PRINT STRING$(work \ 10, 219); STRING$(40 - work \ 10, 176);

    ' leave the cursor at the end of the note so typing feels normal
    LOCATE 6, 7 + LEN(note$)

    ' a tiny delay so the spinner is visible: wait for the next clock
    ' tick (TIMER only changes 18.2 times a second)
    t! = TIMER
    DO WHILE TIMER = t!: LOOP
LOOP

TIMER OFF                          ' always switch traps off when done
CLS
PRINT "The clock ticked"; ticks; "times while you worked."
END

' ---- the event handler ----------------------------------------------------
' Runs once per second.  Keep it SHORT: the main program is frozen
' while we are in here.  It must restore the cursor position so the
' main task does not suddenly print in the wrong place.
ClockTick:
    ticks = ticks + 1
    r = CSRLIN: c = POS(0)              ' remember where the cursor was
    COLOR 14, 1
    LOCATE 1, 30: PRINT "Time "; TIME$;
    LOCATE 1, 55: PRINT USING "Uptime: ##### s"; ticks;
    COLOR 7, 0
    LOCATE r, c                         ' put the cursor back
RETURN
