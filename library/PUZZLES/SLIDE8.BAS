' ============================================================
' TITLE:    8-Puzzle with IDA* Solver
' CATEGORY: Puzzles & Logic
' LEVEL:    Advanced
' TAGS:     sliding puzzle, ida-star, heuristic search, recursion, game
' SUMMARY:  Play the classic 3x3 sliding tile puzzle, then let IDA* search find the SHORTEST solution and play it back.
' ------------------------------------------------------------
' WHAT IT DOES
'   Eight numbered tiles slide around a 3x3 frame with one gap.
'   Put them back in order 1-8 with the gap at the bottom right.
'
'   The solver uses IDA* ("iterative deepening A-star"):
'     * For every position it estimates how many moves are still
'       needed: the MANHATTAN DISTANCE - for each tile, how many rows
'       plus columns it is away from home.  This guess never
'       over-estimates, because each move shifts one tile one step.
'     * It does a depth-first search but cuts off any branch where
'       (moves so far + estimate) is bigger than a limit.
'     * If nothing is found it raises the limit and tries again.
'   The first solution found is guaranteed to be as short as possible,
'   yet the search needs almost no memory.
'
' HOW TO USE
'   Arrow keys slide a tile into the gap.
'   S = solve (watch the optimal moves)   N = new shuffle
'   Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Heuristic search: A* and IDA*
'   * Admissible heuristics (estimates that never overshoot)
'   * Updating the heuristic incrementally instead of recomputing
'   * Recursion with a shared path array
'
' THINGS TO TRY
'   * Replace Manhattan distance with "number of misplaced tiles"
'     and compare node counts - the weaker guess is much slower.
'   * Half of all arrangements are impossible to solve.  Swap two
'     tiles in the start position and find out why (parity!).
' ============================================================
DECLARE FUNCTION Dfs% (g AS INTEGER, prevDir AS INTEGER)
DECLARE SUB DrawBoard (msg$)
DECLARE SUB MoveBlank (d AS INTEGER)
DECLARE FUNCTION Manhattan% ()
DEFINT A-Z

DIM SHARED b(8)              ' b(pos) = tile number, 0 = gap
DIM SHARED blank             ' position of the gap (0..8)
DIM SHARED md(8, 8)          ' md(tile, pos) = Manhattan distance home
DIM SHARED h                 ' current heuristic value
DIM SHARED bound, nextBound, nodes&
DIM SHARED path(80)          ' moves of the solution being built
DIM start(8)                 ' copy of the board before solving
DIM SHARED dRow(3), dCol(3)  ' gap moves: 0 up, 1 down, 2 left, 3 right
dRow(0) = -1: dRow(1) = 1: dCol(2) = -1: dCol(3) = 1

' Tile t belongs at position t-1 (row (t-1)\3, column (t-1) MOD 3).
FOR t = 1 TO 8
    FOR p = 0 TO 8
        md(t, p) = ABS((t - 1) \ 3 - p \ 3) + ABS((t - 1) MOD 3 - p MOD 3)
    NEXT
NEXT

