' ============================================================
' TITLE:    Frame Timing Workshop
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     TIMER, WAIT, vertical retrace, delta time, FPS
' SUMMARY:  Race two balls - one moved "per frame", one moved by real elapsed TIME - and see which keeps steady speed under load.
' ------------------------------------------------------------
' WHAT IT DOES
'   Two balls cross the screen over and over.
'     Red ball:   moves 2 pixels EVERY FRAME.
'     Green ball: moves 120 pixels PER SECOND, using TIMER to
'                 measure how much time the last frame took
'                 ("delta time", dt) and moving 120 * dt pixels.
'   You can add fake "work" to each frame to slow the computer
'   down.  The red ball slows down with it.  The green ball
'   takes bigger steps and keeps the same real speed.
'   You can also turn vertical-retrace syncing on/off.
'
' HOW TO USE
'   +  / -   add / remove extra work per frame (slows things down)
'   V        toggle WAIT &H3DA (sync to the monitor refresh)
'   Esc      quit
'   The top lines show frames per second (FPS) and dt.
'
' CONCEPTS YOU WILL LEARN
'   * TIMER returns seconds since midnight (with fractions)
'   * Delta-time movement: distance = speed * time
'   * WAIT &H3DA, 8 waits for the vertical retrace - the moment
'     the monitor beam jumps back to the top.  Waiting for it
'     paces a game to the screen's refresh rate (60 or 70 Hz)
'   * Counting frames per second
'   * Handling the TIMER rollover at midnight
'
' THINGS TO TRY
'   * Change the green ball's speed (SPEED constant)
'   * Without V-sync, how high does the FPS go?
' ============================================================
DEFINT A-Z
DECLARE SUB Ball (x!, y, c)

CONST SPEED = 120!           ' green ball speed in pixels per second
CONST RADIUS = 8

SCREEN 13
COLOR 15
LOCATE 25, 1: PRINT "+/- work  V vsync  Esc quit";
LINE (0, 70)-(319, 70), 8: LINE (0, 130)-(319, 130), 8
LOCATE 10, 1: PRINT "per frame";
LOCATE 18, 1: PRINT "per second";

redX! = 0: greenX! = 0
oldRed = -100: oldGreen = -100
vsync = -1: work = 0
last! = TIMER                 ' time at the end of the previous frame
fpsStart! = last!: frames = 0: fps = 0

DO
    ' ---- 1. Measure how long the last frame took ------------
    now! = TIMER
    dt! = now! - last!
    ' At midnight TIMER jumps from 86399.99 back to 0, which would
    ' make dt negative.  Adding a whole day (86400 s) fixes it.
    IF dt! < 0 THEN dt! = dt! + 86400
    ' If the program was paused (a very long frame), don't let
    ' the ball teleport: clamp dt to a tenth of a second.
    IF dt! > .1 THEN dt! = .1
    last! = now!

    ' ---- 2. Move both balls ---------------------------------
    redX! = redX! + 2                       ' frame-based
    greenX! = greenX! + SPEED * dt!         ' time-based
    IF redX! > 319 THEN redX! = 0
    IF greenX! > 319 THEN greenX! = 0

    ' ---- 3. Sync to the monitor (optional) ------------------
    ' Bit 3 of port &H3DA is 1 during vertical retrace.  First
    ' wait until it is 0 (WAIT ..., 8, 8 waits for bit=0), then
    ' until it becomes 1.  That catches the START of a retrace.
    IF vsync THEN WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    ' ---- 4. Draw: erase the old balls, draw the new ones ----
    Ball CSNG(oldRed), 100, 0: Ball redX!, 100, 12
    Ball CSNG(oldGreen), 160, 0: Ball greenX!, 160, 10
    oldRed = redX!: oldGreen = greenX!

    ' ---- 5. Fake extra work (like a busy game would have) --
    FOR i = 1 TO work: x! = SQR(i) * SIN(i): NEXT

    ' ---- 6. Frames-per-second counter -----------------------
    frames = frames + 1
    el! = now! - fpsStart!: IF el! < 0 THEN el! = el! + 86400
    IF el! >= 1 THEN
        fps = frames / el!: frames = 0: fpsStart! = now!
        LOCATE 1, 1
        PRINT USING "FPS:###  dt:#.### s  work:#####  "; fps; dt!; work
        LOCATE 2, 1: IF vsync THEN PRINT "V-sync ON "; ELSE PRINT "V-sync OFF";
    END IF

    k$ = UCASE$(INKEY$)
    IF k$ = "+" OR k$ = "=" THEN IF work < 20000 THEN work = work + 500
    IF k$ = "-" THEN IF work > 0 THEN work = work - 500
    IF k$ = "V" THEN vsync = NOT vsync
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

SUB Ball (x!, y, c)
    ' Draw a filled ball - or, with c = 0, erase it by blacking
    ' out the square that contains it.
    IF c = 0 THEN
        LINE (x! - RADIUS, y - RADIUS)-(x! + RADIUS, y + RADIUS), 0, BF
    ELSE
        CIRCLE (x!, y), RADIUS, c
        PAINT (x!, y), c, c
    END IF
END SUB
