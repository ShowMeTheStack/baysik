' ============================================================
' TITLE:    Union-Find and Percolation
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     union-find, disjoint sets, graphs, simulation, graphics
' SUMMARY:  Track groups that merge with the union-find structure, then use it to watch water percolate through a random grid.
' ------------------------------------------------------------
' WHAT IT DOES
'   Part 1 - FRIEND GROUPS: ten people make friends one pair at a
'   time.  After each "union" the parent() array is printed, so you
'   can see the forest of little trees that union-find maintains, and
'   the number of separate groups.
'   Part 2 - PERCOLATION: a 40 x 22 grid starts all blocked.  Random
'   cells open one by one; open neighbours are joined with union.
'   Two extra "virtual" nodes stand for the whole top row and the
'   whole bottom row.  The moment FIND(top) = FIND(bottom), water can
'   flow from top to bottom - the grid "percolates".  Physicists know
'   this happens when about 59% of cells are open.
'
' HOW TO USE
'   Press keys to step through Part 1.  Watch Part 2; press R to run
'   it again or Q / Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Disjoint sets: FIND (which group?) and UNION (merge groups)
'   * Each group is a tree; its root is the group's "name"
'   * Union by size: hang the smaller tree under the bigger one
'   * Path compression: point nodes straight at the root as we go
'   * With both tricks each operation is almost O(1)
'     (technically O(alpha(n)), and alpha(n) < 5 for any real n)
'
' THINGS TO TRY
'   * Turn off path compression and count the steps FIND takes
'   * Use union-find for Kruskal's minimum spanning tree algorithm
' ============================================================
DECLARE FUNCTION Find% (x%)
DECLARE SUB Union (a%, b%)
DECLARE SUB ShowParents (n%)
DECLARE SUB WaitKey ()
DEFINT A-Z
CONST GW = 40, GH = 22                 ' percolation grid
CONST NN = GW * GH + 2                 ' cells + virtual top + bottom
DIM SHARED parent(0 TO NN), size(0 TO NN), groups
DIM SHARED nm$(0 TO 9)

' ====================== PART 1 ==============================
DATA Ann,Bob,Cy,Dee,Eve,Fay,Gus,Hal,Ivy,Jo
FOR i = 0 TO 9: READ nm$(i): NEXT
' At the start everyone is their own group: parent(i) = i means
' "I am a root".  size() counts the members of each root's group.
FOR i = 0 TO 9: parent(i) = i: size(i) = 1: NEXT
groups = 10
COLOR 7, 0: CLS
COLOR 15: PRINT "UNION-FIND: FRIEND GROUPS": COLOR 7
PRINT "parent(i) = i means i is the root (leader) of its group."
PRINT
ShowParents 10
DATA 0,1, 2,3, 4,5, 1,3, 6,7, 8,9, 5,7, 0,7, 3,6
FOR s = 1 TO 9
    WaitKey
    READ a, b
    PRINT
    PRINT nm$(a); " and "; nm$(b); " become friends: ";
    IF Find(a) = Find(b) THEN
        PRINT "already in the same group!"
    ELSE
        PRINT "merge groups led by "; nm$(Find(a)); " and "; nm$(Find(b))
        Union a, b
    END IF
    ShowParents 10
NEXT
PRINT
PRINT "Same group?  Ann & Jo:";
IF Find(0) = Find(9) THEN PRINT " yes" ELSE PRINT " no"
PRINT "             Bob & Hal:";
IF Find(1) = Find(7) THEN PRINT " yes" ELSE PRINT " no"
PRINT : PRINT "Press a key for the percolation experiment..."
WaitKey

