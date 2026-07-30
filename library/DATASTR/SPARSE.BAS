' ============================================================
' TITLE:    Sparse Matrix with Linked Rows
' CATEGORY: Data Structures
' LEVEL:    Advanced
' TAGS:     sparse matrix, linked list, matrix addition, transpose, memory
' SUMMARY:  Stores a mostly-empty 20x40 matrix as linked lists of non-zero cells, then adds, transposes and multiplies it.
' ------------------------------------------------------------
' WHAT IT DOES
'   Many real matrices are SPARSE: almost every entry is zero (a
'   road map between towns, pixels in a line drawing, links between
'   web pages). Storing all those zeros wastes memory.
'
'   Here each ROW of the matrix is a sorted linked list of only
'   the non-zero cells: (column, value, next). rowHead(r) points to
'   the first cell of row r. All the cells live in one shared pool.
'
'   The program builds two sparse matrices (a diagonal-ish pattern
'   and a random one), draws them, adds them by MERGING the row
'   lists, transposes one, multiplies by a vector and compares the
'   memory used with a normal 2-D array.
'
' HOW TO USE
'   Press a key between steps. Esc quits early.
'
' CONCEPTS YOU WILL LEARN
'   * Several linked lists sharing one node pool
'   * Keeping each list sorted by column so merges are easy
'   * Get / Set on a structure that only stores non-zeros
'   * Counting the memory cost of different representations
'
' THINGS TO TRY
'   * Make the random matrix denser - when does sparse stop paying off?
'   * Add column lists too (an "orthogonal list") for fast column walks
' ============================================================

DEFINT A-Z
DECLARE SUB SetCell (m AS INTEGER, r AS INTEGER, c AS INTEGER, v AS INTEGER)
DECLARE FUNCTION GetCell% (m AS INTEGER, r AS INTEGER, c AS INTEGER)
DECLARE SUB ShowM (m AS INTEGER, title$)
DECLARE SUB Pause ()
DECLARE FUNCTION CountCells% (m AS INTEGER)

CONST ROWS = 20, COLS = 40, MAXC = 600, NMAT = 4
TYPE Cell
    col AS INTEGER
    value AS INTEGER
    nxt AS INTEGER
END TYPE
DIM SHARED pool(1 TO MAXC) AS Cell, used
' rowHead(m, r): first cell of row r in matrix number m.
DIM SHARED rowHead(1 TO NMAT, 1 TO ROWS)
DIM SHARED nCols(1 TO NMAT), nRows(1 TO NMAT)

RANDOMIZE TIMER
FOR m = 1 TO NMAT: nRows(m) = ROWS: nCols(m) = COLS: NEXT m

' ---- Matrix 1: two diagonal stripes --------------------------
FOR r = 1 TO ROWS
    SetCell 1, r, r, 1
    SetCell 1, r, r * 2, 2
NEXT r
' ---- Matrix 2: about 40 random cells -------------------------
FOR i = 1 TO 40
    SetCell 2, INT(RND * ROWS) + 1, INT(RND * COLS) + 1, INT(RND * 9) + 1
NEXT i
ShowM 1, "MATRIX A (two stripes)"
Pause
ShowM 2, "MATRIX B (random)"
Pause

' ---- Addition: merge row lists of A and B into C -------------
' Because both lists are sorted by column, we walk them together
' like zipping a zipper: take the smaller column, or add the
' two values when the columns match.
FOR r = 1 TO ROWS
    pa = rowHead(1, r): pb = rowHead(2, r)
    DO WHILE pa <> 0 OR pb <> 0
        IF pb = 0 THEN
            ca = pool(pa).col: va = pool(pa).value: pa = pool(pa).nxt
        ELSEIF pa = 0 THEN
            ca = pool(pb).col: va = pool(pb).value: pb = pool(pb).nxt
        ELSEIF pool(pa).col < pool(pb).col THEN
            ca = pool(pa).col: va = pool(pa).value: pa = pool(pa).nxt
        ELSEIF pool(pb).col < pool(pa).col THEN
            ca = pool(pb).col: va = pool(pb).value: pb = pool(pb).nxt
        ELSE
            ca = pool(pa).col: va = pool(pa).value + pool(pb).value
            pa = pool(pa).nxt: pb = pool(pb).nxt
        END IF
        SetCell 3, r, ca, va
    LOOP
NEXT r
ShowM 3, "C = A + B (merged row lists)"
Pause

' ---- Transpose of A: cell (r,c) becomes (c,r) -----------------
' Only the first 20 rows of the transpose fit our 20-row lists,
' so we keep the cells whose column is 1..20.
nRows(4) = ROWS: nCols(4) = ROWS
FOR r = 1 TO ROWS
    p = rowHead(1, r)
    DO WHILE p
        IF pool(p).col <= ROWS THEN SetCell 4, pool(p).col, r, pool(p).value
        p = pool(p).nxt
    LOOP
