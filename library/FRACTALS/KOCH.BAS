' ============================================================
' TITLE:    Koch Snowflake
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     fractals, recursion, trigonometry, perimeter, SCREEN 12
' SUMMARY:  A recursive SUB turns a triangle into a snowflake whose edge grows longer forever.
' ------------------------------------------------------------
' WHAT IT DOES
'   Take a straight line.  Cut it into thirds and replace the middle
'   third with two sides of a little equilateral triangle that
'   points outward:      ____    becomes   __/\__
'   Do that to every new piece, again and again.  Applying it to all
'   three sides of a triangle gives the Koch snowflake.
'   The program draws levels 0 to 5, coloring each level differently,
'   and shows how the perimeter grows by 4/3 every level.
'
' HOW TO USE
'   Press a key to draw the next level.  Esc quits.
'   At the end press A for "anti-snowflake" (bumps pointing inward).
'
' CONCEPTS YOU WILL LEARN
'   * A recursive SUB that splits a line into 4 smaller lines
'   * Rotating a direction vector with COS and SIN (60 degrees)
'   * Geometric growth: perimeter * (4/3)^n gets bigger and bigger,
'     yet the area of the snowflake stays finite
'
' THINGS TO TRY
'   * Use a square start shape (4 sides) instead of a triangle
'   * Change the bump angle from 60 to 80 or 85 degrees
'   * Replace the middle third with 3 sides of a square
' ============================================================
DECLARE SUB Koch (x1!, y1!, x2!, y2!, level%, c%)

DIM SHARED sgn!         ' +1: bumps point outward, -1: inward
CONST PI = 3.14159265#
SCREEN 12

sgn! = 1
DO
    FOR lev% = 0 TO 5
        CLS
        GOSUB DrawFlake
        COLOR 15
        LOCATE 1, 1: PRINT "Koch snowflake, level"; lev%
        ' Each level: every segment becomes 4 segments 1/3 as long.
        segs& = 3 * 4 ^ lev%
        PRINT "segments:"; segs&
        PRINT USING "perimeter: ####.## x the starting triangle"; (4 / 3) ^ lev%
        LOCATE 30, 1: PRINT "any key = next level   Esc = quit";
        DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
        IF k$ = CHR$(27) THEN EXIT DO
    NEXT
    IF k$ = CHR$(27) THEN EXIT DO
    LOCATE 30, 1: PRINT "A = anti-snowflake  S = snowflake  Esc = quit";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "A" OR k$ = "S" OR k$ = CHR$(27)
    IF k$ = "A" THEN sgn! = -1 ELSE sgn! = 1
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

DrawFlake:
    ' An equilateral triangle centred on the screen.  We list the
    ' corners CLOCKWISE so that "turn left" from each side means
    ' "outward".  SCREEN 12 pixels are square, so no aspect fix needed.
    r! = 190                                ' distance centre -> corner
    cx! = 320: cy! = 260
    FOR i% = 0 TO 2
        a1! = -PI / 2 + i% * 2 * PI / 3     ' angle of this corner
        a2! = a1! + 2 * PI / 3              ' angle of the next corner
        Koch cx! + r! * COS(a1!), cy! + r! * SIN(a1!), cx! + r! * COS(a2!), cy! + r! * SIN(a2!), lev%, 9 + lev%
    NEXT
    RETURN

' Draws a Koch curve from (x1,y1) to (x2,y2).
SUB Koch (x1!, y1!, x2!, y2!, level%, c%)
    IF level% = 0 THEN
        LINE (x1!, y1!)-(x2!, y2!), c%      ' base case: straight line
        EXIT SUB
    END IF
    dx! = (x2! - x1!) / 3                   ' one third of the segment
    dy! = (y2! - y1!) / 3
    ax! = x1! + dx!: ay! = y1! + dy!        ' point A at 1/3
    bx! = x1! + 2 * dx!: by! = y1! + 2 * dy!  ' point B at 2/3
    ' Tip of the bump: rotate the vector (dx, dy) by 60 degrees and
    ' add it to A.  Rotation by angle t:
    '    x' = x * cos(t) - y * sin(t)
    '    y' = x * sin(t) + y * cos(t)
    ' cos(60) = 0.5 and sin(60) = 0.866.  Screen y points DOWN, so a
    ' negative angle turns "left" as we see it.
    s! = -.8660254 * sgn!
    px! = ax! + dx! * .5 - dy! * s!
    py! = ay! + dx! * s! + dy! * .5
    ' Four smaller Koch curves: x1->A, A->tip, tip->B, B->x2
    Koch x1!, y1!, ax!, ay!, level% - 1, c%
    Koch ax!, ay!, px!, py!, level% - 1, c%
    Koch px!, py!, bx!, by!, level% - 1, c%
    Koch bx!, by!, x2!, y2!, level% - 1, c%
END SUB
