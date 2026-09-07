' ============================================================
' TITLE:    Demoscene Fire
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     fire effect, SCREEN 13, palette, cellular, demoscene
' SUMMARY:  The classic demoscene fire: random heat at the bottom, averaged upward and cooled, colored by a black-red-yellow-white palette.
' ------------------------------------------------------------
' WHAT IT DOES
'   Keeps a grid of "heat" numbers from 0 (cold) to 63 (white
'   hot).  Every frame:
'     1. The bottom row gets random hot and cold spots (fuel).
'     2. Every other cell becomes the AVERAGE of the cells just
'        below it, minus a little cooling.  Heat therefore drifts
'        upward, spreads out and fades - just like flames.
'   Heat numbers are used directly as color numbers, and the
'   palette for colors 0-63 is set to a fire ramp, so heat 0 is
'   black and heat 63 is white.
'
' HOW TO USE
'   +  / -   more / less cooling (shorter / taller flames)
'   W        toggle a breeze that bends the flames
'   Esc      quit
'
' CONCEPTS YOU WILL LEARN
'   * Writing your own 64-color palette with OUT &H3C8 / &H3C9
'   * A cellular effect: each cell's new value depends on its
'     neighbours (like Conway's Life, but with averaging)
'   * Updating a grid "in place": we sweep from the top down, so
'     the rows below are still last frame's values when we read them
'   * Drawing a low-resolution grid as 5x5 pixel blocks
'
' THINGS TO TRY
'   * Change the palette to blue/green for magic fire
'   * Make the fuel row follow a shape - e.g. only burn in the
'     middle third of the screen
' ============================================================
DEFINT A-Z

CONST GW = 64, GH = 28            ' grid size in cells
CONST CELL = 5                    ' each cell is 5x5 pixels (64*5 = 320)
CONST TOP = 200 - GH * CELL       ' first screen row of the fire

DIM heat(GW + 2, GH + 1)          ' spare columns/row so every neighbour exists

SCREEN 13
RANDOMIZE TIMER

' ---- 1. The fire palette ------------------------------------
' Colors 0..63:  0-20 black->red, 21-41 red->yellow,
'                42-63 yellow->white.  Each DAC value is 0-63.
OUT &H3C8, 0                      ' start writing at color 0
FOR c = 0 TO 63
    r = c * 3: g = (c - 21) * 3: b = (c - 42) * 3
    IF r > 63 THEN r = 63
    IF g < 0 THEN g = 0
    IF g > 63 THEN g = 63
    IF b < 0 THEN b = 0
    ' After the first OUT &H3C8, the DAC moves to the next color
    ' automatically after every three &H3C9 writes (red,green,blue).
    OUT &H3C9, r: OUT &H3C9, g: OUT &H3C9, b
NEXT
' Color 64 is used for text.
OUT &H3C8, 64: OUT &H3C9, 50: OUT &H3C9, 50: OUT &H3C9, 50
COLOR 64
LOCATE 2, 2: PRINT "+/- cooling  W wind  Esc quit"

cool = 1: wind = 0
DO
    ' ---- 2. Fuel: random heat on the hidden bottom row -------
    FOR x = 1 TO GW
        IF RND < .5 THEN heat(x, GH + 1) = 63 ELSE heat(x, GH + 1) = 10
    NEXT

    ' ---- 3. Spread heat upward and draw ----------------------
    FOR y = 1 TO GH
        sy = TOP + (y - 1) * CELL
        FOR x = 1 TO GW
            ' Average the three cells below (left, centre, right)
            ' plus this cell.  With wind = 1 we sample one cell to
            ' the right, so the flames lean to the left.
            ' (This inner loop runs ~1800 times per frame, so it
            ' is kept as short as possible.)
            v = (heat(x + wind - 1, y + 1) + heat(x + wind, y + 1) + heat(x + wind + 1, y + 1) + heat(x, y)) \ 4 - cool
            IF v < 0 THEN v = 0
            ' Only redraw cells that changed - a big speed-up,
            ' because the cold sky at the top rarely changes.
            IF v <> heat(x, y) THEN
                heat(x, y) = v
                LINE ((x - 1) * CELL, sy)-STEP(CELL - 1, CELL - 1), v, BF
            END IF
        NEXT
    NEXT

    k$ = UCASE$(INKEY$)
    IF k$ = "+" OR k$ = "=" THEN IF cool < 8 THEN cool = cool + 1
    IF k$ = "-" THEN IF cool > 0 THEN cool = cool - 1
    IF k$ = "W" THEN wind = 1 - wind     ' toggles 0 <-> 1
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
