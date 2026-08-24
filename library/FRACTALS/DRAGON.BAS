' ============================================================
' TITLE:    Paper-Folding Dragon Curve
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     fractals, bitwise, AND, turtle graphics, SCREEN 12
' SUMMARY:  Draws the Heighway dragon one step at a time using a bit trick that predicts every left and right turn.
' ------------------------------------------------------------
' WHAT IT DOES
'   Fold a strip of paper in half, again and again, always the same
'   way.  Unfold it so every crease is a 90 degree corner and look
'   from the side: you get the "dragon curve".
'
'   Amazingly, you don't need to simulate any folding.  For step
'   number n (1, 2, 3 ...) the turn direction is given by the bit
'   just above the lowest 1-bit of n:
'       n AND -n     isolates the lowest set bit of n
'       times 2      moves to the bit above it
'       AND n        is that bit set in n?   yes -> turn right
'                                            no  -> turn left
'   The program draws 4 dragons spinning out from the centre - they
'   fit together perfectly without overlapping!
'
' HOW TO USE
'   Watch the dragons grow.  Esc quits, any other key restarts.
'
' CONCEPTS YOU WILL LEARN
'   * Bitwise AND and two's-complement negative numbers
'   * Turtle graphics: a position plus a heading (0..3)
'   * Using small arrays as direction tables (dx, dy)
'   * Tiling: 4 rotated copies of a fractal can fill the plane
'
' THINGS TO TRY
'   * Draw only one dragon and make STEPS bigger with a smaller SEGLEN
'   * Make the turns 60 or 120 degrees instead of 90 (what happens?)
'   * Print the turn sequence as letters L and R for n = 1 to 32
' ============================================================
DEFINT A-Z
CONST STEPS = 4096       ' segments per dragon (2^12 = 12 folds)
CONST SEGLEN = 3         ' pixels per segment

' Direction table: heading 0 = right, 1 = down, 2 = left, 3 = up.
DIM dx(3), dy(3)
dx(0) = 1: dy(0) = 0
dx(1) = 0: dy(1) = 1
dx(2) = -1: dy(2) = 0
dx(3) = 0: dy(3) = -1

' Each of the 4 dragons has its own turtle: position and heading.
DIM x(3), y(3), h(3)

SCREEN 12
DO
    CLS
    COLOR 15: PRINT "Dragon curve - 4 dragons of"; STEPS; "segments"
    FOR d = 0 TO 3
        x(d) = 320: y(d) = 250: h(d) = d     ' all start in the centre,
    NEXT                                     ' facing 4 different ways
    ' Draw step n of ALL 4 dragons, then step n+1, ... so they grow
    ' together.
    FOR n = 1 TO STEPS
        FOR d = 0 TO 3
            nx = x(d) + dx(h(d)) * SEGLEN
            ny = y(d) + dy(h(d)) * SEGLEN
            LINE (x(d), y(d))-(nx, ny), 10 + d     ' one color per dragon
            x(d) = nx: y(d) = ny
            ' ---- the turn after segment n ----
            IF ((n AND -n) * 2) AND n THEN
                h(d) = (h(d) + 1) MOD 4          ' turn right
            ELSE
                h(d) = (h(d) + 3) MOD 4          ' turn left (= 3 rights)
            END IF
        NEXT
        IF n MOD 64 = 0 THEN
            k$ = INKEY$
            IF k$ <> "" THEN EXIT FOR
        END IF
    NEXT
    IF k$ = "" THEN
        LOCATE 30, 1: PRINT "Any key = again   Esc = quit";
        DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    END IF
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END
