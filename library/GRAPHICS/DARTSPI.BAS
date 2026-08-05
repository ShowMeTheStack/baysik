' ============================================================
' TITLE:    Darts for Pi (POINT and PMAP)
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     point, pmap, window, monte carlo, pi, random, screen 12
' SUMMARY:  Estimates PI by throwing random darts at a painted circle and using POINT to see where each one landed.
' ------------------------------------------------------------
' WHAT IT DOES
'   A circle of radius 1 sits inside a 2 x 2 square. The circle's
'   area is PI and the square's is 4, so a random dart lands in
'   the circle PI/4 of the time. We throw thousands of darts and
'   ask the SCREEN what colour is under each one with POINT -
'   no circle maths needed! PMAP shows how the maths coordinates
'   become real pixels.
'
' HOW TO USE
'   Darts fly automatically. Press any key to stop; the final
'   estimate stays on screen until you press another key.
'
' CONCEPTS YOU WILL LEARN
'   * WINDOW for a -1..1 coordinate system
'   * POINT(x, y): read the colour at a spot (in WINDOW units)
'   * PMAP(x, 0) / PMAP(y, 1): logical -> pixel coordinates
'   * PMAP(px, 2) / PMAP(py, 3): pixel -> logical coordinates
'   * The Monte Carlo method: answering questions with randomness
'
' THINGS TO TRY
'   * Replace the circle with a triangle and estimate its area
'   * Throw 100,000 darts - how close does it get?
'   * Compare with the pure-maths test  x*x + y*y <= 1
'     (the screen circle is made of square pixels, so the POINT
'     answer is always a tiny bit off - about 1%)
' ============================================================

CONST PI = 3.14159265#
CONST INSIDE = 1           ' colour of the circle (blue)
CONST OUTSIDE = 0          ' background

SCREEN 12
CLS
RANDOMIZE TIMER

' The target occupies a 400 x 400 pixel square on the left.
' VIEW limits drawing to it; WINDOW gives it maths coordinates.
VIEW (20, 40)-(419, 439), OUTSIDE, 15
WINDOW (-1, -1)-(1, 1)

' Paint the target once.
CIRCLE (0, 0), 1, INSIDE
PAINT (0, 0), INSIDE, INSIDE

' ---- Show PMAP in action ------------------------------------
' PMAP(0, 0) asks "which pixel column (inside the view) is x=0?"
VIEW: WINDOW                 ' temporarily normal to print text
LOCATE 2, 3: PRINT "Throwing darts at a circle inside a square"
LOCATE 4, 56: PRINT "PMAP conversions:"
VIEW (20, 40)-(419, 439): WINDOW (-1, -1)-(1, 1)
p0 = PMAP(0, 0): p1 = PMAP(1, 1): p2 = PMAP(-1, 1)
px = PMAP(100, 2)
VIEW: WINDOW
LOCATE 5, 56: PRINT USING "x=0   -> pixel ###"; p0
LOCATE 6, 56: PRINT USING "y=1   -> pixel ###"; p1
LOCATE 7, 56: PRINT USING "y=-1  -> pixel ###"; p2
LOCATE 8, 56: PRINT USING "px100 -> x = #.###"; px
LOCATE 9, 56: PRINT "(Y goes UP in WINDOW,"
LOCATE 10, 56: PRINT " but DOWN in pixels!)"

' ---- Throw the darts -----------------------------------------
total& = 0: hits& = 0
DO
    VIEW (20, 40)-(419, 439): WINDOW (-1, -1)-(1, 1)
    FOR i = 1 TO 50                     ' 50 darts per screen update
        x = RND * 2 - 1                 ' -1 .. 1
        y = RND * 2 - 1
        ' What is under the dart? Previous darts may have painted
        ' this spot already, so we accept "hit" colours too.
        c = POINT(x, y)
        IF c = INSIDE OR c = 10 THEN
            hits& = hits& + 1
            PSET (x, y), 10             ' green = inside
        ELSE
            PSET (x, y), 12             ' red = outside
        END IF
        total& = total& + 1
    NEXT i
    ' Show the score (text needs the full-screen view again)
    VIEW: WINDOW
    est# = 4# * hits& / total&
    LOCATE 14, 56: PRINT USING "Darts:  #########"; total&
    LOCATE 15, 56: PRINT USING "Inside: #########"; hits&
    LOCATE 17, 56: PRINT USING "PI ~ #.######"; est#
    LOCATE 18, 56: PRINT USING "PI = #.######"; PI
    LOCATE 19, 56: PRINT USING "error  #.######"; ABS(est# - PI)
    LOCATE 28, 56: PRINT "Any key = stop";
LOOP WHILE INKEY$ = "" AND total& < 200000

LOCATE 28, 56: PRINT "Done! Press a key";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
END
