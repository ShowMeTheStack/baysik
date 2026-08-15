' ============================================================
' TITLE:    Ant Colony Foraging
' CATEGORY: Science & Simulation
' LEVEL:    Advanced
' TAGS:     ecosystem, emergence, pheromones, agents, swarm intelligence
' SUMMARY:  Simple ants wander, find food and lay scent trails - and the colony discovers efficient paths together.
' ------------------------------------------------------------
' WHAT IT DOES
'   No ant knows where the food is, and none is in charge.  Yet
'   colonies build busy highways to food.  The secret is PHEROMONE,
'   a scent ants leave on the ground:
'     * A SEARCHING ant (red) wanders randomly, but prefers to step
'       where the scent is strongest.
'     * When it finds food (green) it picks a crumb and becomes a
'       RETURNING ant (yellow), walking home to the nest (brown) and
'       laying scent as it goes.
'     * Scent slowly EVAPORATES, so trails to used-up food fade away.
'   Strong trails attract more ants, which strengthen the trail more
'   - positive feedback.  Purple shows the scent on the ground.
'
' HOW TO USE
'   F  drop a new food pile at a random spot
'   E  toggle fast evaporation       ESC  quit
'
' CONCEPTS YOU WILL LEARN
'   * Agent-based models: many simple individuals, each with a state
'   * Stigmergy: communicating by changing the environment
'   * Weighted random choice ("roulette wheel" selection)
'   * Direction vectors stored in small lookup arrays
'
' THINGS TO TRY
'   * Turn off scent-following (set FOLLOW to 0).  How much slower
'     is the colony at gathering food?
'   * Put two food piles at different distances.  Which trail wins?
'   * Add a predator that eats ants who stray too far.
' ============================================================

DEFINT A-Z
CONST GW = 80, GH = 46          ' world grid (each cell 4x4 pixels)
CONST CS = 4
CONST NA = 70                   ' number of ants
CONST NESTX = 40, NESTY = 23    ' nest position
CONST FOLLOW = 1                ' 1 = ants follow scent, 0 = pure random

DIM ph(GW - 1, GH - 1)          ' pheromone strength 0..240
DIM food(GW - 1, GH - 1)        ' crumbs in each cell
DIM ax(NA), ay(NA), ad(NA)      ' ant position and heading (0..7)
DIM carry(NA)                   ' 0 = searching, 1 = carrying food home
DIM ddx(7), ddy(7)              ' the 8 compass directions
DIM w(2)                        ' weights for the 3 possible steps
FOR i = 0 TO 7: READ ddx(i), ddy(i): NEXT
DATA 1,0, 1,1, 0,1, -1,1, -1,0, -1,-1, 0,-1, 1,-1

RANDOMIZE TIMER
SCREEN 13
' palette 16..31: black -> purple for scent strength
OUT &H3C8, 16
FOR i = 0 TO 15: OUT &H3C9, i * 3: OUT &H3C9, 0: OUT &H3C9, i * 4: NEXT

FOR i = 1 TO NA
    ax(i) = NESTX: ay(i) = NESTY: ad(i) = INT(RND * 8)
NEXT
FOR i = 1 TO 3: GOSUB AddFood: NEXT
FOR cy = 0 TO GH - 1: FOR cx = 0 TO GW - 1: GOSUB DrawCell: NEXT: NEXT
evapRate = 1
evRow = 0

