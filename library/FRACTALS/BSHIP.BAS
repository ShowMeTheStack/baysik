' ============================================================
' TITLE:    Burning Ship Fractal
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     fractals, complex numbers, progressive rendering, palette
' SUMMARY:  A Mandelbrot cousin that looks like a ship on fire, drawn with coarse-to-fine progressive refinement.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Burning Ship fractal uses almost the same rule as the
'   Mandelbrot set, with one twist: before squaring z we take the
'   ABSOLUTE value of its real and imaginary parts.  That tiny change
'   breaks the symmetry and creates flames, masts and a ship's hull.
'
'   The picture is drawn "progressively": first with big 8x8 blocks
'   (very quick, gives a rough preview), then 4x4, 2x2 and finally
'   single pixels.  Each pass only computes the points that the
'   previous passes have not already computed.
'
' HOW TO USE
'   1  whole fractal          2  the famous little ship
'   3  the flames of the mast
'   Esc  quit.  Any key interrupts a drawing that is in progress.
'
' CONCEPTS YOU WILL LEARN
'   * ABS() and how a small change to a formula gives a new fractal
'   * Progressive (coarse-to-fine) rendering, like old web images
'   * Using MOD to test whether a pixel was done in an earlier pass
'   * A "fire" palette built from red -> orange -> yellow -> white
'
' THINGS TO TRY
'   * Remove the ABS calls: you get the Mandelbrot set back (upside down)
'   * Use ABS on only the real part, or only the imaginary part
'   * Add your own view to the SELECT CASE with new numbers
' ============================================================
DECLARE SUB Render (cx!, cy!, w!, maxit%)
DECLARE FUNCTION Ship% (cr!, ci!, maxit%)

DIM SHARED key$          ' a key pressed while drawing (it stops the drawing)
SCREEN 13

' ---- Fire palette for colors 1..127 ---------------------------
' Black -> dark red -> red -> orange -> yellow -> white.
OUT &H3C8, 1
FOR i% = 1 TO 127
    t! = i% / 127                        ' 0..1 along the gradient
    r% = t! * 3 * 63: IF r% > 63 THEN r% = 63
    g% = (t! * 3 - 1) * 63: IF g% < 0 THEN g% = 0
    IF g% > 63 THEN g% = 63
    b% = (t! * 3 - 2) * 63: IF b% < 0 THEN b% = 0
    OUT &H3C9, r%: OUT &H3C9, g%: OUT &H3C9, b%
NEXT

view% = 1
DO
    CLS
    SELECT CASE view%
        CASE 1: Render -.45, -.5, 3.6, 40        ' the whole fractal
        CASE 2: Render -1.772, -.022, .11, 100   ' the small ship
        CASE 3: Render -1.76, -.035, .06, 100    ' close-up of the mast
    END SELECT
    LOCATE 25, 1: COLOR 127: PRINT "1/2/3 = view    Esc = quit";
    ' Use the key that interrupted the drawing, or wait for one.
    k$ = key$: key$ = ""
    DO UNTIL k$ = CHR$(27) OR (k$ >= "1" AND k$ <= "3")
        k$ = INKEY$
    LOOP
    IF k$ = CHR$(27) THEN EXIT DO
    view% = VAL(k$)
LOOP
SCREEN 0: WIDTH 80
END

' Draws the region centred on (cx!, cy!) that is w! units wide.
SUB Render (cx!, cy!, w!, maxit%)
    sc! = w! / 320                       ' math units per pixel
    x0! = cx! - w! / 2
    y0! = cy! - 100 * sc!
    blk% = 8
    DO
        FOR py% = 0 TO 199 STEP blk%
            FOR px% = 0 TO 319 STEP blk%
                ' A point on the grid of size blk% was already computed
                ' in an earlier pass if it also lies on the grid of
                ' size 2*blk%.  Skip those (except in the first pass).
                IF blk% = 8 OR (px% MOD (blk% * 2)) <> 0 OR (py% MOD (blk% * 2)) <> 0 THEN
                    n% = Ship%(x0! + px% * sc!, y0! + py% * sc!, maxit%)
                    IF n% >= maxit% THEN c% = 0 ELSE c% = 1 + n% * 126 \ maxit%
                    LINE (px%, py%)-STEP(blk% - 1, blk% - 1), c%, BF
                END IF
            NEXT
            ' Any key stops drawing, so you never have to wait for a
            ' slow picture to finish before choosing another one.
            key$ = INKEY$
            IF key$ <> "" THEN EXIT SUB
        NEXT
        blk% = blk% \ 2                  ' 8 -> 4 -> 2 -> 1 -> 0 (stop)
    LOOP WHILE blk% >= 1
END SUB

' Escape-time count for the Burning Ship at point c = cr + ci*i.
FUNCTION Ship% (cr!, ci!, maxit%)
    zr! = 0: zi! = 0
    FOR n% = 0 TO maxit% - 1
        zr2! = zr! * zr!: zi2! = zi! * zi!
        IF zr2! + zi2! > 4 THEN EXIT FOR
        ' The only difference from Mandelbrot: ABS on both parts.
        zi! = 2 * ABS(zr! * zi!) + ci!
        zr! = zr2! - zi2! + cr!
    NEXT
    Ship% = n%
END FUNCTION
