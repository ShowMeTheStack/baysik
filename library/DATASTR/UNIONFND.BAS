' ============================================================
' TITLE:    Union-Find Maze Maker
' CATEGORY: Data Structures
' LEVEL:    Advanced
' TAGS:     union-find, disjoint sets, Kruskal, maze generation, path compression
' SUMMARY:  Generates a perfect maze with Kruskal's algorithm, using a union-find (disjoint set) structure to avoid loops.
' ------------------------------------------------------------
' WHAT IT DOES
'   UNION-FIND keeps track of which items are in the same GROUP.
'   It answers two questions very fast:
'       FIND(x)      - which group is x in? (returns a "leader")
'       UNION(a, b)  - merge a's group with b's group
'   Each item stores a PARENT index. Following parents upward
'   leads to the group leader (an item that is its own parent).
'
'   Two tricks make it almost instant:
'     * UNION BY RANK - hang the shorter tree under the taller one
'     * PATH COMPRESSION - after a FIND, point every item we passed
'       straight at the leader, so next time is one step
'
'   Making a maze: start with every cell walled off (each cell its
'   own group). Visit the walls in random order. Knock a wall down
'   only if the cells on each side are in DIFFERENT groups, then
'   union them. This never makes a loop, and at the end all cells
'   are in one group - a "perfect" maze with exactly one path
'   between any two cells. (This is Kruskal's algorithm.)
'
' HOW TO USE
'   Watch the maze being carved. Then press N for a new maze,
'   or Q / Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Parent-pointer trees stored in an array
'   * Path compression and union by rank
'   * Shuffling a list (Fisher-Yates)
'   * Counting groups as they merge
'
' THINGS TO TRY
'   * Switch off path compression and count the steps FIND takes
'   * Colour each cell by its group leader while carving
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Find% (x AS INTEGER)
DECLARE FUNCTION Union% (a AS INTEGER, b AS INTEGER)

CONST MW = 19, MH = 10                 ' maze size in cells
CONST NCELL = MW * MH
CONST NWALL = (MW - 1) * MH + MW * (MH - 1)
DIM SHARED parent(1 TO NCELL), rnk(1 TO NCELL), steps AS LONG
DIM wallA(1 TO NWALL), wallB(1 TO NWALL)
RANDOMIZE TIMER

DO
    CLS
    ' ---- every cell starts as its own one-member group ---------
    FOR i = 1 TO NCELL: parent(i) = i: rnk(i) = 0: NEXT i
    groups = NCELL: steps = 0

    ' ---- list every internal wall as a pair of cells -----------
    ' Cell number for column x, row y (both from 0) = y*MW + x + 1
    nw = 0
    FOR y = 0 TO MH - 1
        FOR x = 0 TO MW - 1
            c = y * MW + x + 1
            IF x < MW - 1 THEN nw = nw + 1: wallA(nw) = c: wallB(nw) = c + 1
            IF y < MH - 1 THEN nw = nw + 1: wallA(nw) = c: wallB(nw) = c + MW
        NEXT x
    NEXT y
    ' ---- Fisher-Yates shuffle: random order of walls -----------
    FOR i = nw TO 2 STEP -1
        j = INT(RND * i) + 1
        SWAP wallA(i), wallA(j): SWAP wallB(i), wallB(j)
    NEXT i

    ' ---- draw the fully walled grid ----------------------------
    ' Text grid is (2*MW+1) x (2*MH+1); cells sit at odd positions.
    ' Each grid position is drawn 2 characters wide.
    COLOR 6
    FOR gy = 0 TO 2 * MH
        LOCATE 2 + gy, 2
        FOR gx = 0 TO 2 * MW
            IF gx MOD 2 = 1 AND gy MOD 2 = 1 THEN PRINT "  "; ELSE PRINT CHR$(219); CHR$(219);
        NEXT gx
    NEXT gy
    COLOR 7
    LOCATE 1, 2: PRINT "UNION-FIND MAZE MAKER (Kruskal's algorithm)";

    ' ---- Kruskal: knock down walls between different groups -----
    removed = 0
    FOR i = 1 TO nw
        a = wallA(i): b = wallB(i)
        IF Union%(a, b) THEN
            groups = groups - 1: removed = removed + 1
            ' Find the wall's grid position: halfway between cells.
            ax = (a - 1) MOD MW: ay = (a - 1) \ MW
            bx = (b - 1) MOD MW: by = (b - 1) \ MW
            gx = ax + bx + 1: gy = ay + by + 1
            LOCATE 2 + gy, 2 + gx * 2: PRINT "  ";
            LOCATE 24, 2: PRINT "Groups left:"; groups; "  walls removed:"; removed; "  find steps:"; steps; "   ";
            ' a tiny pause so you can watch it carve
            t! = TIMER: DO: LOOP WHILE TIMER - t! < .01 AND TIMER >= t!
            k$ = INKEY$
            IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN EXIT DO
        END IF
        IF groups = 1 THEN EXIT FOR
    NEXT i
    ' Open an entrance and an exit.
    LOCATE 3, 2: PRINT "  ";
    LOCATE 2 + 2 * MH - 1, 2 + 4 * MW: PRINT "  ";
    LOCATE 24, 2
    PRINT "Done! 1 group,"; removed; "walls removed (always cells-1 ="; NCELL - 1; ")  ";
    LOCATE 25, 2: PRINT USING "Average FIND steps: #.##   N = new maze, Q = quit"; steps / (2 * i);
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "N" OR k$ = "Q" OR k$ = CHR$(27)
LOOP UNTIL k$ <> "N"
COLOR 7: CLS
END

' Find%: follow parents up to the leader, then compress the path.
FUNCTION Find% (x AS INTEGER)
    r = x
    DO WHILE parent(r) <> r
        r = parent(r): steps = steps + 1
    LOOP
    ' Path compression: second pass points everyone at r.
    y = x
    DO WHILE parent(y) <> r AND y <> r
        nx = parent(y): parent(y) = r: y = nx
    LOOP
    Find% = r
END FUNCTION

' Union%: merge the groups of a and b. Returns TRUE if they were
' separate (so a merge happened), FALSE if already together.
FUNCTION Union% (a AS INTEGER, b AS INTEGER)
    ra = Find%(a): rb = Find%(b)
    IF ra = rb THEN Union% = 0: EXIT FUNCTION
    ' Union by rank: the shallower tree goes under the deeper one.
    IF rnk(ra) < rnk(rb) THEN
        parent(ra) = rb
    ELSEIF rnk(ra) > rnk(rb) THEN
        parent(rb) = ra
    ELSE
        parent(rb) = ra: rnk(ra) = rnk(ra) + 1
    END IF
    Union% = -1
END FUNCTION
