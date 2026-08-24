' ============================================================
' TITLE:    Random Truchet Tiles
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     generative art, random, tiles, CIRCLE arcs, patterns
' SUMMARY:  Fill the screen with randomly turned tiles and watch winding paths and mazes emerge from coin flips.
' ------------------------------------------------------------
' WHAT IT DOES
'   A Truchet tile is a square with a simple picture on it that can
'   be placed in two (or four) different rotations.  Lay out a grid
'   of them, flip a coin for each one to choose its rotation, and
'   surprisingly beautiful patterns appear: long snaking paths,
'   loops and maze-like walls.
'
'   Three tile styles are included:
'     1  Quarter circles (Smith tiles) - two arcs joining the
'        middles of the edges, so paths always connect smoothly
'     2  Diagonal lines - the famous "10 PRINT" maze
'     3  Half-filled triangles - bold geometric patterns (4 turns)
'
' HOW TO USE
'   1 / 2 / 3   choose tile style      + / -   bigger / smaller tiles
'   Space       new random pattern     Esc     quit
'
' CONCEPTS YOU WILL LEARN
'   * Nested loops to cover the screen with a grid
'   * RND as a coin flip:  IF RND < .5 THEN ...
'   * CIRCLE with start and end angles to draw arcs
'   * How simple local rules make large-scale structure
'
' THINGS TO TRY
'   * Make the coin unfair (RND < .8) - how does the pattern change?
'   * Choose the rotation from a formula like (x * y) MOD 2 instead
'     of RND for regular, woven-looking patterns
'   * Color each tile by its row and column
' ============================================================
DECLARE SUB Tile (x%, y%, s%, style%, turn%)

CONST PI = 3.14159265#
SCREEN 12
RANDOMIZE TIMER
style% = 1: size% = 32

DO
    CLS
    ' Cover the screen (minus the bottom text row) with tiles.
    FOR y% = 0 TO 463 - size% STEP size%
        FOR x% = 0 TO 639 - size% + 1 STEP size%
            IF style% = 3 THEN
                turn% = INT(RND * 4)       ' 4 possible rotations
            ELSE
                turn% = INT(RND * 2)       ' coin flip: 0 or 1
            END IF
            Tile x%, y%, size%, style%, turn%
        NEXT
    NEXT
    LOCATE 30, 1: COLOR 7
    PRINT "1/2/3 style  +/- size  Space new  Esc quit   tile size:"; size%;
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "1", "2", "3": style% = VAL(k$)
        CASE "+", "=": IF size% < 80 THEN size% = size% * 2
        CASE "-", "_": IF size% > 10 THEN size% = size% \ 2
    END SELECT
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' Draws one tile with its top-left corner at (x, y) and side s.
SUB Tile (x%, y%, s%, style%, turn%)
    h% = s% \ 2                         ' half a tile: arc radius
    x2% = x% + s%: y2% = y% + s%        ' the opposite corner
    SELECT CASE style%
        CASE 1
            ' Two quarter circles centred on opposite corners.
            ' CIRCLE angles are in radians, counter-clockwise, with
            ' 0 pointing right - and "up" means up on the screen.
            IF turn% = 0 THEN
                CIRCLE (x%, y%), h%, 11, 1.5 * PI, 2 * PI       ' top-left corner
                CIRCLE (x2%, y2%), h%, 11, .5 * PI, PI          ' bottom-right
            ELSE
                CIRCLE (x2%, y%), h%, 14, PI, 1.5 * PI          ' top-right corner
                CIRCLE (x%, y2%), h%, 14, 0, .5 * PI            ' bottom-left
            END IF
        CASE 2
            ' One diagonal: "/" or "\".  Two lines make it thicker.
            IF turn% = 0 THEN
                LINE (x%, y2%)-(x2%, y%), 10
                LINE (x% + 1, y2%)-(x2% + 1, y%), 10
            ELSE
                LINE (x%, y%)-(x2%, y2%), 13
                LINE (x% + 1, y%)-(x2% + 1, y2%), 13
            END IF
        CASE 3
            ' A square split along a diagonal; one half is filled.
            ' Outline the triangle, then PAINT inside it.
            SELECT CASE turn%
                CASE 0: ax% = x%: ay% = y%: bx% = x2%: by% = y%: cx% = x%: cy% = y2%
                CASE 1: ax% = x2%: ay% = y%: bx% = x2%: by% = y2%: cx% = x%: cy% = y%
                CASE 2: ax% = x2%: ay% = y2%: bx% = x%: by% = y2%: cx% = x2%: cy% = y%
                CASE 3: ax% = x%: ay% = y2%: bx% = x%: by% = y%: cx% = x2%: cy% = y2%
            END SELECT
            LINE (ax%, ay%)-(bx%, by%), 9
            LINE -(cx%, cy%), 9
            LINE -(ax%, ay%), 9
            ' A point safely inside: the triangle's centre of gravity.
            PAINT ((ax% + bx% + cx%) \ 3, (ay% + by% + cy%) \ 3), 9, 9
    END SELECT
END SUB
