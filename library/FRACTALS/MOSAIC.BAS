' ============================================================
' TITLE:    Mosaic Generator
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     generative art, color, averaging, POINT, palette, SCREEN 13
' SUMMARY:  Paints a sunset scene, then rebuilds it as a tiled mosaic by averaging the colors under every tile.
' ------------------------------------------------------------
' WHAT IT DOES
'   First the program paints a picture: a sunset sky, a sun, layered
'   mountains and the sea.  It uses a palette of 216 colors arranged
'   as a 6 x 6 x 6 "color cube": color number = 16 + 36*R + 6*G + B
'   where R, G and B each go from 0 to 5.  Because of that rule we
'   can turn any color number back into its R, G, B parts.
'
'   Then it turns the picture into a mosaic.  For each tile it reads
'   every pixel under the tile with POINT, adds up the red, green and
'   blue parts, divides to get the AVERAGE color, and draws a tile in
'   that color with a dark line of "grout" around it.  A small random
'   change to each tile makes it look hand-made.
'
' HOW TO USE
'   1-4  tile size (4, 8, 12, 16 pixels)    O  show the original
'   R    round tiles instead of square      Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * A color cube palette and encoding 3 numbers in 1
'   * Reading pixels back with POINT
'   * Averaging: sum / count
'   * GET and PUT: saving the original picture so it can be restored
'
' THINGS TO TRY
'   * Use the brightest pixel in each tile instead of the average
'   * Make the tiles diamonds, or offset every other row like bricks
'   * Paint your own scene in SUB Scene
' ============================================================
DECLARE SUB Scene ()
DECLARE SUB Mosaic (t%, round%)
DECLARE FUNCTION Cube% (r%, g%, b%)

' A buffer big enough to GET a 320 x 192 picture (in SCREEN 13 a
' GET needs 4 bytes + 1 byte per pixel; one INTEGER holds 2 bytes).
DIM SHARED pic%(30725)

SCREEN 13
RANDOMIZE TIMER
' ---- Build the 6x6x6 color cube in colors 16..231 ------------------
OUT &H3C8, 16
FOR r% = 0 TO 5
    FOR g% = 0 TO 5
        FOR b% = 0 TO 5
            ' 0..5 -> 0..63 (the VGA DAC range)
            OUT &H3C9, r% * 63 \ 5: OUT &H3C9, g% * 63 \ 5: OUT &H3C9, b% * 63 \ 5
        NEXT
    NEXT
NEXT

Scene
GET (0, 0)-(319, 191), pic%           ' remember the original
tile% = 8: round% = 0
Mosaic tile%, round%
DO
    LOCATE 25, 1: COLOR 15: PRINT "1-4 size  O original  R round  Esc";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "1" TO "4"
            tile% = VAL(k$) * 4
            PUT (0, 0), pic%, PSET: Mosaic tile%, round%
        CASE "R"
            round% = NOT round%
            PUT (0, 0), pic%, PSET: Mosaic tile%, round%
        CASE "O": PUT (0, 0), pic%, PSET
    END SELECT
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' Color number for cube coordinates r, g, b (each 0..5).
FUNCTION Cube% (r%, g%, b%)
    Cube% = 16 + 36 * r% + 6 * g% + b%
END FUNCTION

SUB Mosaic (t%, round%)
    FOR ty% = 0 TO 191 - t% + 1 STEP t%
        FOR tx% = 0 TO 319 - t% + 1 STEP t%
            ' ---- 1. average the colors under this tile ----
            sr% = 0: sg% = 0: sb% = 0: cnt% = 0
            FOR y% = ty% TO ty% + t% - 1
                FOR x% = tx% TO tx% + t% - 1
                    c% = POINT(x%, y%) - 16      ' 0..215
                    IF c% >= 0 AND c% < 216 THEN
                        ' Decode: c = 36*R + 6*G + B
                        sr% = sr% + c% \ 36
                        sg% = sg% + (c% \ 6) MOD 6
                        sb% = sb% + c% MOD 6
                        cnt% = cnt% + 1
                    END IF
                NEXT
            NEXT
            IF cnt% = 0 THEN cnt% = 1
            ' Round to the nearest whole cube step.  Adding a random
            ' -0.4..+0.4 makes neighbouring tiles vary like real glass.
            r% = INT(sr% / cnt% + .5 + (RND - .5) * .8)
            g% = INT(sg% / cnt% + .5 + (RND - .5) * .8)
            b% = INT(sb% / cnt% + .5 + (RND - .5) * .8)
            IF r% < 0 THEN r% = 0 ELSE IF r% > 5 THEN r% = 5
            IF g% < 0 THEN g% = 0 ELSE IF g% > 5 THEN g% = 5
            IF b% < 0 THEN b% = 0 ELSE IF b% > 5 THEN b% = 5
            ' ---- 2. draw the tile with dark grout around it ----
            LINE (tx%, ty%)-(tx% + t% - 1, ty% + t% - 1), Cube%(0, 0, 1), BF
            IF round% THEN
                rad% = t% \ 2 - 1
                CIRCLE (tx% + t% \ 2, ty% + t% \ 2), rad%, Cube%(r%, g%, b%)
                PAINT (tx% + t% \ 2, ty% + t% \ 2), Cube%(r%, g%, b%)
            ELSE
                LINE (tx% + 1, ty% + 1)-(tx% + t% - 2, ty% + t% - 2), Cube%(r%, g%, b%), BF
            END IF
        NEXT
    NEXT
END SUB

' Paints the original picture using only cube colors.
SUB Scene
    ' Sky: a gradient from deep purple at the top to orange.
    FOR y% = 0 TO 110
        t! = y% / 110
        ' A little random "dither" smooths the steps between colors.
        FOR x% = 0 TO 319 STEP 4
            d! = RND * .9
            r% = INT(1 + t! * 4 + d!): g% = INT(t! * 3 + d!): b% = INT(3 - t! * 2 + d!)
            IF r% > 5 THEN r% = 5
            LINE (x%, y%)-(x% + 3, y%), Cube%(r%, g%, b%)
        NEXT
    NEXT
    ' The sun
    CIRCLE (220, 58), 26, Cube%(5, 5, 2)
    PAINT (220, 58), Cube%(5, 5, 2)
    CIRCLE (220, 58), 18, Cube%(5, 5, 4)
    PAINT (220, 58), Cube%(5, 5, 4)
    ' Two mountain ranges: random walks for the ridge line.
    FOR layer% = 0 TO 1
        h! = 85 + layer% * 15
        FOR x% = 0 TO 319
            h! = h! + (RND - .5) * 4
            IF h! < 50 THEN h! = 50
            IF h! > 105 THEN h! = 105
            IF layer% = 0 THEN c% = Cube%(2, 1, 3) ELSE c% = Cube%(1, 0, 2)
            LINE (x%, h!)-(x%, 115), c%
        NEXT
    NEXT
    ' The sea, with sparkling reflections of the sun.
    FOR y% = 115 TO 191
        FOR x% = 0 TO 319 STEP 8
            c% = Cube%(0, 1 + (y% > 150), 3)
            IF ABS(x% - 220) < 40 - (y% - 115) \ 3 AND RND < .5 THEN c% = Cube%(5, 4, 1)
            LINE (x%, y%)-(x% + 7, y%), c%
        NEXT
    NEXT
END SUB
