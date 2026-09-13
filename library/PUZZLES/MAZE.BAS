' ============================================================
' TITLE:    Maze Generator & Solver
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     maze, depth-first search, stack, bfs, graphics, animation
' SUMMARY:  Carves a perfect maze with the recursive-backtracker algorithm, then floods it with BFS to find the way out.
' ------------------------------------------------------------
' WHAT IT DOES
'   GENERATING: start in a corner, knock down the wall to a random
'   unvisited neighbour, move there, repeat.  When every neighbour is
'   already visited, back up (pop the stack) until a cell has unvisited
'   neighbours again.  This "recursive backtracker" makes a PERFECT
'   maze: exactly one path between any two cells, no loops.
'
'   SOLVING: breadth-first search spreads out from the entrance like
'   water, one step at a time (blue).  When it reaches the exit we
'   follow the "came from" arrows back to draw the shortest path
'   (yellow).
'
' HOW TO USE
'   S = solve   N = new maze   F = fast/slow animation   Q/Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Depth-first search with an explicit stack (no recursion limits)
'   * Breadth-first search with a queue
'   * Storing walls as bits: 1 = North, 2 = East, 4 = South, 8 = West
'   * SCREEN 12 graphics with LINE ... BF
'
' THINGS TO TRY
'   * Change CS (cell size) for bigger or smaller mazes.
'   * Remove a few extra walls at random to make loops, then see that
'     BFS still finds the SHORTEST way.
'   * Use a queue instead of a stack when generating: what changes?
' ============================================================
DECLARE SUB Generate ()
DECLARE SUB Solve ()
DECLARE SUB FillCell (x AS INTEGER, y AS INTEGER, col AS INTEGER)
DECLARE SUB OpenWall (x AS INTEGER, y AS INTEGER, d AS INTEGER, col AS INTEGER)
DECLARE SUB Pause ()
DEFINT A-Z

CONST CS = 20              ' cell size in pixels
CONST W = 31, H = 22       ' maze size in cells
CONST OX = 10, OY = 20     ' top-left corner of the maze on screen

DIM SHARED walls(W - 1, H - 1)  ' bits of the walls still standing
DIM SHARED seen(W - 1, H - 1)
DIM SHARED from(W - 1, H - 1)   ' BFS: direction we arrived from
DIM SHARED dx(3), dy(3), bit(3), opp(3)
DIM SHARED fast, quit
' Direction 0 = North, 1 = East, 2 = South, 3 = West
dx(0) = 0: dy(0) = -1: bit(0) = 1: opp(0) = 2
dx(1) = 1: dy(1) = 0: bit(1) = 2: opp(1) = 3
dx(2) = 0: dy(2) = 1: bit(2) = 4: opp(2) = 0
dx(3) = -1: dy(3) = 0: bit(3) = 8: opp(3) = 1

RANDOMIZE TIMER
SCREEN 12
Generate
DO
    LOCATE 30, 1: PRINT "S = solve   N = new maze   F = fast/slow   Q = quit";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
        CASE "S": Solve
        CASE "N": Generate
        CASE "F": fast = NOT fast
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
    IF quit THEN EXIT DO
LOOP
SCREEN 0: WIDTH 80: CLS
END

SUB FillCell (x AS INTEGER, y AS INTEGER, col AS INTEGER)
    ' The inside of a cell, leaving a 2-pixel border for walls.
    LINE (OX + x * CS + 2, OY + y * CS + 2)-(OX + x * CS + CS - 2, OY + y * CS + CS - 2), col, BF
END SUB

