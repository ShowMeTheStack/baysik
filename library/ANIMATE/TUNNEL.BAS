' ============================================================
' TITLE:    Palette Tunnel
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     palette cycling, tunnel, ATN, SCREEN 13, demoscene
' SUMMARY:  Fly down an endless two-tone tunnel - the picture is drawn only once and all motion comes from rotating the palette.
' ------------------------------------------------------------
' WHAT IT DOES
'   For every pixel we work out two "tunnel coordinates":
'     depth  u = K / distance-from-centre   (near the middle =
'              deep in the tunnel)
'     around v = the angle around the centre (from ATN)
'   The pixel's color number comes from u and v, which paints a two-tone
'   striped tube.  That slow drawing happens ONCE.  After that
'   the program only changes the palette: color n takes the
'   look of color n+1, n+1 of n+2, and so on.  Because colors
'   are arranged by depth, shifting them makes the stripes slide
'   inwards and you seem to fly forward - with almost no work!
'
' HOW TO USE
'   Wait a moment while the tunnel is drawn.  Then:
'     Up / Down arrows   faster / slower (or reverse!)
'     Esc                quit
'
' CONCEPTS YOU WILL LEARN
'   * Palette cycling - the classic 8-bit animation trick
'   * Polar coordinates: distance with SQR, angle with ATN
'   * Using symmetry to compute only a quarter of the pixels
'   * Writing many palette entries quickly through &H3C8/&H3C9
'
' THINGS TO TRY
'   * Change K to make the stripes longer or shorter
'   * Use 4 groups of colors instead of 2 (SEGS MOD 4)
' ============================================================
DEFINT A-Z

CONST PI = 3.14159265#
CONST K = 1400!                 ' depth scale: bigger = longer stripes
CONST SEGS = 16                 ' color stripes around the tunnel

SCREEN 13

' ---- 1. Two color ramps --------------------------------------
' ramp(i) is a brightness 0-63 that rises and falls smoothly
' over the 32 depth bands, so each band fades into the next.
DIM ramp(31)
FOR i = 0 TO 31
    ramp(i) = 20 + 43 * (.5 + .5 * COS(i * 2 * PI / 32))
NEXT

shift = 0: speed = 1
GOSUB SetPalette                ' set the colors BEFORE drawing
COLOR 15: LOCATE 12, 10: PRINT "Building the tunnel..."

' ---- 2. Draw the tunnel once ---------------------------------
' (x, y) are measured from the screen centre (160, 100).  We do
' one quarter (x >= 0, y >= 0) and mirror the angle for the
' other three quarters.
FOR y = 0 TO 100
    FOR x = 0 TO 160
        d! = SQR(x * x + y * y * 1.44)     ' 1.44 corrects for tall pixels
        IF d! < 6 THEN
            ' the far end of the tunnel: black
            PSET (160 + x, 100 + y), 0: PSET (160 - x, 100 + y), 0
            PSET (160 + x, 100 - y), 0: PSET (160 - x, 100 - y), 0
        ELSE
            u = INT(K / d!) MOD 32                   ' depth band 0..31
            IF x = 0 THEN a! = PI / 2 ELSE a! = ATN(y * 1.2 / x)  ' 0..pi/2
            ' The four mirrored angles, each turned into a segment
            ' number; even/odd segment chooses the color group.
            c1 = 1 + u + 32 * (INT(a! * SEGS / (2 * PI)) MOD 2)
            c2 = 1 + u + 32 * (INT((PI - a!) * SEGS / (2 * PI)) MOD 2)
            c3 = 1 + u + 32 * (INT((PI + a!) * SEGS / (2 * PI)) MOD 2)
            c4 = 1 + u + 32 * (INT((2 * PI - a!) * SEGS / (2 * PI)) MOD 2)
            PSET (160 + x, 100 + y), c1
            PSET (160 - x, 100 + y), c2
            PSET (160 - x, 100 - y), c3
            PSET (160 + x, 100 - y), c4
        END IF
    NEXT
NEXT

' ---- 3. Cycle! -----------------------------------------------
DO
    GOSUB SetPalette
    ' "AND 31" keeps shift in 0..31, even when it goes negative
    ' (two's complement magic) - like MOD but never below zero.
    shift = (shift + speed) AND 31

    WAIT &H3DA, 8, 8: WAIT &H3DA, 8
    k$ = INKEY$
    IF k$ = CHR$(0) + "H" AND speed < 4 THEN speed = speed + 1
    IF k$ = CHR$(0) + "P" AND speed > -4 THEN speed = speed - 1
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

SetPalette:
    ' Color 1+i shows ramp brightness number (i + shift).  As
    ' shift grows, each color takes the look of its neighbour,
    ' so the bands appear to move.
    OUT &H3C8, 1                    ' start at color 1; it auto-advances
    FOR i = 0 TO 31                 ' group 1 (colors 1-32): blue
        b = ramp((i + shift) AND 31)
        OUT &H3C9, b \ 4: OUT &H3C9, b \ 2: OUT &H3C9, b
    NEXT
    FOR i = 0 TO 31                 ' group 2 (colors 33-64): orange
        b = ramp((i + shift) AND 31)
        OUT &H3C9, b: OUT &H3C9, b \ 2: OUT &H3C9, b \ 6
    NEXT
    RETURN
