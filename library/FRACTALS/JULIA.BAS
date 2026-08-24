' ============================================================
' TITLE:    Julia Set Gallery
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     fractals, complex numbers, palette, julia, SCREEN 13
' SUMMARY:  Browse famous Julia sets and nudge the magic constant c to morph one shape into another.
' ------------------------------------------------------------
' WHAT IT DOES
'   A Julia set uses the same formula as the Mandelbrot set,
'   z = z*z + c, but the roles are swapped: c is ONE fixed number
'   for the whole picture, and each pixel supplies the starting z.
'   Every different c gives a different Julia set - dragons, rabbits,
'   lightning, dust...  This program shows a gallery of good ones
'   and lets you steer c yourself.
'
' HOW TO USE
'   N / P        next / previous preset from the gallery
'   Arrow keys   nudge c (real part left/right, imaginary up/down)
'   C            cycle the color palette (instant, no redraw!)
'   Esc          quit
'
' CONCEPTS YOU WILL LEARN
'   * How Julia sets relate to the Mandelbrot set
'   * DATA / READ / RESTORE to store a table of presets
'   * Palette rotation: changing colors without redrawing pixels
'   * Symmetry: a Julia set looks the same rotated by 180 degrees,
'     so we only compute the top half and mirror it!
'
' THINGS TO TRY
'   * Pick a c inside the Mandelbrot set: the Julia set is one piece.
'     Pick c outside it: the Julia set shatters into "dust".
'   * Add your own favourite c values to the DATA lines
' ============================================================
DECLARE SUB Render ()
DECLARE SUB SetPal (shift%)

DIM SHARED cr!, ci!             ' the constant c = cr + ci*i
DIM SHARED quit%
CONST MAXIT = 40
CONST NPRESETS = 8

' ---- Gallery of nice c values (real, imaginary, name) ---------
DATA -0.8, 0.156, "Lightning"
DATA -0.123, 0.745, "Douady's Rabbit"
DATA 0.285, 0.01, "Seahorse Spiral"
DATA -0.4, 0.6, "Twisted Coral"
DATA -0.70176, -0.3842, "Fireworks"
DATA 0.355, 0.355, "Snowflake Swirl"
DATA -1.476, 0, "Needle"
DATA -0.835, -0.2321, "Dragon"

SCREEN 13
preset% = 1: shift% = 0
SetPal shift%
GOSUB LoadPreset

DO
    LINE (0, 0)-(319, 199), 0, BF
    LOCATE 1, 1: COLOR 15
    PRINT name$
    PRINT USING "c = ##.### + ##.###i"; cr!; ci!
    Render
    IF quit% THEN EXIT DO
    LOCATE 25, 1: PRINT "N/P preset  Arrows nudge  C color Esc";
    DO
        k$ = INKEY$
        SELECT CASE UCASE$(k$)
            CASE "N": preset% = preset% MOD NPRESETS + 1: GOSUB LoadPreset: EXIT DO
            CASE "P": preset% = (preset% + NPRESETS - 2) MOD NPRESETS + 1: GOSUB LoadPreset: EXIT DO
            CASE CHR$(0) + "K": cr! = cr! - .02: name$ = "Custom": EXIT DO
            CASE CHR$(0) + "M": cr! = cr! + .02: name$ = "Custom": EXIT DO
            CASE CHR$(0) + "H": ci! = ci! + .02: name$ = "Custom": EXIT DO
            CASE CHR$(0) + "P": ci! = ci! - .02: name$ = "Custom": EXIT DO
            CASE "C"
                ' Only the palette changes - the pixels keep their
                ' numbers, but each number now means a new color.
                shift% = (shift% + 20) MOD 240: SetPal shift%
            CASE CHR$(27): quit% = -1
        END SELECT
    LOOP UNTIL quit%
LOOP UNTIL quit%
SCREEN 0: WIDTH 80
END

' Reads preset number preset% from the DATA table.
LoadPreset:
    RESTORE                          ' go back to the first DATA item
    FOR i% = 1 TO preset%
        READ cr!, ci!, name$         ' skip forward to the wanted row
    NEXT
    RETURN

SUB Render
    ' The picture shows z from -1.6..1.6 (real) and -1..1 (imaginary).
    ' Each "pixel" is a 2x2 block so the drawing stays quick.
    ' Thanks to symmetry, pixel (x, y) and pixel (318-x, 198-y) always
    ' have the same color: if z escapes, so does -z.  So we only
    ' compute rows 16..106 and draw each result twice.
    FOR py% = 16 TO 106 STEP 2
        zi0! = (py% - 107) / 90                 ' imaginary part (top half)
        FOR px% = 0 TO 318 STEP 2
            zr! = (px% - 159) / 99              ' real part
            zi! = zi0!
            n% = 0
            DO
                zr2! = zr! * zr!: zi2! = zi! * zi!
                IF zr2! + zi2! > 4 THEN EXIT DO
                zi! = 2 * zr! * zi! + ci!
                zr! = zr2! - zi2! + cr!
                n% = n% + 1
            LOOP UNTIL n% = MAXIT
            IF n% = MAXIT THEN col% = 0 ELSE col% = 16 + n% * 6
            LINE (px%, py%)-STEP(1, 1), col%, BF
            ' mirror image through the centre point (159, 107)
            LINE (318 - px%, 214 - py%)-STEP(1, 1), col%, BF
        NEXT
        IF INKEY$ = CHR$(27) THEN quit% = -1: EXIT SUB
    NEXT
END SUB

' Colors 16..255 get a smooth fire-and-ice gradient.  shift% rotates
' the gradient so the same picture can be recolored instantly.
SUB SetPal (shift%)
    OUT &H3C8, 16                    ' start writing at color 16
    FOR i% = 0 TO 239
        t! = ((i% + shift%) MOD 240) / 240 * 6.2832
        OUT &H3C9, 31 + 31 * SIN(t!)              ' red
        OUT &H3C9, 31 + 31 * SIN(t! * 2 + 1)      ' green
        OUT &H3C9, 31 + 31 * COS(t!)              ' blue
    NEXT
END SUB
