' ============================================================
' TITLE:    Hilbert Space-Filling Curve
' CATEGORY: Fractals & Generative Art
' LEVEL:    Advanced
' TAGS:     fractals, recursion, space-filling curve, rainbow, SCREEN 12
' SUMMARY:  One unbroken line that visits every cell of a grid, drawn by mutually rotating recursive calls.
' ------------------------------------------------------------
' WHAT IT DOES
'   David Hilbert found (in 1891) a curve that wiggles through EVERY
'   cell of a square grid exactly once without ever crossing itself.
'   Order 1 is a simple "U" through 4 cells.  Each higher order
'   replaces the U by four smaller, rotated copies of the whole
'   curve joined end to end.  As the order grows, the line fills the
'   square completely - a 1-dimensional line covering a 2-D area!
'
'   The curve is drawn in rainbow colors along its length so you can
'   follow its path: nearby colors are nearby along the line.
'
' HOW TO USE
'   1..7   pick the order          Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Recursion with turning angles (+90 / -90) as parameters
'   * Turtle graphics: Forward and Turn using a direction number
'   * Why Hilbert curves are used for image dithering, databases and
'     memory layouts: points close on the line are close in space
'   * Custom palettes: making a 16-color rainbow with PALETTE
'
' THINGS TO TRY
'   * Draw it slowly (add a delay in Forward) to watch the path
'   * Compare with the Peano curve (3x3 instead of 2x2)
'   * Count the segments: 4^order - 1
' ============================================================
DECLARE SUB Hilbert (level%, angle%)
DECLARE SUB Forward ()
DECLARE SUB Turn (angle%)

DIM SHARED x%, y%, dir%, stp%, cnt&, total&

SCREEN 12
' ---- A 15-step rainbow in colors 1..15 ------------------------
' PALETTE attr, color uses the formula  color = R + 256*G + 65536*B
' with R, G, B each from 0 to 63.
FOR i% = 1 TO 15
    h! = (i% - 1) / 15 * 6.2832
    r% = 32 + 31 * COS(h!)
    g% = 32 + 31 * COS(h! - 2.094)          ' 120 degrees later
    b% = 32 + 31 * COS(h! - 4.189)          ' 240 degrees later
    PALETTE i%, r% + 256& * g% + 65536 * b%
NEXT

order% = 5
DO
    CLS
    ' The curve fills a 448-pixel square.  Order n has 2^n cells
    ' along each side, so each step is 448 / 2^n pixels.
    stp% = 448 \ 2 ^ order%
    total& = 4 ^ order% - 1: cnt& = 0
    ' Start in the bottom-left cell, facing right (dir 0).
    x% = 96 + stp% \ 2: y% = 16 + 448 - stp% \ 2: dir% = 0
    PSET (x%, y%), 1                         ' set the "last point" for LINE -
    Hilbert order%, 90
    COLOR 15: LOCATE 1, 1: PRINT "Hilbert curve of order"; order%
    PRINT total&; "segments,"; 4 ^ order%; "cells"
    LOCATE 30, 1: PRINT "1-7 = order   Esc = quit";
    DO
        k$ = INKEY$
    LOOP UNTIL k$ = CHR$(27) OR (k$ >= "1" AND k$ <= "7")
    IF k$ <> CHR$(27) THEN order% = VAL(k$)
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' Moves the turtle one step in its current direction, drawing a
' line whose color depends on how far along the curve we are.
SUB Forward
    SELECT CASE dir%
        CASE 0: x% = x% + stp%           ' right
        CASE 1: y% = y% - stp%           ' up
        CASE 2: x% = x% - stp%           ' left
        CASE 3: y% = y% + stp%           ' down
    END SELECT
    cnt& = cnt& + 1
    LINE -(x%, y%), 1 + cnt& * 15 \ (total& + 1)
END SUB

' The classic recursive Hilbert rule (as an L-system it is
'   A -> +BF-AFA-FB+   and   B -> -AF+BFB+FA-).
' Here one SUB does both A and B: B is just A with every turn
' reversed, so we pass the turn angle (+90 or -90) as a parameter.
SUB Hilbert (level%, angle%)
    IF level% = 0 THEN EXIT SUB
    Turn angle%
    Hilbert level% - 1, -angle%
    Forward
    Turn -angle%
    Hilbert level% - 1, angle%
    Forward
    Hilbert level% - 1, angle%
    Turn -angle%
    Forward
    Hilbert level% - 1, -angle%
    Turn angle%
END SUB

' Turns the turtle by +90 (left) or -90 (right) degrees.
SUB Turn (angle%)
    dir% = (dir% + angle% \ 90 + 4) MOD 4
END SUB
