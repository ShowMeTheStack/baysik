' ============================================================
' TITLE:    Dijkstra's Shortest Path
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     graphs, shortest path, dijkstra, grids, graphics
' SUMMARY:  Find the cheapest route across grass, forest and mountains as Dijkstra's algorithm settles cells in order of distance.
' ------------------------------------------------------------
' WHAT IT DOES
'   Generates a random terrain map.  Entering a cell costs:
'       grass 1 (green)   forest 3 (dark green)   mountain 8 (brown)
'   and water (blue) cannot be entered.  Dijkstra's algorithm finds
'   the cheapest route from the top-left corner (S) to the
'   bottom-right corner (G).  Settled cells are shaded as the search
'   spreads, so you can see it explore cheap terrain first.  Then the
'   best path is drawn in yellow with its total cost.
'
' HOW TO USE
'   Watch the search.  Then press N for a new map, Q or Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * A grid as a graph: each cell is a node, neighbours are edges
'   * Dijkstra: always settle the unsettled node with smallest distance
'   * "Relaxing" an edge: dist(v) = min(dist(v), dist(u) + cost(v))
'   * Recording each node's predecessor to rebuild the path
'   * This simple version is O(V^2); a priority queue makes it
'     O(E log V) - and with a heuristic it becomes A* search
'
' THINGS TO TRY
'   * Make mountains cost 50 - does the path avoid them more?
'   * Allow diagonal moves (8 neighbours)
' ============================================================
DECLARE SUB NewMap ()
DECLARE SUB DrawCell (i%, shade%)
DEFINT A-Z
CONST W = 24, H = 16, CS = 24          ' grid size and cell size (pixels)
CONST V = W * H                        ' number of nodes
CONST INF = 32000
' Cells are numbered 0 .. V-1:  node = y * W + x.  This lets us use
' simple 1-D arrays for everything.
DIM SHARED cost(0 TO V - 1)            ' 1, 3, 8 or 0 (= water)
DIM SHARED dist(0 TO V - 1)            ' best known distance from S
DIM SHARED prev(0 TO V - 1)            ' previous node on best path
DIM SHARED done(0 TO V - 1)            ' settled? (distance is final)
DIM dx(1 TO 4), dy(1 TO 4)
dx(1) = 1: dx(2) = -1: dy(3) = 1: dy(4) = -1

SCREEN 12
RANDOMIZE TIMER
DO
    NewMap
    start = 0: goal = V - 1

    ' -------- Dijkstra ------------------------------------------
    ' 1. dist(S) = 0, every other dist = infinity, nothing settled.
    ' 2. Repeat: pick the UNSETTLED node u with the smallest dist.
    '    Its distance can never improve (all costs are positive, so
    '    any other route would already be longer) -> settle it.
    ' 3. For each neighbour v of u: if going through u is cheaper,
    '    i.e. dist(u) + cost(v) < dist(v), update dist(v) and
    '    remember prev(v) = u.  This is called RELAXING the edge.
    ' Stop when the goal is settled or nothing reachable is left.
    FOR i = 0 TO V - 1: dist(i) = INF: prev(i) = -1: done(i) = 0: NEXT
    dist(start) = 0
    settled = 0
    DO
        ' --- step 2: linear scan for the closest unsettled node ---
        ' (V steps each time, V times -> O(V^2).  A heap would find
        '  it in O(log V), which matters for big maps.)
        u = -1: best = INF
        FOR i = 0 TO V - 1
            IF NOT done(i) AND dist(i) < best THEN best = dist(i): u = i
        NEXT
        IF u = -1 THEN EXIT DO                ' nothing reachable left
        done(u) = -1: settled = settled + 1
        IF u <> start AND u <> goal THEN DrawCell u, -1
        IF u = goal THEN EXIT DO
        ' --- step 3: relax the 4 neighbours ---
        ux = u MOD W: uy = u \ W
        FOR d = 1 TO 4
            nx = ux + dx(d): ny = uy + dy(d)
            IF nx >= 0 AND nx < W AND ny >= 0 AND ny < H THEN
                v2 = ny * W + nx
                IF cost(v2) > 0 AND NOT done(v2) THEN
                    IF dist(u) + cost(v2) < dist(v2) THEN
                        dist(v2) = dist(u) + cost(v2)
                        prev(v2) = u
                    END IF
                END IF
            END IF
        NEXT
        IF INKEY$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
    LOOP

    ' -------- Draw the path by following prev() back from G -----
    LOCATE 27, 1
    IF dist(goal) >= INF THEN
        PRINT "No route! Water blocks the way.            "
    ELSE
        n = goal: steps = 0
        DO WHILE n <> -1
            x = (n MOD W) * CS + CS \ 2: y = (n \ W) * CS + CS \ 2
            LINE (x - 4, y - 4)-(x + 4, y + 4), 14, BF   ' a yellow dot
            IF prev(n) <> -1 THEN
                px = (prev(n) MOD W) * CS + CS \ 2: py = (prev(n) \ W) * CS + CS \ 2
                LINE (x, y)-(px, py), 14
            END IF
            n = prev(n): steps = steps + 1
        LOOP
        PRINT "Path cost"; dist(goal); "  steps"; steps - 1; "  cells settled"; settled; "of"; V
    END IF
    PRINT "N = new map,  Q = quit";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "N" OR k$ = "Q" OR k$ = CHR$(27)
