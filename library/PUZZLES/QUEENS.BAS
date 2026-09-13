' ============================================================
' TITLE:    Eight Queens - All 92 Solutions
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     chess, queens, backtracking, recursion, combinatorics
' SUMMARY:  Finds every way to place 8 queens so none attack each other, then lets you flip through all 92.
' ------------------------------------------------------------
' WHAT IT DOES
'   Place eight chess queens on a board so that no two share a row,
'   column or diagonal.  The program uses recursive backtracking to
'   find ALL the answers, stores them, and shows them one at a time.
'   First it prints a table of how many solutions exist for boards
'   of size 1 to 10 - notice how quickly the numbers grow.
'
' HOW TO USE
'   Press any key after the table.  Then:
'     N or Right arrow / Space  = next solution
'     P or Left arrow           = previous solution
'     Q or Esc                  = quit
'
' CONCEPTS YOU WILL LEARN
'   * Backtracking: place, recurse, remove
'   * Diagonal tricks: on one diagonal "row+col" is constant, on the
'     other "row-col" is constant, so a single array marks each one
'   * Storing results in a 2-D array for later browsing
'   * Reading arrow keys from INKEY$ (two-character codes)
'
' THINGS TO TRY
'   * Count how many of the 92 are just rotations/reflections of each
'     other (there are only 12 "fundamental" solutions).
'   * Raise the table to N = 12 and time it.
' ============================================================
DECLARE SUB PlaceRow (r AS INTEGER)
DECLARE SUB ShowSolution (k AS INTEGER)
DEFINT A-Z

CONST MAXN = 12
DIM SHARED n                        ' current board size
DIM SHARED q(1 TO MAXN)             ' q(r) = column of the queen in row r
DIM SHARED colUsed(1 TO MAXN)       ' -1 if some queen is in that column
DIM SHARED d1(2 TO 2 * MAXN)        ' "/" diagonals, indexed by r + c
DIM SHARED d2(-MAXN TO MAXN)        ' "\" diagonals, indexed by r - c
DIM SHARED count&                   ' solutions found
DIM SHARED store                    ' -1 = save each solution
DIM SHARED sols(1 TO 92, 1 TO 8)    ' all solutions for n = 8

CLS
COLOR 14: PRINT "N-QUEENS: how many ways to place N peaceful queens?": COLOR 7
PRINT
PRINT "   N   solutions"
PRINT "  --   ---------"
FOR n = 1 TO 10
    count& = 0: store = (n = 8)
    PlaceRow 1
    PRINT USING "  ##   #########"; n; count&
NEXT
PRINT
PRINT "  (N=2 and N=3 are impossible!)"
PRINT : PRINT "  Press any key to browse the 92 solutions for N = 8..."
DO: k$ = INKEY$: LOOP WHILE k$ = ""
IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN CLS : END

n = 8: k = 1
DO
    ShowSolution k
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    SELECT CASE UCASE$(k$)
        CASE "N", " ", CHR$(0) + "M", CHR$(13)
            k = k MOD 92 + 1                 ' wrap 92 -> 1
        CASE "P", CHR$(0) + "K"
            k = (k + 90) MOD 92 + 1          ' wrap 1 -> 92
        CASE "Q", CHR$(27)
            EXIT DO
    END SELECT
LOOP
CLS
END

SUB PlaceRow (r AS INTEGER)
    ' Try to put a queen somewhere in row r.  Rows 1..r-1 are done.
    IF r > n THEN
        ' All rows filled: one more solution!
        count& = count& + 1
        IF store THEN
            FOR i = 1 TO 8: sols(count&, i) = q(i): NEXT
        END IF
        EXIT SUB
    END IF
    FOR c = 1 TO n
        ' A square is safe if its column and both diagonals are free.
        IF NOT colUsed(c) AND NOT d1(r + c) AND NOT d2(r - c) THEN
            q(r) = c
            colUsed(c) = -1: d1(r + c) = -1: d2(r - c) = -1
            PlaceRow r + 1                      ' solve the rest
            colUsed(c) = 0: d1(r + c) = 0: d2(r - c) = 0   ' backtrack
        END IF
    NEXT
END SUB

SUB ShowSolution (k AS INTEGER)
    ' Draw solution number k as a checkered board.
    CLS
    COLOR 14: PRINT "  Solution"; k; "of 92": COLOR 7
    PRINT
    FOR r = 1 TO 8
        PRINT "  ";
        FOR c = 1 TO 8
            ' Light and dark squares alternate: (r + c) even = light.
            IF (r + c) MOD 2 = 0 THEN COLOR 0, 7 ELSE COLOR 7, 1
            IF sols(k, r) = c THEN
                IF (r + c) MOD 2 = 0 THEN COLOR 4 ELSE COLOR 14
                PRINT " Q ";
            ELSE
                PRINT "   ";
            END IF
        NEXT
        COLOR 7, 0: PRINT
    NEXT
    PRINT
    ' Also show the compact form: the column of the queen in each row.
    PRINT "  Columns by row: ";
    FOR r = 1 TO 8: PRINT CHR$(96 + sols(k, r)); : NEXT
    PRINT
    PRINT
    PRINT "  N/Space = next   P = previous   Q = quit"
END SUB
