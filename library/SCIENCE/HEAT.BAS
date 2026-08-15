' ============================================================
' TITLE:    Heat Diffusion on a Metal Plate
' CATEGORY: Science & Simulation
' LEVEL:    Advanced
' TAGS:     physics, heat equation, finite differences, palette, grid
' SUMMARY:  Place heaters and ice blocks on a metal plate and watch heat spread out, colour-coded from blue to red.
' ------------------------------------------------------------
' WHAT IT DOES
'   Heat always flows from hot to cold.  On a flat plate, each small
'   square gets warmer if its neighbours are warmer than it, and
'   cooler if they are cooler.  That is the HEAT EQUATION, solved
'   here with the "finite difference" method:
'       newT = T + alpha * (Tleft + Tright + Tup + Tdown - 4 * T)
'   (the bracket is how much hotter the neighbours are on average).
'   alpha must be at most 0.25 or the numbers explode - try to
'   understand why!
'   Heaters (H) stay at 100 degrees, coolers (C) at 0.  The colours
'   run from dark blue (cold) through green and yellow to red (hot).
'
' HOW TO USE
'   Arrow keys  move the cursor        H  place a heater
'   C           place a cooler         E  erase (normal plate)
'   SPACE       splash of heat         R  reset the plate to 20 degrees
'   I           toggle insulated edges / edges held at 20 degrees
'   ESC         quit
'
' CONCEPTS YOU WILL LEARN
'   * The heat (diffusion) equation and the discrete Laplacian
'   * Stability limits of explicit numerical methods
'   * Boundary conditions: insulated vs fixed temperature
'   * Building a 64-colour "heat map" palette with OUT
'
' THINGS TO TRY
'   * Put a heater and a cooler a few squares apart: a steady
'     gradient forms between them.
'   * Draw a wall of coolers with a gap.
'   * Change ALPHA to 0.3 and watch the instability!
' ============================================================

DEFINT A-Z
CONST GW = 64, GH = 36          ' grid size
CONST CS = 5                    ' 5x5 pixels per cell
CONST ALPHA = .2                ' diffusion rate per step (must be <= 0.25)
CONST NORMAL = 0, HEATER = 1, COOLER = 2

DIM t!(1, GW + 1, GH + 1)       ' two temperature grids, ping-pong style
DIM kind(GW + 1, GH + 1)        ' what each cell is
cg = 0: ng = 1                  ' current and next grid numbers
insulated = 1
cx = GW \ 2: cy = GH \ 2        ' cursor position

SCREEN 13
' ---- build a heat-map palette in colours 16..79 -----------------
' 0..63 maps blue -> cyan -> green -> yellow -> red
OUT &H3C8, 16
FOR i = 0 TO 63
    IF i < 16 THEN
        r = 0: g = i * 4: b = 40 + i
    ELSEIF i < 32 THEN
        r = 0: g = 63: b = 63 - (i - 16) * 4
    ELSEIF i < 48 THEN
        r = (i - 32) * 4: g = 63: b = 0
    ELSE
        r = 63: g = 63 - (i - 48) * 4: b = 0
    END IF
    OUT &H3C9, r: OUT &H3C9, g: OUT &H3C9, b
NEXT
' colour bar legend
FOR i = 0 TO 63: LINE (i * 5, 181)-(i * 5 + 4, 183), 16 + i, BF: NEXT
LOCATE 25, 1: PRINT "0 C  cold";: LOCATE 25, 32: PRINT "hot 100";

GOSUB ResetPlate
DO
    ' ---- keyboard ---------------------------------------------------
    k$ = UCASE$(INKEY$)
    IF LEN(k$) = 2 THEN                    ' arrow keys send CHR$(0) + code
        SELECT CASE RIGHT$(k$, 1)
            CASE "H": IF cy > 1 THEN cy = cy - 1
            CASE "P": IF cy < GH THEN cy = cy + 1
            CASE "K": IF cx > 1 THEN cx = cx - 1
            CASE "M": IF cx < GW THEN cx = cx + 1
        END SELECT
    ELSE
        SELECT CASE k$
            CASE "H": kind(cx, cy) = HEATER
            CASE "C": kind(cx, cy) = COOLER
            CASE "E": kind(cx, cy) = NORMAL
            CASE " "
                FOR y = cy - 2 TO cy + 2: FOR x = cx - 2 TO cx + 2
                    IF x >= 1 AND x <= GW AND y >= 1 AND y <= GH THEN t!(cg, x, y) = 100
                NEXT: NEXT
            CASE "R": GOSUB ResetPlate
            CASE "I": insulated = 1 - insulated
            CASE CHR$(27): EXIT DO
        END SELECT
    END IF

    ' ---- boundary: the ghost cells around the edge -----------------
    ' Insulated = no heat flows out, so the ghost copies its neighbour.
    ' Fixed = the ghost is always 20 degrees, so heat leaks out.
    FOR x = 1 TO GW
        IF insulated THEN
            t!(cg, x, 0) = t!(cg, x, 1): t!(cg, x, GH + 1) = t!(cg, x, GH)
        ELSE
            t!(cg, x, 0) = 20: t!(cg, x, GH + 1) = 20
        END IF
    NEXT
    FOR y = 1 TO GH
        IF insulated THEN
            t!(cg, 0, y) = t!(cg, 1, y): t!(cg, GW + 1, y) = t!(cg, GW, y)
        ELSE
            t!(cg, 0, y) = 20: t!(cg, GW + 1, y) = 20
        END IF
    NEXT

    ' ---- one diffusion step and draw ----------------------------------
    FOR y = 1 TO GH
        FOR x = 1 TO GW
            SELECT CASE kind(x, y)
                CASE HEATER: v! = 100
                CASE COOLER: v! = 0
                CASE ELSE
                    ' the Laplacian: neighbours' total minus 4 times me
                    lap! = t!(cg, x - 1, y) + t!(cg, x + 1, y) + t!(cg, x, y - 1) + t!(cg, x, y + 1) - 4 * t!(cg, x, y)
                    v! = t!(cg, x, y) + ALPHA * lap!
            END SELECT
            t!(ng, x, y) = v!
            c = 16 + INT(v! * .63)
            IF c < 16 THEN c = 16
            IF c > 79 THEN c = 79
            LINE ((x - 1) * CS, (y - 1) * CS)-((x - 1) * CS + CS - 1, (y - 1) * CS + CS - 1), c, BF
        NEXT
    NEXT
    SWAP cg, ng

    ' ---- cursor and labels ------------------------------------------
    LINE ((cx - 1) * CS, (cy - 1) * CS)-((cx - 1) * CS + CS - 1, (cy - 1) * CS + CS - 1), 15, B
    LOCATE 24, 1
    IF insulated THEN e$ = "insulated" ELSE e$ = "20-degree"
    PRINT USING "T=###.# edges:\       \ H C E SPC R I"; t!(cg, cx, cy); e$;
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' ResetPlate: everything back to 20 degrees, no heaters/coolers,
' except one heater and one cooler to get things started.
' ------------------------------------------------------------
ResetPlate:
    FOR y = 0 TO GH + 1: FOR x = 0 TO GW + 1
        t!(0, x, y) = 20: t!(1, x, y) = 20: kind(x, y) = NORMAL
    NEXT: NEXT
    kind(16, 18) = HEATER: kind(17, 18) = HEATER
    kind(48, 18) = COOLER: kind(49, 18) = COOLER
RETURN
