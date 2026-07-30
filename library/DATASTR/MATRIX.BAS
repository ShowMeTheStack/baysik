' ============================================================
' TITLE:    Grid and Matrix Workshop
' CATEGORY: Data Structures
' LEVEL:    Beginner
' TAGS:     2D arrays, matrix, rotate, transpose, multiply, grid
' SUMMARY:  Rotate, flip and transpose a pixel-art picture stored in a 2-D array, then multiply two matrices.
' ------------------------------------------------------------
' WHAT IT DOES
'   A 2-D array is a grid: g(row, col). Lots of things are grids -
'   game boards, spreadsheets, pictures. This program loads a small
'   8x8 picture (a rocket) from DATA lines and lets you transform
'   it. Each transform is just a different rule for WHERE each cell
'   moves to:
'       transpose      new(r, c) = old(c, r)
'       flip left/right new(r, c) = old(r, N+1-c)
'       flip up/down    new(r, c) = old(N+1-r, c)
'       rotate right    new(r, c) = old(N+1-c, r)
'   Then it shows matrix multiplication, where each answer cell is
'   a row of the first matrix "dotted" with a column of the second.
'
' HOW TO USE
'   T = transpose   H = flip horizontal   V = flip vertical
'   R = rotate 90 degrees clockwise       I = invert colours
'   M = matrix multiplication demo        Q / Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Nested FOR loops over rows and columns
'   * Why you need a second (temporary) array when transforming
'   * Row-by-column multiplication of matrices
'
' THINGS TO TRY
'   * Draw your own 8x8 picture in the DATA lines
'   * Rotate four times - are you back where you started?
'   * Add "rotate left" (hint: three rights make a left!)
' ============================================================

DEFINT A-Z
CONST N = 8
DIM g(1 TO N, 1 TO N)        ' the picture: 1 = filled, 0 = empty
DIM tmp(1 TO N, 1 TO N)      ' scratch copy used during transforms
DIM a(1 TO 2, 1 TO 3), b(1 TO 3, 1 TO 2), cm(1 TO 2, 1 TO 2)  ' for the multiply demo

' Load the picture. Each DATA string is one row; "#" = filled.
FOR r = 1 TO N
    READ row$
    FOR c = 1 TO N
        IF MID$(row$, c, 1) = "#" THEN g(r, c) = 1
    NEXT c
NEXT r
DATA "...##..."
DATA "..####.."
DATA "..#..#.."
DATA "..####.."
DATA "..####.."
DATA ".######."
DATA "##.##.##"
DATA "#..##..#"

last$ = "Original picture"
DO
    CLS
    PRINT "GRID WORKSHOP - an 8x8 picture in the array g(row, col)"
    PRINT
    ' Draw: each cell is 2 characters wide so it looks square.
    FOR r = 1 TO N
        PRINT "   ";
        FOR c = 1 TO N
            IF g(r, c) THEN COLOR 14: PRINT CHR$(219); CHR$(219); ELSE COLOR 8: PRINT ". ";
        NEXT c
        COLOR 7
        ' Also show the raw numbers beside the picture.
        PRINT "     ";
        FOR c = 1 TO N: PRINT g(r, c); : NEXT c
        PRINT
    NEXT r
    PRINT
    PRINT "Last action: "; last$
    PRINT
    PRINT "(T)ranspose (H)flip (V)flip (R)otate (I)nvert (M)ultiply demo (Q)uit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""

    ' Each transform writes into tmp() using the old g(), then
    ' copies tmp() back. If we wrote straight into g() we would
    ' overwrite cells we still need to read!
    SELECT CASE k$
    CASE "T"
        FOR r = 1 TO N: FOR c = 1 TO N: tmp(r, c) = g(c, r): NEXT c: NEXT r
        last$ = "Transpose: rows became columns (mirror on the diagonal)"
    CASE "H"
        FOR r = 1 TO N: FOR c = 1 TO N: tmp(r, c) = g(r, N + 1 - c): NEXT c: NEXT r
        last$ = "Flip horizontal: column c came from column N+1-c"
    CASE "V"
        FOR r = 1 TO N: FOR c = 1 TO N: tmp(r, c) = g(N + 1 - r, c): NEXT c: NEXT r
        last$ = "Flip vertical: row r came from row N+1-r"
    CASE "R"
        ' Rotate clockwise = transpose, then flip horizontally,
        ' done in one step with this formula:
        FOR r = 1 TO N: FOR c = 1 TO N: tmp(r, c) = g(N + 1 - c, r): NEXT c: NEXT r
        last$ = "Rotate 90 clockwise: new(r,c) = old(N+1-c, r)"
    CASE "I"
        FOR r = 1 TO N: FOR c = 1 TO N: tmp(r, c) = 1 - g(r, c): NEXT c: NEXT r
        last$ = "Invert: 1 - value turns 0 into 1 and 1 into 0"
    CASE "M"
        GOSUB MultiplyDemo
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
    IF INSTR("THVRI", k$) > 0 AND k$ <> "" THEN
        FOR r = 1 TO N: FOR c = 1 TO N: g(r, c) = tmp(r, c): NEXT c: NEXT r
    END IF
LOOP
CLS : PRINT "Bye!"
END

' -------------------------------------------------------------
' Matrix multiplication: C = A x B.
' A is 2x3 and B is 3x2, so C is 2x2. Cell C(i,j) is
'   A(i,1)*B(1,j) + A(i,2)*B(2,j) + A(i,3)*B(3,j)
' i.e. walk ALONG row i of A and DOWN column j of B together.
' -------------------------------------------------------------
MultiplyDemo:
    CLS
    RESTORE MatData
    FOR i = 1 TO 2: FOR j = 1 TO 3: READ a(i, j): NEXT j: NEXT i
    FOR i = 1 TO 3: FOR j = 1 TO 2: READ b(i, j): NEXT j: NEXT i
    PRINT "A (2 x 3):          B (3 x 2):"
    FOR i = 1 TO 3
        IF i <= 2 THEN FOR j = 1 TO 3: PRINT USING "###"; a(i, j); : NEXT j ELSE PRINT SPACE$(9);
        PRINT SPACE$(11);
        FOR j = 1 TO 2: PRINT USING "###"; b(i, j); : NEXT j
        PRINT
    NEXT i
    PRINT
    FOR i = 1 TO 2
        FOR j = 1 TO 2
            cm(i, j) = 0
            PRINT "C("; LTRIM$(STR$(i)); ","; LTRIM$(STR$(j)); ") =";
            FOR k = 1 TO 3
                cm(i, j) = cm(i, j) + a(i, k) * b(k, j)
                PRINT a(i, k); "*"; b(k, j);
                IF k < 3 THEN PRINT " +";
            NEXT k
            PRINT " ="; cm(i, j)
        NEXT j
    NEXT i
    PRINT
    PRINT "C (2 x 2):"
    FOR i = 1 TO 2: FOR j = 1 TO 2: PRINT USING "####"; cm(i, j); : NEXT j: PRINT : NEXT i
    PRINT
    PRINT "Rule: (rows x shared) times (shared x cols) gives (rows x cols)."
    PRINT "Press a key...": k$ = INPUT$(1)
    last$ = "Matrix multiplication demo"
    k$ = ""
    RETURN
MatData:
DATA 1, 2, 3
DATA 4, 5, 6
DATA 7, 8
DATA 9, 10
DATA 11, 12
