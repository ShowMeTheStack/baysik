' ============================================================
' TITLE:    Forest Fire Model
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     cellular automata, ecology, fire, probability, self-organized criticality
' SUMMARY:  Trees grow, lightning strikes and fires sweep the forest in a never-ending cycle.
' ------------------------------------------------------------
' WHAT IT DOES
'   A grid where every square is EMPTY ground, a TREE, or FIRE.
'   Every tick these rules are applied to all squares at once
'   (the Drossel-Schwabl forest-fire model, 1992):
'     1. A burning square becomes empty (the tree burnt down).
'     2. A tree next to a fire catches fire.
'     3. A tree may be hit by lightning (tiny chance F) and ignite.
'     4. Empty ground may grow a new tree (small chance P).
'   Forests build up until they are thick enough for a single spark
'   to burn huge areas.  Fires come in all sizes, from tiny to giant
'   - a pattern scientists call "self-organized criticality".
'   A bar graph at the bottom tracks how many trees there are.
'
' HOW TO USE
'   G / g   faster / slower tree growth
'   L / l   more / less lightning
'   SPACE   drop a lightning bolt right now
'   ESC     quit
'
' CONCEPTS YOU WILL LEARN
'   * Cellular automata with 3 states
'   * Using two grids so updates happen "all at once"
'   * Probability with RND
'   * Feedback cycles in ecosystems
'
' THINGS TO TRY
'   * Make growth very fast: fires never stop.
'   * Turn lightning nearly off: the forest grows dense, then one
'     strike burns almost everything.
'   * Add wind: let fire spread only to the right.
' ============================================================

DEFINT A-Z
CONST GW = 80, GH = 39          ' grid size in cells
CONST CS = 4                    ' each cell is 4x4 pixels
CONST EMPTY = 0, TREE = 1, FIRE = 2

' Two grids in one array: g(0,x,y) and g(1,x,y).  Each tick we read
' from grid "c" (current) and write into grid "n" (next), then just
' swap the two numbers - no need to copy thousands of cells.
' The extra row/column of always-empty cells around the edge means
' x-1, x+1, y-1, y+1 never fall outside the array.
DIM g(1, GW + 1, GH + 1)
c = 0: n = 1
DIM hist(GW)                    ' tree count history for the graph
DIM col(2)
col(EMPTY) = 6                  ' brown earth
col(TREE) = 2                   ' green tree
col(FIRE) = 12                  ' bright red fire

RANDOMIZE TIMER
pGrow! = .02                    ' chance per tick an empty square grows a tree
pLight! = .00005                ' chance per tick a tree is struck by lightning

SCREEN 13
' start with a random half-filled forest
FOR y = 1 TO GH: FOR x = 1 TO GW
    IF RND < .5 THEN g(c, x, y) = TREE ELSE g(c, x, y) = EMPTY
    LINE ((x - 1) * CS, (y - 1) * CS)-((x - 1) * CS + CS - 1, (y - 1) * CS + CS - 1), col(g(c, x, y)), BF
NEXT: NEXT

DO
    k$ = INKEY$
    SELECT CASE k$
        CASE "G": pGrow! = pGrow! * 1.5: IF pGrow! > .5 THEN pGrow! = .5
        CASE "g": pGrow! = pGrow! / 1.5
        CASE "L": pLight! = pLight! * 2: IF pLight! > .01 THEN pLight! = .01
        CASE "l": pLight! = pLight! / 2
        CASE " ": g(c, 1 + INT(RND * GW), 1 + INT(RND * GH)) = FIRE
        CASE CHR$(27): EXIT DO
    END SELECT

    trees = 0: fires = 0
    FOR y = 1 TO GH
        FOR x = 1 TO GW
            s = g(c, x, y)
            SELECT CASE s
                CASE FIRE
                    ns = EMPTY                      ' rule 1
                CASE TREE
                    ns = TREE
                    ' rule 2: any of the 4 neighbours burning?
                    IF g(c, x - 1, y) = FIRE OR g(c, x + 1, y) = FIRE OR g(c, x, y - 1) = FIRE OR g(c, x, y + 1) = FIRE THEN
                        ns = FIRE
                    ELSEIF RND < pLight! THEN
                        ns = FIRE                   ' rule 3: lightning
                    END IF
                CASE ELSE
                    ns = EMPTY
                    IF RND < pGrow! THEN ns = TREE  ' rule 4: growth
            END SELECT
            g(n, x, y) = ns
            IF ns = TREE THEN trees = trees + 1
            IF ns = FIRE THEN fires = fires + 1
            ' only redraw squares that changed - much faster
            IF ns <> s THEN LINE ((x - 1) * CS, (y - 1) * CS)-((x - 1) * CS + CS - 1, (y - 1) * CS + CS - 1), col(ns), BF
        NEXT
    NEXT
    ' swap: the new grid becomes the current one
    SWAP c, n

    ' ---- history graph of tree cover ------------------------------
    FOR i = 1 TO GW - 1: hist(i) = hist(i + 1): NEXT
    hist(GW) = trees
    LINE (0, 158)-(319, 185), 0, BF   ' clear the graph area
    FOR i = 1 TO GW
        h = hist(i) * 26& / (GW * GH)         ' bar height 0..26
        IF h > 0 THEN LINE ((i - 1) * 4, 185 - h)-((i - 1) * 4 + 2, 185), 10, BF
    NEXT
    LOCATE 25, 1: COLOR 15
    PRINT USING "Trees ####  Fire ####  G### L#.#####"; trees; fires; pGrow! * 100; pLight! * 100;
LOOP
SCREEN 0: WIDTH 80
END
