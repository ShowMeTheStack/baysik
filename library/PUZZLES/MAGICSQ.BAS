' ============================================================
' TITLE:    Magic Square Builder
' CATEGORY: Puzzles & Logic
' LEVEL:    Intermediate
' TAGS:     magic square, math, arrays, algorithms, number puzzles
' SUMMARY:  Builds a magic square of any size from 3 to 16 using three classic methods, then proves it is magic.
' ------------------------------------------------------------
' WHAT IT DOES
'   A magic square holds the numbers 1..n*n so that every row, every
'   column and both long diagonals add up to the same "magic sum":
'          M = n * (n*n + 1) / 2        (15 for a 3x3 square)
'   There is no single recipe that works for every size, so we use
'   three different ones:
'     * ODD n (3,5,7...):  the Siamese method - go up-and-right,
'                          and step down when blocked.
'     * n divisible by 4:  write 1..n*n in order, then flip the
'                          numbers on the diagonals of each 4x4 block.
'     * other EVEN n (6,10,14): Strachey's method - build four odd
'                          squares and swap some cells between them.
'   Afterwards the program adds every line to check its work.
'
' HOW TO USE
'   Type a size from 3 to 16 and press Enter.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Wrapping around the edges with MOD
'   * Splitting a problem into cases with SELECT CASE
'   * Building a big answer out of smaller copies (Strachey)
'   * Verifying a result instead of trusting it
'
' THINGS TO TRY
'   * There is no 2x2 magic square - can you see why?
'   * Rotate or mirror the square: is it still magic?
'   * Add a constant to every cell - what happens to the sum?
' ============================================================
DECLARE SUB OddSquare (sz AS INTEGER, r0 AS INTEGER, c0 AS INTEGER, add AS INTEGER)
DECLARE SUB Doubly ()
DECLARE SUB Singly ()
DECLARE FUNCTION Verify% ()
DEFINT A-Z

CONST MAXN = 16
DIM SHARED n
DIM SHARED sq(1 TO MAXN, 1 TO MAXN)

DO
    CLS
    COLOR 14: PRINT "MAGIC SQUARE BUILDER": COLOR 7
    PRINT
    LINE INPUT "Size of square, 3 to 16 (Q quits): "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    n = VAL(a$)
    IF n = 2 THEN
        PRINT : PRINT "A 2x2 magic square is impossible: a+b = a+c forces b = c!"
    ELSEIF n = 1 THEN
        PRINT : PRINT "The 1x1 square [1] is magic - but rather boring."
    ELSEIF n < 3 OR n > MAXN THEN
        PRINT : PRINT "Please choose a size from 3 to 16."
    ELSE
        ' Start with an empty (all zero) square - the Siamese method
        ' uses 0 to mean "this cell is still free".
        FOR r = 1 TO MAXN: FOR c = 1 TO MAXN: sq(r, c) = 0: NEXT: NEXT
        ' Choose the method based on the size.
        SELECT CASE n MOD 4
            CASE 1, 3
                method$ = "Siamese (odd)"
                OddSquare n, 0, 0, 0
            CASE 0
                method$ = "diagonal flip (doubly even)"
                Doubly
            CASE 2
                method$ = "Strachey (singly even)"
                Singly
        END SELECT

        ' Print the square.  Use 4 columns per number when n*n > 99.
        PRINT
        PRINT "Method: "; method$; "    magic sum ="; n * (n * n + 1) \ 2
        PRINT
        IF n * n > 99 THEN f$ = "####" ELSE f$ = "###"
        FOR r = 1 TO n
            FOR c = 1 TO n
                ' Colour cells by size so patterns stand out.
                COLOR 9 + (sq(r, c) - 1) * 6 \ (n * n)
                PRINT USING f$; sq(r, c);
            NEXT
            PRINT
        NEXT
        COLOR 7
        PRINT
        IF Verify% THEN
            COLOR 10: PRINT "Checked: 1 to"; n * n; "used once, all"; 2 * n + 2; "lines add up."
        ELSE
            COLOR 12: PRINT "Oops - something is not magic!"
        END IF
        COLOR 7
    END IF
    PRINT
    LINE INPUT "Press Enter for another (Q quits) "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

