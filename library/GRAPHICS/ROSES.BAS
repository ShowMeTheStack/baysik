' ============================================================
' TITLE:    Polar Rose Garden
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     polar, window, trigonometry, curves, screen 11
' SUMMARY:  Draws mathematical "rose" curves r = cos(k*theta) in a 3 x 3 garden, one rose per value of k = n/d.
' ------------------------------------------------------------
' WHAT IT DOES
'   A polar rose is the curve you get when the distance from the
'   centre, r, is cos(k * angle). Whole-number k gives petals;
'   fractions n/d give lacy, overlapping flowers. This program
'   uses SCREEN 11 (640x480, two colours) and a WINDOW for each
'   little garden plot to draw nine roses at a time.
'
' HOW TO USE
'   Space / Enter  next page of roses (27 roses on 3 pages)
'   Q or Esc       quit
'
' CONCEPTS YOU WILL LEARN
'   * Polar coordinates: (r, theta) -> x = r*cos(theta), y = r*sin(theta)
'   * VIEW to choose a part of the screen + WINDOW to put maths
'     coordinates inside it
'   * Why the curve closes after d*PI or 2*d*PI radians
'   * READ / DATA / RESTORE to step through a list of values
'
' THINGS TO TRY
'   * Use SIN instead of COS - the roses rotate!
'   * Try r = cos(k*t) + 0.5 for "limacon" style flowers
'   * Increase the step size to see the curve turn into polygons
' ============================================================

CONST PI = 3.14159265#

SCREEN 11                         ' 640 x 480, 2 colours (black/white)

DO
    CLS
    VIEW                          ' full screen for the title text
    LOCATE 1, 25: PRINT "Polar roses  r = cos( n/d * t )"
    LOCATE 30, 20: PRINT "Space = more roses     Q = quit";

    ' Nine cells in a 3 x 3 grid. Each cell is 200 x 145 pixels.
    FOR cell% = 0 TO 8
        cx% = cell% MOD 3: cy% = cell% \ 3
        ' Read the next fraction n/d. When the list runs out, go
        ' back to the start of it.
        READ n%, d%
        IF n% = 0 THEN RESTORE: READ n%, d%

        x1% = 15 + cx% * 205: y1% = 22 + cy% * 148
        ' VIEW (...)-(...), fill, border: a little framed window.
        VIEW (x1%, y1%)-(x1% + 195, y1% + 138), 0, 1
        ' A WINDOW 1.4 units each side of the centre. The ratio
        ' 139/196 keeps circles round inside a non-square cell.
        WINDOW (-1.4, -1.4 * 139 / 196)-(1.4, 1.4 * 139 / 196)

        ' How far round must we go before the curve repeats?
        '   if n*d is odd the rose closes after d*PI
        '   otherwise it needs 2*d*PI
        IF (n% * d%) MOD 2 = 1 THEN tmax = d% * PI ELSE tmax = 2 * d% * PI
        k = n% / d%

        PSET (1, 0)               ' r = cos(0) = 1 at angle 0
        FOR t = 0 TO tmax + .001 STEP .02
            r = COS(k * t)
            LINE -(r * COS(t), r * SIN(t))
        NEXT t

        ' Label the cell. PRINT ignores VIEW and WINDOW: text
        ' always uses whole-screen rows and columns.
        VIEW
        LOCATE (y1% \ 16) + 2, (x1% \ 8) + 2
        PRINT LTRIM$(STR$(n%)); "/"; LTRIM$(STR$(d%))
    NEXT cell%

    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
LOOP

VIEW: WINDOW
SCREEN 0: WIDTH 80
END

' ---- The fractions n/d, nine per page ----------------------------
' Fractions are in lowest terms: 2/4 would just repeat 1/2.
DATA 2,1, 3,1, 4,1, 1,2, 3,2, 5,2, 1,3, 2,3, 4,3
DATA 5,1, 7,2, 5,3, 1,4, 3,4, 5,4, 7,4, 2,5, 3,5
DATA 6,1, 9,2, 7,3, 4,5, 6,5, 1,5, 5,6, 7,6, 8,7
DATA 0,0
