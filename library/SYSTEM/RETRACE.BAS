' ============================================================
' TITLE:    Vertical Retrace Sync (WAIT &H3DA)
' CATEGORY: System, Events & Hardware
' LEVEL:    Advanced
' TAGS:     wait, inp, port 3da, vsync, refresh rate, animation
' SUMMARY:  Measure your monitor's refresh rate and lock an animation to it using the VGA status port &H3DA.
' ------------------------------------------------------------
' WHAT IT DOES
'   A CRT monitor draws the picture with an electron beam, line by
'   line, about 60-70 times a second.  After the last line the beam
'   flies back to the top: the VERTICAL RETRACE.  VGA status port
'   &H3DA has bit 3 (value 8) set during that short moment.  Drawing
'   only during the retrace means the viewer never sees a half-drawn
'   frame ("tearing"), and gives perfectly steady timing for free.
'
'   WAIT port, mask, xor  pauses until  (INP(port) XOR xor) AND mask
'   is non-zero.  So:
'       WAIT &H3DA, 8      - wait until a retrace IS happening
'       WAIT &H3DA, 8, 8   - wait until the retrace is OVER
'   Doing both in a row waits for the START of the next retrace.
'
'   Part 1 counts retraces for 2 seconds to measure the refresh rate.
'   Part 2 bounces a block of stripes, synced to the retrace.
'
' HOW TO USE
'   Watch part 1.  In part 2 press S to switch sync on/off and see
'   how the speed changes; Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * WAIT port, AND-mask, XOR-mask
'   * Edge detection: waiting for a 0->1 change, not just a 1
'   * Frame-locked animation versus "as fast as possible"
'
' THINGS TO TRY
'   * Move the block 1 pixel per frame: speed is then the same on any
'     computer with the same monitor
'   * Print INP(&H3DA) in a loop and watch bit 0 (horizontal retrace)
' ============================================================

DEFINT A-Z
CLS
PRINT "PART 1: measuring the refresh rate with WAIT &H3DA"
PRINT "Counting vertical retraces for 2 seconds..."

frames = 0
t0! = TIMER
DO
    WAIT &H3DA, 8, 8          ' if a retrace is in progress, let it finish
    WAIT &H3DA, 8             ' now wait for the NEXT one to begin
    frames = frames + 1
LOOP WHILE TIMER - t0! < 2 AND TIMER >= t0!
el! = TIMER - t0!
IF el! <= 0 THEN el! = 2
PRINT USING "Counted ### retraces in #.## s  =>  about ###.# Hz"; frames; el!; frames / el!
PRINT
' The same measurement done "by hand" with INP: count each 0 -> 1 edge
' of bit 3.  This is exactly what WAIT does for you internally.
PRINT "Same thing with an INP polling loop (edge detection)..."
frames = 0: was = 0
t0! = TIMER
DO
    now = INP(&H3DA) AND 8          ' 8 during retrace, 0 otherwise
    IF now = 8 AND was = 0 THEN frames = frames + 1   ' rising edge
    was = now
LOOP WHILE TIMER - t0! < 2 AND TIMER >= t0!
el! = TIMER - t0!
IF el! <= 0 THEN el! = 2
PRINT USING "Counted ### rising edges in #.## s  =>  about ###.# Hz"; frames; el!; frames / el!
PRINT "(Typical answers: 60 or 70 Hz.  A busy browser tab may count fewer.)"
PRINT
PRINT "Press a key for part 2 (Esc quits)."
DO: k$ = INKEY$: LOOP WHILE k$ = ""
IF k$ = CHR$(27) THEN END

' ---- PART 2: retrace-locked animation ------------------------------------
SCREEN 13
sync = 1: x = 10: dx = 2: n& = 0
t0! = TIMER
DO
    IF sync THEN
        WAIT &H3DA, 8, 8: WAIT &H3DA, 8     ' one move per screen refresh
    END IF
    ' erase the old block's leading/trailing edge and draw at the new x
    LINE (x, 60)-(x + 59, 140), 0, BF
    x = x + dx
    IF x < 2 OR x > 258 THEN dx = -dx: x = x + dx
    FOR s = 0 TO 59 STEP 6                  ' vertical stripes
        LINE (x + s, 60)-(x + s + 2, 140), 40 + s \ 6, BF
    NEXT s
    n& = n& + 1

    LOCATE 1, 1
    IF sync THEN PRINT "SYNC ON  (WAIT &H3DA) "; ELSE PRINT "SYNC OFF (full speed) ";
    IF TIMER - t0! >= 1 OR TIMER < t0! THEN    ' frames-per-second meter
        fps& = n&: n& = 0: t0! = TIMER
    END IF
    LOCATE 2, 1: PRINT USING "Moves per second: #####"; fps&;
    LOCATE 24, 1: PRINT "S = toggle sync   Esc = quit";

    k$ = UCASE$(INKEY$)
    IF k$ = "S" THEN sync = 1 - sync
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
PRINT "Bye."
END
