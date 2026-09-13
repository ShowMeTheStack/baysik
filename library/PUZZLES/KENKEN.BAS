' ============================================================
' TITLE:    KenKen Mini Solver
' CATEGORY: Puzzles & Logic
' LEVEL:    Advanced
' TAGS:     kenken, latin square, constraints, backtracking, pruning
' SUMMARY:  Draws a KenKen arithmetic puzzle with its cages and animates a backtracking solver that cracks it.
' ------------------------------------------------------------
' WHAT IT DOES
'   KenKen is like Sudoku with sums.  On an n x n grid each row and
'   column holds 1..n exactly once (a "Latin square").  Thick borders
'   group cells into CAGES; each cage shows a target and an operation:
'       7+   the cells add up to 7
'       2-   the two cells differ by 2
'       12x  the cells multiply to 12
'       2/   one cell is twice the other
'       3    a single cell that must hold 3
'   The program draws the puzzle, then fills cells one by one.  When a
'   guess breaks a rule it is erased (you'll see digits flicker) and
'   the next digit is tried.  Finally it checks whether the solution
'   is UNIQUE, which every good puzzle must be.
'
' HOW TO USE
'   Choose puzzle 1 (4x4) or 2 (5x5).  Press F during solving to skip
'   the animation.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Describing a puzzle with DATA (a letter map plus a cage list)
'   * Constraint checking with early pruning:
'       - a partial sum must not already exceed the target
'       - a partial product must divide the target
'   * Box-drawing characters (CHR$ 186, 205) for a neat grid
'
' THINGS TO TRY
'   * Design your own cages in the DATA lines.  Does the solver say
'     your puzzle is unique?
'   * Add a 6x6 puzzle (raise MAXN and the arrays).
' ============================================================
DECLARE FUNCTION Solve% (k AS INTEGER)
DECLARE FUNCTION CageOK% (cg AS INTEGER)
DECLARE SUB DrawGrid ()
DECLARE SUB ShowCell (r AS INTEGER, c AS INTEGER, col AS INTEGER)
DEFINT A-Z

CONST MAXN = 6
CONST X0 = 4, Y0 = 3                 ' screen position of the grid
DIM SHARED n
DIM SHARED cage(MAXN - 1, MAXN - 1)  ' which cage each cell belongs to
DIM SHARED g(MAXN - 1, MAXN - 1)     ' the digits, 0 = empty
DIM SHARED rowUsed(MAXN - 1, MAXN), colUsed(MAXN - 1, MAXN)
DIM SHARED op$(25), target(25), nCages
DIM SHARED sol(MAXN - 1, MAXN - 1)
DIM SHARED nSol, nodes&, animate, limit

