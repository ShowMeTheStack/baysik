' ============================================================
' TITLE:    Copper Bars
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     copper bars, palette, demoscene, SIN, raster effects
' SUMMARY:  Shiny rainbow bars swing up and down through each other - an Amiga demo classic made purely with palette tricks.
' ------------------------------------------------------------
' WHAT IT DOES
'   On the Amiga, a chip nicknamed the "copper" could change the
'   background color on every scan line, which demo coders used
'   to draw glowing horizontal "copper bars".  We fake it in
'   SCREEN 13: each screen row y is filled ONCE with its own
'   color number (1 + y).  After that we never draw again - each
'   frame we just compute a new red/green/blue value for all 200
'   colors and send them to the VGA palette.  Change the palette
'   and every row changes color instantly.
'
' HOW TO USE
'   + / -   more / fewer bars       S  faster / slower toggle
'   Esc     quit
'
' CONCEPTS YOU WILL LEARN
'   * One color per scan line + palette writes = raster effects
'   * Shading a bar: brightness falls off from its centre line
'   * Layering (painter's algorithm): later bars cover earlier
'   * Sine waves with different phases make bars weave around
'
' THINGS TO TRY
'   * Make the bars wider (BARH) or give them a white core
'   * Add a sine-wave "wobble" of the text using colors too
' ============================================================
DEFINT A-Z

CONST ROWS = 200
CONST BARH = 10                   ' half-height of each bar in rows
CONST MAXBARS = 8
DIM r(ROWS), g(ROWS), b(ROWS)     ' the color of every screen row
DIM hr(MAXBARS), hg(MAXBARS), hb(MAXBARS)   ' each bar's hue

SCREEN 13
' ---- each row gets its own color number ----------------------
FOR y = 0 TO ROWS - 1
    LINE (0, y)-(319, y), 1 + y
NEXT
' A black panel with a title, drawn in color 0 and 255.
LINE (60, 88)-(259, 111), 0, BF
OUT &H3C8, 255: OUT &H3C9, 63: OUT &H3C9, 63: OUT &H3C9, 63
COLOR 255
LOCATE 13, 10: PRINT "C O P P E R   B A R S"
LOCATE 25, 2: PRINT "+/- bars  S speed  Esc quit";

' Bar colors: red, orange, yellow, green, cyan, blue, purple, pink
FOR i = 1 TO MAXBARS: READ hr(i), hg(i), hb(i): NEXT
DATA 63,10,10, 63,35,0, 63,63,10, 10,63,10, 10,63,63, 15,25,63, 40,10,63, 63,20,50

nBars = 6: t! = 0: spd! = .04
DO
    ' ---- 1. Start with a dark blue background --------------
    FOR y = 0 TO ROWS - 1
        r(y) = 0: g(y) = 0: b(y) = 4 + y \ 20
    NEXT

    ' ---- 2. Paint each bar into the row arrays --------------
    FOR i = 1 TO nBars
        ' Each bar has its own phase (i * 0.45), so they follow
        ' one another like a snake.
        cy = 100 + 85 * SIN(t! + i * .45)
        FOR d = -BARH TO BARH
            y = cy + d
            IF y >= 0 AND y < ROWS THEN
                ' Brightness: 1 in the middle, falling to ~0 at
                ' the edges.  A cosine curve looks rounded and shiny.
                br! = COS(d / BARH * 1.5)
                r(y) = hr(i) * br!: g(y) = hg(i) * br!: b(y) = hb(i) * br!
            END IF
        NEXT
    NEXT

    ' ---- 3. Send all 200 colors to the palette --------------
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8   ' change colors during retrace
    OUT &H3C8, 1
    FOR y = 0 TO ROWS - 1
        OUT &H3C9, r(y): OUT &H3C9, g(y): OUT &H3C9, b(y)
    NEXT

    t! = t! + spd!
    IF t! > 6.2832 THEN t! = t! - 6.2832

    k$ = UCASE$(INKEY$)
    IF (k$ = "+" OR k$ = "=") AND nBars < MAXBARS THEN nBars = nBars + 1
    IF k$ = "-" AND nBars > 1 THEN nBars = nBars - 1
    IF k$ = "S" THEN IF spd! < .05 THEN spd! = .09 ELSE spd! = .04
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