SUB Generate
    DIM stackX(W * H), stackY(W * H)
    DIM choice(3)
    CLS
    COLOR 14: LOCATE 1, 2: PRINT "Generating with a recursive backtracker...";
    ' Every cell starts with all 4 walls and unvisited.
    FOR y = 0 TO H - 1: FOR x = 0 TO W - 1
        walls(x, y) = 15: seen(x, y) = 0
    NEXT: NEXT
    sp = 1: stackX(1) = 0: stackY(1) = 0: seen(0, 0) = -1
    FillCell 0, 0, 7
    DO WHILE sp > 0
        x = stackX(sp): y = stackY(sp)
        ' Collect the directions that lead to unvisited cells.
        n = 0
        FOR d = 0 TO 3
            nx = x + dx(d): ny = y + dy(d)
            IF nx >= 0 AND nx < W AND ny >= 0 AND ny < H THEN
                IF NOT seen(nx, ny) THEN choice(n) = d: n = n + 1
            END IF
        NEXT
        IF n = 0 THEN
            sp = sp - 1                      ' dead end: backtrack
            FillCell x, y, 7                 ' turn grey = finished
        ELSE
            d = choice(INT(RND * n))         ' random unvisited neighbour
            nx = x + dx(d): ny = y + dy(d)
            ' Knock down the wall on BOTH sides.
            walls(x, y) = walls(x, y) AND NOT bit(d)
            walls(nx, ny) = walls(nx, ny) AND NOT bit(opp(d))
            seen(nx, ny) = -1
            OpenWall x, y, d, 7
            FillCell nx, ny, 12              ' red = the current head
            sp = sp + 1: stackX(sp) = nx: stackY(sp) = ny
            FillCell x, y, 7
            Pause
            IF quit THEN EXIT SUB
        END IF
    LOOP
    ' Mark the entrance (green) and the exit (red).
    FillCell 0, 0, 10: FillCell W - 1, H - 1, 12
    LOCATE 1, 2: PRINT SPACE$(60);
    LOCATE 1, 2: PRINT "A perfect maze of"; W * H; "cells.  Green = start, red = goal.";
END SUB

SUB OpenWall (x AS INTEGER, y AS INTEGER, d AS INTEGER, col AS INTEGER)
    ' Paint the gap between cell (x,y) and its neighbour in direction d.
    px = OX + x * CS: py = OY + y * CS
    SELECT CASE d
        CASE 0: LINE (px + 2, py - 2)-(px + CS - 2, py + 2), col, BF
        CASE 1: LINE (px + CS - 2, py + 2)-(px + CS + 2, py + CS - 2), col, BF
        CASE 2: LINE (px + 2, py + CS - 2)-(px + CS - 2, py + CS + 2), col, BF
        CASE 3: LINE (px - 2, py + 2)-(px + 2, py + CS - 2), col, BF
    END SELECT
END SUB

SUB Pause
    ' Short delay so we can watch; Esc quits, F toggles speed.
    k$ = UCASE$(INKEY$)
    IF k$ = CHR$(27) OR k$ = "Q" THEN quit = -1
    IF k$ = "F" THEN fast = NOT fast
    IF fast THEN EXIT SUB
    t! = TIMER
    DO: LOOP UNTIL TIMER - t! > .01 OR TIMER < t!
END SUB

SUB Solve
    DIM qx(W * H), qy(W * H)
    FOR y = 0 TO H - 1: FOR x = 0 TO W - 1: seen(x, y) = 0: NEXT: NEXT
    head = 0: tail = 1: qx(0) = 0: qy(0) = 0: seen(0, 0) = -1
    DO WHILE head < tail
        x = qx(head): y = qy(head): head = head + 1
        IF x = W - 1 AND y = H - 1 THEN EXIT DO     ' reached the goal!
        FOR d = 0 TO 3
            ' We can move in direction d only if that wall is gone.
            IF (walls(x, y) AND bit(d)) = 0 THEN
                nx = x + dx(d): ny = y + dy(d)
                IF NOT seen(nx, ny) THEN
                    seen(nx, ny) = -1: from(nx, ny) = d
                    qx(tail) = nx: qy(tail) = ny: tail = tail + 1
                    FillCell nx, ny, 9: OpenWall x, y, d, 9
                END IF
            END IF
        NEXT
        IF head MOD 4 = 0 THEN Pause
        IF quit THEN EXIT SUB
    LOOP
    ' Walk back from the goal using from() to paint the path.
    x = W - 1: y = H - 1: steps = 0
    FillCell x, y, 14
    DO UNTIL x = 0 AND y = 0
        d = from(x, y)
        px = x - dx(d): py = y - dy(d)   ' the cell we came from
        OpenWall px, py, d, 14
        x = px: y = py: FillCell x, y, 14
        steps = steps + 1
    LOOP
    LOCATE 1, 2: PRINT SPACE$(70);
    LOCATE 1, 2: PRINT "Shortest path:"; steps; "steps.  BFS visited"; tail; "of"; W * H; "cells.";
END SUB
