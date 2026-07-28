' ============================================================
' TITLE:    N-Queens Backtracking
' CATEGORY: Algorithms
' LEVEL:    Advanced
' TAGS:     backtracking, recursion, chess, graphics, search
' SUMMARY:  Watch a recursive search place queens, hit dead ends, back up and try again until no queen attacks another.
' ------------------------------------------------------------
' WHAT IT DOES
'   Place N chess queens on an N x N board so that no two share a
'   row, a column or a diagonal.  The program draws the board in
'   SCREEN 12 and animates the backtracking search: a queen is placed
'   (green), and when a row has no safe square the last queen is
'   removed (flashed red) and moved further along.  After the first
'   solution is found it counts ALL solutions at full speed.
'
' HOW TO USE
'   Type a board size from 4 to 10 (Enter = 8).  Watch the search,
'   press a key to count all solutions, then a key to finish.
'   + / - change the animation speed, Esc skips the animation.
'
' CONCEPTS YOU WILL LEARN
'   * Backtracking: try, recurse, undo ("choose, explore, un-choose")
'   * Pruning: stop exploring as soon as a partial board is invalid
'   * O(1) safety checks using column and diagonal flag arrays:
'       every square on a "/" diagonal has the same row + col,
'       every square on a "\" diagonal has the same row - col
'   * Recursive SUBs and SHARED state
'
' THINGS TO TRY
'   * Print how many queen placements the search tried in total
'   * Try N = 2 and N = 3: why are there no solutions?
' ============================================================
DECLARE SUB Solve (row%)
DECLARE SUB DrawSquare (r%, c%, mode%)
DEFINT A-Z
DIM SHARED n, q(1 TO 12)                  ' q(row) = column of that row's queen
DIM SHARED colUsed(1 TO 12), diag1(2 TO 24), diag2(-11 TO 11)
DIM SHARED animate, found, solutions&, tries&, delay&, sz

SCREEN 12
LINE INPUT "Board size 4-10 (Enter = 8): "; t$
n = VAL(t$)
IF n < 4 OR n > 10 THEN n = 8
sz = 400 \ n                               ' square size in pixels
CLS
FOR r = 1 TO n: FOR c = 1 TO n: DrawSquare r, c, 0: NEXT c, r
LOCATE 1, 60: PRINT n; "-Queens"
animate = -1: delay& = 3000

' ---- Phase 1: animated search for the first solution ----------
Solve 1
LOCATE 3, 60: PRINT "Placements tried:"
LOCATE 4, 60: PRINT tries&
LOCATE 6, 60: PRINT "First solution!"
LOCATE 7, 60: PRINT "Press a key to"
LOCATE 8, 60: PRINT "count them all."
DO: LOOP WHILE INKEY$ = ""

' ---- Phase 2: count every solution, no drawing ----------------
LOCATE 10, 60: PRINT "Counting..."
animate = 0: found = 0: solutions& = 0: tries& = 0
FOR i = 1 TO 12: colUsed(i) = 0: NEXT
FOR i = 2 TO 24: diag1(i) = 0: NEXT
FOR i = -11 TO 11: diag2(i) = 0: NEXT
t! = TIMER
Solve 1
LOCATE 10, 60: PRINT "Solutions:"; solutions&
LOCATE 11, 60: PRINT "Tries:"; tries&
LOCATE 12, 60: PRINT USING "Time: ##.# s"; TIMER - t!
LOCATE 14, 60: PRINT "Brute force would"
LOCATE 15, 60: PRINT "check"; CDBL(n) ^ n
LOCATE 16, 60: PRINT "boards!"
LOCATE 18, 60: PRINT "Press a key."
DO: LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
END

' mode 0 = empty, 1 = queen placed, 2 = queen being removed
SUB DrawSquare (r, c, mode)
    x = 20 + (c - 1) * sz: y = 40 + (r - 1) * sz
    IF (r + c) MOD 2 = 0 THEN bg = 7 ELSE bg = 6      ' light / brown
    LINE (x, y)-(x + sz - 1, y + sz - 1), bg, BF
    IF mode > 0 THEN
        IF mode = 1 THEN fg = 10 ELSE fg = 12
        cx = x + sz \ 2: cy = y + sz \ 2: rr = sz \ 3
        ' a simple queen: a crown of three circles on a filled body
        CIRCLE (cx, cy + rr \ 3), rr, fg
        PAINT (cx, cy + rr \ 3), fg, fg
        CIRCLE (cx - rr \ 2, cy - rr \ 2), rr \ 3, 15
        CIRCLE (cx, cy - rr * 2 \ 3), rr \ 3, 15
        CIRCLE (cx + rr \ 2, cy - rr \ 2), rr \ 3, 15
    END IF
END SUB

' --------------------------------------------------------------
' Solve tries to place queens in rows "row" .. n.
' Rows 1..row-1 already hold safe queens.
'   For every column c of this row:
'     if c's column and both diagonals are free:
'        place the queen, mark them used     (choose)
'        Solve row + 1                       (explore)
'        remove the queen, unmark them       (un-choose / backtrack)
' A row with NO safe column simply returns, which makes the caller
' move its queen to the next column - that is the backtracking.
' Worst case is exponential, but pruning makes it fast in practice.
' --------------------------------------------------------------
SUB Solve (row)
    IF row > n THEN                       ' all n queens placed!
        solutions& = solutions& + 1
        found = -1
        EXIT SUB
    END IF
    FOR c = 1 TO n
        IF NOT colUsed(c) AND NOT diag1(row + c) AND NOT diag2(row - c) THEN
            tries& = tries& + 1
            q(row) = c
            colUsed(c) = -1: diag1(row + c) = -1: diag2(row - c) = -1
            IF animate THEN
                DrawSquare row, c, 1
                FOR d& = 1 TO delay&: NEXT
                k$ = INKEY$
                IF k$ = "+" THEN delay& = delay& \ 2
                IF k$ = "-" THEN delay& = delay& * 2 + 100
                IF k$ = CHR$(27) THEN delay& = 0
            END IF
            Solve row + 1
            ' In phase 1 stop at the first solution and keep it drawn.
            IF animate AND found THEN EXIT SUB
            colUsed(c) = 0: diag1(row + c) = 0: diag2(row - c) = 0
            IF animate THEN
                DrawSquare row, c, 2              ' flash red: backing up
                FOR d& = 1 TO delay& \ 2: NEXT
                DrawSquare row, c, 0
            END IF
        END IF
    NEXT
END SUB