RANDOMIZE TIMER
CLS
newGame = -1
DO
    IF newGame THEN
        ' Start solved and make 60 random gap moves: the result is
        ' always solvable (unlike a random arrangement).
        FOR i = 0 TO 7: b(i) = i + 1: NEXT: b(8) = 0: blank = 8
        last = -1
        FOR i = 1 TO 60
            DO
                d = INT(RND * 4)
                r = blank \ 3 + dRow(d): c = blank MOD 3 + dCol(d)
            LOOP UNTIL r >= 0 AND r <= 2 AND c >= 0 AND c <= 2 AND d <> (last XOR 1)
            MoveBlank d: last = d
        NEXT
        moves = 0: newGame = 0
    END IF
    DrawBoard "Moves:" + STR$(moves)
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    ' Pressing an arrow moves the TILE that way, so the gap goes the
    ' opposite way: Up arrow = gap moves down, etc.
    d = -1
    SELECT CASE UCASE$(k$)
        CASE CHR$(0) + "H": d = 1
        CASE CHR$(0) + "P": d = 0
        CASE CHR$(0) + "K": d = 3
        CASE CHR$(0) + "M": d = 2
        CASE "N": newGame = -1
        CASE "Q", CHR$(27): EXIT DO
        CASE "S"
            ' ---- IDA* main loop -------------------------------------
            DrawBoard "Thinking..."
            ' Keep a copy of the start: when Dfs% succeeds it leaves the
            ' board in the solved state.
            FOR i = 0 TO 8: start(i) = b(i): NEXT: startBlank = blank
            h = Manhattan%: bound = h: nodes& = 0
            found = (h = 0)
            DO UNTIL found
                nextBound = 999
                found = Dfs%(0, -1)
                IF NOT found THEN
                    LOCATE 20, 5: PRINT "Limit"; bound; "-> no luck, trying"; nextBound; "  "
                    bound = nextBound
                END IF
            LOOP
            LOCATE 20, 5: PRINT SPACE$(50)
            FOR i = 0 TO 8: b(i) = start(i): NEXT: blank = startBlank
            ' Replay the path; bound is now exactly the solution length.
            total = bound
            FOR i = 0 TO total - 1
                MoveBlank path(i)
                DrawBoard "Optimal solution: move" + STR$(i + 1) + " of" + STR$(total) + "  (" + LTRIM$(STR$(nodes&)) + " nodes searched)"
                t! = TIMER
                DO: LOOP UNTIL TIMER - t! > .4 OR TIMER < t!
            NEXT
            moves = 0
            LOCATE 22, 5: PRINT "Solved in"; total; "moves - nobody can do it in fewer! (any key)"
            DO: LOOP WHILE INKEY$ = ""
            LOCATE 22, 5: PRINT SPACE$(70)
    END SELECT
    IF d >= 0 THEN
        r = blank \ 3 + dRow(d): c = blank MOD 3 + dCol(d)
        IF r >= 0 AND r <= 2 AND c >= 0 AND c <= 2 THEN
            MoveBlank d: moves = moves + 1
            IF Manhattan% = 0 THEN
                DrawBoard "Solved in" + STR$(moves) + " moves!  Press any key."
                DO: LOOP WHILE INKEY$ = ""
                newGame = -1
            END IF
        END IF
    END IF
LOOP
CLS
END

FUNCTION Dfs% (g AS INTEGER, prevDir AS INTEGER)
    ' g = moves made so far on this branch.
    nodes& = nodes& + 1
    f = g + h
    IF f > bound THEN
        ' Too deep for this round; remember the smallest overshoot so
        ' the next round's limit is as small as possible.
        IF f < nextBound THEN nextBound = f
        Dfs% = 0: EXIT FUNCTION
    END IF
    IF h = 0 THEN Dfs% = -1: EXIT FUNCTION      ' solved!
    FOR d = 0 TO 3
        ' (d XOR 1) is the opposite direction: never undo the last move.
        IF d <> (prevDir XOR 1) OR prevDir < 0 THEN
            r = blank \ 3 + dRow(d): c = blank MOD 3 + dCol(d)
            IF r >= 0 AND r <= 2 AND c >= 0 AND c <= 2 THEN
                np = r * 3 + c
                tile = b(np)
                ' The tile moves from np to the old gap: adjust h only
                ' for that one tile instead of recomputing everything.
                dh = md(tile, blank) - md(tile, np)
                oldBlank = blank
                b(oldBlank) = tile: b(np) = 0: blank = np: h = h + dh
                path(g) = d
                IF Dfs%(g + 1, d) THEN Dfs% = -1: EXIT FUNCTION
                b(np) = tile: b(oldBlank) = 0: blank = oldBlank: h = h - dh
            END IF
        END IF
    NEXT
    Dfs% = 0
END FUNCTION

SUB DrawBoard (msg$)
    LOCATE 2, 5: COLOR 14: PRINT "THE 8-PUZZLE": COLOR 7
    FOR p = 0 TO 8
        r = p \ 3: c = p MOD 3
        IF b(p) = 0 THEN
            COLOR 0, 0
        ELSEIF b(p) = p + 1 THEN
            COLOR 15, 2                     ' green = tile is home
        ELSE
            COLOR 15, 4
        END IF
        FOR y = 0 TO 2
            LOCATE 4 + r * 4 + y, 5 + c * 10: PRINT SPACE$(9);
        NEXT
        IF b(p) THEN LOCATE 5 + r * 4, 9 + c * 10: PRINT CHR$(48 + b(p));
        COLOR 7, 0
    NEXT
    LOCATE 17, 5: PRINT LEFT$(msg$ + SPACE$(70), 70)
    LOCATE 24, 5: PRINT "Arrows = slide   S = solve   N = new shuffle   Q = quit";
END SUB

FUNCTION Manhattan%
    s = 0
    FOR p = 0 TO 8
        IF b(p) THEN s = s + md(b(p), p)
    NEXT
    Manhattan% = s
END FUNCTION

SUB MoveBlank (d AS INTEGER)
    ' Swap the gap with its neighbour in direction d.
    np = (blank \ 3 + dRow(d)) * 3 + blank MOD 3 + dCol(d)
    b(blank) = b(np): b(np) = 0: blank = np
END SUB
