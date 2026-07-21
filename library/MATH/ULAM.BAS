' ============================================================
' TITLE:    Ulam Prime Spiral
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     primes, sieve of eratosthenes, spiral, graphics, patterns
' SUMMARY:  Writes the numbers in a square spiral and lights up the primes - mysterious diagonal lines appear.
' ------------------------------------------------------------
' WHAT IT DOES
'   In 1963 the mathematician Stanislaw Ulam was doodling during a
'   boring meeting.  He wrote 1 in the middle of the page, then 2, 3,
'   4 ... spiralling outwards, and circled the prime numbers:
'
'        17 16 15 14 13
'        18  5  4  3 12
'        19  6  1  2 11
'        20  7  8  9 10
'        21 22 23 24 25 ...
'
'   The primes cluster along DIAGONAL LINES!  Diagonals correspond
'   to quadratic formulas like 4n^2 + 2n + 41, and some of those
'   formulas produce unusually many primes.  Nobody fully knows why.
'   This program finds primes up to 25600 with the Sieve of
'   Eratosthenes and draws the spiral on a 160 x 160 grid.
'
' HOW TO USE
'   Watch it draw.  Afterwards press D to highlight the famous
'   Euler line n^2 + n + 41, or Esc / Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * The Sieve of Eratosthenes: cross out multiples of each prime
'   * Walking a square spiral: 1 right, 1 up, 2 left, 2 down, 3 right...
'   * Turning directions with (dx, dy) and a "rotate left" rule
'
' THINGS TO TRY
'   * Start the spiral at 41 instead of 1 - one diagonal becomes solid
'   * Colour numbers by how many divisors they have
'   * Make the cells 1 pixel and use more numbers (needs a bigger sieve)
' ============================================================

DEFINT A-Z
CONST SIDE = 160                ' grid is SIDE x SIDE numbers
CONST CELL = 3                  ' each number is a 3x3 pixel square
CONST MAXN = 25600              ' SIDE * SIDE
DIM composite(MAXN) AS INTEGER  ' 0 = still might be prime, 1 = crossed out

SCREEN 12: CLS
COLOR 14: LOCATE 2, 63: PRINT "ULAM SPIRAL"
COLOR 7: LOCATE 4, 63: PRINT "Sieving..."

' ---- Sieve of Eratosthenes ----
' 1 is not prime.  For each p that is still uncrossed, it is prime;
' cross out p*p, p*p + p, p*p + 2p ...  (smaller multiples of p were
' already crossed out by smaller primes).
composite(1) = 1
p = 2
DO WHILE CLNG(p) * p <= MAXN
    IF composite(p) = 0 THEN
        FOR m& = CLNG(p) * p TO MAXN STEP p
            composite(m&) = 1
        NEXT m&
    END IF
    p = p + 1
LOOP
count = 0
FOR i = 2 TO MAXN: IF composite(i) = 0 THEN count = count + 1
NEXT i
LOCATE 4, 63: PRINT "Primes found:"
LOCATE 5, 63: PRINT count; "of"; MAXN

' ---- Spiral walk ----
' Start in the middle; direction (dx, dy) = (1, 0) means "right".
' Rotating 90 degrees left on screen: (dx, dy) -> (dy, -dx).
ox = 240 - SIDE * CELL \ 2: oy = 240 - SIDE * CELL \ 2
x = SIDE \ 2: y = SIDE \ 2
dx = 1: dy = 0
stepLen = 1: stepsDone = 0: turns = 0
FOR n = 1 TO MAXN
    IF composite(n) = 0 THEN
        LINE (ox + x * CELL, oy + y * CELL)-STEP(CELL - 2, CELL - 2), 15, BF
    ELSEIF n = 1 THEN
        LINE (ox + x * CELL, oy + y * CELL)-STEP(CELL - 2, CELL - 2), 12, BF
    END IF
    ' move one step
    x = x + dx: y = y + dy
    stepsDone = stepsDone + 1
    IF stepsDone = stepLen THEN
        stepsDone = 0
        t = dx: dx = dy: dy = -t            ' turn left
        turns = turns + 1
        ' The run length grows by one after every SECOND turn:
        ' 1, 1, 2, 2, 3, 3, 4, 4 ...
        IF turns MOD 2 = 0 THEN stepLen = stepLen + 1
    END IF
NEXT n

COLOR 7
LOCATE 7, 63: PRINT "White = prime"
COLOR 12: LOCATE 8, 63: PRINT "Red = 1 (centre)"
COLOR 7
LOCATE 10, 63: PRINT "See the diagonal"
LOCATE 11, 63: PRINT "streaks?"
LOCATE 13, 63: PRINT "D = Euler's line"
LOCATE 14, 63: PRINT "Esc/Q = quit"

DO
    k$ = UCASE$(INKEY$)
    IF k$ = "D" THEN GOSUB Euler
LOOP UNTIL k$ = "Q" OR k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' Mark n^2 + n + 41 in yellow.  Euler noticed (1772) that this gives
' primes for n = 0 to 39.  In this spiral the even n values land on one
' diagonal half-line and the odd n values on another, because
' (2m)^2 + 2m + 41 = 4m^2 + 2m + 41 and every 4m^2 + bm + c is a diagonal.
Euler:
    ' Walk the spiral again, this time marking members of the formula.
    x = SIDE \ 2: y = SIDE \ 2: dx = 1: dy = 0
    stepLen = 1: stepsDone = 0: turns = 0
    k = 0: target& = 41
    FOR n = 1 TO MAXN
        IF n = target& THEN
            LINE (ox + x * CELL, oy + y * CELL)-STEP(CELL - 2, CELL - 2), 14, BF
            k = k + 1: target& = CLNG(k) * k + k + 41
        END IF
        x = x + dx: y = y + dy
        stepsDone = stepsDone + 1
        IF stepsDone = stepLen THEN
            stepsDone = 0
            t = dx: dx = dy: dy = -t
            turns = turns + 1
            IF turns MOD 2 = 0 THEN stepLen = stepLen + 1
        END IF
    NEXT n
    COLOR 14: LOCATE 16, 63: PRINT "Yellow: n^2+n+41"
    LOCATE 17, 63: PRINT "prime for n=0..39"
    RETURN
