' ============================================================
' TITLE:    Game of Life in 50-Line Mode
' CATEGORY: Console & Text
' LEVEL:    Advanced
' TAGS:     width 80 50, half blocks, video memory, cellular automaton
' SUMMARY:  Conway's Game of Life on an 80x100 grid squeezed into text mode with 50-line mode and half-block characters.
' ------------------------------------------------------------
' WHAT IT DOES
'   EGA and VGA cards can show 43 or 50 lines of text instead of 25
'   by using a smaller font: WIDTH 80, 43 or WIDTH 80, 50.  Then
'   this program uses another trick: each character cell shows TWO
'   "pixels", one on top of the other, using the half-block
'   characters (upper half, lower half, full block, space).  That
'   gives an 80 x 100 grid in plain text mode!
'   On that grid it runs Conway's Game of Life: every cell lives or
'   dies depending on how many of its 8 neighbours are alive.
'
' HOW TO USE
'   2 / 4 / 5   switch to 25, 43 or 50 lines (grid resizes)
'   R           new random soup        G   drop a glider gun-ish seed
'   Space       pause / resume         Esc or Q  quit
'
' CONCEPTS YOU WILL LEARN
'   * WIDTH 80, 25 / 43 / 50 text modes
'   * Packing two pixels into one character with CHR$(223/220/219)
'   * Writing whole rows to video memory with POKE for speed
'   * Two arrays (now / next) so updates don't disturb each other
'   * Wrapping edges: the grid is a doughnut shape (a torus)
'
' THINGS TO TRY
'   * Colour cells by age: young cells green, old cells blue.
'   * Change the rules (e.g. born with 3 or 6 = "HighLife").
'   * Add a cursor so you can draw your own patterns.
' ============================================================

DEFINT A-Z
DECLARE SUB SetMode (lines)
DECLARE SUB Randomize2 ()
DECLARE SUB DrawGrid ()

CONST W = 80
DIM SHARED cell(0 TO 79, 0 TO 99), nxt(0 TO 79, 0 TO 99)
DIM SHARED H, rows, gen&

RANDOMIZE TIMER
SetMode 50
Randomize2
paused = 0

DO
    DrawGrid
    IF NOT paused THEN
        ' ---- one generation of Life ----
        FOR y = 0 TO H - 1
            ' neighbouring rows, wrapping around top and bottom
            yu = (y + H - 1) MOD H: yd = (y + 1) MOD H
            FOR x = 0 TO W - 1
                xl = (x + W - 1) MOD W: xr = (x + 1) MOD W
                n = cell(xl, yu) + cell(x, yu) + cell(xr, yu)
                n = n + cell(xl, y) + cell(xr, y)
                n = n + cell(xl, yd) + cell(x, yd) + cell(xr, yd)
                ' The rules: a live cell survives with 2 or 3 neighbours;
                ' an empty cell comes alive with exactly 3.
                IF n = 3 OR (n = 2 AND cell(x, y) = 1) THEN nxt(x, y) = 1 ELSE nxt(x, y) = 0
            NEXT x
        NEXT y
        ' copy next -> now
        FOR y = 0 TO H - 1
            FOR x = 0 TO W - 1
                cell(x, y) = nxt(x, y)
            NEXT x
        NEXT y
        gen& = gen& + 1
    END IF

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "2": SetMode 25: Randomize2
        CASE "4": SetMode 43: Randomize2
        CASE "5": SetMode 50: Randomize2
        CASE "R": Randomize2
        CASE " ": paused = NOT paused
        CASE "G"
            ' Clear and drop a few gliders that will fly diagonally.
            ERASE cell
            FOR g = 0 TO 5
                gx = 5 + g * 12: gy = 5 + (g MOD 3) * 10
                cell(gx + 1, gy) = 1
                cell(gx + 2, gy + 1) = 1
                cell(gx, gy + 2) = 1: cell(gx + 1, gy + 2) = 1: cell(gx + 2, gy + 2) = 1
            NEXT g
            gen& = 0
        CASE CHR$(27), "Q": EXIT DO
    END SELECT
LOOP

WIDTH 80, 25
COLOR 7, 0: CLS
END

' Paint the grid.  Text row r shows grid rows 2r (top half) and
' 2r+1 (bottom half).  The status line uses the last text row.
SUB DrawGrid
    DEF SEG = &HB800
    FOR r = 0 TO rows - 2
        ofs = r * 160
        y = r * 2
        FOR x = 0 TO W - 1
            ' Combine the two pixels into a number 0..3:
            '   0 = both off  -> space        (32)
            '   1 = top only  -> upper half   (223)
            '   2 = bottom    -> lower half   (220)
            '   3 = both      -> full block   (219)
            v = cell(x, y) + 2 * cell(x, y + 1)
            SELECT CASE v
                CASE 0: ch = 32
                CASE 1: ch = 223
                CASE 2: ch = 220
                CASE 3: ch = 219
            END SELECT
            POKE ofs, ch
            POKE ofs + 1, &HA            ' light green on black
            ofs = ofs + 2
        NEXT x
    NEXT r
    DEF SEG
    COLOR 0, 7
    LOCATE rows, 1
    PRINT USING " LIFE  80x###  lines:##  gen:#####   2/4/5=mode R=random G=gliders Space Esc "; H; rows; gen&;
END SUB

' Fill the grid with random cells (about 1 in 4 alive).
SUB Randomize2
    ERASE cell
    FOR y = 0 TO H - 1
        FOR x = 0 TO W - 1
            IF RND < .25 THEN cell(x, y) = 1
        NEXT x
    NEXT y
    gen& = 0
END SUB

' Switch the number of text lines and work out the grid height.
' One text row is kept for the status bar, the rest hold 2 pixels each.
SUB SetMode (lines)
    WIDTH 80, lines
    COLOR 7, 0: CLS
    rows = lines
    H = (rows - 1) * 2
END SUB
