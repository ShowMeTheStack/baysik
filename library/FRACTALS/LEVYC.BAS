' ============================================================
' TITLE:    Levy C Curve
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     fractals, recursion, geometry, animation, SCREEN 12
' SUMMARY:  Replace every line with two lines meeting at a right angle - and an ornate letter C appears.
' ------------------------------------------------------------
' WHAT IT DOES
'   Start with one straight line.  Replace it by the two short sides
'   of a right-angled isosceles triangle built on top of it (a "tent"
'   with a 90 degree peak).  Do the same with each new line, forever.
'   Paul Levy studied this curve in 1938; it looks like a fancy
'   letter C made of lace.
'
'   The program animates levels 0 to 14.  Each level is drawn in a
'   new color on top of the last one so you can see how the curve
'   bends outward step by step.
'
' HOW TO USE
'   Watch the animation.  Space = pause/continue, Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Recursion that doubles the number of lines every level
'   * Finding the peak point with a 45-degree rotation:
'       peak = midpoint + (perpendicular of the line) / 2
'   * 2^n growth: level 14 has 16384 tiny lines
'
' THINGS TO TRY
'   * Alternate the side of the tent every other call -> the dragon!
'   * Change the peak so the angle is 120 degrees instead of 90
'   * Draw only the final level, without the earlier ones
' ============================================================
DECLARE SUB Levy (x1!, y1!, x2!, y2!, level%, c%)

SCREEN 12
CONST MAXLEV = 14

DO
    CLS
    COLOR 15: PRINT "Levy C curve"
    FOR lev% = 0 TO MAXLEV
        LOCATE 2, 1: PRINT "level"; lev%; "  lines:"; 2 ^ lev%; "   "
        ' Each level is drawn on top of the previous ones in a new
        ' color (1..15), so you can see the curve bulge outward.
        Levy 220, 340, 420, 340, lev%, 1 + lev% MOD 15
        ' pause about half a second, or longer if Space is pressed
        t! = TIMER
        DO
            k$ = INKEY$
            IF k$ = CHR$(27) THEN EXIT DO
            IF k$ = " " THEN
                DO: k$ = INKEY$: LOOP UNTIL k$ <> ""   ' wait for a key
                IF k$ = CHR$(27) THEN EXIT DO
            END IF
        LOOP UNTIL TIMER - t! > .5 OR TIMER < t!
        IF k$ = CHR$(27) THEN EXIT FOR
    NEXT
    IF k$ <> CHR$(27) THEN
        LOCATE 30, 1: PRINT "Any key = again   Esc = quit";
        DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    END IF
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' Draws a Levy curve between (x1,y1) and (x2,y2).
SUB Levy (x1!, y1!, x2!, y2!, level%, c%)
    IF level% = 0 THEN
        LINE (x1!, y1!)-(x2!, y2!), c%
        EXIT SUB
    END IF
    ' The vector along the line is (dx, dy).  Turning it 90 degrees
    ' gives (dy, -dx).  The tent's peak is the midpoint pushed out by
    ' half of that perpendicular vector, so both new sides have length
    ' (old length) / sqrt(2) and meet at exactly 90 degrees.
    dx! = x2! - x1!: dy! = y2! - y1!
    px! = (x1! + x2!) / 2 + dy! / 2
    py! = (y1! + y2!) / 2 - dx! / 2
    Levy x1!, y1!, px!, py!, level% - 1, c%
    Levy px!, py!, x2!, y2!, level% - 1, c%
END SUB
