' ============================================================
' TITLE:    Pythagoras Tree
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     fractals, recursion, vectors, squares, palette, SCREEN 12
' SUMMARY:  Squares sprout two smaller squares on a right triangle, building a tree out of the Pythagorean theorem.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draw a square.  On its top side stand a right-angled triangle,
'   and on the two short sides of the triangle draw two new squares.
'   Because of Pythagoras (a^2 + b^2 = c^2) the two new squares
'   together have exactly the same AREA as the old one.  Repeat on
'   every new square and a tree grows - each "layer" of the tree has
'   the same total area as the trunk!
'
'   No angles are needed: everything is done with vectors.  If a
'   side goes from P to Q along vector (dx, dy), the side at right
'   angles to it is (dy, -dx).
'
' HOW TO USE
'   Left / Right arrows  change the triangle's angle (lopsided trees)
'   Up / Down arrows     more / fewer levels
'   F                    toggle filled / outlined squares
'   Esc                  quit
'
' CONCEPTS YOU WILL LEARN
'   * Vector rotation by 90 degrees without SIN or COS
'   * Drawing a rotated filled square with LINE and PAINT
'   * Recursion with depth-based coloring (brown trunk, green top)
'   * The Pythagorean theorem, shown geometrically
'
' THINGS TO TRY
'   * Make the angle change randomly at each level
'   * Draw only the triangles, not the squares
'   * Try 45 degrees with 14 levels: a symmetric "broccoli"
' ============================================================
DECLARE SUB Square (x1!, y1!, x2!, y2!, depth%)

DIM SHARED ca!, sa!, filled%, maxDepth%
CONST PI = 3.14159265#

SCREEN 12
' Colors 1..12 from brown (trunk) to bright green (leaves).
FOR i% = 1 TO 12
    t! = (i% - 1) / 11
    r% = 40 * (1 - t!) + 10 * t!
    g% = 20 * (1 - t!) + 60 * t!
    b% = 8 * (1 - t!) + 15 * t!
    PALETTE i%, r% + 256& * g% + 65536 * b%
NEXT

angle% = 40: maxDepth% = 10: filled% = -1
DO
    CLS
    ' The triangle splits the top side: with angle t, the left square
    ' has side cos(t) and the right one side sin(t) (times the parent).
    ca! = COS(angle% * PI / 180)
    sa! = SIN(angle% * PI / 180)
    ' Base square: bottom side from (280, 460) to (360, 460).
    Square 280, 460, 360, 460, 0
    COLOR 15: LOCATE 1, 1
    PRINT "angle:"; angle%; " levels:"; maxDepth%
    LOCATE 30, 1: PRINT "Arrows: angle/levels   F: fill   Esc: quit";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE CHR$(0) + "K": IF angle% > 15 THEN angle% = angle% - 5
        CASE CHR$(0) + "M": IF angle% < 75 THEN angle% = angle% + 5
        CASE CHR$(0) + "H": IF maxDepth% < 12 THEN maxDepth% = maxDepth% + 1
        CASE CHR$(0) + "P": IF maxDepth% > 1 THEN maxDepth% = maxDepth% - 1
        CASE "F": filled% = NOT filled%
        CASE CHR$(27): EXIT DO
    END SELECT
LOOP
SCREEN 0: WIDTH 80
END

' Draws a square standing on the side (x1,y1)-(x2,y2) - going from
' left to right as seen from inside the square - then recurses.
SUB Square (x1!, y1!, x2!, y2!, depth%)
    dx! = x2! - x1!: dy! = y2! - y1!
    ' (dy, -dx) is (dx, dy) turned 90 degrees "upward" on screen.
    x3! = x2! + dy!: y3! = y2! - dx!        ' top right corner
    x4! = x1! + dy!: y4! = y1! - dx!        ' top left corner
    c% = 1 + depth% * 11 \ maxDepth%
    LINE (x1!, y1!)-(x2!, y2!), c%
    LINE -(x3!, y3!), c%
    LINE -(x4!, y4!), c%
    LINE -(x1!, y1!), c%
    ' Fill the inside: PAINT from the centre up to the border color.
    ' (Only when the square is big enough to have an inside.)
    IF filled% AND dx! * dx! + dy! * dy! > 16 THEN
        PAINT ((x1! + x3!) / 2, (y1! + y3!) / 2), c%, c%
    END IF
    IF depth% >= maxDepth% THEN EXIT SUB
    ' Apex of the right triangle on the top side (x4,y4)-(x3,y3).
    ' Walk along the top side by cos^2(t) of its length, then go "up"
    ' by cos(t)*sin(t) of its length.  (Thales: the apex lies on the
    ' circle whose diameter is the top side.)
    k1! = ca! * ca!: k2! = ca! * sa!
    px! = x4! + dx! * k1! + dy! * k2!
    py! = y4! + dy! * k1! - dx! * k2!
    Square x4!, y4!, px!, py!, depth% + 1   ' left child
    Square px!, py!, x3!, y3!, depth% + 1   ' right child
END SUB