SUB Doubly
    ' 1. Fill in reading order: 1, 2, 3 ...
    ' 2. Split into 4x4 blocks.  A cell lies on a block diagonal when
    '    (r MOD 4 = c MOD 4) or ((r MOD 4) + (c MOD 4) = 3), counting
    '    from 0.  Those cells get replaced by  n*n + 1 - value.
    FOR r = 1 TO n
        FOR c = 1 TO n
            v = (r - 1) * n + c
            i = (r - 1) MOD 4: j = (c - 1) MOD 4
            IF i = j OR i + j = 3 THEN v = n * n + 1 - v
            sq(r, c) = v
        NEXT
    NEXT
END SUB

SUB OddSquare (sz AS INTEGER, r0 AS INTEGER, c0 AS INTEGER, add AS INTEGER)
    ' Siamese method for an odd sz x sz square, written into sq() with
    ' its top-left corner at (r0+1, c0+1) and "add" added to every
    ' number (Strachey's method needs these extras).
    r = 0: c = sz \ 2                   ' start in the middle of the top row
    FOR k = 1 TO sz * sz
        sq(r0 + r + 1, c0 + c + 1) = k + add
        ' Next spot: one up and one right, wrapping round the edges.
        nr = (r - 1 + sz) MOD sz: nc = (c + 1) MOD sz
        IF sq(r0 + nr + 1, c0 + nc + 1) > add THEN
            nr = (r + 1) MOD sz: nc = c   ' occupied -> go down instead
        END IF
        r = nr: c = nc
    NEXT
END SUB

SUB Singly
    ' n = 4k + 2.  Make four odd squares of size h = n/2:
    '    A (top-left)  numbers 1..h*h         C (top-right) + 2h*h
    '    D (bottom-left) + 3h*h               B (bottom-right) + h*h
    h = n \ 2: hh = h * h: k = (n - 2) \ 4
    FOR r = 1 TO n: FOR c = 1 TO n: sq(r, c) = 0: NEXT: NEXT
    OddSquare h, 0, 0, 0
    OddSquare h, h, h, hh
    OddSquare h, 0, h, 2 * hh
    OddSquare h, h, 0, 3 * hh
    ' Swap the leftmost k columns between A and D, except in the middle
    ' row where we shift one place right.  Then swap the rightmost k-1
    ' columns between C and B.
    FOR r = 1 TO h
        FOR c = 1 TO k
            cc = c
            IF r = h \ 2 + 1 THEN cc = c + 1   ' middle row is shifted
            SWAP sq(r, cc), sq(r + h, cc)
        NEXT
        FOR c = n - k + 2 TO n
            SWAP sq(r, c), sq(r + h, c)
        NEXT
    NEXT
END SUB

FUNCTION Verify%
    ' Add every row, column and diagonal; all must equal M.
    m& = CLNG(n) * (CLNG(n) * n + 1) \ 2
    ok = -1
    FOR i = 1 TO n
        rs& = 0: cs& = 0
        FOR j = 1 TO n
            rs& = rs& + sq(i, j): cs& = cs& + sq(j, i)
        NEXT
        IF rs& <> m& OR cs& <> m& THEN ok = 0
    NEXT
    d1& = 0: d2& = 0
    FOR i = 1 TO n
        d1& = d1& + sq(i, i): d2& = d2& + sq(i, n + 1 - i)
    NEXT
    IF d1& <> m& OR d2& <> m& THEN ok = 0
    ' Also make sure every number 1..n*n appears exactly once.
    DIM seen(1 TO MAXN * MAXN)
    FOR i = 1 TO n
        FOR j = 1 TO n
            v = sq(i, j)
            IF v < 1 OR v > n * n THEN
                ok = 0
            ELSEIF seen(v) THEN
                ok = 0
            ELSE
                seen(v) = -1
            END IF
        NEXT
    NEXT
    Verify% = ok
END FUNCTION
