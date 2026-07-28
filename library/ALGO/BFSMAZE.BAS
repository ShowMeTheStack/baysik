' ============================================================
' TITLE:    Maze Maker and BFS Solver
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     maze, BFS, DFS, queue, stack, graphs, graphics
' SUMMARY:  Carve a random maze with a depth-first "drunk walk", then solve it with breadth-first search and trace the shortest path.
' ------------------------------------------------------------
' WHAT IT DOES
'   1. GENERATES a perfect maze (exactly one route between any two
'      points) with the "recursive backtracker": wander randomly,
'      knocking down walls, and back up (using a stack) when stuck.
'   2. SOLVES it with BREADTH-FIRST SEARCH from the top-left to the
'      bottom-right.  BFS explores in waves: first every cell 1 step
'      away, then 2 steps, and so on, so the first time it reaches the
'      exit it has found the SHORTEST route.  The wave is coloured by
'      distance so you can see it spread.
'   3. Follows the parent links back from the exit and draws the path.
'
' HOW TO USE
'   Watch.  At the end press N for a new maze, Q or Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Mazes as graphs: open cells are nodes, openings are edges
'   * DFS with an explicit stack (generation)
'   * BFS with a queue, distances and parent pointers (solving)
'   * Why BFS gives shortest paths in unweighted graphs
'   * Both run in O(cells)
'
' THINGS TO TRY
'   * Solve with a stack instead of a queue - is the path still
'     shortest?  (In a perfect maze, yes - why?)
'   * Knock down a few extra walls to create loops, then compare
'     BFS and DFS again
' ============================================================
DECLARE SUB Generate ()
DECLARE SUB Solve ()
DECLARE SUB Block (x%, y%, c%)
DEFINT A-Z
CONST MW = 39, MH = 23                 ' maze size in blocks (odd numbers)
CONST WALL = 0, PATH = 1
DIM SHARED m(0 TO MW - 1, 0 TO MH - 1)
DIM SHARED qx(1 TO MW * MH), qy(1 TO MW * MH)      ' stack / queue
DIM SHARED dist(0 TO MW - 1, 0 TO MH - 1), par(0 TO MW - 1, 0 TO MH - 1)
DIM SHARED dx(0 TO 3), dy(0 TO 3), quit
dx(0) = 1: dx(1) = -1: dy(2) = 1: dy(3) = -1

SCREEN 13
RANDOMIZE TIMER
DO
    CLS
    Generate
    IF quit THEN EXIT DO
    Solve
    IF quit THEN EXIT DO
    LOCATE 25, 1: PRINT "N=new maze  Q=quit";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "N" OR k$ = "Q" OR k$ = CHR$(27)
LOOP WHILE k$ = "N"
SCREEN 0: WIDTH 80
END

' 8 x 8 pixel block for maze cell (x, y)
SUB Block (x, y, c)
    LINE (x * 8, y * 8)-(x * 8 + 7, y * 8 + 7), c, BF
END SUB

' --------------------------------------------------------------
' Generate: the maze lives on a grid where cells with EVEN x and y
' (0,0), (2,0), (0,2)... are "rooms" and everything else starts as
' wall.  Joining two rooms means clearing the wall block between
' them.
'   push the start room, mark it open
'   while the stack is not empty:
'     look at the room on top of the stack
'     pick a random neighbour room (2 blocks away) still unvisited
'     if there is one: clear the wall between, mark it, push it
'     else: pop (back up - this is the "backtracking")
' Every room gets visited once and joined once -> a tree, so there
' is exactly one path between any two rooms: a "perfect" maze.
' --------------------------------------------------------------
SUB Generate
    FOR y = 0 TO MH - 1: FOR x = 0 TO MW - 1: m(x, y) = WALL: NEXT x, y
    LINE (0, 0)-(MW * 8 - 1, MH * 8 - 1), 6, BF   ' brown = solid rock
    sp = 1: qx(1) = 0: qy(1) = 0                  ' sp = stack pointer
    m(0, 0) = PATH: Block 0, 0, 7
    DIM opts(0 TO 3)
    DO WHILE sp > 0
        cx = qx(sp): cy = qy(sp)
        ' collect the directions that lead to unvisited rooms
        n = 0
        FOR d = 0 TO 3
            nx = cx + dx(d) * 2: ny = cy + dy(d) * 2
            IF nx >= 0 AND nx < MW AND ny >= 0 AND ny < MH THEN
                IF m(nx, ny) = WALL THEN opts(n) = d: n = n + 1
            END IF
        NEXT
        IF n = 0 THEN
            sp = sp - 1                            ' dead end: back up
        ELSE
            d = opts(INT(RND * n))                 ' random direction
            m(cx + dx(d), cy + dy(d)) = PATH       ' knock down the wall
            Block cx + dx(d), cy + dy(d), 7
            nx = cx + dx(d) * 2: ny = cy + dy(d) * 2
            m(nx, ny) = PATH: Block nx, ny, 7
            sp = sp + 1: qx(sp) = nx: qy(sp) = ny  ' push the new room
            FOR t& = 1 TO 80: NEXT
        END IF
        IF INKEY$ = CHR$(27) THEN quit = -1: EXIT SUB
    LOOP
END SUB

' --------------------------------------------------------------
' Solve with BFS.
'   dist(start) = 0, put start in the queue
'   while the queue is not empty:
'     take the OLDEST cell from the front of the queue
'     for each open neighbour not seen yet:
'        dist = dist + 1, parent = this cell, add it to the back
' Because cells leave the queue in order of distance, the first time
' we reach the goal its distance is the smallest possible.
' --------------------------------------------------------------
SUB Solve
    FOR y = 0 TO MH - 1: FOR x = 0 TO MW - 1: dist(x, y) = -1: NEXT x, y
    gx = MW - 1: gy = MH - 1
    head = 1: tail = 1: qx(1) = 0: qy(1) = 0: dist(0, 0) = 0
    DO WHILE head <= tail
        cx = qx(head): cy = qy(head): head = head + 1
        ' colour by distance: one of the 24 rainbow colours 32..55
        Block cx, cy, 32 + (dist(cx, cy) \ 4) MOD 24
        IF cx = gx AND cy = gy THEN EXIT DO           ' reached the exit
        FOR d = 0 TO 3
            nx = cx + dx(d): ny = cy + dy(d)
            IF nx >= 0 AND nx < MW AND ny >= 0 AND ny < MH THEN
                IF m(nx, ny) = PATH AND dist(nx, ny) = -1 THEN
                    dist(nx, ny) = dist(cx, cy) + 1
                    par(nx, ny) = d                   ' the move that got us here
                    tail = tail + 1: qx(tail) = nx: qy(tail) = ny
                END IF
            END IF
        NEXT
        FOR t& = 1 TO 60: NEXT
        IF INKEY$ = CHR$(27) THEN quit = -1: EXIT SUB
    LOOP
    ' Walk back from the goal: par() says which way we CAME, so we
    ' step the opposite way until we are home.
    x = gx: y = gy
    DO
        Block x, y, 15                     ' white = the shortest path
        IF x = 0 AND y = 0 THEN EXIT DO
        d = par(x, y)
        x = x - dx(d): y = y - dy(d)
        FOR t& = 1 TO 300: NEXT
    LOOP
    LOCATE 24, 1
    PRINT "Shortest path:"; dist(gx, gy); "steps, explored"; head - 1;
END SUB
