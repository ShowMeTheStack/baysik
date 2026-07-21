' ============================================================
' TITLE:    Simultaneous Equation Solver
' CATEGORY: Mathematics
' LEVEL:    Advanced
' TAGS:     gaussian elimination, linear equations, matrices, algorithms
' SUMMARY:  Solves systems of up to 6 linear equations by Gaussian elimination, showing every stage.
' ------------------------------------------------------------
' WHAT IT DOES
'   A system like      2x +  y -  z =   8
'                     -3x -  y + 2z = -11
'                     -2x +  y + 2z =  -3
'   can be solved by GAUSSIAN ELIMINATION, invented in China around
'   200 BC and named after Carl Friedrich Gauss:
'     1. FORWARD ELIMINATION: use the first equation to remove x from
'        all equations below it, then use the second to remove y from
'        those below it, and so on.  You get a "staircase" (upper
'        triangular) system.
'     2. BACK SUBSTITUTION: the last equation now has one unknown -
'        solve it, put the answer into the one above, and climb up.
'   The program prints the augmented matrix after each elimination
'   step so you can follow along with pencil and paper.
'
' HOW TO USE
'   Choose 1 for the example above or 2 to type your own system.
'   For your own: give the number of unknowns, then each equation's
'   coefficients and right-hand side separated by commas.
'   Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Representing equations as an augmented matrix [A | b]
'   * Row operations that do not change the solutions
'   * Partial pivoting for accuracy, detecting singular systems
'   * Verifying a solution by substituting it back (residuals)
'
' THINGS TO TRY
'   * Enter two parallel lines: x + y = 1, x + y = 2 (no solution)
'   * Fit a parabola through 3 points by solving for a, b, c
'   * Count how many multiplications are needed for n equations (~n^3/3)
' ============================================================

DEFDBL A-Z
DEFINT I-J, N                       ' counters i, j and the size n are integers
DIM m(1 TO 6, 1 TO 7), orig(1 TO 6, 1 TO 7), x(1 TO 6)
DIM nm$(1 TO 6)
FOR i = 1 TO 6: READ nm$(i): NEXT i
DATA x, y, z, w, u, v

DO
    CLS
    COLOR 14: PRINT "SIMULTANEOUS EQUATION SOLVER (Gaussian elimination)": COLOR 7
    PRINT "1) Example: 3 equations    2) Enter your own    Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "1" THEN
        n = 3
        RESTORE Example
        FOR i = 1 TO n: FOR j = 1 TO n + 1: READ m(i, j): NEXT j: NEXT i
    ELSEIF k$ = "2" THEN
        DO
            INPUT "How many unknowns (2-6)"; n
        LOOP UNTIL n >= 2 AND n <= 6
        PRINT "For each equation type"; n; "coefficients then the right-hand side,"
        PRINT "separated by commas.  e.g. for 2x + y = 5 type  2,1,5"
        FOR i = 1 TO n
            PRINT "Equation"; i;
            LINE INPUT ": "; t$
            ' Pull numbers out of the comma separated text.
            t$ = t$ + ","
            FOR j = 1 TO n + 1
                c = INSTR(t$, ",")
                IF c = 0 THEN m(i, j) = 0 ELSE m(i, j) = VAL(LEFT$(t$, c - 1)): t$ = MID$(t$, c + 1)
            NEXT j
        NEXT i
    ELSE
        GOTO Again
    END IF

    ' Keep a copy for the final check.
    FOR i = 1 TO n: FOR j = 1 TO n + 1: orig(i, j) = m(i, j): NEXT j: NEXT i
    PRINT : PRINT "Starting system:"
    GOSUB ShowMatrix

    ' ---------------- forward elimination ----------------
    singular = 0
    FOR col = 1 TO n
        ' Pivot: pick the row (at or below col) with the largest value in
        ' this column and swap it up.  Swapping equations is harmless.
        best = col
        FOR r = col + 1 TO n
            IF ABS(m(r, col)) > ABS(m(best, col)) THEN best = r
        NEXT r
        IF ABS(m(best, col)) < 1E-10 THEN singular = 1: EXIT FOR
        IF best <> col THEN
            FOR j = 1 TO n + 1: SWAP m(col, j), m(best, j): NEXT j
        END IF
        ' Eliminate: row r = row r - factor * pivot row, which makes
        ' m(r, col) zero.  The factor is m(r,col) / m(col,col).
        FOR r = col + 1 TO n
            f = m(r, col) / m(col, col)
            FOR j = col TO n + 1
                m(r, j) = m(r, j) - f * m(col, j)
            NEXT j
        NEXT r
        IF col < n THEN
            PRINT "After clearing "; nm$(col); " below row"; col; ":"
            GOSUB ShowMatrix
        END IF
    NEXT col

    IF singular THEN
        COLOR 12
        PRINT "No unique solution: the equations are dependent or contradictory."
        COLOR 7
    ELSE
        ' ---------------- back substitution ----------------
        ' Row i now says: m(i,i)*x(i) + m(i,i+1)*x(i+1) + ... = m(i,n+1)
        ' and every x after x(i) is already known.
        FOR i = n TO 1 STEP -1
            s = m(i, n + 1)
            FOR j = i + 1 TO n
                s = s - m(i, j) * x(j)
            NEXT j
            x(i) = s / m(i, i)
        NEXT i
        COLOR 11: PRINT "Solution:": COLOR 15
        FOR i = 1 TO n
            ' Round tiny floating point fuzz for a cleaner display.
            v = x(i): IF ABS(v - CLNG(v)) < 1E-9 THEN v = CLNG(v)
            PRINT "   "; nm$(i); " ="; v
        NEXT i
        COLOR 7
        ' Residual check: plug the answers into the original equations.
        worst = 0
        FOR i = 1 TO n
            s = 0
            FOR j = 1 TO n: s = s + orig(i, j) * x(j): NEXT j
            IF ABS(s - orig(i, n + 1)) > worst THEN worst = ABS(s - orig(i, n + 1))
        NEXT i
        PRINT USING "Check: biggest error when substituted back = #.##^^^^"; worst
    END IF
    PRINT "Press a key...": k$ = INPUT$(1)
Again:
LOOP
END

Example:
DATA 2, 1, -1, 8
DATA -3, -1, 2, -11
DATA -2, 1, 2, -3

' Prints the augmented matrix [A | b] with a bar before the last column.
ShowMatrix:
    FOR i = 1 TO n
        PRINT "   ";
        FOR j = 1 TO n
            PRINT USING "####.### "; m(i, j);
        NEXT j
        PRINT "|";
        PRINT USING "####.###"; m(i, n + 1)
    NEXT i
    RETURN
