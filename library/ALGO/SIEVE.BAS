' ============================================================
' TITLE:    Sieve of Eratosthenes
' CATEGORY: Algorithms
' LEVEL:    Beginner
' TAGS:     primes, math, arrays, graphics
' SUMMARY:  A 2200-year-old algorithm crosses out multiples on a colourful grid until only the primes are left.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws the numbers 1 to 240 in a grid.  Starting with 2, it finds
'   the next number that is not crossed out (that number is PRIME),
'   colours it, and crosses out all of its multiples in a matching
'   colour.  It stops once p*p is bigger than 240.  Everything still
'   white at the end is prime.  Then it sieves up to 20000 at full
'   speed and reports how many primes it found.
'
' HOW TO USE
'   Watch the animation.  Press a key to continue at each pause.
'   Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * A boolean "crossed out" array as a sieve
'   * Why we only need to sieve with primes up to SQR(n)
'   * Why crossing out can start at p*p
'   * Complexity O(n log log n) - almost linear!
'   * Drawing text-and-boxes grids in SCREEN 12
'
' THINGS TO TRY
'   * Change LIMIT to 1000000 - but mind the memory for the array
'   * Print the twin primes (pairs like 11 and 13)
' ============================================================
DECLARE SUB Cell (k%, fg%, bg%)
DECLARE SUB WaitKey ()
DEFINT A-Z
CONST SHOWN = 240           ' numbers in the animated grid
CONST COLS = 20             ' grid columns
DIM SHARED crossed(1 TO SHOWN)

SCREEN 12
COLOR 15
LOCATE 1, 1: PRINT "Sieve of Eratosthenes: numbers 1 to"; SHOWN
FOR k = 1 TO SHOWN: Cell k, 15, 8: NEXT
crossed(1) = -1: Cell 1, 8, 8        ' 1 is not prime by definition
WaitKey

' ---- The sieve ----------------------------------------------
' For each p from 2 upward:
'   if p is not crossed out, nobody smaller divides it -> PRIME.
'   Cross out 2p, 3p, 4p ... because they all have p as a factor.
' Two speed-ups:
'   * Start crossing at p*p.  Smaller multiples like 3p were already
'     crossed out by the smaller prime 3.
'   * Stop when p*p > n.  Any composite number <= n has a factor no
'     bigger than SQR(n), so it has already been crossed out.
colr = 9
FOR p = 2 TO SHOWN
    IF p * p > SHOWN THEN EXIT FOR
    IF NOT crossed(p) THEN
        Cell p, colr, colr                       ' highlight the prime
        LOCATE 2, 1: PRINT "Prime"; p; ": crossing out"; p * p; "+"; p; "+"; p; "...      "
        FOR m = p * p TO SHOWN STEP p
            IF NOT crossed(m) THEN
                crossed(m) = -1
                Cell m, 8, colr - 8           ' darker shade = crossed out
                FOR d& = 1 TO 400: NEXT       ' small animation delay
            END IF
        NEXT
        colr = colr + 1: IF colr > 14 THEN colr = 9
        WaitKey
    END IF
NEXT

' Everything still not crossed out is prime.  Colour them green.
cnt = 0
FOR k = 2 TO SHOWN
    IF NOT crossed(k) THEN Cell k, 10, 10: cnt = cnt + 1
NEXT
LOCATE 2, 1: PRINT "Done!"; cnt; "primes below"; SHOWN; "(green). Press a key.         "
WaitKey

' ---- Big sieve, no graphics ---------------------------------
' Crossing out costs n/2 + n/3 + n/5 + n/7 + ... = n * (1/2+1/3+1/5..)
' and that sum over primes grows like log(log(n)), which is tiny:
' for n = 20000 it is about 2.3.  So the sieve is nearly O(n).
CONST LIMIT = 20000
DIM big(1 TO LIMIT) AS INTEGER
SCREEN 0: WIDTH 80: CLS
PRINT "Sieving up to"; LIMIT; "..."
t! = TIMER
work& = 0
big(1) = -1
FOR p = 2 TO INT(SQR(LIMIT))
    IF NOT big(p) THEN
        FOR m = p * p TO LIMIT STEP p
            big(m) = -1: work& = work& + 1
        NEXT
    END IF
NEXT
cnt = 0: last = 0
FOR k = 2 TO LIMIT
    IF NOT big(k) THEN cnt = cnt + 1: last = k
NEXT
PRINT "Found"; cnt; "primes. The biggest is"; last
PRINT "Cross-out operations:"; work&; " (n ="; LIMIT; ")"
PRINT USING "Time: ##.## seconds"; TIMER - t!
PRINT
PRINT "The last 10 primes:";
c = 0
FOR k = LIMIT TO 2 STEP -1
    IF NOT big(k) THEN PRINT k; : c = c + 1
    IF c = 10 THEN EXIT FOR
NEXT
PRINT : PRINT : PRINT "Press a key to quit."
WaitKey
END

' Draws number k in its grid cell with foreground fg and background bg.
' Each cell is 32x32 pixels, starting at y = 40, so the number lands
' exactly on a text row (SCREEN 12 text rows are 16 pixels high).
' PRINT in graphics mode paints a black background behind the digits,
' so each cell looks like a coloured frame around a black label.
SUB Cell (k, fg, bg)
    r = (k - 1) \ COLS: c = (k - 1) MOD COLS
    x = c * 32: y = 40 + r * 32
    LINE (x + 1, y + 1)-(x + 30, y + 30), bg, BF
    ' text rows are 16 pixels high in SCREEN 12, columns 8 wide
    COLOR fg
    LOCATE (y + 8) \ 16 + 1, x \ 8 + 1
    PRINT USING "###"; k;
    COLOR 15
END SUB

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
END SUB
