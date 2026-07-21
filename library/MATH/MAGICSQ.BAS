' ============================================================
' TITLE:    Magic Square Maker
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     magic squares, 2-d arrays, algorithms, MOD, puzzles
' SUMMARY:  Builds magic squares of any odd size or multiple of 4 and proves every row, column and diagonal match.
' ------------------------------------------------------------
' WHAT IT DOES
'   A magic square of size n holds the numbers 1 to n*n so that every
'   row, every column and both diagonals add up to the same "magic
'   constant"  M = n * (n*n + 1) / 2.   (For n = 3, M = 15.)
'   Two classic recipes are used:
'     ODD n  - the "Siamese" method (de la Loubere, 1693): start in
'              the middle of the top row, always step up-and-right
'              (wrapping around the edges); if that cell is taken,
'              step down instead.
'     n = 4, 8, 12 - fill 1..n*n in order, then on the "diagonal
'              pattern" cells replace k by n*n + 1 - k.
'   The program then adds up every line to check the magic.
'
' HOW TO USE
'   Enter a size: odd (3, 5, 7, 9, 11) or a multiple of 4 (4, 8, 12).
'   Enter 0 to quit.
'
' CONCEPTS YOU WILL LEARN
'   * 2-D arrays and wrap-around indexing with MOD
'   * Following an algorithm exactly, step by step
'   * Checking your work automatically
'
' THINGS TO TRY
'   * Watch the Siamese method fill the square one number at a time
'   * Rotate or mirror a square - is it still magic?
'   * Add the "LUX" method for sizes like 6 and 10
' ============================================================

DEFINT A-Z
DIM sq(1 TO 12, 1 TO 12)

CLS
COLOR 14: PRINT "MAGIC SQUARE MAKER": COLOR 7
DO
    PRINT
    INPUT "Size (odd 3-11, or 4, 8, 12; 0 = quit)"; n
    IF n = 0 THEN EXIT DO
    IF n < 3 OR n > 12 OR (n MOD 2 = 0 AND n MOD 4 <> 0) THEN
        PRINT "Sorry, I can do odd sizes 3-11 and 4, 8, 12."
        GOTO NextSize
    END IF
    FOR r = 1 TO n: FOR c = 1 TO n: sq(r, c) = 0: NEXT c: NEXT r

    IF n MOD 2 = 1 THEN
        ' ---------- Siamese method ----------
        r = 1: c = (n + 1) \ 2               ' middle of the top row
        FOR k = 1 TO n * n
            sq(r, c) = k
            ' Try up-and-right.  Using MOD makes row 0 wrap to row n and
            ' column n+1 wrap to column 1 (the square is like a donut).
            nr = (r - 2 + n) MOD n + 1
            nc = c MOD n + 1
            IF sq(nr, nc) <> 0 THEN
                nr = r MOD n + 1             ' blocked: go straight down
                nc = c
            END IF
            r = nr: c = nc
        NEXT k
    ELSE
        ' ---------- Doubly even (multiple of 4) ----------
        ' Split into 4x4 blocks.  In each block, cells on its two
        ' diagonals are "flipped": k becomes n*n + 1 - k.
        k = 1
        FOR r = 1 TO n
            FOR c = 1 TO n
                rr = (r - 1) MOD 4: cc = (c - 1) MOD 4
                IF rr = cc OR rr + cc = 3 THEN
                    sq(r, c) = n * n + 1 - k
                ELSE
                    sq(r, c) = k
                END IF
                k = k + 1
            NEXT c
        NEXT r
    END IF

    ' ---------- Show it ----------
    magic = n * (n * n + 1) \ 2
    w = 4: IF n * n >= 100 THEN w = 5      ' column width
    f$ = STRING$(w, "#")
    PRINT
    FOR r = 1 TO n
        FOR c = 1 TO n
            ' Colour the diagonals so you can see them.
            IF r = c OR r + c = n + 1 THEN COLOR 11 ELSE COLOR 7
            PRINT USING f$; sq(r, c);
        NEXT c
        PRINT
    NEXT r
    COLOR 7

    ' ---------- Check it ----------
    ok = -1
    d1 = 0: d2 = 0
    FOR i = 1 TO n
        rs = 0: cs = 0
        FOR j = 1 TO n
            rs = rs + sq(i, j)                ' row i
            cs = cs + sq(j, i)                ' column i
        NEXT j
        IF rs <> magic OR cs <> magic THEN ok = 0
        d1 = d1 + sq(i, i)
        d2 = d2 + sq(i, n + 1 - i)
    NEXT i
    IF d1 <> magic OR d2 <> magic THEN ok = 0
    PRINT "Magic constant n(n^2+1)/2 ="; magic
    IF ok THEN
        COLOR 10: PRINT "Checked: all"; n; "rows,"; n; "columns and 2 diagonals add up to"; magic
    ELSE
        COLOR 12: PRINT "Something is wrong - not magic!"
    END IF
    COLOR 7
NextSize:
LOOP
PRINT "Bye!"