DO
    CLS
    COLOR 14: PRINT "KENKEN MINI SOLVER": COLOR 7
    PRINT
    PRINT "  1) 4 x 4 puzzle     2) 5 x 5 puzzle     Q) Quit"
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF INSTR(a$, "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    IF a$ = "1" OR a$ = "2" THEN
        ' ---- Load the puzzle from DATA -----------------------------
        RESTORE PUZZLES
        FOR p = 1 TO VAL(a$)
            READ n
            FOR r = 0 TO n - 1
                READ row$
                FOR c = 0 TO n - 1: cage(r, c) = ASC(MID$(row$, c + 1, 1)) - 65: NEXT
            NEXT
            READ nCages
            FOR i = 0 TO nCages - 1: READ target(i), op$(i): NEXT
        NEXT
        FOR r = 0 TO n - 1: FOR c = 0 TO n - 1: g(r, c) = 0: NEXT: NEXT
        FOR i = 0 TO MAXN - 1: FOR d = 0 TO MAXN
            rowUsed(i, d) = 0: colUsed(i, d) = 0
        NEXT: NEXT

        CLS
        COLOR 14: PRINT " KENKEN"; n; "x"; n; " - press F to skip the animation": COLOR 7
        DrawGrid
        ' ---- Solve, counting up to 2 solutions ----------------------
        nSol = 0: nodes& = 0: animate = -1: limit = 2
        dummy = Solve%(0)
        ' Show the first solution in bright green.
        FOR r = 0 TO n - 1: FOR c = 0 TO n - 1
            g(r, c) = sol(r, c): ShowCell r, c, 10
        NEXT: NEXT
        LOCATE Y0 + 3 * n + 2, 1
        IF nSol = 0 THEN
            PRINT " No solution exists!"
        ELSEIF nSol = 1 THEN
            PRINT " Solved - and the solution is UNIQUE."
        ELSE
            PRINT " Solved - but there is MORE than one solution (not a fair puzzle)."
        END IF
        PRINT " Search nodes:"; nodes&
    END IF
    PRINT
    LINE INPUT " Press Enter (Q quits) "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

PUZZLES:
' Each puzzle: size, the cage map (one letter per cell), then the
' number of cages and a target + operation for cage A, B, C ...
DATA 4
DATA "AABB", "ACBD", "CCED", "FFED"
DATA 6
DATA 36,"x", 7,"+", 8,"x", 9,"+", 3,"x", 2,"x"
DATA 5
DATA "ABBCD", "EEFCD", "GFFHD", "GIIHJ", "KKLJJ"
DATA 12
DATA 2,"=", 15,"x", 4,"+", 20,"x", 9,"+", 24,"x"
DATA 4,"x", 7,"+", 2,"/", 24,"x", 3,"/", 5,"="

FUNCTION CageOK% (cg AS INTEGER)
    ' Check cage cg using only the cells filled in so far.
    cnt = 0: filled = 0: sum = 0: prod& = 1: hi = 0: lo = 99
    FOR r = 0 TO n - 1
        FOR c = 0 TO n - 1
            IF cage(r, c) = cg THEN
                cnt = cnt + 1
                v = g(r, c)
                IF v THEN
                    filled = filled + 1: sum = sum + v: prod& = prod& * v
                    IF v > hi THEN hi = v
                    IF v < lo THEN lo = v
                END IF
            END IF
        NEXT
    NEXT
    t = target(cg): ok = -1
    SELECT CASE op$(cg)
        CASE "+"
            ' Each empty cell adds at least 1, so the sum so far plus
            ' the number of empty cells may not exceed the target.
            IF sum + (cnt - filled) > t THEN ok = 0
            IF filled = cnt AND sum <> t THEN ok = 0
        CASE "x"
            ' The product so far must divide the target exactly.
            IF t MOD prod& <> 0 THEN ok = 0
            IF filled = cnt AND prod& <> t THEN ok = 0
        CASE "-"
            IF filled = cnt AND hi - lo <> t THEN ok = 0
        CASE "/"
            IF filled = cnt AND hi <> lo * t THEN ok = 0
        CASE "="
            IF filled = cnt AND sum <> t THEN ok = 0
    END SELECT
    CageOK% = ok
END FUNCTION

SUB DrawGrid
    ' Thick (double) lines between different cages, thin dim lines
    ' between cells of the same cage.
    FOR r = 0 TO n
        FOR c = 0 TO n
            y = Y0 + r * 3: x = X0 + c * 6
            COLOR 8: LOCATE y, x: PRINT "+";
            IF c < n THEN
                thick = (r = 0 OR r = n)
                IF NOT thick THEN thick = (cage(r - 1, c) <> cage(r, c))
                IF thick THEN COLOR 15: PRINT STRING$(5, 205); ELSE COLOR 8: PRINT " - - ";
            END IF
            IF r < n THEN
                thick = (c = 0 OR c = n)
                IF NOT thick THEN thick = (cage(r, c - 1) <> cage(r, c))
                FOR k = 1 TO 2
                    LOCATE y + k, x
                    IF thick THEN COLOR 15: PRINT CHR$(186); ELSE COLOR 8: PRINT CHR$(179);
                NEXT
            END IF
        NEXT
    NEXT
    ' Write each cage's clue in its first cell (reading order).
    DIM done(25)
    COLOR 14
    FOR r = 0 TO n - 1
        FOR c = 0 TO n - 1
            cg = cage(r, c)
            IF NOT done(cg) THEN
                done(cg) = -1
                LOCATE Y0 + r * 3 + 1, X0 + c * 6 + 1
                PRINT LTRIM$(STR$(target(cg)));
                IF op$(cg) <> "=" THEN PRINT op$(cg);
            END IF
        NEXT
    NEXT
    COLOR 7
END SUB

SUB ShowCell (r AS INTEGER, c AS INTEGER, col AS INTEGER)
    LOCATE Y0 + r * 3 + 2, X0 + c * 6 + 3
    COLOR col
    IF g(r, c) THEN PRINT CHR$(48 + g(r, c)); ELSE PRINT " ";
    COLOR 7
END SUB

FUNCTION Solve% (k AS INTEGER)
    ' Fill cell number k (reading order).  Returns -1 when we have
    ' found "limit" solutions and should stop everything.
    IF k = n * n THEN
        nSol = nSol + 1
        IF nSol = 1 THEN
            FOR r = 0 TO n - 1: FOR c = 0 TO n - 1: sol(r, c) = g(r, c): NEXT: NEXT
            animate = 0          ' no need to animate the uniqueness check
        END IF
        Solve% = (nSol >= limit)
        EXIT FUNCTION
    END IF
    r = k \ n: c = k MOD n
    FOR d = 1 TO n
        IF NOT rowUsed(r, d) AND NOT colUsed(c, d) THEN
            nodes& = nodes& + 1
            g(r, c) = d: rowUsed(r, d) = -1: colUsed(c, d) = -1
            IF animate THEN
                ShowCell r, c, 11
                IF UCASE$(INKEY$) = "F" THEN animate = 0
                t! = TIMER
                DO: LOOP UNTIL TIMER - t! > .02 OR TIMER < t!
            END IF
            IF CageOK%(cage(r, c)) THEN
                IF Solve%(k + 1) THEN Solve% = -1: EXIT FUNCTION
            END IF
            g(r, c) = 0: rowUsed(r, d) = 0: colUsed(c, d) = 0
            IF animate THEN ShowCell r, c, 11
        END IF
    NEXT
    Solve% = 0
END FUNCTION
