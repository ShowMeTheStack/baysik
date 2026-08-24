' ============================================================
' TITLE:    Voronoi Diagram
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     generative art, geometry, distance, nearest neighbour, SCREEN 13
' SUMMARY:  Splits the screen into colored cells, one per random seed, where every pixel belongs to its nearest seed.
' ------------------------------------------------------------
' WHAT IT DOES
'   Scatter some points ("seeds") on the screen.  Now color every
'   pixel with the color of the seed it is CLOSEST to.  The screen
'   breaks into cells that look like stained glass, giraffe skin,
'   dried mud or a map of countries.  This is a Voronoi diagram,
'   used for real in mapping (which hospital is nearest?), biology,
'   robotics and games.
'
'   You can also change what "distance" means:
'     Euclidean  - straight-line distance: SQR(dx^2 + dy^2)
'     Manhattan  - walking on a city grid: ABS(dx) + ABS(dy)
'     Chebyshev  - a chess king's moves:   the larger of ABS(dx), ABS(dy)
'   Each gives cells with a different look.
'
' HOW TO USE
'   Space  new seeds          D  change the distance type
'   + / -  more / fewer seeds Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Nearest-neighbour search (the brute-force way)
'   * Comparing squared distances to avoid slow SQR calls
'   * Finding cell borders: a block whose neighbour belongs to a
'     different seed is on an edge
'   * Different distance metrics
'
' THINGS TO TRY
'   * Shade each pixel by its distance to the seed (cells look 3-D)
'   * Move the seeds a little each frame for a living animation
'   * Place seeds on a grid with a small random wobble
' ============================================================
DEFINT A-Z
CONST BW = 160, BH = 96         ' we work on 2x2 pixel blocks
CONST MAXS = 60
DIM sx(MAXS), sy(MAXS)          ' seed positions (in blocks)
DIM owner(BW - 1, BH - 1)       ' which seed owns each block

SCREEN 13
RANDOMIZE TIMER
' ---- Stained-glass palette: 60 random rich colors ----------------
OUT &H3C8, 1
FOR i = 1 TO MAXS
    ' Make one channel strong, the others weaker, so colors stay vivid.
    r = 10 + RND * 30: g = 10 + RND * 30: b = 10 + RND * 30
    SELECT CASE i MOD 3
        CASE 0: r = 63
        CASE 1: g = 55
        CASE 2: b = 63
    END SELECT
    OUT &H3C9, r: OUT &H3C9, g: OUT &H3C9, b
NEXT
' Colors 1..60 are now cells, so make color 255 pure white for text.
OUT &H3C8, 255: OUT &H3C9, 63: OUT &H3C9, 63: OUT &H3C9, 63

nSeeds = 24: metric = 1: newSeeds = -1
DO
    ' ---- 1. random seeds (kept when only the metric changes) ----
    IF newSeeds THEN
        FOR i = 1 TO nSeeds
            sx(i) = INT(RND * BW): sy(i) = INT(RND * BH)
        NEXT
    END IF
    ' ---- 2. find the nearest seed for every block ---------------
    CLS
    FOR y = 0 TO BH - 1
        FOR x = 0 TO BW - 1
            best& = 2147483647: who = 1
            ' One loop per metric (rather than a SELECT CASE inside a
            ' single loop) because this is the innermost, busiest code.
            SELECT CASE metric
                CASE 1    ' Euclidean - compare SQUARED distances: if
                          ' a < b then a^2 < b^2, so SQR is not needed
                    FOR i = 1 TO nSeeds
                        dx = x - sx(i): dy = y - sy(i)
                        d& = CLNG(dx) * dx + CLNG(dy) * dy
                        IF d& < best& THEN best& = d&: who = i
                    NEXT
                CASE 2    ' Manhattan
                    FOR i = 1 TO nSeeds
                        d& = ABS(x - sx(i)) + ABS(y - sy(i))
                        IF d& < best& THEN best& = d&: who = i
                    NEXT
                CASE 3    ' Chebyshev
                    FOR i = 1 TO nSeeds
                        dx = ABS(x - sx(i)): dy = ABS(y - sy(i))
                        IF dx > dy THEN d& = dx ELSE d& = dy
                        IF d& < best& THEN best& = d&: who = i
                    NEXT
            END SELECT
            owner(x, y) = who
            LINE (x * 2, y * 2)-STEP(1, 1), who, BF
        NEXT
        IF INKEY$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
    NEXT
    ' ---- 3. dark "lead" lines on the borders --------------------
    ' A block is on a border if the block to its right or below it
    ' belongs to a different seed.
    FOR y = 0 TO BH - 2
        FOR x = 0 TO BW - 2
            IF owner(x, y) <> owner(x + 1, y) OR owner(x, y) <> owner(x, y + 1) THEN
                LINE (x * 2, y * 2)-STEP(1, 1), 0, BF
            END IF
        NEXT
    NEXT
    ' ---- 4. the seeds themselves ---------------------------------
    FOR i = 1 TO nSeeds
        CIRCLE (sx(i) * 2 + 1, sy(i) * 2 + 1), 2, 255
    NEXT
    SELECT CASE metric
        CASE 1: m$ = "Euclidean"
        CASE 2: m$ = "Manhattan"
        CASE 3: m$ = "Chebyshev"
    END SELECT
    LOCATE 25, 1: COLOR 255
    PRINT m$; nSeeds; "seeds  Spc D +/- Esc";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "D": metric = metric MOD 3 + 1
        CASE "+", "=": IF nSeeds < MAXS THEN nSeeds = nSeeds + 6
        CASE "-", "_": IF nSeeds > 6 THEN nSeeds = nSeeds - 6
    END SELECT
    ' New seeds for every key except D (D only changes the metric).
    ' A comparison gives -1 (true) or 0 (false), which we can store.
    newSeeds = (k$ <> "D")
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END