NEXT r
ShowM 4, "TRANSPOSE of A (left 20 columns)"
Pause

' ---- Multiply A by the vector x = (1,2,3,...,40) ---------------
' y(r) = sum over non-zero cells of value * x(col). We never touch
' the zeros, so the work is proportional to the cell count.
CLS
PRINT "y = A times the vector x = (1,2,3,...,40)"
PRINT
work = 0
FOR r = 1 TO ROWS
    y = 0: p = rowHead(1, r)
    DO WHILE p
        y = y + pool(p).value * pool(p).col   ' x(col) = col
        work = work + 1
        p = pool(p).nxt
    LOOP
    PRINT USING "  y(##) = ###"; r; y;
    IF r MOD 4 = 0 THEN PRINT
NEXT r
PRINT
PRINT "Multiplications done:"; work; " (a full matrix would need"; ROWS * COLS; ")"
PRINT
' ---- Memory comparison ----------------------------------------
' A cell uses 3 INTEGERs = 6 bytes; a full matrix uses 2 bytes per entry.
FOR m = 1 TO 3
    n = CountCells%(m)
    PRINT USING "Matrix #: ### non-zeros -> sparse ####  bytes, full #### bytes"; m; n; n * 6 + ROWS * 2; ROWS * COLS * 2
NEXT m
PRINT "Sparse storage wins easily when most entries are zero."
END

FUNCTION CountCells% (m AS INTEGER)
    n = 0
    FOR r = 1 TO nRows(m)
        p = rowHead(m, r)
        DO WHILE p: n = n + 1: p = pool(p).nxt: LOOP
    NEXT r
    CountCells% = n
END FUNCTION

' GetCell%: walk row r's list looking for column c. Missing = 0.
FUNCTION GetCell% (m AS INTEGER, r AS INTEGER, c AS INTEGER)
    p = rowHead(m, r)
    DO WHILE p
        IF pool(p).col = c THEN GetCell% = pool(p).value: EXIT FUNCTION
        IF pool(p).col > c THEN EXIT DO   ' sorted, so we can stop early
        p = pool(p).nxt
    LOOP
    GetCell% = 0
END FUNCTION

SUB Pause
    LOCATE 25, 1: PRINT "Press a key (Esc quits)...";
    k$ = INPUT$(1)
    IF k$ = CHR$(27) THEN END
END SUB

' SetCell: store v at (r,c), keeping the row sorted by column.
' (A real version would also delete a cell when v becomes 0.)
SUB SetCell (m AS INTEGER, r AS INTEGER, c AS INTEGER, v AS INTEGER)
    ' (values above 9 are drawn as # on screen)
    IF c < 1 OR c > nCols(m) THEN EXIT SUB
    prev = 0: p = rowHead(m, r)
    DO WHILE p
        IF pool(p).col >= c THEN EXIT DO
        prev = p: p = pool(p).nxt
    LOOP
    IF p THEN IF pool(p).col = c THEN pool(p).value = v: EXIT SUB  ' overwrite
    IF used = MAXC THEN EXIT SUB
    used = used + 1
    pool(used).col = c: pool(used).value = v: pool(used).nxt = p
    IF prev = 0 THEN rowHead(m, r) = used ELSE pool(prev).nxt = used
END SUB

' ShowM: draw the matrix ('.' for zero) plus the raw list of row 1.
SUB ShowM (m AS INTEGER, title$)
    CLS
    PRINT title$; "  -"; CountCells%(m); "non-zero cells of"; nRows(m) * nCols(m)
    FOR r = 1 TO nRows(m)
        LOCATE r + 1, 1
        PRINT USING "##"; r;
        PRINT " ";
        FOR c = 1 TO nCols(m)
            v = GetCell%(m, r, c)
            IF v = 0 THEN COLOR 8: PRINT "."; ELSE COLOR 14: IF v > 9 THEN PRINT "#"; ELSE PRINT LTRIM$(STR$(v));
        NEXT c
        COLOR 7
    NEXT r
    LOCATE 23, 1: PRINT "Row 1 as a list: head";
    p = rowHead(m, 1)
    DO WHILE p
        IF POS(0) > 66 THEN PRINT " ...";: EXIT SUB
        PRINT " -> (c"; LTRIM$(STR$(pool(p).col)); ","; LTRIM$(STR$(pool(p).value)); ")";
        p = pool(p).nxt
    LOOP
    PRINT " -> 0"
END SUB
