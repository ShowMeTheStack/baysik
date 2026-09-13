' ============================================================
' TITLE:    Knight's Tour (Warnsdorff's Rule)
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     chess, knight, heuristic, greedy, graphs
' SUMMARY:  Watch a chess knight visit every square exactly once using a clever 200-year-old rule of thumb.
' ------------------------------------------------------------
' WHAT IT DOES
'   A knight moves in an "L": two squares one way, one square to the
'   side.  The Knight's Tour puzzle asks: can it visit EVERY square of
'   the board exactly once?  Trying all paths would take forever, but
'   in 1823 H. C. von Warnsdorff found a simple rule:
'
'       Always jump to the square that has the FEWEST onward moves.
'
'   Squares near edges and corners are hard to reach, so the rule
'   visits them early, before they get cut off.  On an 8x8 board this
'   greedy rule almost always finds a full tour with no backtracking.
'
' HOW TO USE
'   Enter a board size (5 to 10) and a starting square such as  a1
'   (letter = column, number = row).  The tour is drawn move by move.
'   Press Esc during the animation to skip to the end.
'   Type Q at a prompt to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Greedy algorithms and heuristics
'   * Move tables (DATA for the 8 knight jumps)
'   * 2-D arrays and bounds checking
'   * Tie-breaking and why heuristics can still fail
'
' THINGS TO TRY
'   * Use the MOST onward moves instead and watch it get stuck fast.
'   * On a 5x5 board, which starting squares succeed?  (Hint: colour!)
'   * Check if the last square is a knight's move from the first:
'     that makes it a "closed" tour.
' ============================================================
DECLARE FUNCTION Degree% (r AS INTEGER, c AS INTEGER)
DECLARE SUB DrawBoard ()
DECLARE SUB ShowSquare (r AS INTEGER, c AS INTEGER, hilite AS INTEGER)
DEFINT A-Z

CONST MAXN = 10
DIM SHARED n                       ' board size n x n
DIM SHARED b(1 TO MAXN, 1 TO MAXN) ' 0 = unvisited, else move number
DIM SHARED dr(7), dc(7)            ' the 8 knight jumps

' The eight L-shaped jumps as (row change, column change) pairs.
FOR i = 0 TO 7: READ dr(i), dc(i): NEXT
DATA -2,1, -1,2, 1,2, 2,1, 2,-1, 1,-2, -1,-2, -2,-1

DO
    CLS
    COLOR 14: PRINT "KNIGHT'S TOUR - Warnsdorff's rule": COLOR 7
    PRINT
    ' ---- Ask for the board size --------------------------------
    DO
        LINE INPUT "Board size 5-10 (Q quits): "; a$
        IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN CLS : END
        n = VAL(a$)
    LOOP UNTIL n >= 5 AND n <= MAXN
    ' ---- Ask for the starting square ----------------------------
    lastCol$ = CHR$(ASC("a") + n - 1)
    DO
        PRINT "Start square, a1 to "; lastCol$; LTRIM$(STR$(n));
        LINE INPUT " (Q quits): "; a$
        a$ = LCASE$(LTRIM$(RTRIM$(a$)))
        IF INSTR(a$, "q") OR INSTR(a$, CHR$(27)) THEN CLS : END
        sc = 0: sr = 0
        IF LEN(a$) >= 2 THEN
            sc = ASC(a$) - ASC("a") + 1       ' letter -> column number
            sr = VAL(MID$(a$, 2))              ' digits -> row number
        END IF
        ok = sc >= 1 AND sc <= n AND sr >= 1 AND sr <= n
        IF NOT ok THEN PRINT "  Please type something like b3."
    LOOP UNTIL ok

    ' ---- Run the tour ---------------------------------------------
    FOR r = 1 TO n: FOR c = 1 TO n: b(r, c) = 0: NEXT: NEXT
    CLS
    DrawBoard
    r = sr: c = sc: b(r, c) = 1
    ShowSquare r, c, 1
    skip = 0
    FOR moveNo = 2 TO n * n
        ' Look at every legal jump and pick the one whose target has
        ' the smallest "degree" (number of unvisited squares it could
        ' jump to next).  Ties go to the first one found.
        bestK = -1: bestD = 9
        FOR k = 0 TO 7
            nr = r + dr(k): nc = c + dc(k)
            IF nr >= 1 AND nr <= n AND nc >= 1 AND nc <= n THEN
                IF b(nr, nc) = 0 THEN
                    d = Degree%(nr, nc)
                    IF d < bestD THEN bestD = d: bestK = k
                END IF
            END IF
        NEXT
        IF bestK < 0 THEN EXIT FOR             ' stuck: no moves left
        ShowSquare r, c, 0                      ' un-highlight old square
        r = r + dr(bestK): c = c + dc(bestK)
        b(r, c) = moveNo
        ShowSquare r, c, 1
        ' Small pause so you can watch (Esc skips the animation).
        IF NOT skip THEN
            t! = TIMER
            DO
                k$ = INKEY$
                IF k$ = CHR$(27) THEN skip = -1
            LOOP UNTIL TIMER - t! > .12 OR TIMER < t! OR skip
        END IF
    NEXT
    ShowSquare r, c, 0

    LOCATE 2 + 2 * n + 2, 1
    visited = moveNo - 1
    IF moveNo > n * n THEN visited = n * n
    IF visited = n * n THEN
        COLOR 10: PRINT "Complete tour! All"; n * n; "squares visited.";
        ' Is the tour CLOSED (last square one jump from the first)?
        closed = 0
        FOR k = 0 TO 7
            IF r + dr(k) = sr AND c + dc(k) = sc THEN closed = -1
        NEXT
        IF closed THEN PRINT " It is even CLOSED." ELSE PRINT " (open tour)"
    ELSE
        COLOR 12: PRINT "Stuck after"; visited; "of"; n * n; "squares - the heuristic failed here."
    END IF
    COLOR 7
    LINE INPUT "Press Enter to try again (Q quits) "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

FUNCTION Degree% (r AS INTEGER, c AS INTEGER)
    ' Count the unvisited squares reachable from (r, c).
    cnt = 0
    FOR k = 0 TO 7
        nr = r + dr(k): nc = c + dc(k)
        IF nr >= 1 AND nr <= n AND nc >= 1 AND nc <= n THEN
            IF b(nr, nc) = 0 THEN cnt = cnt + 1
        END IF
    NEXT
    Degree% = cnt
END FUNCTION

SUB DrawBoard
    ' Draw the empty grid.  Row n is at the top, like a chess diagram.
    COLOR 14: PRINT "KNIGHT'S TOUR"; n; "x"; n: COLOR 7
    FOR r = n TO 1 STEP -1
        y = 2 + 2 * (n - r)
        LOCATE y, 4: PRINT STRING$(n * 4 + 1, "-")
        LOCATE y + 1, 1: PRINT USING "## "; r;
        FOR c = 1 TO n: PRINT "|   "; : NEXT: PRINT "|"
    NEXT
    LOCATE 2 + 2 * n, 4: PRINT STRING$(n * 4 + 1, "-")
    LOCATE 3 + 2 * n, 6
    FOR c = 1 TO n: PRINT CHR$(96 + c); "   "; : NEXT
END SUB

SUB ShowSquare (r AS INTEGER, c AS INTEGER, hilite AS INTEGER)
    ' Print the move number inside square (r, c).  The knight's
    ' current square is shown in reverse colours.
    LOCATE 3 + 2 * (n - r), 4 * c + 1
    IF hilite THEN COLOR 0, 14 ELSE COLOR 11, 0
    PRINT USING "###"; b(r, c);
    COLOR 7, 0
END SUB
