' ============================================================
' TITLE:    Matrix Workshop
' CATEGORY: Mathematics
' LEVEL:    Advanced
' TAGS:     matrices, linear algebra, determinant, inverse, arrays, SUB
' SUMMARY:  Multiplies matrices and finds determinants and inverses, with a check that A x A^-1 = I.
' ------------------------------------------------------------
' WHAT IT DOES
'   A matrix is a rectangular grid of numbers.  Matrices describe
'   things like rotations in computer graphics and systems of
'   equations.  This workshop shows three key operations on 3x3
'   matrices:
'     MULTIPLY     (A x B)(i,j) = row i of A "dot" column j of B
'     DETERMINANT  one number telling how much the matrix stretches
'                  space; 0 means it squashes it flat (no inverse)
'     INVERSE      the matrix A^-1 that "undoes" A:  A x A^-1 = I
'   The determinant uses expansion along the first row (cofactors);
'   the inverse uses Gauss-Jordan elimination on [A | I].
'
' HOW TO USE
'   Menu: 1 = demo with built-in matrices, 2 = type your own 3x3
'   matrix, Q = quit.
'
' CONCEPTS YOU WILL LEARN
'   * 2-D arrays and passing them to SUBs with  a()
'   * Triple-nested loops for matrix multiplication
'   * Row operations and pivoting (swap rows to avoid dividing by 0)
'   * Why A x B is usually NOT equal to B x A
'
' THINGS TO TRY
'   * Make N a variable and support 4x4 matrices
'   * Find a matrix whose determinant is 0 and see the inverse fail
'   * Build a rotation matrix with COS and SIN and check its det is 1
' ============================================================

DECLARE SUB ShowMat (title$, m#())
DECLARE SUB MatMul (a#(), b#(), c#())
DECLARE SUB Det3 (m#(), d#)
DECLARE SUB Inverse (a#(), inv#(), ok%)

CONST N = 3
DIM a#(1 TO N, 1 TO N), b#(1 TO N, 1 TO N), c#(1 TO N, 1 TO N), inv#(1 TO N, 1 TO N)

DO
    CLS
    COLOR 14: PRINT "MATRIX WORKSHOP": COLOR 7
    PRINT "1) Demo with built-in matrices"
    PRINT "2) Enter your own 3x3 matrix"
    PRINT "Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    CLS
    IF k$ = "1" THEN
        RESTORE MatData
        FOR i = 1 TO N: FOR j = 1 TO N: READ a#(i, j): NEXT j: NEXT i
        FOR i = 1 TO N: FOR j = 1 TO N: READ b#(i, j): NEXT j: NEXT i
        ShowMat "A", a#()
        ShowMat "B", b#()
        MatMul a#(), b#(), c#()
        ShowMat "A x B", c#()
        MatMul b#(), a#(), c#()
        ShowMat "B x A  (different! order matters)", c#()
        PRINT "Press a key...": k$ = INPUT$(1): CLS
    ELSEIF k$ = "2" THEN
        PRINT "Enter the matrix one row at a time (3 numbers separated by commas)."
        FOR i = 1 TO N
            PRINT "Row"; i;
            INPUT a#(i, 1), a#(i, 2), a#(i, 3)
        NEXT i
    ELSE
        GOTO Skip
    END IF

    ShowMat "A", a#()
    Det3 a#(), d#
    PRINT "det(A) ="; d#
    Inverse a#(), inv#(), ok%
    IF ok% THEN
        ShowMat "Inverse of A", inv#()
        MatMul a#(), inv#(), c#()
        ' Tiny values like 1E-17 are just rounding noise - clean them up.
        FOR i = 1 TO N: FOR j = 1 TO N
            IF ABS(c#(i, j)) < 1E-12 THEN c#(i, j) = 0
        NEXT j: NEXT i
        ShowMat "Check: A x inverse  (should be the identity I)", c#()
    ELSE
        COLOR 12: PRINT "A is SINGULAR (determinant 0): it has no inverse.": COLOR 7
    END IF
    PRINT "Press a key...": k$ = INPUT$(1)
Skip:
LOOP
END

MatData:
DATA 2, 1, 1
DATA 1, 3, 2
DATA 1, 0, 0
DATA 1, 2, 0
DATA 0, 1, 1
DATA 3, 0, 1

' Determinant by cofactor expansion along row 1:
'   det = a11(a22 a33 - a23 a32) - a12(a21 a33 - a23 a31) + a13(a21 a32 - a22 a31)
' Each bracket is the determinant of a 2x2 "minor".
SUB Det3 (m#(), d#)
    d# = m#(1, 1) * (m#(2, 2) * m#(3, 3) - m#(2, 3) * m#(3, 2)) - m#(1, 2) * (m#(2, 1) * m#(3, 3) - m#(2, 3) * m#(3, 1)) + m#(1, 3) * (m#(2, 1) * m#(3, 2) - m#(2, 2) * m#(3, 1))
END SUB

' Gauss-Jordan: write [A | I] side by side, then use row operations to
' turn the left half into I.  The same operations turn the right half
' into A^-1.  Sets ok% = 0 (false) if A cannot be inverted.
SUB Inverse (a#(), inv#(), ok%)
    DIM w#(1 TO N, 1 TO 2 * N)           ' the augmented matrix [A | I]
    FOR i = 1 TO N
        FOR j = 1 TO N
            w#(i, j) = a#(i, j)
            IF i = j THEN w#(i, j + N) = 1 ELSE w#(i, j + N) = 0
        NEXT j
    NEXT i
    FOR col = 1 TO N
        ' Partial pivoting: use the row with the biggest number in this
        ' column.  Avoids dividing by zero and reduces rounding error.
        best = col
        FOR r = col + 1 TO N
            IF ABS(w#(r, col)) > ABS(w#(best, col)) THEN best = r
        NEXT r
        IF ABS(w#(best, col)) < 1E-12 THEN ok% = 0: EXIT SUB
        IF best <> col THEN
            FOR j = 1 TO 2 * N: SWAP w#(col, j), w#(best, j): NEXT j
        END IF
        ' Scale the pivot row so the pivot becomes 1.
        p# = w#(col, col)
        FOR j = 1 TO 2 * N: w#(col, j) = w#(col, j) / p#: NEXT j
        ' Subtract multiples of the pivot row to clear the column elsewhere.
        FOR r = 1 TO N
            IF r <> col THEN
                f# = w#(r, col)
                FOR j = 1 TO 2 * N: w#(r, j) = w#(r, j) - f# * w#(col, j): NEXT j
            END IF
        NEXT r
    NEXT col
    FOR i = 1 TO N: FOR j = 1 TO N: inv#(i, j) = w#(i, j + N): NEXT j: NEXT i
    ok% = -1
END SUB

' c = a x b.  Entry (i, j) is the sum of a(i,k) * b(k,j) over k:
' walk along row i of a and down column j of b, multiplying pairs.
SUB MatMul (a#(), b#(), c#())
    FOR i = 1 TO N
        FOR j = 1 TO N
            s# = 0
            FOR k = 1 TO N
                s# = s# + a#(i, k) * b#(k, j)
            NEXT k
            c#(i, j) = s#
        NEXT j
    NEXT i
END SUB

SUB ShowMat (title$, m#())
    COLOR 11: PRINT title$: COLOR 7
    FOR i = 1 TO N
        PRINT "  [";
        FOR j = 1 TO N
            PRINT USING " ####.####"; m#(i, j);
        NEXT j
        PRINT " ]"
    NEXT i
END SUB
