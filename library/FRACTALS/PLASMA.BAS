' ============================================================
' TITLE:    Plasma Terrain (Diamond-Square)
' CATEGORY: Fractals & Generative Art
' LEVEL:    Advanced
' TAGS:     fractals, diamond-square, terrain, heightmap, palette cycling
' SUMMARY:  Generates random island maps with the diamond-square algorithm, then melts them into a cycling plasma.
' ------------------------------------------------------------
' WHAT IT DOES
'   Creates a "height map" - a grid of numbers where each number is
'   the height of the land at that spot - using the diamond-square
'   algorithm, a classic of computer graphics:
'     1. Give the 4 corners random heights.
'     2. DIAMOND step: the centre of each square = average of its 4
'        corners + a random nudge.
'     3. SQUARE step: the middle of each edge = average of its 4
'        neighbours (in a diamond shape) + a random nudge.
'     4. Halve the step size AND the size of the random nudges,
'        and repeat until every grid point has a height.
'   Big nudges early make continents; small nudges late make rocky
'   coastlines.  The result is a fractal: zoom in and it still looks
'   like landscape.
'
'   The heights are shown with a map palette: deep sea, shallow sea,
'   sand, grass, forest, rock and snow.  Press P to switch to a
'   psychedelic palette and watch it flow by palette cycling.
'
' HOW TO USE
'   N  new map      + / -  rougher / smoother land
'   P  toggle map / plasma colors      Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * 2-D arrays and a grid of size 2^n + 1
'   * Recursive subdivision done with loops instead of recursion
'   * Fractional "roughness": noise shrinks by a factor every level
'   * Palette cycling: animating 64 colors without touching pixels
'
' THINGS TO TRY
'   * Make the corners very low so you always get one island
'   * Set roughness to 0.8 for jagged mountains everywhere
'   * Draw the map in 3-D: shift each row up by its height
' ============================================================
DECLARE SUB Generate ()
DECLARE SUB Show ()
DECLARE SUB MapPalette ()
DECLARE SUB PlasmaPalette (phase%)

CONST N = 128                       ' grid is (N+1) x (N+1), N = 2^7
DIM SHARED h(N, N) AS INTEGER       ' heights 0..255
DIM SHARED rough!

SCREEN 13
RANDOMIZE TIMER
rough! = .55
plasma% = 0

DO
    MapPalette
    Generate
    Show
    plasma% = 0: phase% = 0
    DO
        k$ = UCASE$(INKEY$)
        IF plasma% THEN
            ' Rotate the palette one step per frame: each color number
            ' slides to the next color, so the bands seem to flow.
            phase% = (phase% + 1) MOD 64
            PlasmaPalette phase%
            ' Wait for the start of the next screen refresh (bit 3 of
            ' port &H3DA is 1 during the "vertical retrace").  This
            ' paces the animation at the monitor's speed: ~70 per second.
            DO WHILE INP(&H3DA) AND 8: LOOP       ' wait until retrace ends
            DO UNTIL INP(&H3DA) AND 8: LOOP       ' wait until it starts
        END IF
        SELECT CASE k$
            CASE "P"
                plasma% = NOT plasma%
                IF NOT plasma% THEN MapPalette
            CASE "+", "=": IF rough! < .9 THEN rough! = rough! + .05
                EXIT DO
            CASE "-", "_": IF rough! > .3 THEN rough! = rough! - .05
                EXIT DO
            CASE "N": EXIT DO
            CASE CHR$(27): EXIT DO
        END SELECT
    LOOP
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