' ====================== PART 2 ==============================
SCREEN 13
RANDOMIZE TIMER
DIM openCell(0 TO GW * GH - 1)
DIM order(0 TO GW * GH - 1)
top = GW * GH: bottom = GW * GH + 1      ' the two virtual nodes
DO
    CLS
    FOR i = 0 TO NN: parent(i) = i: size(i) = 1: NEXT
    FOR i = 0 TO GW * GH - 1: openCell(i) = 0: order(i) = i: NEXT
    ' Shuffle the cell numbers so cells open in random order
    ' (Fisher-Yates shuffle: swap each item with a random earlier one).
    FOR i = GW * GH - 1 TO 1 STEP -1
        j = INT(RND * (i + 1)): SWAP order(i), order(j)
    NEXT
    LINE (0, 0)-(GW * 8 - 1, GH * 8 - 1), 8, BF      ' grey = blocked
    opened = 0
    FOR s = 0 TO GW * GH - 1
        c = order(s)
        x = c MOD GW: y = c \ GW
        openCell(c) = -1: opened = opened + 1
        LINE (x * 8, y * 8)-(x * 8 + 7, y * 8 + 7), 15, BF   ' white = open
        ' join with the virtual nodes and any open neighbours
        IF y = 0 THEN Union c, top
        IF y = GH - 1 THEN Union c, bottom
        IF x > 0 THEN IF openCell(c - 1) THEN Union c, c - 1
        IF x < GW - 1 THEN IF openCell(c + 1) THEN Union c, c + 1
        IF y > 0 THEN IF openCell(c - GW) THEN Union c, c - GW
        IF y < GH - 1 THEN IF openCell(c + GW) THEN Union c, c + GW
        IF s MOD 10 = 0 THEN
            LOCATE 24, 1
            PRINT USING "Open: ###.#%"; opened * 100! / (GW * GH);
        END IF
        IF Find(top) = Find(bottom) THEN EXIT FOR      ' it percolates!
        IF INKEY$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
    NEXT
    ' Colour every open cell that is connected to the top in blue:
    ' that is where the water has reached.
    rt = Find(top)
    FOR c = 0 TO GW * GH - 1
        IF openCell(c) THEN
            IF Find(c) = rt THEN
                x = c MOD GW: y = c \ GW
                LINE (x * 8, y * 8)-(x * 8 + 7, y * 8 + 7), 9, BF
            END IF
        END IF
    NEXT
    LOCATE 24, 1
    PRINT USING "Percolates at ##.#% open."; opened * 100! / (GW * GH)
    PRINT "R = again, Q = quit  (theory: 59.3%)";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "R" OR k$ = "Q" OR k$ = CHR$(27)
LOOP WHILE k$ = "R"
SCREEN 0: WIDTH 80
END

' --------------------------------------------------------------
' FIND: follow parent links up to the root.  Then walk the path a
' second time and point every node DIRECTLY at the root ("path
' compression"), so the next FIND on any of them takes one step.
' --------------------------------------------------------------
FUNCTION Find (x)
    r = x
    DO WHILE parent(r) <> r: r = parent(r): LOOP     ' find the root
    n = x
    DO WHILE parent(n) <> r                            ' compress
        nxt = parent(n): parent(n) = r: n = nxt
    LOOP
    Find = r
END FUNCTION

' --------------------------------------------------------------
' UNION: find both roots; if different, hang the SMALLER tree under
' the bigger one ("union by size").  This keeps the trees shallow:
' a node's depth only grows when its group at least doubles, so no
' tree is ever deeper than log2(n).
' --------------------------------------------------------------
SUB Union (a, b)
    ra = Find(a): rb = Find(b)
    IF ra = rb THEN EXIT SUB
    IF size(ra) < size(rb) THEN SWAP ra, rb
    parent(rb) = ra
    size(ra) = size(ra) + size(rb)
    groups = groups - 1
END SUB

SUB ShowParents (n)
    PRINT "  i      ";
    FOR i = 0 TO n - 1: PRINT USING "\  \"; nm$(i); : NEXT
    PRINT
    PRINT "  parent ";
    FOR i = 0 TO n - 1
        IF parent(i) = i THEN COLOR 14 ELSE COLOR 7   ' roots in yellow
        PRINT USING "\  \"; nm$(parent(i));
    NEXT
    COLOR 7: PRINT "  groups:"; groups
END SUB

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
END SUB