DO
    k$ = UCASE$(INKEY$)
    IF k$ = "F" THEN GOSUB AddFood
    IF k$ = "E" THEN evapRate = 4 - evapRate        ' toggles 1 <-> 3
    IF k$ = CHR$(27) THEN EXIT DO

    ' ---- move every ant -------------------------------------------
    FOR i = 1 TO NA
        cx = ax(i): cy = ay(i): GOSUB DrawCell   ' repaint the cell it leaves
        IF carry(i) = 0 THEN
            ' SEARCHING: score the 3 cells ahead (left, straight, right)
            ' by scent.  Every option gets a base weight of 4 so ants
            ' still explore.  Then pick one at random by weight.
            tot = 0
            FOR t = -1 TO 1
                d = (ad(i) + t + 8) MOD 8
                nx = ax(i) + ddx(d): ny = ay(i) + ddy(d)
                w(t + 1) = 4
                IF nx >= 0 AND nx < GW AND ny >= 0 AND ny < GH THEN
                    w(t + 1) = 4 + FOLLOW * ph(nx, ny) \ 4
                    IF food(nx, ny) > 0 THEN w(t + 1) = w(t + 1) + 500
                ELSE
                    w(t + 1) = 0                  ' can't walk off the map
                END IF
                tot = tot + w(t + 1)
            NEXT
            IF tot = 0 THEN
                ad(i) = (ad(i) + 4) MOD 8         ' dead end: turn around
            ELSE
                ' roulette wheel: a random number lands in one slice
                r = INT(RND * tot)
                t = 0
                DO WHILE r >= w(t): r = r - w(t): t = t + 1: LOOP
                ad(i) = (ad(i) + t - 1 + 8) MOD 8
                IF RND < .1 THEN ad(i) = (ad(i) + INT(RND * 3) - 1 + 8) MOD 8   ' a little wobble
            END IF
        ELSE
            ' RETURNING: head roughly toward the nest, laying scent
            ph(ax(i), ay(i)) = ph(ax(i), ay(i)) + 40
            IF ph(ax(i), ay(i)) > 240 THEN ph(ax(i), ay(i)) = 240
            sx = SGN(NESTX - ax(i)): sy = SGN(NESTY - ay(i))
            IF RND < .25 THEN sx = INT(RND * 3) - 1    ' not perfectly straight
            FOR d = 0 TO 7
                IF ddx(d) = sx AND ddy(d) = sy THEN ad(i) = d
            NEXT
        END IF
        ' ---- take the step (stay inside the map) --------------------
        nx = ax(i) + ddx(ad(i)): ny = ay(i) + ddy(ad(i))
        IF nx >= 0 AND nx < GW AND ny >= 0 AND ny < GH THEN ax(i) = nx: ay(i) = ny
        ' ---- found food? reached home? ------------------------------
        IF carry(i) = 0 AND food(ax(i), ay(i)) > 0 THEN
            food(ax(i), ay(i)) = food(ax(i), ay(i)) - 1
            carry(i) = 1: ad(i) = (ad(i) + 4) MOD 8
            cx = ax(i): cy = ay(i): GOSUB DrawCell
        ELSEIF carry(i) = 1 AND ABS(ax(i) - NESTX) <= 1 AND ABS(ay(i) - NESTY) <= 1 THEN
            carry(i) = 0: stored& = stored& + 1: ad(i) = (ad(i) + 4) MOD 8
        END IF
        ' draw the ant as a 2x2 dot in the middle of its cell
        IF carry(i) THEN c = 14 ELSE c = 12
        LINE (ax(i) * CS + 1, ay(i) * CS + 1)-(ax(i) * CS + 2, ay(i) * CS + 2), c, BF
    NEXT

    ' ---- evaporation: a few rows per frame to keep things fast ------
    FOR rr = 1 TO 6
        cy = evRow
        FOR cx = 0 TO GW - 1
            IF ph(cx, cy) > 0 THEN
                ph(cx, cy) = ph(cx, cy) - evapRate * 2
                IF ph(cx, cy) < 0 THEN ph(cx, cy) = 0
                GOSUB DrawCell
            END IF
        NEXT
        evRow = (evRow + 1) MOD GH
    NEXT
    LOCATE 25, 1: COLOR 15
    PRINT USING "Food stored ##### F=food E=evap ESC"; stored&;
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' DrawCell: paint cell (cx, cy) as nest, food, or scent level
' ------------------------------------------------------------
DrawCell:
    IF ABS(cx - NESTX) <= 1 AND ABS(cy - NESTY) <= 1 THEN
        c = 6
    ELSEIF food(cx, cy) > 0 THEN
        c = 2: IF food(cx, cy) > 10 THEN c = 10
    ELSE
        c = 16 + ph(cx, cy) \ 16
    END IF
    LINE (cx * CS, cy * CS)-(cx * CS + CS - 1, cy * CS + CS - 1), c, BF
RETURN

' ------------------------------------------------------------
' AddFood: a round pile of crumbs away from the nest
' ------------------------------------------------------------
AddFood:
    DO
        fx = 5 + INT(RND * (GW - 10)): fy = 5 + INT(RND * (GH - 10))
    LOOP WHILE ABS(fx - NESTX) + ABS(fy - NESTY) < 20
    FOR y = fy - 3 TO fy + 3: FOR x = fx - 3 TO fx + 3
        IF (x - fx) ^ 2 + (y - fy) ^ 2 <= 9 THEN
            food(x, y) = food(x, y) + 15
            cx = x: cy = y: GOSUB DrawCell
        END IF
    NEXT: NEXT
RETURN
