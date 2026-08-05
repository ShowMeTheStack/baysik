' ============================================================
' TITLE:    Moire Pattern Machine
' CATEGORY: Graphics
' LEVEL:    Beginner
' TAGS:     moire, lines, circles, patterns, screen 2, cga
' SUMMARY:  Creates shimmering moire interference patterns from nothing but evenly spaced lines and circles in 2-colour CGA.
' ------------------------------------------------------------
' WHAT IT DOES
'   When two sets of fine, regular lines overlap, your eyes see
'   big ghostly curves that nobody drew. These are "moire"
'   patterns (say "mwah-ray"). This program draws four of them
'   in SCREEN 2 (640x200, black and white), which is perfect
'   because its pixels are so small and sharp.
'
' HOW TO USE
'   Press any key for the next pattern. Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Fans of lines from a single point to every edge pixel
'   * Concentric circles with CIRCLE in a FOR loop
'   * How sampling on a pixel grid creates "beats" (aliasing)
'   * Using SELECT CASE to pick which picture to draw
'
' THINGS TO TRY
'   * Change STEP 6 to STEP 4 or STEP 8 in the fan loops
'   * Move the second circle centre a little at a time and animate
'   * Draw the fan from a corner instead of the middle
' ============================================================

SCREEN 2             ' 640 x 200, 2 colours
pattern = 1

DO
    CLS
    SELECT CASE pattern
        CASE 1
            ' ---- A fan of lines from the centre --------------------
            ' Lines go to every 6th pixel across the top and bottom
            ' and every 3rd down the sides (SCREEN 2 pixels are
            ' twice as tall as wide). The pixel grid makes the lines
            ' "beat" into curved bands.
            FOR x = 0 TO 639 STEP 6
                LINE (320, 100)-(x, 0)
                LINE (320, 100)-(x, 199)
            NEXT x
            FOR y = 0 TO 199 STEP 3
                LINE (320, 100)-(0, y)
                LINE (320, 100)-(639, y)
            NEXT y
            t$ = "Fan of lines"
        CASE 2
            ' ---- Two overlapping sets of rings -------------------
            ' Each set alone is boring; together they make
            ' hyperbola-shaped bands - the same shapes you see when
            ' two pebbles drop into a pond.
            FOR r = 4 TO 400 STEP 9
                CIRCLE (250, 100), r
                CIRCLE (390, 100), r
            NEXT r
            t$ = "Two ring sets"
        CASE 3
            ' ---- Two fans from the bottom corners ------------------
            ' Each corner sprays lines to the top edge; where the two
            ' fans cross, diamond-shaped bands appear.
            FOR x = 0 TO 639 STEP 4
                LINE (0, 199)-(x, 0)
                LINE (639, 199)-(x, 0)
            NEXT x
            t$ = "Crossed fans"
        CASE 4
            ' ---- Rings over straight lines ---------------------------
            FOR y = 0 TO 199 STEP 3
                LINE (0, y)-(639, y)
            NEXT y
            FOR r = 3 TO 400 STEP 5
                CIRCLE (320, 100), r
            NEXT r
            t$ = "Rings over stripes"
    END SELECT

    ' A small black label box in the top-left corner.
    LINE (0, 0)-(8 * (LEN(t$) + 2), 9), 0, BF
    LOCATE 1, 2: PRINT t$;

    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN EXIT DO
    pattern = pattern MOD 4 + 1
LOOP

SCREEN 0: WIDTH 80
END
