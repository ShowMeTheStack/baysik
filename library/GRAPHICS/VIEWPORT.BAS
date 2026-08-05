' ============================================================
' TITLE:    Four Viewports
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     view, viewport, window, clipping, animation, screen 9
' SUMMARY:  Splits the screen into four independent VIEW windows, each running its own animation with its own coordinates.
' ------------------------------------------------------------
' WHAT IT DOES
'   VIEW turns a rectangle of the screen into a mini-screen: all
'   drawing is clipped to it, coordinates start at its corner, and
'   CLS clears only that rectangle. Here four viewports run at the
'   same time in EGA 640x350 (SCREEN 9):
'     top-left     a bouncing ball (pixel coordinates)
'     top-right    a scrolling sine wave (WINDOW maths coordinates)
'     bottom-left  random coloured lines, clipped at the edges
'     bottom-right a growing spiral that restarts with CLS
'
' HOW TO USE
'   Watch. Press any key to stop.
'
' CONCEPTS YOU WILL LEARN
'   * VIEW (x1,y1)-(x2,y2), fill, border
'   * VIEW SCREEN: clip but keep whole-screen coordinates
'   * Combining VIEW with WINDOW for per-panel maths coordinates
'   * CLS inside a viewport clears only that viewport
'   * Simple "time slicing": do a little work for each panel per loop
'
' THINGS TO TRY
'   * Add a fifth, smaller viewport in the middle
'   * Make the ball leave a trail by not erasing it
'   * Change the WINDOW in panel 2 to show 4 waves instead of 2
' ============================================================

CONST PI = 3.14159265#
SCREEN 9
CLS
COLOR 15
LOCATE 1, 30: PRINT "VIEW - four mini screens"
LOCATE 25, 30: PRINT "Press any key to stop";

' Panel positions (whole-screen pixels). Each is 300 x 150.
' Ball state: position and velocity in panel-1 coordinates.
bx = 50: by = 40: vx = 3: vy = 2
phase = 0                 ' sine wave scroll position
ang = 0: rad = 0          ' spiral state

RANDOMIZE TIMER
' Draw the four empty panels once, with borders (colour 7).
VIEW (10, 18)-(310, 168), 1, 7     ' fill colour 1 = blue background
VIEW (330, 18)-(630, 168), 0, 7
VIEW (10, 178)-(310, 328), 0, 7
VIEW (330, 178)-(630, 328), 0, 7

DO
    ' ---- Panel 1: bouncing ball ---------------------------------
    ' Coordinates inside the panel start at (0,0) in ITS top-left.
    VIEW (10, 18)-(310, 168)
    CIRCLE (bx, by), 8, 1             ' erase old ball (paint blue)
    PAINT (bx, by), 1, 1
    bx = bx + vx: by = by + vy
    IF bx < 8 OR bx > 292 THEN vx = -vx: bx = bx + vx
    IF by < 8 OR by > 142 THEN vy = -vy: by = by + vy
    CIRCLE (bx, by), 8, 14
    PAINT (bx, by), 14, 14

    ' ---- Panel 2: sine wave with its own WINDOW ------------------
    ' WINDOW applies to the CURRENT viewport, so x runs 0..4*PI
    ' and y runs -1.2..1.2 inside this panel only.
    VIEW (330, 18)-(630, 168)
    WINDOW (0, -1.2)-(4 * PI, 1.2)
    CLS                               ' clears just this panel
    LINE (0, 0)-(4 * PI, 0), 8
    PSET (0, SIN(phase))
    FOR x = 0 TO 4 * PI STEP .1
        LINE -(x, SIN(x + phase)), 10
    NEXT x
    phase = phase + .15
    WINDOW                            ' back to pixels for the others

    ' ---- Panel 3: random lines - VIEW SCREEN ---------------------
    ' With VIEW SCREEN, coordinates stay whole-screen, but drawing
    ' is still clipped. Lines aimed far outside get cut neatly.
    VIEW SCREEN (10, 178)-(310, 328)
    LINE (RND * 640, RND * 350)-(RND * 640, RND * 350), INT(RND * 15) + 1

    ' ---- Panel 4: a spiral ---------------------------------------
    VIEW (330, 178)-(630, 328)
    x1 = 150 + COS(ang) * rad: y1 = 75 + SIN(ang) * rad * .73
    ang = ang + .3: rad = rad + .4
    x2 = 150 + COS(ang) * rad: y2 = 75 + SIN(ang) * rad * .73
    LINE (x1, y1)-(x2, y2), (INT(ang) MOD 6) + 9
    IF rad > 160 THEN CLS: ang = 0: rad = 0

    ' Short pause so the animation runs at the same speed everywhere
    t! = TIMER: DO: LOOP WHILE TIMER - t! < .02 AND TIMER >= t!
LOOP WHILE INKEY$ = ""

VIEW: WINDOW
SCREEN 0: WIDTH 80
END
