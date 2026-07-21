' ============================================================
' TITLE:    Pascal's Triangle & Sierpinski
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     pascal, binomial, combinations, patterns, graphics
' SUMMARY:  Builds Pascal's triangle, then colours it by remainders to reveal hidden fractals.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pascal's triangle starts with a 1 at the top.  Every other number
'   is the sum of the two numbers just above it.  Row n holds the
'   "binomial coefficients" C(n,k): the number of ways to choose k
'   things out of n, and the coefficients of (a + b)^n.
'   Part 2 draws 128 rows as coloured dots, coloured by the remainder
'   when each number is divided by 2, 3, 4 or 5.  Dividing by 2 gives
'   the Sierpinski triangle - a fractal hiding in plain arithmetic!
'
' HOW TO USE
'   Read the triangle, then press a key.  In the picture press
'   2-9 to change the divisor, or Esc / Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Building each row from the previous row (dynamic programming)
'   * Working "mod m" so numbers never get too big
'   * Centering text with LOCATE and TAB
'
' THINGS TO TRY
'   * Add up each row: you always get a power of 2. Why?
'   * Look for the Fibonacci numbers along the shallow diagonals
'   * Colour the cells by "divisible by m" vs "not divisible" only
' ============================================================

DEFLNG A-Z
DIM row(20), nxt(20)

CLS
COLOR 14: PRINT "PASCAL'S TRIANGLE  (each number = sum of the two above)": COLOR 7
PRINT
row(0) = 1
FOR n = 0 TO 12
    ' Print row n.  Each number takes 4 columns; shifting each row
    ' left by 2 columns makes the triangle shape.
    PRINT TAB(38 - 2 * n);
    FOR k = 0 TO n
        PRINT USING "####"; row(k);
    NEXT k
    PRINT
    ' Build row n+1:  new(k) = old(k-1) + old(k)
    nxt(0) = 1
    FOR k = 1 TO n
        nxt(k) = row(k - 1) + row(k)
    NEXT k
    nxt(n + 1) = 1
    FOR k = 0 TO n + 1: row(k) = nxt(k): NEXT k
NEXT n
PRINT
PRINT "Row 4 is 1 4 6 4 1, so (a+b)^4 = a^4 + 4a^3b + 6a^2b^2 + 4ab^3 + b^4"
PRINT "Press any key to see the triangle coloured by remainders..."
k$ = INPUT$(1)

' ------------------------------------------------------------
' Picture mode
' ------------------------------------------------------------
CONST ROWS = 128
DIM r(ROWS), t(ROWS)
SCREEN 12
m = 2
DO
    CLS
    COLOR 15
    LOCATE 1, 1: PRINT "Pascal's triangle MOD"; m; "  (2-9 = change, Q = quit)"
    ' We only ever store remainders, so the numbers stay tiny even
    ' though C(127, 63) has 38 digits!
    FOR k = 0 TO ROWS: r(k) = 0: NEXT k
    r(0) = 1
    FOR n = 0 TO ROWS - 1
        y = 40 + n * 3.4
        FOR k = 0 TO n
            ' x position: centre the row, 3.9 pixels per number
            x = 320 + (k - n / 2) * 3.9
            v = r(k)
            ' Remainder 0 stays black; other remainders get colours.
            IF v > 0 THEN LINE (x, y)-(x + 2, y + 2), 8 + v MOD 8, BF
        NEXT k
        t(0) = 1
        FOR k = 1 TO n: t(k) = (r(k - 1) + r(k)) MOD m: NEXT k
        t(n + 1) = 1
        FOR k = 0 TO n + 1: r(k) = t(k): NEXT k
    NEXT n
    ' Wait for a key we understand.
    DO
        k$ = UCASE$(INKEY$)
    LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ >= "2" AND k$ <= "9" THEN m = VAL(k$)
LOOP
SCREEN 0: WIDTH 80