LOOP WHILE k$ = "N"
SCREEN 0: WIDTH 80
END

' Draws cell i in its terrain colour.  shade = -1 marks it settled
' (drawn with a dotted pattern so the terrain is still visible).
SUB DrawCell (i, shade)
    x = (i MOD W) * CS: y = (i \ W) * CS
    SELECT CASE cost(i)
        CASE 0: c = 1          ' water
        CASE 1: c = 10         ' grass
        CASE 3: c = 2          ' forest
        CASE ELSE: c = 6       ' mountain
    END SELECT
    LINE (x, y)-(x + CS - 2, y + CS - 2), c, BF
    IF shade THEN
        ' a grey frame inside the cell = "settled by Dijkstra"
        LINE (x + 3, y + 3)-(x + CS - 5, y + CS - 5), 7, B
        LINE (x + 6, y + 6)-(x + CS - 8, y + CS - 8), 8, BF
    END IF
END SUB

' Random terrain built from blobs so it looks like real land.
SUB NewMap
    CLS
    FOR i = 0 TO V - 1: cost(i) = 1: NEXT
    FOR b = 1 TO 22
        cx = INT(RND * W): cy = INT(RND * H): r = INT(RND * 3) + 1
        SELECT CASE INT(RND * 5)
            CASE 0, 1: t = 3            ' forest
            CASE 2, 3: t = 8            ' mountain
            CASE ELSE: t = 0: r = 1     ' small lake (so a route usually exists)
        END SELECT
        FOR y = cy - r TO cy + r
            FOR x = cx - r TO cx + r
                IF x >= 0 AND x < W AND y >= 0 AND y < H THEN
                    IF (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r + 1 THEN cost(y * W + x) = t
                END IF
            NEXT
        NEXT
    NEXT
    cost(0) = 1: cost(V - 1) = 1                ' S and G are always land
    FOR i = 0 TO V - 1: DrawCell i, 0: NEXT
    LOCATE 1, 1: PRINT "S";
    LOCATE (H - 1) * CS \ 16 + 1, (W - 1) * CS \ 8 + 1: PRINT "G";
    ' legend on the right
    LOCATE 2, 75: PRINT "1";
    LOCATE 4, 75: PRINT "3";
    LOCATE 6, 75: PRINT "8";
    LOCATE 8, 74: PRINT "no";
    LINE (600, 16)-(615, 31), 10, BF
    LINE (600, 48)-(615, 63), 2, BF
    LINE (600, 80)-(615, 95), 6, BF
    LINE (600, 112)-(615, 127), 1, BF
END SUB
