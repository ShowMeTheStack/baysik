' ============================================================
' TITLE:    Water Ripples
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     wave equation, simulation, palette, cellular, water
' SUMMARY:  Raindrops plop into a pond and the rings spread, bounce off the edges and interfere, using the classic two-buffer wave trick.
' ------------------------------------------------------------
' WHAT IT DOES
'   The pond is a grid of water heights.  Two copies are kept:
'   the heights NOW and the heights one frame AGO.  The new
'   height of each cell is:
'       new = (left + right + up + down) / 2 - old
'   then a little is removed so waves slowly die out (damping).
'   That tiny rule is a version of the real wave equation, and
'   it makes rings spread out, reflect from the walls and pass
'   through each other.  Heights are shown as shades of blue.
'
' HOW TO USE
'   Drops fall by themselves.  Also:
'     SPACE        drop a big stone in the middle
'     Arrow keys   move the target cross, ENTER drops there
'     R            rain on / off
'     Esc          quit
'
' CONCEPTS YOU WILL LEARN
'   * Simulating waves with two buffers (now and before)
'   * Swapping buffers by flipping an index (cur = 1 - cur)
'   * Damping:  v = v - v \ 32  removes 1/32 of the energy
'   * Mapping numbers to a custom blue palette
'
' THINGS TO TRY
'   * Change the damping to 1/8 (thick syrup) or 1/128 for long-lasting waves
'   * Add a wall in the middle of the pond (cells that stay 0)
' ============================================================
DEFINT A-Z

CONST GW = 64, GH = 38            ' grid size
CONST CELL = 5                    ' pixels per cell
CONST TOPY = 8                    ' leave the top text row free
DIM h(1, GW + 1, GH + 1)          ' h(buffer, x, y); border cells stay 0
DIM shown(GW, GH)                 ' color currently on screen

SCREEN 13
RANDOMIZE TIMER

' ---- water palette: colors 16..79 ----------------------------
' Height/4 of -32..31 -> color 48 + height/4.  Low = deep blue,
' high = bright cyan/white crests.
OUT &H3C8, 16
FOR i = 0 TO 63
    OUT &H3C9, i \ 3: OUT &H3C9, 10 + i \ 2: OUT &H3C9, 25 + i \ 2
NEXT
FOR y = 1 TO GH: FOR x = 1 TO GW: shown(x, y) = -1: NEXT: NEXT
COLOR 15: LOCATE 1, 1: PRINT "SPACE stone  arrows+ENTER drop  R rain";

cur = 0: rain = -1: tx = GW \ 2: ty = GH \ 2
DO
    ' ---- drops ----------------------------------------------
    IF rain AND RND < .08 THEN
        dx = 3 + INT(RND * (GW - 4)): dy = 3 + INT(RND * (GH - 4)): amt = 400
        GOSUB Splash
    END IF

    ' ---- one wave step ---------------------------------------
    ' Read from buffer "cur" (now) and "old" (before); the result
    ' overwrites "old", which then becomes the new "now".
    old = 1 - cur
    FOR y = 1 TO GH
        py = TOPY + (y - 1) * CELL
        FOR x = 1 TO GW
            v = (h(cur, x - 1, y) + h(cur, x + 1, y) + h(cur, x, y - 1) + h(cur, x, y + 1)) \ 2 - h(old, x, y)
            v = v - v \ 32                         ' damping
            h(old, x, y) = v
            ' Color: 48 + v/4, clamped to the palette range.
            c = 48 + v \ 4
            IF c < 16 THEN c = 16 ELSE IF c > 79 THEN c = 79
            IF c <> shown(x, y) THEN
                shown(x, y) = c
                LINE ((x - 1) * CELL, py)-STEP(CELL - 1, CELL - 1), c, BF
            END IF
        NEXT
    NEXT
    cur = old                        ' swap buffers

    ' ---- target cross ---------------------------------------
    PSET ((tx - 1) * CELL + 2, TOPY + (ty - 1) * CELL + 2), 14
    shown(tx, ty) = -1               ' force that cell to redraw next time

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE " ": dx = GW \ 2: dy = GH \ 2: amt = 1500: GOSUB Splash
        CASE CHR$(13): dx = tx: dy = ty: amt = 700: GOSUB Splash
        CASE "R": rain = NOT rain
        CASE CHR$(0) + "H": IF ty > 2 THEN ty = ty - 1
        CASE CHR$(0) + "P": IF ty < GH - 1 THEN ty = ty + 1
        CASE CHR$(0) + "K": IF tx > 2 THEN tx = tx - 1
        CASE CHR$(0) + "M": IF tx < GW - 1 THEN tx = tx + 1
    END SELECT
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

Splash:
    ' Push the water at (dx, dy) up as a small rounded bump: full
    ' height in the middle, half on the four neighbours.  A single
    ' spiky cell would make jagged checkerboard noise instead of
    ' smooth rings.
    h(cur, dx, dy) = amt
    h(cur, dx - 1, dy) = amt \ 2: h(cur, dx + 1, dy) = amt \ 2
    h(cur, dx, dy - 1) = amt \ 2: h(cur, dx, dy + 1) = amt \ 2
    RETURN