SUB Generate
    ' 1. Random corners.
    h(0, 0) = RND * 256: h(N, 0) = RND * 256
    h(0, N) = RND * 256: h(N, N) = RND * 256
    stp% = N                        ' distance between known points
    amp! = 128                      ' size of the random nudge
    DO WHILE stp% > 1
        half% = stp% \ 2
        ' 2. DIAMOND step: centres of all squares of size stp%.
        FOR y% = half% TO N STEP stp%
            FOR x% = half% TO N STEP stp%
                avg! = (h(x% - half%, y% - half%) + h(x% + half%, y% - half%) + h(x% - half%, y% + half%) + h(x% + half%, y% + half%)) / 4
                v% = avg! + (RND * 2 - 1) * amp!
                IF v% < 0 THEN v% = 0 ELSE IF v% > 255 THEN v% = 255
                h(x%, y%) = v%
            NEXT
        NEXT
        ' 3. SQUARE step: edge midpoints.  These are the grid points
        ' where (x + y) / half is odd.  Points on the border only have
        ' 3 neighbours, so we count how many we added.
        FOR y% = 0 TO N STEP half%
            ' start at half% on even rows, 0 on odd rows
            IF (y% \ half%) MOD 2 = 0 THEN x0% = half% ELSE x0% = 0
            FOR x% = x0% TO N STEP stp%
                sum! = 0: cnt% = 0
                IF x% >= half% THEN sum! = sum! + h(x% - half%, y%): cnt% = cnt% + 1
                IF x% + half% <= N THEN sum! = sum! + h(x% + half%, y%): cnt% = cnt% + 1
                IF y% >= half% THEN sum! = sum! + h(x%, y% - half%): cnt% = cnt% + 1
                IF y% + half% <= N THEN sum! = sum! + h(x%, y% + half%): cnt% = cnt% + 1
                v% = sum! / cnt% + (RND * 2 - 1) * amp!
                IF v% < 0 THEN v% = 0 ELSE IF v% > 255 THEN v% = 255
                h(x%, y%) = v%
            NEXT
        NEXT
        ' 4. Smaller squares, smaller nudges.
        stp% = half%
        amp! = amp! * rough!
    LOOP
END SUB

' Map palette: 64 colors (1..64) from deep sea to snowy peaks.
SUB MapPalette
    OUT &H3C8, 1
    FOR i% = 0 TO 63
        SELECT CASE i%
            CASE IS < 28: r% = 0: g% = i%: b% = 20 + i% * 1.5      ' sea
            CASE IS < 31: r% = 55: g% = 50: b% = 30                ' sand
            CASE IS < 43: r% = 8: g% = 60 - (i% - 31) * 3: b% = 10 ' grass
            CASE IS < 52: r% = 24 + (i% - 43): g% = 22: b% = 14    ' rock
            CASE ELSE: r% = 50 + (i% - 52): g% = r%: b% = r%       ' snow
        END SELECT
        OUT &H3C9, r%: OUT &H3C9, g%: OUT &H3C9, b%
    NEXT
END SUB

' Plasma palette: smooth rainbow, rotated by "phase".
SUB PlasmaPalette (phase%)
    OUT &H3C8, 1
    FOR i% = 0 TO 63
        t! = ((i% + phase%) MOD 64) / 64 * 6.2832
        OUT &H3C9, 31 + 31 * SIN(t!)
        OUT &H3C9, 31 + 31 * SIN(t! + 2.09)
        OUT &H3C9, 31 + 31 * SIN(t! + 4.19)
    NEXT
END SUB

' Draws the height map stretched to fill 320 x 192 pixels.
SUB Show
    CLS
    FOR y% = 0 TO N
        y1% = y% * 192 \ (N + 1): y2% = (y% + 1) * 192 \ (N + 1) - 1
        FOR x% = 0 TO N
            x1% = x% * 320& \ (N + 1): x2% = (x% + 1) * 320& \ (N + 1) - 1   ' 320& = LONG: 128*320 is too big for an INTEGER
            ' height 0..255  ->  color 1..64
            LINE (x1%, y1%)-(x2%, y2%), 1 + h(x%, y%) \ 4, BF
        NEXT
    NEXT
    LOCATE 25, 1: COLOR 63
    PRINT USING "N:new +/-:rough #.## P:plasma Esc"; rough!;
END SUB
